import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_judgment_draft_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/storage/dtos/upload_url_dto.dart';
import 'package:animus/core/storage/interfaces/drivers/document_picker_driver.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/core/storage/interfaces/storage_service.dart';
import 'package:animus/drivers/document-picker-driver/index.dart';
import 'package:animus/drivers/file_storage/index.dart';
import 'package:animus/rest/services/index.dart';

class SecondInstanceFirstInstanceAnalysisScreenPresenter {
  static const List<String> allowedExtensions = <String>['pdf'];
  static const int maxFileSizeInBytes = 50 * 1024 * 1024;
  static const Duration pollingInterval = Duration(seconds: 3);
  static const Duration requestTimeout = Duration(seconds: 10);
  static const String failedMessage =
      'Não foi possível concluir esta etapa agora. Tente novamente.';

  final IntakeService _intakeService;
  final StorageService _storageService;
  final FileStorageDriver _fileStorageDriver;
  final DocumentPickerDriver _documentPickerDriver;
  final String analysisId;

  final Signal<AnalysisStatusDto> status = signal<AnalysisStatusDto>(
    AnalysisStatusDto.waitingDocumentUpload,
  );
  final Signal<File?> selectedFile = signal<File?>(null);
  final Signal<AnalysisDocumentDto?> analysisDocument =
      signal<AnalysisDocumentDto?>(null);
  final Signal<bool> isUploading = signal<bool>(false);
  final Signal<double?> uploadProgress = signal<double?>(null);
  final Signal<CaseSummaryDto?> caseSummary = signal<CaseSummaryDto?>(null);
  final Signal<SecondInstanceJudgmentDraftDto?> judgmentDraft =
      signal<SecondInstanceJudgmentDraftDto?>(null);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<String> analysisName = signal<String>('Nova Análise');
  final Signal<bool> isArchived = signal<bool>(false);
  final Signal<bool> isManagingAnalysis = signal<bool>(false);
  final Signal<bool> precedentsReady = signal<bool>(false);
  final Signal<bool> hasChosenPrecedents = signal<bool>(false);

  late final ReadonlySignal<bool> canPickDocument = computed(() {
    final AnalysisStatusDto currentStatus = status.value;
    final bool isProcessingCase =
        currentStatus == AnalysisStatusDto.extractingPetition ||
        currentStatus == AnalysisStatusDto.analyzingCase;
    final bool isProcessingDraft =
        currentStatus == AnalysisStatusDto.generatingJudgmentDraft;

    return !isUploading.value &&
        !isManagingAnalysis.value &&
        !isProcessingCase &&
        !isProcessingDraft;
  });

  late final ReadonlySignal<bool> canAnalyzeCase = computed(() {
    return !isUploading.value &&
        !isManagingAnalysis.value &&
        (selectedFile.value != null || analysisDocument.value != null) &&
        (status.value == AnalysisStatusDto.documentUploaded ||
            status.value == AnalysisStatusDto.failed);
  });

  late final ReadonlySignal<bool> canRegenerateSummary = computed(() {
    return !isUploading.value &&
        !isManagingAnalysis.value &&
        status.value == AnalysisStatusDto.caseAnalyzed;
  });

  late final ReadonlySignal<bool> canSearchPrecedents = computed(() {
    return !isUploading.value &&
        !isManagingAnalysis.value &&
        status.value == AnalysisStatusDto.caseAnalyzed &&
        caseSummary.value != null;
  });

  late final ReadonlySignal<bool> canGenerateJudgmentDraft = computed(() {
    return !isUploading.value &&
        !isManagingAnalysis.value &&
        precedentsReady.value &&
        hasChosenPrecedents.value &&
        status.value != AnalysisStatusDto.generatingJudgmentDraft &&
        status.value != AnalysisStatusDto.generatingSynthesis;
  });

  late final ReadonlySignal<bool> canRegenerateJudgmentDraft = computed(() {
    return !isUploading.value &&
        !isManagingAnalysis.value &&
        status.value == AnalysisStatusDto.done &&
        judgmentDraft.value != null;
  });

  late final ReadonlySignal<bool> showCaseProcessingBubble = computed(() {
    return status.value == AnalysisStatusDto.extractingPetition ||
        status.value == AnalysisStatusDto.analyzingCase;
  });

