import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/constants/cache_keys.dart';
import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/case_assessment_analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/first_instance_analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_analysis_report_dto.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/pdf_driver.dart';
import 'package:animus/core/storage/dtos/upload_url_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/storage/interfaces/drivers/document_picker_driver.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/core/storage/interfaces/storage_service.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/drivers/cache/index.dart';
import 'package:animus/drivers/document-picker-driver/index.dart';
import 'package:animus/drivers/pdf-driver/index.dart';
import 'package:animus/drivers/file_storage/index.dart';
import 'package:animus/rest/services/index.dart';

class FirstInstanceAnalysisScreenPresenter {
  static const List<String> allowedExtensions = <String>['pdf', 'docx'];
  static const int maxFileSizeInBytes = 50 * 1024 * 1024;
  static const int minPrecedentsLimit = 1;
  static const int defaultPrecedentsLimit = 5;
  static const int maxPrecedentsLimit = 10;
  static const Duration summaryPollingInterval = Duration(seconds: 3);
  static const Duration summaryRequestTimeout = Duration(seconds: 10);
  static const String failedMessage =
      'Não foi possível analisar o documento agora. Tente novamente.';
  static const String exportFailedMessage =
      'Não foi possível exportar o relatório agora. Tente novamente.';

  final IntakeService _intakeService;
  final StorageService _storageService;
  final CacheDriver _cacheDriver;
  final PdfDriver _pdfDriver;
  final FileStorageDriver _fileStorageDriver;
  final DocumentPickerDriver _documentPickerDriver;
  final String analysisId;

  final Signal<AnalysisStatusDto> status = signal<AnalysisStatusDto>(
    AnalysisStatusDto.waitingPetition,
  );
  final Signal<File?> selectedFile = signal<File?>(null);
  final Signal<bool> isUploading = signal<bool>(false);
  final Signal<double?> uploadProgress = signal<double?>(null);
  final Signal<AnalysisDocumentDto?> analysisDocument =
      signal<AnalysisDocumentDto?>(null);
  final Signal<CaseSummaryDto?> summary = signal<CaseSummaryDto?>(null);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<String> analysisName = signal<String>('Nova Análise');
  final Signal<bool> isArchived = signal<bool>(false);
  final Signal<bool> isManagingAnalysis = signal<bool>(false);
  final Signal<bool> isExportingReport = signal<bool>(false);
  final Signal<int> precedentsLimit = signal<int>(defaultPrecedentsLimit);
  final Signal<List<CourtDto>> precedentsCourts = signal<List<CourtDto>>(
    const <CourtDto>[],
  );
  final Signal<List<PrecedentKindDto>> precedentsKinds =
      signal<List<PrecedentKindDto>>(const <PrecedentKindDto>[]);

  late final ReadonlySignal<int> appliedPrecedentFiltersCount = computed(() {
    return precedentsCourts.value.length + precedentsKinds.value.length;
  });

  late final ReadonlySignal<bool> canPickDocument = computed(() {
    return !isUploading.value &&
        status.value != AnalysisStatusDto.analyzingPetition;
  });

  late final ReadonlySignal<bool> canAnalyze = computed(() {
    final bool hasPetition = analysisDocument.value != null;
    final AnalysisStatusDto currentStatus = status.value;

    return hasPetition &&
        !isUploading.value &&
        generalError.value == null &&
        (currentStatus == AnalysisStatusDto.petitionUploaded ||
            currentStatus == AnalysisStatusDto.failed);
  });

  late final ReadonlySignal<bool> showProcessingBubble = computed(
    () => status.value == AnalysisStatusDto.analyzingPetition,
  );

  late final ReadonlySignal<String> primaryActionLabel = computed(() {
    return status.value == AnalysisStatusDto.caseAnalyzed
        ? 'Buscar precedentes'
        : 'Analisar';
  });

  late final ReadonlySignal<String> fileActionLabel = computed(() {
    return status.value == AnalysisStatusDto.caseAnalyzed
        ? 'Enviar outro documento'
        : 'Selecionar petição';
  });

