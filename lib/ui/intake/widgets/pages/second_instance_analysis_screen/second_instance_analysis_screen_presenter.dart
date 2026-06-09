import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_decision_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_judgment_draft_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/pdf_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/storage/dtos/upload_url_dto.dart';
import 'package:animus/core/storage/interfaces/drivers/document_picker_driver.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/core/storage/interfaces/storage_service.dart';
import 'package:animus/drivers/document-picker-driver/index.dart';
import 'package:animus/drivers/file_storage/index.dart';
import 'package:animus/drivers/pdf-driver/index.dart';
import 'package:animus/rest/services/index.dart';

class SecondInstanceAnalysisScreenPresenter {
  static const List<String> allowedExtensions = <String>['pdf'];
  static const int maxFileSizeInBytes = 100 * 1024 * 1024;
  static const Duration pollingInterval = Duration(seconds: 3);
  static const Duration requestTimeout = Duration(seconds: 10);
  static const String failedMessage =
      'Não foi possível concluir esta etapa agora. Tente novamente.';
  static const String exportFailedMessage =
      'Não foi possível exportar a minuta agora. Tente novamente.';

  final IntakeService _intakeService;
  final StorageService _storageService;
  final PdfDriver _pdfDriver;
  final FileStorageDriver _fileStorageDriver;
  final DocumentPickerDriver _documentPickerDriver;
  final String analysisId;
  bool _isDisposed = false;
  String? _pendingUploadDocumentFilePath;
  int _casePollingFlow = 0;
  int _judgmentDraftPollingFlow = 0;
  Future<bool>? _caseSummaryLoadRequest;