  late final ReadonlySignal<bool> showJudgmentDraftProcessingBubble = computed(
    () =>
        status.value == AnalysisStatusDto.generatingJudgmentDraft ||
        status.value == AnalysisStatusDto.generatingSynthesis,
  );

  late final ReadonlySignal<bool> showPetitionNotFound = computed(
    () => status.value == AnalysisStatusDto.petitionNotFound,
  );

  late final ReadonlySignal<String> primaryActionLabel = computed(() {
    if (status.value == AnalysisStatusDto.failed) {
      if (precedentsReady.value && hasChosenPrecedents.value) {
        return 'Tentar gerar minuta novamente';
      }

      if (caseSummary.value != null) {
        return 'Tentar buscar precedentes novamente';
      }

      return 'Tentar analisar novamente';
    }

    if (status.value == AnalysisStatusDto.done) {
      return 'Regerar minuta';
    }

    if (status.value == AnalysisStatusDto.generatingJudgmentDraft ||
        canGenerateJudgmentDraft.value ||
        precedentsReady.value) {
      return 'Gerar minuta';
    }

    if (canSearchPrecedents.value) {
      return 'Buscar precedentes';
    }

    return 'Analisar';
  });

  SecondInstanceFirstInstanceAnalysisScreenPresenter({
    required IntakeService intakeService,
    required StorageService storageService,
    required FileStorageDriver fileStorageDriver,
    required DocumentPickerDriver documentPickerDriver,
    required this.analysisId,
  }) : _intakeService = intakeService,
       _storageService = storageService,
       _fileStorageDriver = fileStorageDriver,
       _documentPickerDriver = documentPickerDriver;

  Future<void> load() async {
    generalError.value = null;

    final RestResponse<AnalysisDto> analysisResponse = await _intakeService
        .getAnalysis(analysisId: analysisId);

    if (analysisResponse.isFailure) {
      status.value = AnalysisStatusDto.waitingDocumentUpload;
      return;
    }

    final AnalysisDto analysis = analysisResponse.body;
    analysisName.value = analysis.name;
    isArchived.value = analysis.isArchived;
    status.value = analysis.status;
    precedentsReady.value = _isPrecedentsReadyStatus(analysis.status);

    if (_shouldLoadAnalysisDocument(analysis.status)) {
      final RestResponse<AnalysisDocumentDto> documentResponse =
          await _intakeService.getAnalysisDocument(analysisId: analysisId);
      if (documentResponse.isSuccessful) {
        analysisDocument.value = documentResponse.body;
      }
    }

    if (_shouldLoadSummary(analysis.status)) {
      final RestResponse<CaseSummaryDto> summaryResponse = await _intakeService
          .getCaseSummary(analysisId: analysisId);
      if (summaryResponse.isSuccessful) {
        caseSummary.value = summaryResponse.body;
      }
    }

    if (_shouldLoadJudgmentDraft(analysis.status)) {
      await _tryLoadJudgmentDraft();
    }
  }

  Future<void> pickDocument() async {
    if (!canPickDocument.value) {
      return;
    }

    generalError.value = null;

    final File? file = await _documentPickerDriver.pickDocument(
      allowedExtensions: allowedExtensions,
    );

    if (file == null) {
      return;
    }

    final String extension = _getExtension(file.path);
    if (!allowedExtensions.contains(extension)) {
      generalError.value = 'Selecione um arquivo PDF.';
      return;
    }

    final int fileSize = await file.length();
    if (fileSize > maxFileSizeInBytes) {
      generalError.value = 'O arquivo deve ter no máximo 50MB.';
      return;
    }

    selectedFile.value = file;
    await _uploadAnalysisDocument(file);
  }

  Future<void> analyzeCase() async {
    if (!canAnalyzeCase.value) {
      return;
    }

    generalError.value = null;
    isManagingAnalysis.value = true;

    try {
      final RestResponse<void> response = await _intakeService
          .triggerSecondInstanceCaseSummarization(analysisId: analysisId)
          .timeout(
            requestTimeout,
            onTimeout: () => RestResponse<void>(
              statusCode: HttpStatus.requestTimeout,
              errorMessage: _buildTimeoutMessage(),
            ),
          );

      if (response.isFailure) {
        await _applyFailure(response.errorMessage);
        return;
      }

      status.value = AnalysisStatusDto.extractingPetition;
      await _pollUntilCaseReady();
    } finally {
      isManagingAnalysis.value = false;
    }
  }

