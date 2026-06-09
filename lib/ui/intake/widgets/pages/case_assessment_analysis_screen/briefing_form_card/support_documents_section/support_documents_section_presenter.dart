import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/storage/dtos/upload_url_dto.dart';
import 'package:animus/core/storage/interfaces/drivers/document_picker_driver.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/core/storage/interfaces/storage_service.dart';
import 'package:animus/drivers/document-picker-driver/index.dart';
import 'package:animus/drivers/file_storage/index.dart';
import 'package:animus/rest/services/index.dart';

class SupportDocumentsSectionPresenter {
  static const List<String> allowedExtensions = <String>['pdf', 'docx'];
  static const int maxFileSizeInBytes = 20 * 1024 * 1024;
  static const String failedMessage =
      'Não foi possível adicionar o documento agora. Tente novamente.';
  static const String removeFailedMessage =
      'Não foi possível remover o documento agora. Tente novamente.';

  final StorageService _storageService;
  final IntakeService _intakeService;
  final DocumentPickerDriver _documentPickerDriver;
  final FileStorageDriver _fileStorageDriver;
  final String analysisId;

  bool _isDisposed = false;

  final Signal<List<AnalysisDocumentDto>> documents =
      signal<List<AnalysisDocumentDto>>(const <AnalysisDocumentDto>[]);
  final Signal<Map<String, double?>> uploadingDocuments =
      signal<Map<String, double?>>(const <String, double?>{});
  final Signal<bool> isPicking = signal<bool>(false);
  final Signal<String?> generalError = signal<String?>(null);

  late final ReadonlySignal<bool> canAddDocument = computed(() {
    return !isPicking.value && uploadingDocuments.value.isEmpty;
  });

  SupportDocumentsSectionPresenter({
    required StorageService storageService,
    required IntakeService intakeService,
    required DocumentPickerDriver documentPickerDriver,
    required FileStorageDriver fileStorageDriver,
    required this.analysisId,
  }) : _storageService = storageService,
       _intakeService = intakeService,
       _documentPickerDriver = documentPickerDriver,
       _fileStorageDriver = fileStorageDriver;

  Future<void> addSupportDocument() async {
    if (!canAddDocument.value) {
      return;
    }

    generalError.value = null;
    isPicking.value = true;

    final File? file;
    try {
      file = await _documentPickerDriver.pickDocument(
        allowedExtensions: allowedExtensions,
      );
    } finally {
      if (!_isDisposed) {
        isPicking.value = false;
      }
    }

    if (_isDisposed || file == null) {
      return;
    }

    final String extension = extensionFromPath(file.path);
    if (!allowedExtensions.contains(extension)) {
      generalError.value = 'Selecione um arquivo PDF ou DOCX.';
      return;
    }

    final int fileSize = await file.length();
    if (_isDisposed) {
      return;
    }

    if (fileSize > maxFileSizeInBytes) {
      generalError.value = 'Cada arquivo deve ter no máximo 20MB.';
      return;
    }

    final String documentName = fileName(file);
    uploadingDocuments.value = <String, double?>{
      ...uploadingDocuments.value,
      documentName: 0,
    };

    String? uploadedFilePath;

    try {
      final RestResponse<UploadUrlDto> uploadUrlResponse = await _storageService
          .generateAnalysisDocumentUploadUrl(
            analysisId: analysisId,
            documentType: extension,
          );

      if (_isDisposed) {
        return;
      }

      if (uploadUrlResponse.isFailure) {
        generalError.value = uploadUrlResponse.errorMessage.isNotEmpty
            ? uploadUrlResponse.errorMessage
            : failedMessage;
        return;
      }

      uploadedFilePath = uploadUrlResponse.body.filePath;

      await _fileStorageDriver.uploadFile(
        file,
        uploadUrlResponse.body,
        onProgress: (int sentBytes, int totalBytes) {
          if (_isDisposed) {
            return;
          }

          uploadingDocuments.value = <String, double?>{
            ...uploadingDocuments.value,
            documentName: totalBytes <= 0 ? null : sentBytes / totalBytes,
          };
        },
      );

      if (_isDisposed) {
        await _deletePendingUploadDocument(uploadedFilePath);
        return;
      }

      final RestResponse<AnalysisDocumentDto> createDocumentResponse =
          await _intakeService.createAnalysisDocument(
            analysisId: analysisId,
            document: AnalysisDocumentDto(
              analysisId: analysisId,
              uploadedAt: DateTime.now().toUtc().toIso8601String(),
              filePath: uploadedFilePath,
              name: documentName,
            ),
          );

      if (_isDisposed) {
        await _deletePendingUploadDocument(uploadedFilePath);
        return;
      }

      if (createDocumentResponse.isFailure) {
        await _deletePendingUploadDocument(uploadedFilePath);
        generalError.value = createDocumentResponse.errorMessage.isNotEmpty
            ? createDocumentResponse.errorMessage
            : failedMessage;
        return;
      }

      documents.value = <AnalysisDocumentDto>[
        ...documents.value,
        createDocumentResponse.body,
      ];
      generalError.value = null;
    } catch (_) {
      if (uploadedFilePath != null) {
        await _deletePendingUploadDocument(uploadedFilePath);
      }

      if (_isDisposed) {
        return;
      }

      generalError.value = failedMessage;
    } finally {
      if (!_isDisposed) {
        final Map<String, double?> nextUploadingDocuments =
            Map<String, double?>.from(uploadingDocuments.value);
        nextUploadingDocuments.remove(documentName);
        uploadingDocuments.value = nextUploadingDocuments;
      }
    }
  }