  late final ReadonlySignal<bool> showRelevantPrecedents = computed(() {
    final AnalysisStatusDto currentStatus = status.value;

    return currentStatus == AnalysisStatusDto.searchingPrecedents ||
        currentStatus == AnalysisStatusDto.precedentsSearched ||
        currentStatus == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        currentStatus == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        currentStatus == AnalysisStatusDto.generatingSynthesis ||
        currentStatus == AnalysisStatusDto.waitingPrecedentChoice ||
        currentStatus == AnalysisStatusDto.precedentChosen;
  });

  late final ReadonlySignal<bool> canExportReport = computed(() {
    return (status.value == AnalysisStatusDto.precedentChosen ||
            status.value == AnalysisStatusDto.precedentsSearched) &&
        !isExportingReport.value;
  });

  FirstInstanceAnalysisScreenPresenter({
    required IntakeService intakeService,
    required StorageService storageService,
    required CacheDriver cacheDriver,
    PdfDriver? pdfDriver,
    required FileStorageDriver fileStorageDriver,
    required DocumentPickerDriver documentPickerDriver,
    required this.analysisId,
  }) : _intakeService = intakeService,
       _storageService = storageService,
       _cacheDriver = cacheDriver,
       _pdfDriver = pdfDriver ?? _PendingPdfDriver(),
       _fileStorageDriver = fileStorageDriver,
       _documentPickerDriver = documentPickerDriver;

  Future<void> load() async {
    generalError.value = null;
    _loadCachedPrecedentsLimit();

    final RestResponse<AnalysisDto> analysisResponse = await _intakeService
        .getAnalysis(analysisId: analysisId);

    if (analysisResponse.isFailure) {
      status.value = AnalysisStatusDto.waitingPetition;
      analysisDocument.value = null;
      summary.value = null;
      selectedFile.value = null;
      return;
    }

    final AnalysisStatusDto analysisStatus = analysisResponse.body.status;
    analysisName.value = analysisResponse.body.name;
    isArchived.value = analysisResponse.body.isArchived;

    if (analysisStatus == AnalysisStatusDto.failed) {
      await _resetFailedAnalysis();
      return;
    }

    final bool shouldLoadPetition = _shouldLoadPetition(analysisStatus);

    if (!shouldLoadPetition) {
      status.value = analysisStatus;
      analysisDocument.value = null;
      summary.value = null;
      selectedFile.value = null;
      return;
    }

    final RestResponse<AnalysisDocumentDto> petitionResponse =
        await _intakeService.getAnalysisDocument(analysisId: analysisId);

    if (petitionResponse.isFailure) {
      analysisDocument.value = null;
      summary.value = null;
      selectedFile.value = null;
      status.value = AnalysisStatusDto.waitingPetition;
      return;
    }

    analysisDocument.value = petitionResponse.body;
    summary.value = null;

    final File? petitionFile = await _fileStorageDriver.getFile(
      petitionResponse.body.filePath,
    );
    selectedFile.value = petitionFile;

    if (analysisStatus == AnalysisStatusDto.analyzingPetition) {
      status.value = AnalysisStatusDto.analyzingPetition;
      await _pollPetitionSummary();
      return;
    }

    final bool shouldLoadSummary = _shouldLoadSummary(analysisStatus);

    if (!shouldLoadSummary) {
      status.value = analysisStatus;
      return;
    }

    final RestResponse<CaseSummaryDto> caseSummaryResponse =
        await _intakeService.getCaseSummary(analysisId: analysisId);

    if (caseSummaryResponse.isFailure) {
      status.value = analysisStatus;
      summary.value = null;
      generalError.value = caseSummaryResponse.errorMessage;
      return;
    }

    summary.value = caseSummaryResponse.body;
    status.value = analysisStatus;
  }

  void markPrecedentChosen() {
    status.value = AnalysisStatusDto.precedentChosen;
  }