  Future<void> reanalyzeCase() async {
    if (!canRegenerateSummary.value) {
      return;
    }

    caseSummary.value = null;
    judgmentDraft.value = null;
    precedentsReady.value = false;
    status.value = AnalysisStatusDto.documentUploaded;
    await analyzeCase();
  }

  Future<void> requestJudgmentDraft() async {
    if (!canGenerateJudgmentDraft.value && !canRegenerateJudgmentDraft.value) {
      return;
    }

    generalError.value = null;
    status.value = AnalysisStatusDto.generatingJudgmentDraft;
    isManagingAnalysis.value = true;

    try {
      final RestResponse<void> triggerResponse = await _intakeService
          .triggerSecondInstanceJudgmentDraftGeneration(analysisId: analysisId)
          .timeout(
            requestTimeout,
            onTimeout: () => RestResponse<void>(
              statusCode: HttpStatus.requestTimeout,
              errorMessage: _buildTimeoutMessage(),
            ),
          );

      if (triggerResponse.isFailure) {
        await _applyFailure(triggerResponse.errorMessage);
        return;
      }

      await _pollUntilJudgmentDraftReady();
    } finally {
      isManagingAnalysis.value = false;
    }
  }

  Future<void> regenerateJudgmentDraft() async {
    if (!canRegenerateJudgmentDraft.value) {
      return;
    }

    judgmentDraft.value = null;
    await requestJudgmentDraft();
  }

  Future<void> resendDocument() async {
    selectedFile.value = null;
    analysisDocument.value = null;
    caseSummary.value = null;
    judgmentDraft.value = null;
    precedentsReady.value = false;
    uploadProgress.value = null;
    generalError.value = null;
    status.value = AnalysisStatusDto.waitingDocumentUpload;
    await pickDocument();
  }

  Future<bool> renameAnalysis(String name) async {
    if (isManagingAnalysis.value) {
      return false;
    }

    final String normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      generalError.value = 'Informe um nome válido para a análise.';
      return false;
    }

    isManagingAnalysis.value = true;
    final RestResponse<AnalysisDto> response = await _intakeService
        .renameAnalysis(analysisId: analysisId, name: normalizedName);
    isManagingAnalysis.value = false;

    if (response.isFailure) {
      generalError.value = response.errorMessage;
      return false;
    }

