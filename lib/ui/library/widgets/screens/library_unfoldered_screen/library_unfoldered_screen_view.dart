import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/storage/widgets/pages/library_folder_screen/folder_destination_picker/index.dart';
import 'package:animus/ui/storage/widgets/pages/library_folder_screen/library_folder_action_bar/index.dart';
import 'package:animus/ui/storage/widgets/pages/library_folder_screen/library_folder_analysis_list/index.dart';
import 'package:animus/ui/storage/widgets/pages/library_folder_screen/library_folder_empty_state/index.dart';
import 'package:animus/ui/storage/widgets/pages/library_folder_screen/library_folder_error_state/index.dart';
import 'package:animus/ui/storage/widgets/pages/library_folder_screen/library_folder_header/index.dart';

import 'library_unfoldered_screen_presenter.dart';

class LibraryUnfolderedScreenView extends ConsumerWidget {
  const LibraryUnfolderedScreenView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(libraryUnfolderedScreenInitializationProvider);

    final LibraryUnfolderedScreenPresenter presenter = ref.watch(
      libraryUnfolderedScreenPresenterProvider,
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return Scaffold(
      backgroundColor: tokens.surfacePage,
      bottomNavigationBar: Watch((BuildContext context) {
        final bool hasSelection = presenter.hasSelection.watch(context);
        if (!hasSelection) {
          return const SizedBox.shrink();
        }

        final int selectedCount = presenter.selectedCount.watch(context);
        final bool isMoving = presenter.isMovingAnalyses.watch(context);
        final bool isArchiving = presenter.isArchivingAnalyses.watch(context);

        return LibraryFolderActionBar(
          selectedCount: selectedCount,
          isMoving: isMoving,
          isArchiving: isArchiving,
          onMovePressed: () {
            _showDestinationPicker(context, presenter);
          },
          onArchivePressed: () {
            unawaited(_confirmArchiveSelected(context, presenter));
          },
        );
      }),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Watch((BuildContext context) {
                  final List<AnalysisDto> analyses = presenter.analyses.watch(
                    context,
                  );

                  return LibraryFolderHeader(
                    title: 'Sem pasta',
                    count: analyses.length,
                    showSettings: false,
                    onBackPressed: presenter.goBack,
                    onSettingsPressed: () {},
                  );
                }),
                Expanded(
                  child: Watch((BuildContext context) {
                    final bool isLoading = presenter.isLoadingInitialData.watch(
                      context,
                    );
                    final String? generalError = presenter.generalError.watch(
                      context,
                    );
                    final List<AnalysisDto> analyses = presenter.analyses.watch(
                      context,
                    );
                    final Set<String> selectedAnalysisIds = presenter
                        .selectedAnalysisIds
                        .watch(context);
                    final bool isLoadingMore = presenter.isLoadingMore.watch(
                      context,
                    );
                    final bool hasMore = presenter.hasMore.watch(context);

                    if (isLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            tokens.accent,
                          ),
                        ),
                      );
                    }

                    if (generalError != null && analyses.isEmpty) {
                      return LibraryFolderErrorState(
                        message: generalError,
                        onRetry: presenter.load,
                      );
                    }

                    if (analyses.isEmpty) {
                      return const LibraryFolderEmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'Nenhuma analise sem pasta',
                        description:
                            'Todas as suas analises ja estao organizadas em pastas.',
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (generalError != null) ...<Widget>[
                          _InlineError(message: generalError),
                          const SizedBox(height: 12),
                        ],
                        Expanded(
                          child: LibraryFolderAnalysisList(
                            analyses: analyses,
                            selectedAnalysisIds: selectedAnalysisIds,
                            isLoadingMore: isLoadingMore,
                            hasMore: hasMore,
                            formatCreatedAt: presenter.formatCreatedAt,
                            onTapAnalysis: presenter.openAnalysis,
                            onToggleSelection: presenter.toggleSelection,
                            onLoadMore: presenter.loadNextPage,
                            onRefresh: presenter.refresh,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDestinationPicker(
    BuildContext context,
    LibraryUnfolderedScreenPresenter presenter,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return FolderDestinationPicker(
          currentFolderId: '',
          showUnfolderedDestination: false,
          onSelected: presenter.moveSelectedAnalyses,
        );
      },
    );
  }

  Future<void> _confirmArchiveSelected(
    BuildContext context,
    LibraryUnfolderedScreenPresenter presenter,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final AppThemeTokens tokens =
            Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
        final TextTheme textTheme = Theme.of(context).textTheme;

        return AlertDialog(
          backgroundColor: tokens.surfaceElevated,
          title: Text(
            'Arquivar analises',
            style: textTheme.titleSmall?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'As analises selecionadas serao arquivadas e removidas de Sem pasta.',
            style: textTheme.bodySmall?.copyWith(
              color: tokens.textMuted,
              height: 1.35,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: tokens.surfacePage,
              ),
              child: const Text('Arquivar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await presenter.archiveSelectedAnalyses();
    }
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.danger.withValues(alpha: 0.18)),
        ),
        child: Text(
          message,
          style: textTheme.bodySmall?.copyWith(color: tokens.danger),
        ),
      ),
    );
  }
}