  bool _shouldLoadPetition(AnalysisStatusDto status) {
    return status == AnalysisStatusDto.petitionUploaded ||
        status == AnalysisStatusDto.analyzingPetition ||
        status == AnalysisStatusDto.caseAnalyzed ||
        status == AnalysisStatusDto.searchingPrecedents ||
        status == AnalysisStatusDto.precedentsSearched ||
        status == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        status == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        status == AnalysisStatusDto.generatingSynthesis ||
        status == AnalysisStatusDto.waitingPrecedentChoice ||
        status == AnalysisStatusDto.precedentChosen;
  }

  bool _shouldLoadSummary(AnalysisStatusDto status) {
    return status == AnalysisStatusDto.caseAnalyzed ||
        status == AnalysisStatusDto.searchingPrecedents ||
        status == AnalysisStatusDto.precedentsSearched ||
        status == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        status == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        status == AnalysisStatusDto.generatingSynthesis ||
        status == AnalysisStatusDto.waitingPrecedentChoice ||
        status == AnalysisStatusDto.precedentChosen;
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
      generalError.value = 'O arquivo deve ter no máximo 50MB.';
      return;
    }

    selectedFile.value = file;
    uploadProgress.value = null;

    await _preparePetition(file);
  }

  Future<void> analyze() async {
    if (!canAnalyze.value) {
      return;
    }

    generalError.value = null;
    final bool summarized = await _summarizePetition();
    if (!summarized) {
      return;
    }
  }

  Future<void> _preparePetition(File file) async {
    generalError.value = null;
    uploadProgress.value = 0;

    final String documentType = _getExtension(file.path);

    final RestResponse<UploadUrlDto> uploadUrlResponse = await _storageService
        .generateAnalysisDocumentUploadUrl(
          analysisId: analysisId,
          documentType: documentType,
        );

    if (uploadUrlResponse.isFailure) {
      await _applyRemoteFailure(uploadUrlResponse.errorMessage);
      return;
    }

    isUploading.value = true;

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
      await _applyRemoteFailure();
      return;
    }

    isUploading.value = false;
    uploadProgress.value = 1;

    final RestResponse<AnalysisDocumentDto> petitionResponse =
        await _intakeService.createAnalysisDocument(
          analysisId: analysisId,
          document: AnalysisDocumentDto(
            analysisId: analysisId,
            uploadedAt: DateTime.now().toUtc().toIso8601String(),
            filePath: uploadUrlResponse.body.filePath,
            name: file.uri.pathSegments.isEmpty
                ? file.path
                : file.uri.pathSegments.last,
          ),
        );

    if (petitionResponse.isFailure) {
      await _applyRemoteFailure(petitionResponse.errorMessage);
      return;
    }

    analysisDocument.value = petitionResponse.body;
    selectedFile.value = null;
    summary.value = null;
    status.value = AnalysisStatusDto.petitionUploaded;
  }

  Future<void> retrySummary() async {
    if (status.value != AnalysisStatusDto.caseAnalyzed) {
      return;
    }

    generalError.value = null;
    await _summarizePetition();
  }

  Future<void> replaceDocument() async {
    analysisDocument.value = null;
    summary.value = null;
    uploadProgress.value = null;
    generalError.value = null;
    status.value = AnalysisStatusDto.waitingPetition;
    selectedFile.value = null;

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

  AnalysisDto? _findArchivedAnalysis(List<AnalysisDto> analyses) {
    for (final AnalysisDto analysis in analyses) {
      if (analysis.id == analysisId) {
        return analysis;
      }
    }

    return analyses.isEmpty ? null : analyses.first;
  }

  Future<bool> exportAnalysisReport() async {
    if (!canExportReport.value || isManagingAnalysis.value) {
      return false;
    }

    isExportingReport.value = true;
    isManagingAnalysis.value = true;
    generalError.value = null;

    try {
      final RestResponse<FirstInstanceAnalysisReportDto> reportResponse =
          await _intakeService.getFirstInstanceAnalysisReport(
            analysisId: analysisId,
          );

      if (reportResponse.isFailure) {
        generalError.value = exportFailedMessage;
        return false;
      }

      final FirstInstanceAnalysisReportDto report = reportResponse.body;
      final Uint8List bytes = await _pdfDriver
          .generateFirstInstanceAnalysisReport(report: report);

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

  String _buildReportFilename(String rawAnalysisName) {
    final String normalizedName = rawAnalysisName.trim();
    final String fallbackName = 'Análise-$analysisId';
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

    return '$safeName — Relatório.pdf';
  }

  void setPrecedentsLimit(int value) {
    if (value < minPrecedentsLimit) {
      return;
    }

    final int normalizedValue = value.clamp(
      minPrecedentsLimit,
      maxPrecedentsLimit,
    );

    if (precedentsLimit.value == normalizedValue) {
      return;
    }

    precedentsLimit.value = normalizedValue;
    _cacheDriver.set(CacheKeys.precedentsLimit, normalizedValue.toString());
  }

  void setPrecedentFilters({
    required List<CourtDto> courts,
    required List<PrecedentKindDto> kinds,
  }) {
    final List<PrecedentKindDto> validKinds =
        PrecedentKindDto.getValidKindsForCourts(courts);
    final List<PrecedentKindDto> filteredKinds = kinds
        .where((PrecedentKindDto kind) => validKinds.contains(kind))
        .toList(growable: false);

    precedentsCourts.value = List<CourtDto>.unmodifiable(courts);
    precedentsKinds.value = List<PrecedentKindDto>.unmodifiable(filteredKinds);
  }

  void _loadCachedPrecedentsLimit() {
    final String? cachedValue = _cacheDriver.get(CacheKeys.precedentsLimit);
    if (cachedValue == null || cachedValue.isEmpty) {
      return;
    }

    final int? parsed = int.tryParse(cachedValue);
    if (parsed == null || parsed < minPrecedentsLimit) {
      return;
    }

    precedentsLimit.value = parsed.clamp(
      minPrecedentsLimit,
      maxPrecedentsLimit,
    );
  }

  void confirmAndViewPrecedents() {
    if (status.value != AnalysisStatusDto.caseAnalyzed) {
      return;
    }

    if (summary.value == null) {
      generalError.value = failedMessage;
      return;
    }

    generalError.value = null;
    status.value = AnalysisStatusDto.searchingPrecedents;
  }

  void dispose() {
    status.dispose();
    selectedFile.dispose();
    isUploading.dispose();
    uploadProgress.dispose();
    analysisDocument.dispose();
    summary.dispose();
    generalError.dispose();
    analysisName.dispose();
    isArchived.dispose();
    isManagingAnalysis.dispose();
    isExportingReport.dispose();
    precedentsLimit.dispose();
    precedentsCourts.dispose();
    precedentsKinds.dispose();
    appliedPrecedentFiltersCount.dispose();
    canPickDocument.dispose();
    canAnalyze.dispose();
    showProcessingBubble.dispose();
    primaryActionLabel.dispose();
    fileActionLabel.dispose();
    showRelevantPrecedents.dispose();
    canExportReport.dispose();
  }

  Future<void> _applyRemoteFailure([String? errorMessage]) async {
    isUploading.value = false;
    uploadProgress.value = null;
    await _resetFailedAnalysis(errorMessage: errorMessage);
  }

  Future<void> _resetFailedAnalysis({String? errorMessage}) async {
    final String resolvedErrorMessage =
        errorMessage == null || errorMessage.isEmpty
        ? failedMessage
        : errorMessage;

    final RestResponse<AnalysisStatusDto> response = await _intakeService
        .updateAnalysisStatus(
          analysisId: analysisId,
          status: AnalysisStatusDto.waitingPetition,
        );

    analysisDocument.value = null;
    summary.value = null;
    selectedFile.value = null;
    uploadProgress.value = null;
    status.value = response.isSuccessful
        ? response.body
        : AnalysisStatusDto.waitingPetition;
    generalError.value = resolvedErrorMessage;
  }

  Future<bool> _summarizePetition() async {
    if (analysisDocument.value == null) {
      await _applyRemoteFailure();
      return false;
    }

    status.value = AnalysisStatusDto.analyzingPetition;

    final RestResponse<void> summarizeResponse = await _intakeService
        .triggerFirstInstanceCaseSummarization(analysisId: analysisId)
        .timeout(
          summaryRequestTimeout,
          onTimeout: () => RestResponse<void>(
            statusCode: HttpStatus.requestTimeout,
            errorMessage: _buildSummaryTimeoutMessage(summaryRequestTimeout),
          ),
        );

    if (summarizeResponse.isFailure) {
      await _applyRemoteFailure(summarizeResponse.errorMessage);
      return false;
    }

    return _pollPetitionSummary();
  }

  Future<bool> _pollPetitionSummary() async {
    if (analysisDocument.value == null) {
      await _applyRemoteFailure();
      return false;
    }

    while (true) {
      final RestResponse<AnalysisDto> analysisResponse = await _intakeService
          .getAnalysis(analysisId: analysisId)
          .timeout(
            summaryRequestTimeout,
            onTimeout: () => RestResponse<AnalysisDto>(
              statusCode: HttpStatus.requestTimeout,
              errorMessage: _buildSummaryTimeoutMessage(summaryRequestTimeout),
            ),
          );

      if (analysisResponse.isFailure) {
        await _applyRemoteFailure(analysisResponse.errorMessage);
        return false;
      }

      final AnalysisStatusDto currentStatus = analysisResponse.body.status;
      status.value = currentStatus;

      if (currentStatus == AnalysisStatusDto.caseAnalyzed) {
        final RestResponse<CaseSummaryDto> summaryResponse =
            await _intakeService.getCaseSummary(analysisId: analysisId);

        if (summaryResponse.isFailure) {
          await _applyRemoteFailure(summaryResponse.errorMessage);
          return false;
        }

        summary.value = summaryResponse.body;
        generalError.value = null;
        return true;
      }

      if (currentStatus == AnalysisStatusDto.failed) {
        await _applyRemoteFailure();
        return false;
      }

      await Future<void>.delayed(summaryPollingInterval);
    }
  }

  String _buildSummaryTimeoutMessage(Duration timeout) {
    return '$failedMessage O resumo excedeu o tempo limite de ${timeout.inSeconds} segundos.';
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

  String _getExtension(String path) {
    final int lastDot = path.lastIndexOf('.');
    if (lastDot < 0 || lastDot == path.length - 1) {
      return '';
    }

    return path.substring(lastDot + 1).toLowerCase();
  }
}

class _PendingPdfDriver implements PdfDriver {
  @override
  Future<Uint8List> generateCaseAssessmentAnalysisReport({
    required CaseAssessmentAnalysisReportDto report,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> generateFirstInstanceAnalysisReport({
    required FirstInstanceAnalysisReportDto report,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> generateSecondInstanceAnalysisReport({
    required SecondInstanceAnalysisReportDto report,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> sharePdf({required Uint8List bytes, required String filename}) {
    throw UnimplementedError();
  }
}

final firstInstanceAnalysisScreenPresenterProvider = Provider.autoDispose
    .family<FirstInstanceAnalysisScreenPresenter, String>((
      Ref ref,
      String analysisId,
    ) {
      final IntakeService intakeService = ref.watch(intakeServiceProvider);
      final StorageService storageService = ref.watch(storageServiceProvider);
      final CacheDriver cacheDriver = ref.watch(cacheDriverProvider);
      final PdfDriver pdfDriver = ref.watch(pdfDriverProvider);
      final FileStorageDriver fileStorageDriver = ref.watch(
        fileStorageDriverProvider,
      );
      final DocumentPickerDriver documentPickerDriver = ref.watch(
        documentPickerDriverProvider,
      );

      final FirstInstanceAnalysisScreenPresenter presenter =
          FirstInstanceAnalysisScreenPresenter(
            intakeService: intakeService,
            storageService: storageService,
            cacheDriver: cacheDriver,
            pdfDriver: pdfDriver,
            fileStorageDriver: fileStorageDriver,
            documentPickerDriver: documentPickerDriver,
            analysisId: analysisId,
          );

      unawaited(presenter.load());

      ref.onDispose(presenter.dispose);
      return presenter;
    });