    analysisName.value = response.body.name;
    generalError.value = null;
    return true;
  }

  Future<bool> archiveAnalysis() async {
    if (isManagingAnalysis.value) {
      return false;
    }

    isManagingAnalysis.value = true;
    final RestResponse<AnalysisDto> response = await _intakeService
        .archiveAnalysis(analysisId: analysisId);
    isManagingAnalysis.value = false;

    if (response.isFailure) {
      generalError.value = response.errorMessage;
      return false;
    }

    generalError.value = null;
    return true;
  }

  void markPrecedentsReady() {
    precedentsReady.value = true;
  }

  void syncChosenPrecedents(List<AnalysisPrecedentDto> precedents) {
    hasChosenPrecedents.value = precedents.isNotEmpty;
  }

  String fileName(File file) {
    if (file.uri.pathSegments.isNotEmpty) {
      return file.uri.pathSegments.last;
    }

    return file.path;
  }

  String formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    }

    final double sizeInKb = sizeInBytes / 1024;
    if (sizeInKb < 1024) {
      return '${sizeInKb.toStringAsFixed(1)} KB';
    }

    final double sizeInMb = sizeInKb / 1024;
    return '${sizeInMb.toStringAsFixed(1)} MB';
  }

  void dispose() {
    status.dispose();
    selectedFile.dispose();
    analysisDocument.dispose();
    isUploading.dispose();
    uploadProgress.dispose();
    caseSummary.dispose();
    judgmentDraft.dispose();
    generalError.dispose();
    analysisName.dispose();
    isArchived.dispose();
    isManagingAnalysis.dispose();
    precedentsReady.dispose();
    hasChosenPrecedents.dispose();
    canPickDocument.dispose();
    canAnalyzeCase.dispose();
    canRegenerateSummary.dispose();
    canSearchPrecedents.dispose();
    canGenerateJudgmentDraft.dispose();
    canRegenerateJudgmentDraft.dispose();
    showCaseProcessingBubble.dispose();
    showJudgmentDraftProcessingBubble.dispose();
    showPetitionNotFound.dispose();
    primaryActionLabel.dispose();
  }

  Future<void> _uploadAnalysisDocument(File file) async {
    uploadProgress.value = 0;
    isUploading.value = true;

    final RestResponse<UploadUrlDto> uploadUrlResponse = await _storageService
        .generateAnalysisDocumentUploadUrl(
          analysisId: analysisId,
          documentType: _getExtension(file.path),
        );

    if (uploadUrlResponse.isFailure) {
      isUploading.value = false;
      uploadProgress.value = null;
      await _applyFailure(uploadUrlResponse.errorMessage);
      return;
    }

    try {
      await _fileStorageDriver.uploadFile(
        file,
        uploadUrlResponse.body,
        onProgress: (int sentBytes, int totalBytes) {
          if (totalBytes <= 0) {
            uploadProgress.value = null;
            return;
          }

          uploadProgress.value = sentBytes / totalBytes;
        },
      );
    } catch (_) {
      isUploading.value = false;
      uploadProgress.value = null;
      await _applyFailure();
      return;
    }

    final RestResponse<AnalysisDocumentDto> createDocumentResponse =
        await _intakeService.createAnalysisDocument(
          analysisId: analysisId,
          document: AnalysisDocumentDto(
            analysisId: analysisId,
            uploadedAt: DateTime.now().toUtc().toIso8601String(),
            filePath: uploadUrlResponse.body.filePath,
            name: fileName(file),
          ),
        );

    if (createDocumentResponse.isFailure) {
      isUploading.value = false;
      uploadProgress.value = null;
      await _applyFailure(createDocumentResponse.errorMessage);
      return;
    }

    analysisDocument.value = createDocumentResponse.body;

    final RestResponse<AnalysisStatusDto> statusResponse = await _intakeService
        .updateAnalysisStatus(
          analysisId: analysisId,
          status: AnalysisStatusDto.documentUploaded,
        );

    isUploading.value = false;

    if (statusResponse.isFailure) {
      uploadProgress.value = null;
      await _applyFailure(statusResponse.errorMessage);
      return;
    }

    uploadProgress.value = 1;
    status.value = statusResponse.body;
    generalError.value = null;
  }

  Future<void> _pollUntilCaseReady() async {
    while (true) {
      final RestResponse<AnalysisDto> analysisResponse = await _intakeService
          .getAnalysis(analysisId: analysisId)
          .timeout(
            requestTimeout,
            onTimeout: () => RestResponse<AnalysisDto>(
              statusCode: HttpStatus.requestTimeout,
              errorMessage: _buildTimeoutMessage(),
            ),
          );

      if (analysisResponse.isFailure) {
        await _applyFailure(analysisResponse.errorMessage);
        return;
      }

      final AnalysisStatusDto currentStatus = analysisResponse.body.status;
      status.value = currentStatus;

      if (currentStatus == AnalysisStatusDto.caseAnalyzed) {
        final RestResponse<CaseSummaryDto> summaryResponse =
            await _intakeService.getCaseSummary(analysisId: analysisId);

        if (summaryResponse.isFailure) {
          await _applyFailure(summaryResponse.errorMessage);
          return;
        }

        caseSummary.value = summaryResponse.body;
        precedentsReady.value = false;
        generalError.value = null;
        return;
      }

      if (currentStatus == AnalysisStatusDto.petitionNotFound) {
        generalError.value = null;
        return;
      }

      if (currentStatus == AnalysisStatusDto.failed) {
        await _applyFailure();
        return;
      }

      await Future<void>.delayed(pollingInterval);
    }
  }

  Future<void> _pollUntilJudgmentDraftReady() async {
    while (true) {
      final RestResponse<AnalysisDto> analysisResponse = await _intakeService
          .getAnalysis(analysisId: analysisId)
          .timeout(
            requestTimeout,
            onTimeout: () => RestResponse<AnalysisDto>(
              statusCode: HttpStatus.requestTimeout,
              errorMessage: _buildTimeoutMessage(),
            ),
          );

      if (analysisResponse.isFailure) {
        await _applyFailure(analysisResponse.errorMessage);
        return;
      }

      final AnalysisStatusDto currentStatus = analysisResponse.body.status;
      status.value = currentStatus;

      if (_shouldLoadJudgmentDraft(currentStatus)) {
        await _tryLoadJudgmentDraft();
      }

      if (currentStatus == AnalysisStatusDto.done) {
        if (judgmentDraft.value != null) {
          generalError.value = null;
          return;
        }

        final bool didLoadDraft = await _tryLoadJudgmentDraft();
        if (!didLoadDraft) {
          await _applyFailure();
          return;
        }

        generalError.value = null;
        return;
      }

      if (currentStatus == AnalysisStatusDto.failed) {
        await _applyFailure();
        return;
      }

      await Future<void>.delayed(pollingInterval);
    }
  }

  Future<void> _applyFailure([String? message]) async {
    final String errorMessage = message == null || message.isEmpty
        ? failedMessage
        : message;
    generalError.value = errorMessage;
    status.value = AnalysisStatusDto.failed;
  }

  bool _shouldLoadSummary(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.caseAnalyzed ||
        value == AnalysisStatusDto.searchingPrecedents ||
        value == AnalysisStatusDto.precedentsSearched ||
        value == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        value == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        value == AnalysisStatusDto.generatingJudgmentDraft ||
        value == AnalysisStatusDto.generatingSynthesis ||
        value == AnalysisStatusDto.done;
  }

  bool _shouldLoadAnalysisDocument(AnalysisStatusDto value) {
    return value != AnalysisStatusDto.waitingDocumentUpload;
  }

  bool _shouldLoadJudgmentDraft(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.searchingPrecedents ||
        value == AnalysisStatusDto.precedentsSearched ||
        value == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        value == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        value == AnalysisStatusDto.generatingJudgmentDraft ||
        value == AnalysisStatusDto.generatingSynthesis ||
        value == AnalysisStatusDto.done;
  }

  Future<bool> _tryLoadJudgmentDraft() async {
    final RestResponse<SecondInstanceJudgmentDraftDto> draftResponse =
        await _intakeService.getSecondInstanceJudgmentDraft(
          analysisId: analysisId,
        );

    if (draftResponse.isFailure) {
      if (draftResponse.statusCode == HttpStatus.notFound) {
        return false;
      }

      return false;
    }

    judgmentDraft.value = draftResponse.body;
    return true;
  }

  bool _isPrecedentsReadyStatus(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.searchingPrecedents ||
        value == AnalysisStatusDto.precedentsSearched ||
        value == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        value == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        value == AnalysisStatusDto.generatingJudgmentDraft ||
        value == AnalysisStatusDto.generatingSynthesis ||
        value == AnalysisStatusDto.done;
  }

  String _buildTimeoutMessage() {
    return '$failedMessage A requisição excedeu o tempo limite de ${requestTimeout.inSeconds} segundos.';
  }

  String _getExtension(String path) {
    final int lastDot = path.lastIndexOf('.');
    if (lastDot < 0 || lastDot == path.length - 1) {
      return '';
    }

    return path.substring(lastDot + 1).toLowerCase();
  }
}

final secondInstanceFirstInstanceAnalysisScreenPresenterProvider = Provider
    .autoDispose
    .family<SecondInstanceFirstInstanceAnalysisScreenPresenter, String>((
      Ref ref,
      String analysisId,
    ) {
      final IntakeService intakeService = ref.watch(intakeServiceProvider);
      final StorageService storageService = ref.watch(storageServiceProvider);
      final FileStorageDriver fileStorageDriver = ref.watch(
        fileStorageDriverProvider,
      );
      final DocumentPickerDriver documentPickerDriver = ref.watch(
        documentPickerDriverProvider,
      );

      final SecondInstanceFirstInstanceAnalysisScreenPresenter presenter =
          SecondInstanceFirstInstanceAnalysisScreenPresenter(
            intakeService: intakeService,
            storageService: storageService,
            fileStorageDriver: fileStorageDriver,
            documentPickerDriver: documentPickerDriver,
            analysisId: analysisId,
          );

      unawaited(presenter.load());

      ref.onDispose(presenter.dispose);
      return presenter;
    });