  final Signal<AnalysisStatusDto> status = signal<AnalysisStatusDto>(
    AnalysisStatusDto.waitingDocumentUpload,
  );
  final Signal<File?> selectedFile = signal<File?>(null);
  final Signal<AnalysisDocumentDto?> analysisDocument =
      signal<AnalysisDocumentDto?>(null);
  final Signal<bool> isUploading = signal<bool>(false);
  final Signal<double?> uploadProgress = signal<double?>(null);
  final Signal<CaseSummaryDto?> caseSummary = signal<CaseSummaryDto?>(null);
  final Signal<SecondInstanceDecisionDto?> decision =
      signal<SecondInstanceDecisionDto?>(null);
  final Signal<SecondInstanceJudgmentDraftDto?> judgmentDraft =
      signal<SecondInstanceJudgmentDraftDto?>(null);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<String> analysisName = signal<String>('Nova Análise');
  final Signal<bool> isArchived = signal<bool>(false);
  final Signal<bool> isManagingAnalysis = signal<bool>(false);
  final Signal<bool> isExportingReport = signal<bool>(false);
  final Signal<bool> isSubmittingDecision = signal<bool>(false);
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
        !isExportingReport.value &&
        !isProcessingCase &&
        !isProcessingDraft &&
        !_isPrecedentsProcessingStatus(currentStatus);
  });

  late final ReadonlySignal<bool> canAnalyzeCase = computed(() {
    return !isUploading.value &&
        !isManagingAnalysis.value &&
        !isExportingReport.value &&
        (selectedFile.value != null || analysisDocument.value != null) &&
        (status.value == AnalysisStatusDto.documentUploaded ||
            status.value == AnalysisStatusDto.failed);
  });

  late final ReadonlySignal<bool> canRegenerateSummary = computed(() {
    return !isUploading.value &&
        !isManagingAnalysis.value &&
        !isExportingReport.value &&
        status.value == AnalysisStatusDto.caseAnalyzed;
  });

  late final ReadonlySignal<bool> canSearchPrecedents = computed(() {
    return !isUploading.value &&
        !isManagingAnalysis.value &&
        !isExportingReport.value &&
        caseSummary.value != null &&
        decision.value != null &&
        _canSearchPrecedentsAtStatus(status.value);
  });

  late final ReadonlySignal<bool> canEditDecision = computed(() {
    return !isSubmittingDecision.value &&
        _hasReachedDecisionEditingStatus(status.value);
  });

  late final ReadonlySignal<bool> shouldShowSearchDecisionHelper = computed(() {
    return caseSummary.value != null &&
        decision.value == null &&
        _canSearchPrecedentsAtStatus(status.value);
  });

  late final ReadonlySignal<bool> canGenerateJudgmentDraft = computed(() {
    return !isUploading.value &&
        !isManagingAnalysis.value &&
        !isExportingReport.value &&
        precedentsReady.value &&
        hasChosenPrecedents.value &&
        !_isPrecedentsProcessingStatus(status.value) &&
        status.value != AnalysisStatusDto.generatingJudgmentDraft &&
        status.value != AnalysisStatusDto.generatingSynthesis;
  });

  late final ReadonlySignal<bool> canRegenerateJudgmentDraft = computed(() {
    return !isUploading.value &&
        !isManagingAnalysis.value &&
        !isExportingReport.value &&
        status.value == AnalysisStatusDto.done &&
        hasChosenPrecedents.value &&
        judgmentDraft.value != null;
  });

  late final ReadonlySignal<bool> canExportReport = computed(() {
    return status.value == AnalysisStatusDto.done &&
        judgmentDraft.value != null &&
        !isManagingAnalysis.value &&
        !isExportingReport.value;
  });

  late final ReadonlySignal<bool> showCaseProcessingBubble = computed(() {
    return status.value == AnalysisStatusDto.extractingPetition ||
        status.value == AnalysisStatusDto.analyzingCase;
  });

  late final ReadonlySignal<bool> showJudgmentDraftProcessingBubble = computed(
    () => status.value == AnalysisStatusDto.generatingJudgmentDraft,
  );

  late final ReadonlySignal<bool> showPetitionNotFound = computed(
    () => status.value == AnalysisStatusDto.petitionNotFound,
  );

  late final ReadonlySignal<bool> showCourtDocumentPiecesNotFound = computed(
    () => status.value == AnalysisStatusDto.courtDocumentPiecesNotFound,
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

    if (status.value == AnalysisStatusDto.petitionNotFound ||
        status.value == AnalysisStatusDto.courtDocumentPiecesNotFound) {
      return 'Selecionar processo';
    }

    if (_isPrecedentsProcessingStatus(status.value)) {
      return 'Buscando precedentes';
    }

    if (status.value == AnalysisStatusDto.generatingJudgmentDraft ||
        canGenerateJudgmentDraft.value ||
        precedentsReady.value) {
      return 'Gerar minuta';
    }

    if (caseSummary.value != null &&
        _canSearchPrecedentsAtStatus(status.value)) {
      return 'Buscar precedentes';
    }

    return 'Analisar';
  });

  SecondInstanceAnalysisScreenPresenter({
    required IntakeService intakeService,
    required StorageService storageService,
    required PdfDriver pdfDriver,
    required FileStorageDriver fileStorageDriver,
    required DocumentPickerDriver documentPickerDriver,
    required this.analysisId,
  }) : _intakeService = intakeService,
       _storageService = storageService,
       _pdfDriver = pdfDriver,
       _fileStorageDriver = fileStorageDriver,
       _documentPickerDriver = documentPickerDriver;

  Future<void> load() async {
    if (_isDisposed) {
      return;
    }

    generalError.value = null;

    final RestResponse<AnalysisDto> analysisResponse = await _intakeService
        .getAnalysis(analysisId: analysisId);

    if (_isDisposed) {
      return;
    }

    if (analysisResponse.isFailure) {
      status.value = AnalysisStatusDto.waitingDocumentUpload;
      return;
    }

    final AnalysisDto analysis = analysisResponse.body;
    analysisName.value = analysis.name;
    isArchived.value = analysis.isArchived;
    _applyRemoteStatus(analysis.status);
    precedentsReady.value = _isPrecedentsReadyStatus(analysis.status);

    if (_shouldLoadAnalysisDocument(analysis.status)) {
      final RestResponse<AnalysisDocumentDto> documentResponse =
          await _intakeService.getAnalysisDocument(analysisId: analysisId);
      if (_isDisposed) {
        return;
      }

      if (documentResponse.isSuccessful) {
        analysisDocument.value = documentResponse.body;
      }
    }

    if (_shouldLoadSummary(analysis.status)) {
      await _loadCaseSummary();
    }

    if (_shouldLoadDecision(analysis.status)) {
      final bool didLoadDecision = await _loadDecision();
      if (_isDisposed || !didLoadDecision) {
        return;
      }
    }

    if (_shouldResumeCasePolling(analysis.status)) {
      final int currentFlow = ++_casePollingFlow;
      unawaited(_pollUntilCaseReady(currentFlow));
    }

    if (_shouldLoadJudgmentDraft(analysis.status)) {
      await _tryLoadJudgmentDraft();

      if (_shouldResumeJudgmentDraftPolling(analysis.status)) {
        status.value = AnalysisStatusDto.generatingJudgmentDraft;
        final int currentFlow = ++_judgmentDraftPollingFlow;
        unawaited(_pollUntilJudgmentDraftReady(currentFlow));
      }
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
      generalError.value = 'O arquivo deve ter no máximo 100MB.';
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

      status.value = AnalysisStatusDto.analyzingCase;
      final int currentFlow = ++_casePollingFlow;
      await _pollUntilCaseReady(currentFlow);
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

  void updateJudgmentDraftLocally(SecondInstanceJudgmentDraftDto dto) {
    if (_isDisposed) {
      return;
    }

    judgmentDraft.value = dto;
  }

  Future<String?> createDecision(String description) async {
    if (!canEditDecision.value) {
      return failedMessage;
    }

    final String normalizedDescription = description.trim();
    if (normalizedDescription.isEmpty) {
      return 'Descreva a decisão antes de continuar.';
    }

    isSubmittingDecision.value = true;

    try {
      final RestResponse<SecondInstanceDecisionDto> response =
          await _intakeService.createSecondInstanceDecision(
            analysisId: analysisId,
            description: normalizedDescription,
          );

      if (_isDisposed) {
        return failedMessage;
      }

      if (response.isFailure) {
        return response.errorMessage;
      }

      decision.value = response.body;
      if (status.value == AnalysisStatusDto.caseAnalyzed) {
        status.value = AnalysisStatusDto.decisionSubmitted;
      }
      generalError.value = null;
      return null;
    } finally {
      if (!_isDisposed) {
        isSubmittingDecision.value = false;
      }
    }
  }

  Future<void> requestJudgmentDraft({bool force = false}) async {
    if (!force &&
        !canGenerateJudgmentDraft.value &&
        !canRegenerateJudgmentDraft.value) {
      return;
    }

    generalError.value = null;
    status.value = AnalysisStatusDto.generatingJudgmentDraft;
    isManagingAnalysis.value = true;
    final int currentFlow = ++_judgmentDraftPollingFlow;

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

      await _pollUntilJudgmentDraftReady(currentFlow);
    } finally {
      isManagingAnalysis.value = false;
    }
  }

  Future<void> regenerateJudgmentDraft(String comments) async {
    if (!canRegenerateJudgmentDraft.value) {
      return;
    }

    generalError.value = null;
    status.value = AnalysisStatusDto.generatingJudgmentDraft;
    isManagingAnalysis.value = true;
    final int currentFlow = ++_judgmentDraftPollingFlow;

    try {
      final RestResponse<void> response = await _intakeService
          .regenerateJudgmentDraft(analysisId: analysisId, comments: comments)
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

      await _pollUntilJudgmentDraftReady(currentFlow, forceReloadOnDone: true);
    } finally {
      isManagingAnalysis.value = false;
    }
  }

  Future<void> resendDocument() async {
    if (isManagingAnalysis.value || isExportingReport.value) {
      return;
    }

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
    final RestResponse<List<AnalysisDto>> response = await _intakeService
        .archiveAnalysis(analysisId: analysisId);
    isManagingAnalysis.value = false;

    if (response.isFailure) {
      generalError.value = response.errorMessage;
      return false;
    }

    final AnalysisDto? archivedAnalysis = _findArchivedAnalysis(response.body);
    if (archivedAnalysis == null) {
      generalError.value = failedMessage;
      return false;
    }

    isArchived.value = archivedAnalysis.isArchived;
    generalError.value = null;
    return true;
  }

  Future<bool> unarchiveAnalysis() async {
    if (isManagingAnalysis.value || isExportingReport.value) {
      return false;
    }

    isManagingAnalysis.value = true;
    final RestResponse<AnalysisDto> response = await _intakeService
        .unarchiveAnalysis(analysisId: analysisId);
    isManagingAnalysis.value = false;

    if (response.isFailure) {
      generalError.value = response.errorMessage;
      return false;
    }

    isArchived.value = response.body.isArchived;
    generalError.value = null;
    return true;
  }

  AnalysisDto? _findArchivedAnalysis(List<AnalysisDto> analyses) {
    for (final AnalysisDto analysis in analyses) {
      if (analysis.id == analysisId) {
        return analysis;
      }
    }

    return analyses.isEmpty ? null : analyses.first;
  }

  Future<bool> exportSecondInstanceAnalysisReport() async {
    if (!canExportReport.value) {
      return false;
    }

    isExportingReport.value = true;
    isManagingAnalysis.value = true;
    generalError.value = null;

    try {
      final RestResponse<SecondInstanceAnalysisReportDto> reportResponse =
          await _intakeService.getSecondInstanceAnalysisReport(
            analysisId: analysisId,
          );

      if (reportResponse.isFailure) {
        generalError.value = exportFailedMessage;
        return false;
      }

      final SecondInstanceAnalysisReportDto report = _mergeReportWithDraft(
        reportResponse.body,
      );
      final Uint8List bytes = await _pdfDriver
          .generateSecondInstanceAnalysisReport(report: report);
      final String filename = _buildReportFilename(report.analysis.name);

      await _pdfDriver.sharePdf(bytes: bytes, filename: filename);
      return true;
    } catch (_) {
      generalError.value = exportFailedMessage;
      return false;
    } finally {
      isManagingAnalysis.value = false;
      isExportingReport.value = false;
    }
  }

  void markPrecedentsReady() {
    precedentsReady.value = true;

    if (status.value == AnalysisStatusDto.searchingPrecedents ||
        status.value == AnalysisStatusDto.precedentsSearched ||
        status.value == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        status.value == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        status.value == AnalysisStatusDto.generatingSynthesis) {
      status.value = AnalysisStatusDto.precedentsSearched;
    }
  }

  void markPrecedentsSearchStarted() {
    precedentsReady.value = false;
    hasChosenPrecedents.value = false;
    status.value = AnalysisStatusDto.searchingPrecedents;
  }

  void syncChosenPrecedents(List<AnalysisPrecedentDto> precedents) {
    hasChosenPrecedents.value = precedents.isNotEmpty;
  }

  Future<bool> ensureCaseSummaryLoaded() async {
    if (caseSummary.value != null || !_shouldLoadSummary(status.value)) {
      return caseSummary.value != null;
    }

    return _loadCaseSummary();
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
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    _casePollingFlow++;
    _judgmentDraftPollingFlow++;
    status.dispose();
    selectedFile.dispose();
    analysisDocument.dispose();
    isUploading.dispose();
    uploadProgress.dispose();
    caseSummary.dispose();
    decision.dispose();
    judgmentDraft.dispose();
    generalError.dispose();
    analysisName.dispose();
    isArchived.dispose();
    isManagingAnalysis.dispose();
    isExportingReport.dispose();
    isSubmittingDecision.dispose();
    precedentsReady.dispose();
    hasChosenPrecedents.dispose();
    canPickDocument.dispose();
    canAnalyzeCase.dispose();
    canRegenerateSummary.dispose();
    canSearchPrecedents.dispose();
    canEditDecision.dispose();
    shouldShowSearchDecisionHelper.dispose();
    canGenerateJudgmentDraft.dispose();
    canRegenerateJudgmentDraft.dispose();
    canExportReport.dispose();
    showCaseProcessingBubble.dispose();
    showJudgmentDraftProcessingBubble.dispose();
    showPetitionNotFound.dispose();
    showCourtDocumentPiecesNotFound.dispose();
    primaryActionLabel.dispose();
  }

  String _buildReportFilename(String rawAnalysisName) {
    final String normalizedName = rawAnalysisName.trim();
    final String fallbackName = 'Analise-$analysisId';
    final String baseName = normalizedName.isEmpty
        ? fallbackName
        : normalizedName;
    final String sanitizedName = baseName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final String safeName = sanitizedName.isEmpty
        ? fallbackName
        : sanitizedName;

    return '$safeName - Minuta de Sentenca.pdf';
  }

  SecondInstanceAnalysisReportDto _mergeReportWithDraft(
    SecondInstanceAnalysisReportDto report,
  ) {
    final SecondInstanceJudgmentDraftDto? currentDraft = judgmentDraft.value;
    if (currentDraft == null || _hasDraftContent(report.judgmentDraft)) {
      return report;
    }

    return SecondInstanceAnalysisReportDto(
      analysis: report.analysis,
      document: report.document,
      caseSummary: report.caseSummary,
      decision: report.decision,
      precedents: report.precedents,
      judgmentDraft: currentDraft,
    );
  }

  bool _hasDraftContent(SecondInstanceJudgmentDraftDto draft) {
    return draft.report.trim().isNotEmpty ||
        draft.meritAnalysis.trim().isNotEmpty ||
        draft.precedentAdherenceAnalysis.trim().isNotEmpty ||
        draft.ruling.any((String item) => item.trim().isNotEmpty) ||
        (draft.preliminaryIssues?.trim().isNotEmpty ?? false) ||
        (draft.noApplicablePrecedentNotice?.trim().isNotEmpty ?? false);
  }

  Future<void> _uploadAnalysisDocument(File file) async {
    uploadProgress.value = 0;
    isUploading.value = true;

    final RestResponse<UploadUrlDto> uploadUrlResponse = await _storageService
        .generateAnalysisDocumentUploadUrl(
          analysisId: analysisId,
          documentType: _getExtension(file.path),
        );

    if (_isDisposed) {
      return;
    }

    if (uploadUrlResponse.isFailure) {
      isUploading.value = false;
      uploadProgress.value = null;
      await _applyFailure(uploadUrlResponse.errorMessage);
      return;
    }

    _pendingUploadDocumentFilePath = uploadUrlResponse.body.filePath;

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
      await _deletePendingUploadDocument(updateLocalStatus: true);
      if (_isDisposed) {
        return;
      }

      isUploading.value = false;
      uploadProgress.value = null;
      await _applyFailure();
      return;
    }

    if (_isDisposed) {
      await _deletePendingUploadDocument(updateLocalStatus: false);
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
      await _deletePendingUploadDocument(updateLocalStatus: true);
      if (_isDisposed) {
        return;
      }

      isUploading.value = false;
      uploadProgress.value = null;
      await _applyFailure(createDocumentResponse.errorMessage);
      return;
    }

    _pendingUploadDocumentFilePath = null;
    analysisDocument.value = createDocumentResponse.body;
    selectedFile.value = null;

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

  Future<void> _pollUntilCaseReady(int currentFlow) async {
    while (true) {
      if (_isDisposed || currentFlow != _casePollingFlow) {
        return;
      }

      final RestResponse<AnalysisDto> analysisResponse = await _intakeService
          .getAnalysis(analysisId: analysisId)
          .timeout(
            requestTimeout,
            onTimeout: () => RestResponse<AnalysisDto>(
              statusCode: HttpStatus.requestTimeout,
              errorMessage: _buildTimeoutMessage(),
            ),
          );

      if (_isDisposed || currentFlow != _casePollingFlow) {
        return;
      }

      if (analysisResponse.isFailure) {
        await _applyFailure(analysisResponse.errorMessage);
        return;
      }

      final AnalysisStatusDto currentStatus = analysisResponse.body.status;
      status.value = currentStatus;

      if (currentStatus == AnalysisStatusDto.caseAnalyzed) {
        final bool didLoadSummary = await _loadCaseSummary();
        if (_isDisposed || currentFlow != _casePollingFlow) {
          return;
        }

        if (!didLoadSummary) {
          await _applyFailure();
          return;
        }

        precedentsReady.value = false;
        generalError.value = null;
        return;
      }

      if (currentStatus == AnalysisStatusDto.petitionNotFound) {
        generalError.value = null;
        return;
      }

      if (currentStatus == AnalysisStatusDto.courtDocumentPiecesNotFound) {
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

  Future<void> _pollUntilJudgmentDraftReady(
    int currentFlow, {
    bool forceReloadOnDone = false,
  }) async {
    while (true) {
      if (_isDisposed || currentFlow != _judgmentDraftPollingFlow) {
        return;
      }

      final RestResponse<AnalysisDto> analysisResponse = await _intakeService
          .getAnalysis(analysisId: analysisId)
          .timeout(
            requestTimeout,
            onTimeout: () => RestResponse<AnalysisDto>(
              statusCode: HttpStatus.requestTimeout,
              errorMessage: _buildTimeoutMessage(),
            ),
          );

      if (_isDisposed || currentFlow != _judgmentDraftPollingFlow) {
        return;
      }

      if (analysisResponse.isFailure) {
        await _applyFailure(analysisResponse.errorMessage);
        return;
      }

      final AnalysisStatusDto currentStatus = analysisResponse.body.status;

      if (currentStatus == AnalysisStatusDto.done) {
        status.value = currentStatus;

        if (!forceReloadOnDone && judgmentDraft.value != null) {
          generalError.value = null;
          return;
        }

        final RestResponse<SecondInstanceJudgmentDraftDto> draftResponse =
            await _loadJudgmentDraftResponse();
        if (_isDisposed || currentFlow != _judgmentDraftPollingFlow) {
          return;
        }

        if (draftResponse.isFailure) {
          if (draftResponse.statusCode != HttpStatus.notFound) {
            await _applyFailure(draftResponse.errorMessage);
            return;
          }

          status.value = AnalysisStatusDto.generatingJudgmentDraft;
          await Future<void>.delayed(pollingInterval);
          continue;
        }

        judgmentDraft.value = draftResponse.body;

        generalError.value = null;
        return;
      }

      if (_shouldLoadJudgmentDraft(currentStatus)) {
        await _tryLoadJudgmentDraft();
      }

      if (_isDisposed || currentFlow != _judgmentDraftPollingFlow) {
        return;
      }

      status.value = _isJudgmentDraftPendingStatus(currentStatus)
          ? AnalysisStatusDto.generatingJudgmentDraft
          : currentStatus;

      if (currentStatus == AnalysisStatusDto.failed) {
        await _applyFailure();
        return;
      }

      await Future<void>.delayed(pollingInterval);
    }
  }

  Future<void> _applyFailure([String? message]) async {
    if (_isDisposed) {
      return;
    }

    final String errorMessage = message == null || message.isEmpty
        ? failedMessage
        : message;
    generalError.value = errorMessage;
    status.value = AnalysisStatusDto.failed;
  }

  Future<void> _deletePendingUploadDocument({
    required bool updateLocalStatus,
  }) async {
    final String? filePath = _pendingUploadDocumentFilePath;
    if (filePath == null) {
      return;
    }

    _pendingUploadDocumentFilePath = null;
    final RestResponse<void> response = await _intakeService
        .removeAnalysisDocument(analysisId: analysisId, filePath: filePath);

    if (!updateLocalStatus || _isDisposed || response.isFailure) {
      return;
    }

    status.value = AnalysisStatusDto.waitingDocumentUpload;
    analysisDocument.value = null;
    selectedFile.value = null;
  }

  Future<bool> _loadCaseSummary() {
    final Future<bool>? currentRequest = _caseSummaryLoadRequest;
    if (currentRequest != null) {
      return currentRequest;
    }

    final Future<bool> request = _intakeService
        .getCaseSummary(analysisId: analysisId)
        .then((RestResponse<CaseSummaryDto> summaryResponse) {
          if (_isDisposed || summaryResponse.isFailure) {
            return false;
          }

          caseSummary.value = summaryResponse.body;
          return true;
        })
        .whenComplete(() {
          _caseSummaryLoadRequest = null;
        });

    _caseSummaryLoadRequest = request;
    return request;
  }

  Future<bool> _loadDecision() async {
    final RestResponse<SecondInstanceDecisionDto> response =
        await _intakeService.getSecondInstanceDecision(analysisId: analysisId);

    if (_isDisposed) {
      return false;
    }

    if (response.isSuccessful) {
      decision.value = response.body;
      generalError.value = null;
      return true;
    }

    if (response.statusCode == HttpStatus.notFound) {
      decision.value = null;
      return true;
    }

    generalError.value = response.errorMessage;
    return false;
  }

  void _applyRemoteStatus(AnalysisStatusDto value) {
    if (status.value == AnalysisStatusDto.done &&
        _isJudgmentDraftLoadingStatus(value)) {
      return;
    }

    status.value = value;
  }

  bool _shouldLoadSummary(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.caseAnalyzed ||
        value == AnalysisStatusDto.decisionSubmitted ||
        value == AnalysisStatusDto.searchingPrecedents ||
        value == AnalysisStatusDto.precedentsSearched ||
        value == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        value == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        value == AnalysisStatusDto.generatingJudgmentDraft ||
        value == AnalysisStatusDto.generatingSynthesis ||
        value == AnalysisStatusDto.done;
  }

  bool _shouldLoadDecision(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.decisionSubmitted ||
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

  bool _shouldResumeCasePolling(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.extractingPetition ||
        value == AnalysisStatusDto.analyzingCase;
  }

  bool _isPrecedentsProcessingStatus(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.searchingPrecedents ||
        value == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        value == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        value == AnalysisStatusDto.generatingSynthesis;
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

  bool _hasReachedDecisionEditingStatus(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.caseAnalyzed ||
        value == AnalysisStatusDto.decisionSubmitted ||
        value == AnalysisStatusDto.searchingPrecedents ||
        value == AnalysisStatusDto.precedentsSearched ||
        value == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        value == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        value == AnalysisStatusDto.generatingJudgmentDraft ||
        value == AnalysisStatusDto.generatingSynthesis ||
        value == AnalysisStatusDto.done ||
        value == AnalysisStatusDto.failed;
  }

  bool _canSearchPrecedentsAtStatus(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.caseAnalyzed ||
        value == AnalysisStatusDto.decisionSubmitted;
  }

  bool _isJudgmentDraftPendingStatus(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.precedentsSearched ||
        value == AnalysisStatusDto.generatingSynthesis;
  }

  bool _isJudgmentDraftLoadingStatus(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.precedentsSearched ||
        value == AnalysisStatusDto.generatingJudgmentDraft ||
        value == AnalysisStatusDto.generatingSynthesis;
  }

  bool _shouldResumeJudgmentDraftPolling(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.generatingJudgmentDraft;
  }

  Future<RestResponse<SecondInstanceJudgmentDraftDto>>
  _loadJudgmentDraftResponse() {
    return _intakeService.getSecondInstanceJudgmentDraft(
      analysisId: analysisId,
    );
  }

  Future<bool> _tryLoadJudgmentDraft() async {
    final RestResponse<SecondInstanceJudgmentDraftDto> draftResponse =
        await _loadJudgmentDraftResponse();

    if (_isDisposed || draftResponse.isFailure) {
      if (draftResponse.statusCode == HttpStatus.notFound) {
        return false;
      }

      return false;
    }

    judgmentDraft.value = draftResponse.body;
    return true;
  }

  bool _isPrecedentsReadyStatus(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.precedentsSearched ||
        value == AnalysisStatusDto.generatingJudgmentDraft ||
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

final secondInstanceAnalysisScreenPresenterProvider = Provider.autoDispose
    .family<SecondInstanceAnalysisScreenPresenter, String>((
      Ref ref,
      String analysisId,
    ) {
      final IntakeService intakeService = ref.watch(intakeServiceProvider);
      final StorageService storageService = ref.watch(storageServiceProvider);
      final PdfDriver pdfDriver = ref.watch(pdfDriverProvider);
      final FileStorageDriver fileStorageDriver = ref.watch(
        fileStorageDriverProvider,
      );
      final DocumentPickerDriver documentPickerDriver = ref.watch(
        documentPickerDriverProvider,
      );

      final SecondInstanceAnalysisScreenPresenter presenter =
          SecondInstanceAnalysisScreenPresenter(
            intakeService: intakeService,
            storageService: storageService,
            pdfDriver: pdfDriver,
            fileStorageDriver: fileStorageDriver,
            documentPickerDriver: documentPickerDriver,
            analysisId: analysisId,
          );

      unawaited(presenter.load());

      ref.onDispose(presenter.dispose);
      return presenter;
    });
