import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/case_assessment_analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/pdf_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/storage/dtos/upload_url_dto.dart';
import 'package:animus/core/storage/interfaces/drivers/document_picker_driver.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/core/storage/interfaces/storage_service.dart';
import 'package:animus/drivers/cache/index.dart';
import 'package:animus/drivers/document-picker-driver/index.dart';
import 'package:animus/drivers/file_storage/index.dart';
import 'package:animus/drivers/pdf-driver/index.dart';
import 'package:animus/rest/services/index.dart';

/// Presenter for the Case Assessment (lawyer) analysis screen.
///
/// Orchestrates the full lawyer analysis flow: document upload, case
/// summarization, precedents search (delegated to
/// `AnalysisPrecedentsBubblePresenter`), petition draft generation and
/// report export.
class CaseAssessmentAnalysisScreenPresenter {
  static const List<String> allowedExtensions = <String>['pdf', 'docx'];
  static const int maxFileSizeInBytes = 20 * 1024 * 1024;
  static const Duration pollingInterval = Duration(seconds: 3);
  static const Duration requestTimeout = Duration(seconds: 10);
  static const String failedMessage =
      'Não foi possível concluir esta etapa agora. Tente novamente.';
  static const String exportFailedMessage =
      'Não foi possível exportar o relatório agora. Tente novamente.';

  final IntakeService _intakeService;
  final StorageService _storageService;
  final FileStorageDriver _fileStorageDriver;
  final DocumentPickerDriver _documentPickerDriver;
  // ignore: unused_field
  final CacheDriver _cacheDriver;
  // ignore: unused_field
  final PdfDriver _pdfDriver;
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
  final Signal<bool> isExportingReport = signal<bool>(false);
  final Signal<bool> precedentsReady = signal<bool>(false);

