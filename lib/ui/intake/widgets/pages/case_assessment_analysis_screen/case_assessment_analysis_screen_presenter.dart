import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/storage/dtos/upload_url_dto.dart';
import 'package:animus/core/storage/interfaces/drivers/document_picker_driver.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/core/storage/interfaces/storage_service.dart';
import 'package:animus/drivers/document-picker-driver/index.dart';
import 'package:animus/drivers/file_storage/index.dart';
import 'package:animus/rest/services/index.dart';

class CaseAssessmentAnalysisScreenPresenter {
  static const List<String> allowedExtensions = <String>['pdf', 'docx'];
  static const int maxFileSizeInBytes = 20 * 1024 * 1024;
  static const Duration pollingInterval = Duration(seconds: 3);
  static const Duration requestTimeout = Duration(seconds: 10);
  static const Duration generateDraftTimeout = Duration(seconds: 60);
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
  final Signal<PetitionDraftDto?> petitionDraft = signal<PetitionDraftDto?>(
    null,
  );
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<String> analysisName = signal<String>('Nova Análise');
  final Signal<bool> isArchived = signal<bool>(false);
  final Signal<bool> isManagingAnalysis = signal<bool>(false);
  final Signal<bool> precedentsReady = signal<bool>(false);
  final Signal<bool> hasChosenPrecedents = signal<bool>(false);

  late final ReadonlySignal<bool> canPickDocument = computed(() {
    final AnalysisStatusDto currentStatus = status.value;
    final bool isProcessing =
        currentStatus == AnalysisStatusDto.analyzingCase ||
        currentStatus == AnalysisStatusDto.generatingPetitionDraft;

    return !isUploading.value && !isManagingAnalysis.value && !isProcessing;
  });

  late final ReadonlySignal<bool> canAnalyzeCase = computed(() {
    return !isUploading.value &&
        !isManagingAnalysis.value &&
        (analysisDocument.value != null || selectedFile.value != null) &&
        (status.value == AnalysisStatusDto.documentUploaded ||
            status.value == AnalysisStatusDto.failed);
  });

  late final ReadonlySignal<bool> canRegenerateSummary = computed(() {
    return !isUploading.value &&
        !isManagingAnalysis.value &&
        caseSummary.value != null &&
        _isCaseAnalyzedOrLater(status.value);
  });

  late final ReadonlySignal<bool> canSearchPrecedents = computed(() {
    return !isUploading.value &&
        !isManagingAnalysis.value &&
        status.value == AnalysisStatusDto.caseAnalyzed &&
        caseSummary.value != null;
  });

  late final ReadonlySignal<bool> canGenerateDraft = computed(() {
    return !isUploading.value &&
        !isManagingAnalysis.value &&
        precedentsReady.value &&
        hasChosenPrecedents.value &&
        status.value != AnalysisStatusDto.generatingPetitionDraft;
  });

  late final ReadonlySignal<bool> canRegenerateDraft = computed(() {
    return !isUploading.value &&
        !isManagingAnalysis.value &&
        status.value == AnalysisStatusDto.done &&
        petitionDraft.value != null;
  });

  late final ReadonlySignal<bool> showCaseProcessingBubble = computed(
    () => status.value == AnalysisStatusDto.analyzingCase,
  );

