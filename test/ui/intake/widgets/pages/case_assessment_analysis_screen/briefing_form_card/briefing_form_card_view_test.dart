import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/dtos/case_assessment_briefing_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/briefing_form_card_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/briefing_form_card_view.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/support_documents_section/support_documents_section_presenter.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../../../fakers/intake/case_assessment_briefing_dto_faker.dart';
import '../../../../../../fakers/intake/first_instance_analysis_report_dto_faker.dart';

class _MockIntakeService extends Mock implements IntakeService {}

class _MockOnSubmitted extends Mock {
  Future<void> call(CaseAssessmentBriefingDto briefing);
}

class _MockSupportDocumentsSectionPresenter extends Mock
    implements SupportDocumentsSectionPresenter {}

void main() {
  late _MockIntakeService intakeService;
  late _MockOnSubmitted onSubmitted;

  setUpAll(() {
    registerFallbackValue(CaseAssessmentBriefingDtoFaker.fake());
    registerFallbackValue(AnalysisDocumentDtoFaker.fake());
  });

  setUp(() {
    intakeService = _MockIntakeService();
    onSubmitted = _MockOnSubmitted();
    when(() => onSubmitted.call(any())).thenAnswer((_) async {});
  });

  testWidgets(
    'should render briefing form copy and support documents section',
    (WidgetTester tester) async {
      final presenter = BriefingFormCardPresenter(
        intakeService: intakeService,
        analysisId: 'analysis-1',
      );
      addTearDown(presenter.dispose);

      await tester.pumpWidget(_createWidget(presenter: presenter));
      await tester.pump();

      expect(find.text('Briefing do caso'), findsOneWidget);
      expect(find.text('Área jurídica'), findsOneWidget);
      expect(find.text('Tribunal'), findsOneWidget);
      expect(find.text('Pedidos principais'), findsOneWidget);
      expect(find.text('Tese pretendida'), findsOneWidget);
      expect(find.text('Documentos de apoio'), findsOneWidget);
      expect(find.text('Salvar briefing'), findsOneWidget);
    },
  );

  testWidgets('should show inline error from presenter', (
    WidgetTester tester,
  ) async {
    final presenter = BriefingFormCardPresenter(
      intakeService: intakeService,
      analysisId: 'analysis-1',
    );
    addTearDown(presenter.dispose);
    presenter.generalError.value = 'Falha ao carregar briefing';

    await tester.pumpWidget(_createWidget(presenter: presenter));
    await tester.pump();

    expect(find.text('Falha ao carregar briefing'), findsOneWidget);
  });

  testWidgets('should submit valid briefing and notify callback', (
    WidgetTester tester,
  ) async {
    final presenter = BriefingFormCardPresenter(
      intakeService: intakeService,
      analysisId: 'analysis-1',
    );
    addTearDown(presenter.dispose);
    final briefing = CaseAssessmentBriefingDtoFaker.fake();

    presenter.fillForm(briefing);
    presenter.resetAfterResubmit();

    when(
      () => intakeService.submitCaseAssessmentBriefing(
        analysisId: 'analysis-1',
        briefing: any(named: 'briefing'),
      ),
    ).thenAnswer((_) async => RestResponse(statusCode: 200, body: briefing));

    await tester.pumpWidget(
      _createWidget(presenter: presenter, onSubmitted: onSubmitted.call),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Salvar briefing'));
    await tester.tap(find.text('Salvar briefing'));
    await tester.pumpAndSettle();

    verify(() => onSubmitted.call(briefing)).called(1);
  });
}

Widget _createWidget({
  required BriefingFormCardPresenter presenter,
  Future<void> Function(CaseAssessmentBriefingDto briefing)? onSubmitted,
}) {
  final _MockSupportDocumentsSectionPresenter supportPresenter =
      _createSupportDocumentsPresenter();

  return ProviderScope(
    overrides: [
      briefingFormCardPresenterProvider(
        'analysis-1',
      ).overrideWithValue(presenter),
      supportDocumentsSectionPresenterProvider(
        'analysis-1',
      ).overrideWithValue(supportPresenter),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BriefingFormCardView(
              analysisId: 'analysis-1',
              enabled: true,
              onSubmitted: onSubmitted,
            ),
          ),
        ),
      ),
    ),
  );
}

_MockSupportDocumentsSectionPresenter _createSupportDocumentsPresenter() {
  final _MockSupportDocumentsSectionPresenter presenter =
      _MockSupportDocumentsSectionPresenter();
  when(
    () => presenter.documents,
  ).thenReturn(signal<List<AnalysisDocumentDto>>(<AnalysisDocumentDto>[]));
  when(
    () => presenter.uploadingDocuments,
  ).thenReturn(signal<Map<String, double?>>(<String, double?>{}));
  when(() => presenter.isPicking).thenReturn(signal<bool>(false));
  when(() => presenter.generalError).thenReturn(signal<String?>(null));
  when(() => presenter.canAddDocument).thenReturn(signal<bool>(true));
  when(() => presenter.formatFileSize(any())).thenReturn('20.0 MB');
  when(() => presenter.addSupportDocument()).thenAnswer((_) async {});
  when(() => presenter.removeSupportDocument(any())).thenAnswer((_) async {});
  return presenter;
}
