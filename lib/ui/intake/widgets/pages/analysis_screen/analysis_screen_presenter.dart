import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/petition_document_dto.dart';
import 'package:animus/core/intake/dtos/petition_dto.dart';
import 'package:animus/core/intake/dtos/petition_summary_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/storage/interfaces/drivers/document_picker_driver.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/core/storage/interfaces/storage_service.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/drivers/document-picker-driver/index.dart';
import 'package:animus/drivers/storage/file_storage/index.dart';
import 'package:animus/rest/services/index.dart';

class AnalysisScreenPresenter {
  static const List<String> allowedExtensions = <String>['pdf', 'docx'];
  static const int maxFileSizeInBytes = 20 * 1024 * 1024;
  static const String failedMessage =
      'Nao foi possivel analisar o documento agora. Tente novamente.';

  final IntakeService _intakeService;
  final StorageService _storageService;
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

  AnalysisScreenPresenter({
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
    final RestResponse<AnalysisDto> analysisResponse = await _intakeService
        .getAnalysis(analysisId: analysisId);

    if (analysisResponse.isFailure) {
      status.value = AnalysisStatusDto.waitingPetition;
      petition.value = null;
      summary.value = null;
      return;
    }

    final AnalysisStatusDto analysisStatus = analysisResponse.body.status;
    status.value = analysisStatus;

    if (analysisStatus != AnalysisStatusDto.petitionUploaded &&
        analysisStatus != AnalysisStatusDto.analyzingPetition &&
        analysisStatus != AnalysisStatusDto.petitionAnalyzed) {
      petition.value = null;
      summary.value = null;
      return;
    }

    final RestResponse<PetitionDto> petitionResponse = await _intakeService
        .getAnalysisPetition(analysisId: analysisId);

    if (petitionResponse.isFailure) {
      petition.value = null;
      summary.value = null;
      status.value = AnalysisStatusDto.waitingPetition;
      return;
    }

    petition.value = petitionResponse.body;
    summary.value = null;

    if (analysisStatus != AnalysisStatusDto.petitionAnalyzed) {
      status.value = analysisStatus;
      return;
    }

    final String? petitionId = petitionResponse.body.id;
    if (petitionId == null || petitionId.isEmpty) {
      status.value = AnalysisStatusDto.petitionUploaded;
      return;
    }

    final RestResponse<PetitionSummaryDto> petitionSummaryResponse =
        await _intakeService.getPetitionSummary(petitionId: petitionId);

    if (petitionSummaryResponse.isFailure) {
      status.value = AnalysisStatusDto.petitionUploaded;
      return;
    }

    summary.value = petitionSummaryResponse.body;
    status.value = AnalysisStatusDto.petitionAnalyzed;
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
    final bool summarized = await _summarizePetition(petitionId);
    if (!summarized) {
      return;
    }
  }

  Future<void> _preparePetition(File file) async {
    generalError.value = null;
    uploadProgress.value = 0;

    final String documentType = _getExtension(file.path);

    final RestResponse<dynamic> uploadUrlResponse = await _storageService
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
      _applyRemoteFailure();
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
    await _summarizePetition(petitionId);
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

  void confirmAndViewPrecedents() {}

  void dispose() {
    status.dispose();
    selectedFile.dispose();
    isUploading.dispose();
    uploadProgress.dispose();
    petition.dispose();
    summary.dispose();
    generalError.dispose();
    canPickDocument.dispose();
    canAnalyze.dispose();
    showProcessingBubble.dispose();
    primaryActionLabel.dispose();
    fileActionLabel.dispose();
  }

  void _applyRemoteFailure([String? errorMessage]) {
    isUploading.value = false;
    uploadProgress.value = null;
    status.value = AnalysisStatusDto.failed;
    generalError.value = errorMessage == null || errorMessage.isEmpty
        ? failedMessage
        : errorMessage;
  }

  Future<bool> _summarizePetition(String? petitionId) async {
    if (petitionId == null || petitionId.isEmpty) {
      _applyRemoteFailure();
      return false;
    }

    status.value = AnalysisStatusDto.analyzingPetition;

    final RestResponse<PetitionSummaryDto>
    summaryResponse = await _intakeService
        .summarizePetition(petitionId: petitionId)
        .timeout(
          const Duration(seconds: 60),
          onTimeout: () => RestResponse<PetitionSummaryDto>(
            statusCode: HttpStatus.requestTimeout,
            errorMessage:
                '$failedMessage O resumo excedeu o tempo limite de 60 segundos.',
          ),
        );

    if (summaryResponse.isFailure) {
      _applyRemoteFailure(summaryResponse.errorMessage);
      return false;
    }

    summary.value = summaryResponse.body;
    status.value = AnalysisStatusDto.petitionAnalyzed;
    generalError.value = null;
    return true;
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

final analysisScreenPresenterProvider = Provider.autoDispose
    .family<AnalysisScreenPresenter, String>((Ref ref, String analysisId) {
      final IntakeService intakeService = ref.watch(intakeServiceProvider);
      final StorageService storageService = ref.watch(storageServiceProvider);
      final FileStorageDriver fileStorageDriver = ref.watch(
        fileStorageDriverProvider,
      );
      final DocumentPickerDriver documentPickerDriver = ref.watch(
        documentPickerDriverProvider,
      );

      final AnalysisScreenPresenter presenter = AnalysisScreenPresenter(
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
