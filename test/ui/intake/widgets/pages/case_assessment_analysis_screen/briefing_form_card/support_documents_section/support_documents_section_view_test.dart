import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/support_documents_section/support_documents_section_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/support_documents_section/support_documents_section_view.dart';

import '../../../../../../../fakers/intake/first_instance_analysis_report_dto_faker.dart';

class _MockSupportDocumentsSectionPresenter extends Mock
    implements SupportDocumentsSectionPresenter {}

void main() {
  setUpAll(() {
    registerFallbackValue(AnalysisDocumentDtoFaker.fake());
  });

  testWidgets('should render empty state and add button', (
    WidgetTester tester,
  ) async {
    final presenter = _createPresenter();

    await tester.pumpWidget(_createWidget(presenter));
    await tester.pump();

    expect(find.text('Documentos de apoio'), findsOneWidget);
    expect(find.text('Adicionar documento'), findsOneWidget);
    expect(
      find.text('Nenhum documento de apoio anexado até o momento.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'should render uploading and persisted items and delegate actions',
    (WidgetTester tester) async {
      final document = AnalysisDocumentDtoFaker.fake(name: 'contrato.pdf');
      final presenter = _createPresenter(
        generalError: signal<String?>('Falha ao anexar'),
        documents: signal<List<AnalysisDocumentDto>>(<AnalysisDocumentDto>[
          document,
        ]),
        uploadingDocuments: signal<Map<String, double?>>(<String, double?>{
          'peticao.docx': 0.5,
        }),
      );

      await tester.pumpWidget(_createWidget(presenter));
      await tester.pumpAndSettle();

      expect(find.text('Falha ao anexar'), findsOneWidget);
      expect(find.text('peticao.docx'), findsOneWidget);
      expect(find.text('50% concluído'), findsOneWidget);
      expect(find.text('contrato.pdf'), findsOneWidget);

      await tester.tap(find.text('Adicionar documento'));
      await tester.pump();
      await tester.tap(find.byTooltip('Remover documento').last);
      await tester.pump();

      verify(() => presenter.addSupportDocument()).called(1);
      verify(() => presenter.removeSupportDocument(document)).called(1);
    },
  );
}

Widget _createWidget(_MockSupportDocumentsSectionPresenter presenter) {
  return ProviderScope(
    overrides: [
      supportDocumentsSectionPresenterProvider(
        'analysis-1',
      ).overrideWithValue(presenter),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(
        body: SupportDocumentsSectionView(
          analysisId: 'analysis-1',
          enabled: true,
        ),
      ),
    ),
  );
}

_MockSupportDocumentsSectionPresenter _createPresenter({
  Signal<List<AnalysisDocumentDto>>? documents,
  Signal<Map<String, double?>>? uploadingDocuments,
  Signal<bool>? isPicking,
  Signal<String?>? generalError,
  ReadonlySignal<bool>? canAddDocument,
}) {
  final presenter = _MockSupportDocumentsSectionPresenter();
  when(() => presenter.documents).thenReturn(
    documents ?? signal<List<AnalysisDocumentDto>>(<AnalysisDocumentDto>[]),
  );
  when(() => presenter.uploadingDocuments).thenReturn(
    uploadingDocuments ?? signal<Map<String, double?>>(<String, double?>{}),
  );
  when(() => presenter.isPicking).thenReturn(isPicking ?? signal<bool>(false));
  when(
    () => presenter.generalError,
  ).thenReturn(generalError ?? signal<String?>(null));
  when(
    () => presenter.canAddDocument,
  ).thenReturn(canAddDocument ?? signal<bool>(true));
  when(() => presenter.formatFileSize(any())).thenReturn('20.0 MB');
  when(() => presenter.addSupportDocument()).thenAnswer((_) async {});
  when(() => presenter.removeSupportDocument(any())).thenAnswer((_) async {});
  return presenter;
}
