import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_empty_state/index.dart';
import 'package:animus/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_error_state/index.dart';
import 'package:animus/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_list/index.dart';
import 'package:animus/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_loading_state/index.dart';
import 'package:animus/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_search_bar/index.dart';

import 'archived_analyses_screen_presenter.dart';

class ArchivedAnalysesScreenView extends ConsumerWidget {
  const ArchivedAnalysesScreenView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(archivedAnalysesScreenInitializationProvider);

    final ArchivedAnalysesScreenPresenter presenter = ref.watch(
      archivedAnalysesScreenPresenterProvider,
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: tokens.surfacePage,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    height: 52,
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: presenter.goBack,
                          icon: Icon(
                            Icons.arrow_back,
                            color: tokens.textPrimary,
                            size: 22,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Análises arquivadas',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ArchivedAnalysesSearchBar(
                    initialQuery: presenter.searchQuery.value,
                    onQueryChanged: presenter.updateSearchQuery,
                    onClear: presenter.clearSearch,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Watch((BuildContext context) {
                      final bool isLoading = presenter.isLoadingInitialData
                          .watch(context);
                      final bool isLoadingMore = presenter.isLoadingMore.watch(
                        context,
                      );
                      final bool hasMore = presenter.hasMore.watch(context);
                      final String? generalError = presenter.generalError.watch(
                        context,
                      );
                      final String? paginationError = presenter.paginationError
                          .watch(context);
                      final String? unarchivingId = presenter.unarchivingId
                          .watch(context);
                      final List<AnalysisDto> analyses = presenter
                          .archivedAnalyses
                          .watch(context);
                      final bool showEmpty = presenter.showEmptyState.watch(
                        context,
                      );
                      final bool showSearchEmpty = presenter
                          .showSearchEmptyState
                          .watch(context);
                      final String searchQuery = presenter.searchQuery.watch(
                        context,
                      );

                      if (isLoading && analyses.isEmpty) {
                        return const ArchivedAnalysesLoadingState();
                      }

                      if (generalError != null && analyses.isEmpty) {
                        return ArchivedAnalysesErrorState(
                          message: generalError,
                          onRetry: presenter.refresh,
                        );
                      }

                      if (showEmpty) {
                        return const ArchivedAnalysesEmptyState(
                          message: 'Você ainda não tem análises arquivadas.',
                        );
                      }

                      if (showSearchEmpty) {
                        return ArchivedAnalysesEmptyState(
                          icon: Icons.search_off,
                          message:
                              'Nenhuma análise encontrada para "${searchQuery.trim()}".',
                        );
                      }

                      return ArchivedAnalysesList(
                        analyses: analyses,
                        isLoading: isLoading,
                        isLoadingMore: isLoadingMore,
                        hasMore: hasMore,
                        errorMessage: paginationError,
                        unarchivingId: unarchivingId,
                        formatCreatedAt: presenter.formatCreatedAt,
                        onLoadMore: presenter.loadNextPage,
                        onTapAnalysis: presenter.openAnalysis,
                        onUnarchive: (AnalysisDto analysis) async {
                          final bool succeeded = await presenter.unarchive(
                            analysis,
                          );
                          if (!context.mounted) {
                            return;
                          }

                          final ScaffoldMessengerState messenger =
                              ScaffoldMessenger.of(context);
                          messenger.clearSnackBars();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                succeeded
                                    ? 'Análise desarquivada com sucesso.'
                                    : 'Não foi possível desarquivar a análise agora. Tente novamente.',
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