  Future<void> removeSupportDocument(AnalysisDocumentDto document) async {
    generalError.value = null;

    final RestResponse<void> response = await _intakeService
        .removeAnalysisDocument(
          analysisId: analysisId,
          filePath: document.filePath,
        );

    if (_isDisposed) {
      return;
    }

    if (response.isFailure) {
      generalError.value = response.errorMessage.isNotEmpty
          ? response.errorMessage
          : removeFailedMessage;
      return;
    }

    documents.value = documents.value
        .where((AnalysisDocumentDto item) => item.filePath != document.filePath)
        .toList(growable: false);
  }

  String fileName(File file) {
    return file.uri.pathSegments.isEmpty
        ? file.path
        : file.uri.pathSegments.last;
  }

  String formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    }

    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String extensionFromPath(String path) {
    final String fileName = path.split(Platform.pathSeparator).last;
    final int extensionIndex = fileName.lastIndexOf('.');
    if (extensionIndex < 0 || extensionIndex == fileName.length - 1) {
      return '';
    }

    return fileName.substring(extensionIndex + 1).toLowerCase();
  }

  Future<void> _deletePendingUploadDocument(String filePath) async {
    await _intakeService.removeAnalysisDocument(
      analysisId: analysisId,
      filePath: filePath,
    );
  }

  void dispose() {
    _isDisposed = true;
    documents.dispose();
    uploadingDocuments.dispose();
    isPicking.dispose();
    generalError.dispose();
    canAddDocument.dispose();
  }
}

final supportDocumentsSectionPresenterProvider = Provider.autoDispose
    .family<SupportDocumentsSectionPresenter, String>((
      Ref ref,
      String analysisId,
    ) {
      final StorageService storageService = ref.watch(storageServiceProvider);
      final IntakeService intakeService = ref.watch(intakeServiceProvider);
      final DocumentPickerDriver documentPickerDriver = ref.watch(
        documentPickerDriverProvider,
      );
      final FileStorageDriver fileStorageDriver = ref.watch(
        fileStorageDriverProvider,
      );

      final SupportDocumentsSectionPresenter presenter =
          SupportDocumentsSectionPresenter(
            storageService: storageService,
            intakeService: intakeService,
            documentPickerDriver: documentPickerDriver,
            fileStorageDriver: fileStorageDriver,
            analysisId: analysisId,
          );

      ref.onDispose(presenter.dispose);
      return presenter;
    });