  late final ReadonlySignal<bool> showDraftProcessingBubble = computed(
    () => status.value == AnalysisStatusDto.generatingPetitionDraft,
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

    if (canRegenerateDraft.value) {
      return 'Regerar minuta';
    }

    if (canGenerateDraft.value ||
        status.value == AnalysisStatusDto.generatingPetitionDraft) {
      return 'Gerar minuta';
    }

    if (canSearchPrecedents.value) {
      return 'Buscar precedentes';
    }

    return 'Analisar';
  });

  CaseAssessmentAnalysisScreenPresenter({
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
        selectedFile.value = await _fileStorageDriver.getFile(
          documentResponse.body.filePath,
        );
      }
    }

    if (_shouldLoadSummary(analysis.status)) {
      final RestResponse<CaseSummaryDto> summaryResponse = await _intakeService
          .getCaseSummary(analysisId: analysisId);

      if (summaryResponse.isSuccessful) {
        caseSummary.value = summaryResponse.body;
      }
    }

    if (_shouldLoadPetitionDraft(analysis.status)) {
      await _tryLoadPetitionDraft();
    }

    if (analysis.status == AnalysisStatusDto.analyzingCase) {
      await _pollUntilCaseReady();
    }

    if (analysis.status == AnalysisStatusDto.generatingPetitionDraft) {
      await _pollUntilDraftReady();
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
      generalError.value = 'Selecione um arquivo PDF ou DOCX.';
      return;
    }

    final int fileSize = await file.length();
    if (fileSize > maxFileSizeInBytes) {
      generalError.value = 'O arquivo deve ter no máximo 20MB.';
      return;
    }

    selectedFile.value = file;
    await _uploadAnalysisDocument(file);
  }

  Future<void> analyze() async {
    if (!canAnalyzeCase.value) {
      return;
    }

    generalError.value = null;
    isManagingAnalysis.value = true;

    try {
      final RestResponse<void> response = await _intakeService
          .triggerCaseAssessmentCaseSummarization(analysisId: analysisId)
          .timeout(
            requestTimeout,
            onTimeout: () => RestResponse<void>(
              statusCode: HttpStatus.requestTimeout,
              errorMessage: _buildTimeoutMessage(requestTimeout),
            ),
          );

      if (response.isFailure) {
        await _applyFailure(response.errorMessage);
        return;
      }

      status.value = AnalysisStatusDto.analyzingCase;
      await _pollUntilCaseReady();
    } finally {
      isManagingAnalysis.value = false;
    }
  }

  Future<void> retrySummarize() async {
    caseSummary.value = null;
    petitionDraft.value = null;
    precedentsReady.value = false;
    hasChosenPrecedents.value = false;
    status.value = AnalysisStatusDto.documentUploaded;
    await analyze();
  }

  Future<void> searchPrecedents() async {
    if (!canSearchPrecedents.value) {
      return;
    }

    generalError.value = null;
    precedentsReady.value = true;
    status.value = AnalysisStatusDto.searchingPrecedents;
  }

  Future<void> retrySearchPrecedents() async {
    petitionDraft.value = null;
    hasChosenPrecedents.value = false;
    generalError.value = null;
    precedentsReady.value = true;
    status.value = AnalysisStatusDto.searchingPrecedents;
  }

  Future<void> generateDraft() async {
    if (!canGenerateDraft.value && !canRegenerateDraft.value) {
      return;
    }

    generalError.value = null;
    isManagingAnalysis.value = true;
    status.value = AnalysisStatusDto.generatingPetitionDraft;

    try {
      final RestResponse<void> triggerResponse = await _intakeService
          .triggerPetitionDraftGeneration(analysisId: analysisId)
          .timeout(
            generateDraftTimeout,
            onTimeout: () => RestResponse<void>(
              statusCode: HttpStatus.requestTimeout,
              errorMessage: _buildTimeoutMessage(generateDraftTimeout),
            ),
          );

      if (triggerResponse.isFailure) {
        await _applyFailure(triggerResponse.errorMessage);
        return;
      }

      await _pollUntilDraftReady();
    } finally {
      isManagingAnalysis.value = false;
    }
  }

  Future<void> retryGenerateDraft() async {
    petitionDraft.value = null;
    await generateDraft();
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

    isArchived.value = response.body.isArchived;
    generalError.value = null;
    return true;
  }

  void markPrecedentsReady() {
    precedentsReady.value = true;
  }

  void syncChosenPrecedents(List<AnalysisPrecedentDto> precedents) {
    hasChosenPrecedents.value = precedents.any(
      (AnalysisPrecedentDto precedent) => precedent.isChosen,
    );
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
    petitionDraft.dispose();
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
    canGenerateDraft.dispose();
    canRegenerateDraft.dispose();
    showCaseProcessingBubble.dispose();
    showDraftProcessingBubble.dispose();
    primaryActionLabel.dispose();
  }

  Future<void> _uploadAnalysisDocument(File file) async {
    uploadProgress.value = 0;
    isUploading.value = true;

    final String extension = _getExtension(file.path);
    final RestResponse<UploadUrlDto> uploadUrlResponse = await _storageService
        .generateAnalysisDocumentUploadUrl(
          analysisId: analysisId,
          documentType: extension,
        );

    if (uploadUrlResponse.isFailure) {
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
      await _applyFailure();
      return;
    }

    isUploading.value = false;
    uploadProgress.value = 1;

    final RestResponse<AnalysisDocumentDto> documentResponse =
        await _intakeService.createAnalysisDocument(
          analysisId: analysisId,
          document: AnalysisDocumentDto(
            analysisId: analysisId,
            uploadedAt: DateTime.now().toUtc().toIso8601String(),
            filePath: uploadUrlResponse.body.filePath,
            name: fileName(file),
          ),
        );

    if (documentResponse.isFailure) {
      await _applyFailure(documentResponse.errorMessage);
      return;
    }

    analysisDocument.value = documentResponse.body;
    caseSummary.value = null;
    petitionDraft.value = null;
    precedentsReady.value = false;
    hasChosenPrecedents.value = false;
    status.value = AnalysisStatusDto.documentUploaded;
    generalError.value = null;
  }

  Future<void> _pollUntilCaseReady() async {
    while (true) {
      final RestResponse<AnalysisStatusDto> statusResponse =
          await _intakeService
              .getAnalysisStatus(analysisId: analysisId)
              .timeout(
                requestTimeout,
                onTimeout: () => RestResponse<AnalysisStatusDto>(
                  statusCode: HttpStatus.requestTimeout,
                  errorMessage: _buildTimeoutMessage(requestTimeout),
                ),
              );

      if (statusResponse.isFailure) {
        await _applyFailure(statusResponse.errorMessage);
        return;
      }

      status.value = statusResponse.body;
      precedentsReady.value = _isPrecedentsReadyStatus(statusResponse.body);

      if (statusResponse.body == AnalysisStatusDto.caseAnalyzed) {
        final RestResponse<CaseSummaryDto> summaryResponse =
            await _intakeService.getCaseSummary(analysisId: analysisId);

        if (summaryResponse.isFailure) {
          generalError.value = summaryResponse.errorMessage;
          return;
        }

        caseSummary.value = summaryResponse.body;
        generalError.value = null;
        return;
      }

      if (statusResponse.body == AnalysisStatusDto.failed) {
        await _applyFailure();
        return;
      }

      await Future<void>.delayed(pollingInterval);
    }
  }

  Future<void> _pollUntilDraftReady() async {
    while (true) {
      final RestResponse<AnalysisStatusDto> statusResponse =
          await _intakeService
              .getAnalysisStatus(analysisId: analysisId)
              .timeout(
                requestTimeout,
                onTimeout: () => RestResponse<AnalysisStatusDto>(
                  statusCode: HttpStatus.requestTimeout,
                  errorMessage: _buildTimeoutMessage(requestTimeout),
                ),
              );

      if (statusResponse.isFailure) {
        await _applyFailure(statusResponse.errorMessage);
        return;
      }

      status.value = statusResponse.body;

      if (statusResponse.body == AnalysisStatusDto.done) {
        final bool loaded = await _tryLoadPetitionDraft();
        if (!loaded) {
          await _applyFailure();
          return;
        }

        generalError.value = null;
        return;
      }

      if (statusResponse.body == AnalysisStatusDto.failed) {
        await _applyFailure();
        return;
      }

      await Future<void>.delayed(pollingInterval);
    }
  }

  Future<bool> _tryLoadPetitionDraft() async {
    final RestResponse<PetitionDraftDto> draftResponse = await _intakeService
        .getPetitionDraft(analysisId: analysisId);

    if (draftResponse.isFailure) {
      return false;
    }

    petitionDraft.value = draftResponse.body;
    return true;
  }

  Future<void> _applyFailure([String? errorMessage]) async {
    isUploading.value = false;
    isManagingAnalysis.value = false;
    uploadProgress.value = null;
    status.value = AnalysisStatusDto.failed;
    generalError.value = errorMessage == null || errorMessage.isEmpty
        ? failedMessage
        : errorMessage;
  }

  bool _shouldLoadAnalysisDocument(AnalysisStatusDto value) {
    return value != AnalysisStatusDto.waitingDocumentUpload;
  }

  bool _shouldLoadSummary(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.caseAnalyzed ||
        value == AnalysisStatusDto.searchingPrecedents ||
        value == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        value == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        value == AnalysisStatusDto.generatingPetitionDraft ||
        value == AnalysisStatusDto.done;
  }

  bool _shouldLoadPetitionDraft(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.generatingPetitionDraft ||
        value == AnalysisStatusDto.done;
  }

  bool _isPrecedentsReadyStatus(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.searchingPrecedents ||
        value == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        value == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        value == AnalysisStatusDto.generatingPetitionDraft ||
        value == AnalysisStatusDto.done;
  }

  bool _isCaseAnalyzedOrLater(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.caseAnalyzed ||
        value == AnalysisStatusDto.searchingPrecedents ||
        value == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        value == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        value == AnalysisStatusDto.generatingPetitionDraft ||
        value == AnalysisStatusDto.done;
  }

  String _buildTimeoutMessage(Duration timeout) {
    return '$failedMessage A requisição excedeu o tempo limite de ${timeout.inSeconds} segundos.';
  }

  String _getExtension(String path) {
    final int lastDot = path.lastIndexOf('.');
    if (lastDot < 0 || lastDot == path.length - 1) {
      return '';
    }

    return path.substring(lastDot + 1).toLowerCase();
  }
}

final caseAssessmentAnalysisScreenPresenterProvider = Provider.autoDispose
    .family<CaseAssessmentAnalysisScreenPresenter, String>((
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

      final CaseAssessmentAnalysisScreenPresenter presenter =
          CaseAssessmentAnalysisScreenPresenter(
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
