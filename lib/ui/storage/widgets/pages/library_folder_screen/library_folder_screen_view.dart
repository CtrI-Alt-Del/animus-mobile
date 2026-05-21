import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/storage/widgets/pages/library_folder_screen/folder_available_analysis_picker/index.dart';
import 'package:animus/ui/storage/widgets/pages/library_folder_screen/folder_destination_picker/index.dart';
import 'package:animus/ui/storage/widgets/pages/library_folder_screen/library_folder_action_bar/index.dart';
import 'package:animus/ui/storage/widgets/pages/library_folder_screen/library_folder_analysis_list/index.dart';
import 'package:animus/ui/storage/widgets/pages/library_folder_screen/library_folder_empty_state/index.dart';
import 'package:animus/ui/storage/widgets/pages/library_folder_screen/library_folder_error_state/index.dart';
import 'package:animus/ui/storage/widgets/pages/library_folder_screen/library_folder_header/index.dart';
import 'package:animus/ui/storage/widgets/pages/library_folder_screen/library_folder_settings_modal/index.dart';

import 'library_folder_screen_presenter.dart';

class LibraryFolderScreenView extends ConsumerWidget {
  final String folderId;

  const LibraryFolderScreenView({required this.folderId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(libraryFolderScreenInitializationProvider(folderId));

    final LibraryFolderScreenPresenter presenter = ref.watch(
      libraryFolderScreenPresenterProvider(folderId),
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
                  final FolderDto? folder = presenter.folder.watch(context);
                  final List<AnalysisDto> analyses = presenter.analyses.watch(
                    context,
                  );
                  final int count = folder?.analysisCount ?? analyses.length;

                  return LibraryFolderHeader(
                    title: folder?.name ?? 'Pasta',
                    count: count,
                    onBackPressed: presenter.goBack,
                    onSettingsPressed: folder == null
                        ? () {}
                        : () {
                            _showSettingsModal(context, presenter, folder);
                          },
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
                    final List<AnalysisDto> availableAnalyses = presenter
                        .availableAnalyses
                        .watch(context);
                    final Set<String> selectedAnalysisIds = presenter
                        .selectedAnalysisIds
                        .watch(context);
                    final Set<String> selectedAvailableIds = presenter
                        .selectedAvailableAnalysisIds
                        .watch(context);
                    final bool isLoadingMore = presenter.isLoadingMore.watch(
                      context,
                    );
                    final bool hasMore = presenter.hasMore.watch(context);
                    final bool showAvailablePicker = presenter
                        .showAvailableAnalysisPicker
                        .watch(context);
                    final bool showEmptyState = presenter.showEmptyState.watch(
                      context,
                    );
                    final bool isLoadingAvailable = presenter
                        .isLoadingAvailableAnalyses
                        .watch(context);
                    final bool isAddingAvailable = presenter
                        .isAddingAvailableAnalyses
                        .watch(context);

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

                    if (showAvailablePicker) {
                      return FolderAvailableAnalysisPicker(
                        availableAnalyses: availableAnalyses,
                        selectedAnalysisIds: selectedAvailableIds,
                        isLoading: isLoadingAvailable,
                        isAdding: isAddingAvailable,
                        onToggleSelection:
                            presenter.toggleAvailableAnalysisSelection,
                        onConfirm: presenter.addSelectedAvailableAnalyses,
                        onRetry: presenter.loadAvailableAnalysesForEmptyFolder,
                      );
                    }

                    if (showEmptyState) {
                      return const LibraryFolderEmptyState();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _FolderArchiveNotice(tokens: tokens),
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

  void _showSettingsModal(
    BuildContext context,
    LibraryFolderScreenPresenter presenter,
    FolderDto folder,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return LibraryFolderSettingsModal(
          folder: folder,
          onRename: presenter.renameFolder,
          onArchive: presenter.archiveFolder,
        );
      },
    );
  }

  void _showDestinationPicker(
    BuildContext context,
    LibraryFolderScreenPresenter presenter,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return FolderDestinationPicker(
          currentFolderId: folderId,
          onSelected: presenter.moveSelectedAnalyses,
        );
      },
    );
  }

  Future<void> _confirmArchiveSelected(
    BuildContext context,
    LibraryFolderScreenPresenter presenter,
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
            'Arquivar análises',
            style: textTheme.titleSmall?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'As análises selecionadas serão arquivadas e removidas desta pasta.',
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

class _FolderArchiveNotice extends StatelessWidget {
  final AppThemeTokens tokens;

  const _FolderArchiveNotice({required this.tokens});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.danger.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.danger.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.warning_amber_outlined, color: tokens.danger, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ao arquivar esta pasta, as análises serão movidas para Sem pasta.',
                style: textTheme.bodySmall?.copyWith(
                  color: tokens.textMuted,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
