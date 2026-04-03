import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/create_analysis_fab/index.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/home_background_decorations/index.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/home_header/index.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/index.dart';

import 'home_screen_presenter.dart';

class HomeScreenView extends ConsumerWidget {
  const HomeScreenView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(homeScreenInitializationProvider);

    final HomeScreenPresenter presenter = ref.watch(
      homeScreenPresenterProvider,
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return Scaffold(
      backgroundColor: tokens.surfacePage,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Watch((BuildContext context) {
        final bool isLoadingInitialData = presenter.isLoadingInitialData.watch(
          context,
        );
        final bool isCreatingAnalysis = presenter.isCreatingAnalysis.watch(
          context,
        );

        return CreateAnalysisFab(
          isLoading: isCreatingAnalysis,
          onPressed: isLoadingInitialData ? null : presenter.createAnalysis,
        );
      }),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: IgnorePointer(
                    child: HomeBackgroundDecorations(tokens: tokens),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Watch((BuildContext context) {
                        final String greeting = presenter.greeting.watch(
                          context,
                        );
                        return HomeHeader(
                          greeting: greeting,
                          subtitle: 'Seu resumo juridico de hoje',
                          onProfilePressed: presenter.openProfile,
                        );
                      }),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Watch((BuildContext context) {
                          final List<AnalysisDto> analyses = presenter
                              .recentAnalyses
                              .watch(context);
                          final bool isLoadingInitialData = presenter
                              .isLoadingInitialData
                              .watch(context);
                          final bool isLoadingMore = presenter.isLoadingMore
                              .watch(context);
                          final bool showEmptyState = presenter.showEmptyState
                              .watch(context);
                          final String? errorMessage = presenter.generalError
                              .watch(context);

                          return RecentAnalysesSection(
                            analyses: analyses,
                            isLoading: isLoadingInitialData,
                            isLoadingMore: isLoadingMore,
                            showEmptyState: showEmptyState,
                            errorMessage: errorMessage,
                            formatCreatedAt: presenter.formatCreatedAt,
                            onRefresh: presenter.refresh,
                            onTapAnalysis: presenter.openAnalysis,
                            onRetry: () {
                              presenter.initialize();
                            },
                            onLoadMore: () {
                              presenter.loadNextPage();
                            },
                            onCreateFirstAnalysis: () {
                              presenter.createAnalysis();
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
