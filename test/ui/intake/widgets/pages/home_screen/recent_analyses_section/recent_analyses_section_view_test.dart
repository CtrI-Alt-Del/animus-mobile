import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_loading_state/index.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_section_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../fakers/intake/analysis_dto_faker.dart';

void main() {
  testWidgets('renderiza loading inicial da secao', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _createWidget(
        RecentAnalysesSectionView(
          analyses: const <AnalysisDto>[],
          isLoading: true,
          isLoadingMore: false,
          hasMore: false,
          showEmptyState: false,
          errorMessage: null,
          formatCreatedAt: (String value) => value,
          onRefresh: () async {},
          onTapAnalysis: (_) async {},
          onRetry: () {},
          onLoadMore: () async {},
          onCreateFirstAnalysis: () {},
        ),
      ),
    );

    expect(find.byType(RecentAnalysesLoadingState), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Tentar novamente'), findsNothing);
    expect(find.text('Iniciar primeira analise'), findsNothing);
  });

  testWidgets('renderiza erro inicial e executa retry', (
    WidgetTester tester,
  ) async {
    int retryCount = 0;

    await tester.pumpWidget(
      _createWidget(
        RecentAnalysesSectionView(
          analyses: const <AnalysisDto>[],
          isLoading: false,
          isLoadingMore: false,
          hasMore: false,
          showEmptyState: false,
          errorMessage: 'Falha ao buscar analises',
          formatCreatedAt: (String value) => value,
          onRefresh: () async {},
          onTapAnalysis: (_) async {},
          onRetry: () {
            retryCount += 1;
          },
          onLoadMore: () async {},
          onCreateFirstAnalysis: () {},
        ),
      ),
    );

    expect(find.text('Falha ao buscar analises'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();

    expect(retryCount, 1);
  });

  testWidgets('renderiza estado vazio e executa CTA principal', (
    WidgetTester tester,
  ) async {
    int createCount = 0;

    await tester.pumpWidget(
      _createWidget(
        RecentAnalysesSectionView(
          analyses: const <AnalysisDto>[],
          isLoading: false,
          isLoadingMore: false,
          hasMore: false,
          showEmptyState: true,
          errorMessage: null,
          formatCreatedAt: (String value) => value,
          onRefresh: () async {},
          onTapAnalysis: (_) async {},
          onRetry: () {},
          onLoadMore: () async {},
          onCreateFirstAnalysis: () {
            createCount += 1;
          },
        ),
      ),
    );

    expect(
      find.text('Nenhuma analise ainda. Que tal comecar agora?'),
      findsOneWidget,
    );
    expect(find.text('Iniciar primeira analise'), findsOneWidget);

    await tester.tap(find.text('Iniciar primeira analise'));
    await tester.pump();

    expect(createCount, 1);
  });

  testWidgets('renderiza conteudo com item e dispara onLoadMore ao rolar', (
    WidgetTester tester,
  ) async {
    int loadMoreCount = 0;
    final List<AnalysisDto> analyses = List<AnalysisDto>.generate(
      20,
      (int index) => AnalysisDtoFaker.fake(
        id: 'analysis-$index',
        name: 'Analise $index',
        createdAt: '2026-03-31T10:00:00Z',
      ),
    );

    await tester.pumpWidget(
      _createWidget(
        RecentAnalysesSectionView(
          analyses: analyses,
          isLoading: false,
          isLoadingMore: false,
          hasMore: true,
          showEmptyState: false,
          errorMessage: null,
          formatCreatedAt: (_) => '31/03/2026',
          onRefresh: () async {},
          onTapAnalysis: (_) async {},
          onRetry: () {},
          onLoadMore: () async {
            loadMoreCount += 1;
          },
          onCreateFirstAnalysis: () {},
        ),
      ),
    );

    expect(find.text('Analise 0'), findsOneWidget);
    expect(find.text('31/03/2026'), findsWidgets);

    final BuildContext listContext = tester.element(
      find.byType(ListView).first,
    );
    ScrollEndNotification(
      metrics: FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 1000,
        pixels: 950,
        viewportDimension: 400,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      ),
      context: listContext,
    ).dispatch(listContext);
    await tester.pump();

    expect(loadMoreCount, greaterThan(0));
  });

  testWidgets(
    'separa analises em andamento e concluidas com labels esperadas',
    (WidgetTester tester) async {
      final List<AnalysisDto> analyses = <AnalysisDto>[
        AnalysisDtoFaker.fake(
          id: 'processing-1',
          name: 'Analise em andamento',
          status: AnalysisStatusDto.generatingJudgmentDraft,
        ),
        AnalysisDtoFaker.fake(
          id: 'processing-2',
          name: 'Analise extraindo peticao',
          status: AnalysisStatusDto.extractingPetition,
        ),
        AnalysisDtoFaker.fake(
          id: 'done-1',
          name: 'Analise concluida',
          status: AnalysisStatusDto.precedentChosen,
        ),
      ];

      await tester.pumpWidget(
        _createWidget(
          RecentAnalysesSectionView(
            analyses: analyses,
            isLoading: false,
            isLoadingMore: false,
            hasMore: false,
            showEmptyState: false,
            errorMessage: null,
            formatCreatedAt: (_) => '31/03/2026',
            onRefresh: () async {},
            onTapAnalysis: (_) async {},
            onRetry: () {},
            onLoadMore: () async {},
            onCreateFirstAnalysis: () {},
          ),
        ),
      );

      expect(find.text('Em andamento'), findsOneWidget);
      expect(find.text('Recentes'), findsOneWidget);
      expect(find.text('Gerando minuta do julgamento'), findsOneWidget);
      expect(find.text('Extraindo petição'), findsOneWidget);
      expect(find.text('Concluída'), findsOneWidget);
    },
  );
}

Widget _createWidget(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: SizedBox(height: 420, child: child)),
  );
}
