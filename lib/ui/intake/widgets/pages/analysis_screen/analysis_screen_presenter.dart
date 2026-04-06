import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/constants/cache_keys.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/petition_document_dto.dart';
import 'package:animus/core/intake/dtos/petition_dto.dart';
import 'package:animus/core/intake/dtos/petition_summary_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';
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
import 'package:animus/drivers/storage/file_storage/index.dart';
import 'package:animus/rest/services/index.dart';

class AnalysisScreenPresenter {
  static const List<String> allowedExtensions = <String>['pdf', 'docx'];
  static const int maxFileSizeInBytes = 20 * 1024 * 1024;
  static const int defaultPrecedentsLimit = 5;
  static const Duration summaryPollingInterval = Duration(seconds: 3);
  static const Duration summaryRequestTimeout = Duration(seconds: 10);
  static const Duration summaryTimeout = Duration(seconds: 60);
  static const String failedMessage =
      'Nao foi possivel analisar o documento agora. Tente novamente.';
  static const String exportFailedMessage =
      'Nao foi possivel exportar o relatorio agora. Tente novamente.';

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
  final Signal<PetitionDto?> petition = signal<PetitionDto?>(null);
  final Signal<PetitionSummaryDto?> summary = signal<PetitionSummaryDto?>(null);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<String> analysisName = signal<String>('Nova Análise');
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
    final String? petitionId = petition.value?.id;
    final bool hasPetition = petitionId != null && petitionId.isNotEmpty;
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
    return status.value == AnalysisStatusDto.petitionAnalyzed
        ? 'Buscar precedentes'
        : 'Analisar';
  });

  late final ReadonlySignal<String> fileActionLabel = computed(() {
    return status.value == AnalysisStatusDto.petitionAnalyzed
        ? 'Enviar outro documento'
        : 'Selecionar petição';
  });

  late final ReadonlySignal<bool> showRelevantPrecedents = computed(() {
    final AnalysisStatusDto currentStatus = status.value;

    return currentStatus == AnalysisStatusDto.searchingPrecedents ||
        currentStatus == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        currentStatus == AnalysisStatusDto.generatingSynthesis ||
        currentStatus == AnalysisStatusDto.waitingPrecedentChoice ||
        currentStatus == AnalysisStatusDto.precedentChosen;
  });

  late final ReadonlySignal<bool> canExportReport = computed(() {
    return status.value == AnalysisStatusDto.precedentChosen &&
        !isExportingReport.value;
  });

  AnalysisScreenPresenter({
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
      petition.value = null;
      summary.value = null;
      selectedFile.value = null;
      return;
    }

    final AnalysisStatusDto analysisStatus = analysisResponse.body.status;
    analysisName.value = analysisResponse.body.name;

    final bool shouldLoadPetition = _shouldLoadPetition(analysisStatus);

    if (!shouldLoadPetition) {
      status.value = analysisStatus;
      petition.value = null;
      summary.value = null;
      selectedFile.value = null;
      return;
    }

    final RestResponse<PetitionDto> petitionResponse = await _intakeService
        .getAnalysisPetition(analysisId: analysisId);

    if (petitionResponse.isFailure) {
      petition.value = null;
      summary.value = null;
      selectedFile.value = null;
      status.value = AnalysisStatusDto.waitingPetition;
      return;
    }

    petition.value = petitionResponse.body;
    summary.value = null;

    final File? petitionFile = await _fileStorageDriver.getFile(
      petitionResponse.body.document.filePath,
    );
    selectedFile.value = petitionFile;

    if (analysisStatus == AnalysisStatusDto.analyzingPetition) {
      status.value = AnalysisStatusDto.analyzingPetition;
      await _pollPetitionSummary(petition.value);
      return;
    }

    final bool shouldLoadSummary = _shouldLoadSummary(analysisStatus);

    if (!shouldLoadSummary) {
      status.value = analysisStatus;
      return;
    }

    final String? petitionId = petition.value?.id;
    if (petitionId == null || petitionId.isEmpty) {
      status.value = AnalysisStatusDto.petitionUploaded;
      return;
    }

    final RestResponse<PetitionSummaryDto> petitionSummaryResponse =
        await _intakeService.getPetitionSummary(petitionId: petitionId);

    if (petitionSummaryResponse.isFailure) {
      status.value = analysisStatus;
      summary.value = null;
      generalError.value = petitionSummaryResponse.errorMessage;
      return;
    }

    summary.value = petitionSummaryResponse.body;
    status.value = analysisStatus;
  }

  void markPrecedentChosen() {
    status.value = AnalysisStatusDto.precedentChosen;
  }

  bool _shouldLoadPetition(AnalysisStatusDto status) {
    return status == AnalysisStatusDto.petitionUploaded ||
        status == AnalysisStatusDto.analyzingPetition ||
        status == AnalysisStatusDto.petitionAnalyzed ||
        status == AnalysisStatusDto.searchingPrecedents ||
        status == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        status == AnalysisStatusDto.generatingSynthesis ||
        status == AnalysisStatusDto.waitingPrecedentChoice ||
        status == AnalysisStatusDto.precedentChosen;
  }

  bool _shouldLoadSummary(AnalysisStatusDto status) {
    return status == AnalysisStatusDto.petitionAnalyzed ||
        status == AnalysisStatusDto.searchingPrecedents ||
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
      generalError.value = 'O arquivo deve ter no maximo 20MB.';
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

    final String? petitionId = petition.value?.id;
    if (petitionId == null || petitionId.isEmpty) {
      return;
    }

    generalError.value = null;
    final PetitionDto? currentPetition = petition.value;
    final bool summarized = await _summarizePetition(currentPetition);
    if (!summarized) {
      return;
    }
  }

  Future<void> _preparePetition(File file) async {
    generalError.value = null;
    uploadProgress.value = 0;

    final String documentType = _getExtension(file.path);

    final RestResponse<UploadUrlDto> uploadUrlResponse = await _storageService
        .generatePetitionUploadUrl(
          analysisId: analysisId,
          documentType: documentType,
        );

    if (uploadUrlResponse.isFailure) {
      _applyRemoteFailure(uploadUrlResponse.errorMessage);
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
      _applyRemoteFailure();
      return;
    }

    isUploading.value = false;
    uploadProgress.value = 1;

    final PetitionDto createdPetitionPayload = PetitionDto(
      analysisId: analysisId,
      uploadedAt: DateTime.now().toUtc().toIso8601String(),
      document: PetitionDocumentDto(
        filePath: uploadUrlResponse.body.filePath,
        name: file.uri.pathSegments.isEmpty
            ? file.path
            : file.uri.pathSegments.last,
      ),
    );

    final RestResponse<PetitionDto> petitionResponse = await _intakeService
        .createPetition(petition: createdPetitionPayload);

    if (petitionResponse.isFailure) {
      _applyRemoteFailure(petitionResponse.errorMessage);
      return;
    }

    petition.value = petitionResponse.body;
    summary.value = null;
    status.value = AnalysisStatusDto.petitionUploaded;
  }

  Future<void> retrySummary() async {
    if (status.value != AnalysisStatusDto.petitionAnalyzed) {
      return;
    }

    final String? petitionId = petition.value?.id;
    if (petitionId == null || petitionId.isEmpty) {
      _applyRemoteFailure();
      return;
    }

    generalError.value = null;
    await _summarizePetition(petition.value);
  }

  Future<void> replaceDocument() async {
    petition.value = null;
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

  Future<bool> exportAnalysisReport() async {
    if (!canExportReport.value || isManagingAnalysis.value) {
      return false;
    }

    isExportingReport.value = true;
    isManagingAnalysis.value = true;
    generalError.value = null;

    try {
      final RestResponse<AnalysisReportDto> reportResponse =
          await _intakeService.getAnalysisReport(analysisId: analysisId);

      if (reportResponse.isFailure) {
        generalError.value = exportFailedMessage;
        return false;
      }

      final AnalysisReportDto report = reportResponse.body;
      final Uint8List bytes = await _pdfDriver.generateAnalysisReport(
        report: report,
      );

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

    return '$safeName — Relatorio.pdf';
  }

  void setPrecedentsLimit(int value) {
    if (value <= 0) {
      return;
    }

    if (precedentsLimit.value == value) {
      return;
    }

    precedentsLimit.value = value;
    _cacheDriver.set(CacheKeys.precedentsLimit, value.toString());
  }

  void setPrecedentFilters({
    required List<CourtDto> courts,
    required List<PrecedentKindDto> kinds,
  }) {
    precedentsCourts.value = List<CourtDto>.unmodifiable(courts);
    precedentsKinds.value = List<PrecedentKindDto>.unmodifiable(kinds);
  }

  void _loadCachedPrecedentsLimit() {
    final String? cachedValue = _cacheDriver.get(CacheKeys.precedentsLimit);
    if (cachedValue == null || cachedValue.isEmpty) {
      return;
    }

    final int? parsed = int.tryParse(cachedValue);
    if (parsed == null || parsed <= 0) {
      return;
    }

    precedentsLimit.value = parsed;
  }

  void confirmAndViewPrecedents() {
    if (status.value != AnalysisStatusDto.petitionAnalyzed) {
      return;
    }

    final String? petitionId = petition.value?.id;
    if (petitionId == null || petitionId.isEmpty) {
      generalError.value = failedMessage;
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
    petition.dispose();
    summary.dispose();
    generalError.dispose();
    analysisName.dispose();
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

  void _applyRemoteFailure([String? errorMessage]) {
    isUploading.value = false;
    uploadProgress.value = null;
    status.value = AnalysisStatusDto.failed;
    generalError.value = errorMessage == null || errorMessage.isEmpty
        ? failedMessage
        : errorMessage;
  }

  Future<bool> _summarizePetition(PetitionDto? petitionData) async {
    final String? petitionId = petitionData?.id;

    if (petitionId == null || petitionId.isEmpty) {
      _applyRemoteFailure();
      return false;
    }

    status.value = AnalysisStatusDto.analyzingPetition;

    final RestResponse<void> summarizeResponse = await _intakeService
        .summarizePetition(petitionId: petitionId)
        .timeout(
          summaryRequestTimeout,
          onTimeout: () => RestResponse<void>(
            statusCode: HttpStatus.requestTimeout,
            errorMessage: _buildSummaryTimeoutMessage(summaryRequestTimeout),
          ),
        );

    if (summarizeResponse.isFailure) {
      _applyRemoteFailure(summarizeResponse.errorMessage);
      return false;
    }

    return _pollPetitionSummary(petitionData);
  }

  Future<bool> _pollPetitionSummary(PetitionDto? petitionData) async {
    final String? petitionId = petitionData?.id;
    final String analysisId = petitionData?.analysisId ?? this.analysisId;

    if (petitionId == null || petitionId.isEmpty) {
      _applyRemoteFailure();
      return false;
    }

    Duration elapsed = Duration.zero;

    while (elapsed < summaryTimeout) {
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
        _applyRemoteFailure(analysisResponse.errorMessage);
        return false;
      }

      final AnalysisStatusDto currentStatus = analysisResponse.body.status;
      status.value = currentStatus;

      if (currentStatus == AnalysisStatusDto.petitionAnalyzed) {
        final RestResponse<PetitionSummaryDto> summaryResponse =
            await _intakeService.getPetitionSummary(petitionId: petitionId);

        if (summaryResponse.isFailure) {
          _applyRemoteFailure(summaryResponse.errorMessage);
          return false;
        }

        summary.value = summaryResponse.body;
        generalError.value = null;
        return true;
      }

      if (currentStatus == AnalysisStatusDto.failed) {
        _applyRemoteFailure();
        return false;
      }

      await Future<void>.delayed(summaryPollingInterval);
      elapsed += summaryPollingInterval;
    }

    _applyRemoteFailure(_buildSummaryTimeoutMessage(summaryTimeout));
    return false;
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
  Future<Uint8List> generateAnalysisReport({
    required AnalysisReportDto report,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> sharePdf({required Uint8List bytes, required String filename}) {
    throw UnimplementedError();
  }
}

final analysisScreenPresenterProvider = Provider.autoDispose
    .family<AnalysisScreenPresenter, String>((Ref ref, String analysisId) {
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

      final AnalysisScreenPresenter presenter = AnalysisScreenPresenter(
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