  late final ReadonlySignal<bool> canPickDocument = computed(() {
    final AnalysisStatusDto currentStatus = status.value;
    final bool isProcessingCase =
        currentStatus == AnalysisStatusDto.analyzingCase;
    final bool isProcessingDraft =
        currentStatus == AnalysisStatusDto.generatingPetitionDraft;

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

  late final ReadonlySignal<bool> canGeneratePetitionDraft = computed(() {
    return !isUploading.value &&
        !isManagingAnalysis.value &&
        precedentsReady.value &&
        status.value != AnalysisStatusDto.generatingPetitionDraft;
  });

  late final ReadonlySignal<bool> canRegeneratePetitionDraft = computed(() {
    return !isUploading.value &&
        !isManagingAnalysis.value &&
        status.value == AnalysisStatusDto.done &&
        petitionDraft.value != null;
  });

  late final ReadonlySignal<bool> showCaseProcessingBubble = computed(
    () => status.value == AnalysisStatusDto.analyzingCase,
  );

  late final ReadonlySignal<bool> showPetitionDraftProcessingCard = computed(
    () => status.value == AnalysisStatusDto.generatingPetitionDraft,
  );

  late final ReadonlySignal<bool> canExportReport = computed(() {
    return status.value == AnalysisStatusDto.done &&
        petitionDraft.value != null &&
        !isExportingReport.value;
  });

  late final ReadonlySignal<String> primaryActionLabel = computed(() {
    if (status.value == AnalysisStatusDto.failed) {
      if (precedentsReady.value) {
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

    if (status.value == AnalysisStatusDto.generatingPetitionDraft ||
        canGeneratePetitionDraft.value) {
      return 'Gerar minuta';
    }

    if (canSearchPrecedents.value) {
      return 'Buscar precedentes';
    }

    return 'Analisar';
  });

  late final ReadonlySignal<String> fileActionLabel = computed(() {
    final AnalysisStatusDto currentStatus = status.value;
    if (currentStatus == AnalysisStatusDto.waitingDocumentUpload ||
        currentStatus == AnalysisStatusDto.documentUploaded) {
      return 'Selecionar petição';
    }

    return 'Enviar outro documento';
  });

  CaseAssessmentAnalysisScreenPresenter({
    required IntakeService intakeService,
    required StorageService storageService,
    required FileStorageDriver fileStorageDriver,
    required DocumentPickerDriver documentPickerDriver,
    required CacheDriver cacheDriver,
    required PdfDriver pdfDriver,
    required this.analysisId,
  }) : _intakeService = intakeService,
       _storageService = storageService,
       _fileStorageDriver = fileStorageDriver,
       _documentPickerDriver = documentPickerDriver,
       _cacheDriver = cacheDriver,
       _pdfDriver = pdfDriver;

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

    if (_shouldLoadPetitionDraft(analysis.status)) {
      await _tryLoadPetitionDraft();
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

  Future<void> analyzeCase() async {
    if (!canAnalyzeCase.value) {
      return;
    }

    generalError.value = null;
    isManagingAnalysis.value = true;

    try {
      final RestResponse<void> response = await _intakeService
          .triggerFirstInstanceCaseSummarization(analysisId: analysisId)
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

      status.value = AnalysisStatusDto.analyzingCase;
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
    petitionDraft.value = null;
    precedentsReady.value = false;
    status.value = AnalysisStatusDto.documentUploaded;
    await analyzeCase();
  }

  Future<void> retrySummary() async {
    if (status.value == AnalysisStatusDto.caseAnalyzed) {
      await reanalyzeCase();
      return;
    }

    if (status.value == AnalysisStatusDto.failed) {
      caseSummary.value = null;
      petitionDraft.value = null;
      precedentsReady.value = false;
      status.value = AnalysisStatusDto.documentUploaded;
      await analyzeCase();
    }
  }

  void confirmAndViewPrecedents() {
    if (status.value != AnalysisStatusDto.caseAnalyzed) {
      return;
    }

    if (caseSummary.value == null) {
      generalError.value = failedMessage;
      return;
    }

    generalError.value = null;
    status.value = AnalysisStatusDto.searchingPrecedents;
  }

  void markPrecedentsReady() {
    precedentsReady.value = true;
  }

  Future<void> requestPetitionDraft() async {
    if (!canGeneratePetitionDraft.value && !canRegeneratePetitionDraft.value) {
      return;
    }

    generalError.value = null;
    status.value = AnalysisStatusDto.generatingPetitionDraft;
    isManagingAnalysis.value = true;

    try {
      await _pollUntilPetitionDraftReady();
    } finally {
      isManagingAnalysis.value = false;
    }
  }

  Future<void> regeneratePetitionDraft() async {
    if (!canRegeneratePetitionDraft.value) {
      return;
    }

    petitionDraft.value = null;
    await requestPetitionDraft();
  }

  Future<void> replaceDocument() async {
    selectedFile.value = null;
    analysisDocument.value = null;
    caseSummary.value = null;
    petitionDraft.value = null;
    precedentsReady.value = false;
    uploadProgress.value = null;
    generalError.value = null;
    status.value = AnalysisStatusDto.waitingDocumentUpload;
    await pickDocument();
  }

  Future<bool> renameAnalysis(String name) async {
    if (isManagingAnalysis.value || isExportingReport.value) {
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
    if (isManagingAnalysis.value || isExportingReport.value) {
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

  /// Exports the full case assessment analysis report as PDF and shares it.
  ///
  /// Note: `PdfDriver` currently only exposes a first-instance report
  /// generator. Until `PdfDriver.generateCaseAssessmentReport(...)` is
  /// added (pending ticket — see spec 10.1), this method fetches the
  /// report and reports an export failure so the UI can surface the
  /// pending dependency without crashing.
  Future<bool> exportAnalysisReport() async {
    if (!canExportReport.value || isManagingAnalysis.value) {
      return false;
    }

    isExportingReport.value = true;
    isManagingAnalysis.value = true;
    generalError.value = null;

    try {
      final RestResponse<CaseAssessmentAnalysisReportDto> reportResponse =
          await _intakeService.getCaseAssessmentAnalysisReport(
            analysisId: analysisId,
          );

      if (reportResponse.isFailure) {
        generalError.value = exportFailedMessage;
        return false;
      }

      // PdfDriver does not yet expose generateCaseAssessmentReport.
      // Surface the gap explicitly until the driver method ships.
      generalError.value = exportFailedMessage;
      return false;
    } catch (_) {
      generalError.value = exportFailedMessage;
      return false;
    } finally {
      isManagingAnalysis.value = false;
      isExportingReport.value = false;
    }
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
    isExportingReport.dispose();
    precedentsReady.dispose();
    canPickDocument.dispose();
    canAnalyzeCase.dispose();
    canRegenerateSummary.dispose();
    canSearchPrecedents.dispose();
    canGeneratePetitionDraft.dispose();
    canRegeneratePetitionDraft.dispose();
    showCaseProcessingBubble.dispose();
    showPetitionDraftProcessingCard.dispose();
    canExportReport.dispose();
    primaryActionLabel.dispose();
    fileActionLabel.dispose();
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

      if (currentStatus == AnalysisStatusDto.failed) {
        await _applyFailure();
        return;
      }

      await Future<void>.delayed(pollingInterval);
    }
  }

  Future<void> _pollUntilPetitionDraftReady() async {
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

      if (_shouldLoadPetitionDraft(currentStatus)) {
        await _tryLoadPetitionDraft();
      }

      if (currentStatus == AnalysisStatusDto.done) {
        if (petitionDraft.value != null) {
          generalError.value = null;
          return;
        }

        final bool didLoadDraft = await _tryLoadPetitionDraft();
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

  Future<bool> _tryLoadPetitionDraft() async {
    final RestResponse<PetitionDraftDto> draftResponse = await _intakeService
        .getPetitionDraft(analysisId: analysisId);

    if (draftResponse.isFailure) {
      return false;
    }

    petitionDraft.value = draftResponse.body;
    return true;
  }

  Future<void> _applyFailure([String? message]) async {
    final String errorMessage = message == null || message.isEmpty
        ? failedMessage
        : message;
    generalError.value = errorMessage;
    status.value = AnalysisStatusDto.failed;
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
    return value == AnalysisStatusDto.searchingPrecedents ||
        value == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        value == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        value == AnalysisStatusDto.generatingPetitionDraft ||
        value == AnalysisStatusDto.done;
  }

  bool _isPrecedentsReadyStatus(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.searchingPrecedents ||
        value == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        value == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        value == AnalysisStatusDto.generatingPetitionDraft ||
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
      final CacheDriver cacheDriver = ref.watch(cacheDriverProvider);
      final PdfDriver pdfDriver = ref.watch(pdfDriverProvider);

      final CaseAssessmentAnalysisScreenPresenter presenter =
          CaseAssessmentAnalysisScreenPresenter(
            intakeService: intakeService,
            storageService: storageService,
            fileStorageDriver: fileStorageDriver,
            documentPickerDriver: documentPickerDriver,
            cacheDriver: cacheDriver,
            pdfDriver: pdfDriver,
            analysisId: analysisId,
          );

      unawaited(presenter.load());

      ref.onDispose(presenter.dispose);
      return presenter;
    });
