import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/storage/dtos/upload_url_dto.dart';
import 'package:animus/core/storage/interfaces/drivers/document_picker_driver.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/core/storage/interfaces/storage_service.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/support_documents_section/support_documents_section_presenter.dart';

import '../../../../../../../fakers/intake/first_instance_analysis_report_dto_faker.dart';

class _MockStorageService extends Mock implements StorageService {}

class _MockIntakeService extends Mock implements IntakeService {}

class _MockDocumentPickerDriver extends Mock implements DocumentPickerDriver {}

class _MockFileStorageDriver extends Mock implements FileStorageDriver {}

void main() {
  late _MockStorageService storageService;
  late _MockIntakeService intakeService;
  late _MockDocumentPickerDriver documentPickerDriver;
  late _MockFileStorageDriver fileStorageDriver;

  setUpAll(() {
    registerFallbackValue(File('dummy.pdf'));
    registerFallbackValue(
      const UploadUrlDto(
        url: 'https://upload.test',
        token: 'token',
        filePath: 'uploads/analysis-1.pdf',
      ),
    );
    registerFallbackValue(AnalysisDocumentDtoFaker.fake());
  });

  setUp(() {
    storageService = _MockStorageService();
    intakeService = _MockIntakeService();
    documentPickerDriver = _MockDocumentPickerDriver();
    fileStorageDriver = _MockFileStorageDriver();
  });

  SupportDocumentsSectionPresenter createPresenter() {
    return SupportDocumentsSectionPresenter(
      storageService: storageService,
      intakeService: intakeService,
      documentPickerDriver: documentPickerDriver,
      fileStorageDriver: fileStorageDriver,
      analysisId: 'analysis-1',
    );
  }

  group('SupportDocumentsSectionPresenter', () {
    test('should reject unsupported extension before upload', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);
      final file = await _createTempFile('notes.txt', 256);

      when(
        () => documentPickerDriver.pickDocument(
          allowedExtensions: SupportDocumentsSectionPresenter.allowedExtensions,
        ),
      ).thenAnswer((_) async => file);

      await presenter.addSupportDocument();

      expect(presenter.generalError.value, 'Selecione um arquivo PDF ou DOCX.');
      verifyNever(
        () => storageService.generateAnalysisDocumentUploadUrl(
          analysisId: any(named: 'analysisId'),
          documentType: any(named: 'documentType'),
        ),
      );
    });

    test('should reject files larger than 20MB', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);
      final file = await _createTempFile(
        'briefing.pdf',
        SupportDocumentsSectionPresenter.maxFileSizeInBytes + 1,
      );

      when(
        () => documentPickerDriver.pickDocument(
          allowedExtensions: SupportDocumentsSectionPresenter.allowedExtensions,
        ),
      ).thenAnswer((_) async => file);

      await presenter.addSupportDocument();

      expect(
        presenter.generalError.value,
        'Cada arquivo deve ter no máximo 20MB.',
      );
      verifyNever(
        () => storageService.generateAnalysisDocumentUploadUrl(
          analysisId: any(named: 'analysisId'),
          documentType: any(named: 'documentType'),
        ),
      );
    });

    test(
      'should upload and persist selected support document successfully',
      () async {
        final presenter = createPresenter();
        addTearDown(presenter.dispose);
        final file = await _createTempFile('briefing.pdf', 1024);
        const uploadUrl = UploadUrlDto(
          url: 'https://upload.test',
          token: 'token',
          filePath: 'uploads/analysis-1/briefing.pdf',
        );
        final document = AnalysisDocumentDtoFaker.fake(
          analysisId: 'analysis-1',
          filePath: uploadUrl.filePath,
          name: 'briefing.pdf',
        );

        when(
          () => documentPickerDriver.pickDocument(
            allowedExtensions:
                SupportDocumentsSectionPresenter.allowedExtensions,
          ),
        ).thenAnswer((_) async => file);
        when(
          () => storageService.generateAnalysisDocumentUploadUrl(
            analysisId: 'analysis-1',
            documentType: 'pdf',
          ),
        ).thenAnswer(
          (_) async => RestResponse(statusCode: 200, body: uploadUrl),
        );
        when(
          () => fileStorageDriver.uploadFile(
            any(),
            any(),
            onProgress: any(named: 'onProgress'),
          ),
        ).thenAnswer((Invocation invocation) async {
          final callback =
              invocation.namedArguments[#onProgress]
                  as void Function(int sentBytes, int totalBytes)?;
          callback?.call(256, 1024);
        });
        when(
          () => intakeService.createAnalysisDocument(
            analysisId: 'analysis-1',
            document: any(named: 'document'),
          ),
        ).thenAnswer(
          (_) async => RestResponse(statusCode: 200, body: document),
        );

        await presenter.addSupportDocument();

        expect(presenter.documents.value, <AnalysisDocumentDto>[document]);
        expect(presenter.uploadingDocuments.value, isEmpty);
        expect(presenter.generalError.value, isNull);
        verify(
          () => storageService.generateAnalysisDocumentUploadUrl(
            analysisId: 'analysis-1',
            documentType: 'pdf',
          ),
        ).called(1);
        verify(
          () => intakeService.createAnalysisDocument(
            analysisId: 'analysis-1',
            document: any(named: 'document'),
          ),
        ).called(1);
      },
    );

    test('should remove persisted document when service succeeds', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);
      final document = AnalysisDocumentDtoFaker.fake();
      presenter.documents.value = <AnalysisDocumentDto>[document];

      when(
        () => intakeService.removeAnalysisDocument(
          analysisId: 'analysis-1',
          filePath: document.filePath,
        ),
      ).thenAnswer((_) async => RestResponse<void>(statusCode: 200));

      await presenter.removeSupportDocument(document);

      expect(presenter.documents.value, isEmpty);
      expect(presenter.generalError.value, isNull);
    });

    test('should keep document and show error when remove fails', () async {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);
      final document = AnalysisDocumentDtoFaker.fake();
      presenter.documents.value = <AnalysisDocumentDto>[document];

      when(
        () => intakeService.removeAnalysisDocument(
          analysisId: 'analysis-1',
          filePath: document.filePath,
        ),
      ).thenAnswer(
        (_) async => RestResponse<void>(
          statusCode: 500,
          errorMessage: 'Falha ao remover',
        ),
      );

      await presenter.removeSupportDocument(document);

      expect(presenter.documents.value, <AnalysisDocumentDto>[document]);
      expect(presenter.generalError.value, 'Falha ao remover');
    });

    test('should format sizes and extensions consistently', () {
      final presenter = createPresenter();
      addTearDown(presenter.dispose);

      expect(
        presenter.fileName(File(r'C:\temp\briefing.docx')),
        'briefing.docx',
      );
      expect(presenter.extensionFromPath(r'C:\temp\briefing.DOCX'), 'docx');
      expect(presenter.formatFileSize(512), '512 B');
      expect(presenter.formatFileSize(2048), '2.0 KB');
      expect(presenter.formatFileSize(3 * 1024 * 1024), '3.0 MB');
    });
  });
}

Future<File> _createTempFile(String name, int sizeInBytes) async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'animus_support_documents_test',
  );
  final File file = File('${directory.path}${Platform.pathSeparator}$name');
  await file.writeAsBytes(List<int>.filled(sizeInBytes, 1));
  return file;
}
