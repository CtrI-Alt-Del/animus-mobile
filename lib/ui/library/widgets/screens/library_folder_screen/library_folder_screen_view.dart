import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/archive_selected_analyses_dialog/index.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/folder_analysis_list/index.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/folder_available_analysis_picker/index.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/folder_empty_state/index.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/folder_error_state/index.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/folder_loading_state/index.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/folder_selection_action_bar/index.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/folder_settings_modal/index.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/library_folder_background/index.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/library_folder_header/index.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/library_folder_screen_presenter.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/move_analyses_modal/index.dart';

class LibraryFolderScreenView extends ConsumerWidget {
  final String folderId;

  const LibraryFolderScreenView({required this.folderId, super.key});

  Future<void> _showMoveAnalysesModal(
    BuildContext context,
    LibraryFolderScreenPresenter presenter,
  ) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return MoveAnalysesModal(
          currentFolderId: folderId,
          selectedCount: presenter.selectedCount.value,
          onMove: presenter.moveSelectedAnalyses,
        );
      },
    );
  }

  Future<void> _showArchiveDialog(
    BuildContext context,
    LibraryFolderScreenPresenter presenter,
  ) async {
    final bool shouldArchive =
        await showDialog<bool>(
          context: context,
          barrierColor: (Theme.of(context).extension<AppThemeTokens>()?.scrim ?? AppTheme.tokens.scrim),
          builder: (_) => ArchiveSelectedAnalysesDialog(
            selectedCount: presenter.selectedCount.value,
          ),
        ) ??
        false;

    if (!shouldArchive) {
      return;
    }

    final bool archived = await presenter.archiveSelectedAnalyses();
    if (!context.mounted) {
      return;
    }

    if (!archived) {
      _showFeedback(context, presenter.generalError.value);
    }
  }

  Future<void> _showFolderSettingsModal(
    BuildContext context,
    FolderDto folder,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return FolderSettingsModal(folderId: folderId, folder: folder);
      },
    );
  }

  void _showFeedback(BuildContext context, String? message) {
    if (message == null || message.trim().isEmpty) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    final LibraryFolderScreenPresenter presenter = ref.watch(
      libraryFolderScreenPresenterProvider(folderId),
    );
    ref.watch(libraryFolderScreenInitializationProvider(folderId));

    final bool isLoading = presenter.isLoading.watch(context);
    final FolderDto? folder = presenter.folder.watch(context);
    final List<AnalysisDto> analyses = presenter.analyses.watch(context);
    final List<AnalysisDto> availableAnalyses = presenter.availableAnalyses
        .watch(context);
    final Set<String> selectedAvailableAnalysisIds = presenter
        .selectedAvailableAnalysisIds
        .watch(context);
    final bool hasSelection = presenter.hasSelection.watch(context);
    final int selectedCount = presenter.selectedCount.watch(context);
    final bool isOperating = presenter.isOperating.watch(context);
    final bool isLoadingAvailableAnalyses = presenter.isLoadingAvailableAnalyses
        .watch(context);
    final bool isAddingAvailableAnalyses = presenter.isAddingAvailableAnalyses
        .watch(context);
    final String? generalError = presenter.generalError.watch(context);
    final bool showAvailableAnalysisPicker = presenter
        .showAvailableAnalysisPicker
        .watch(context);
    final bool showEmptyState = presenter.showEmptyState.watch(context);

    return Scaffold(
      backgroundColor: tokens.surfacePage,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 402),
            child: Stack(
              children: <Widget>[
                Positioned.fill(child: LibraryFolderBackground(tokens: tokens)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: LibraryFolderHeader(
                        title: folder?.name ?? 'Pasta',
                        analysisCount: folder?.analysisCount ?? analyses.length,
                        onBack: presenter.goBack,
                        onSettings: () {
                          if (folder == null) {
                            return;
                          }

                          unawaited(_showFolderSettingsModal(context, folder));
                        },
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Builder(
                          builder: (BuildContext context) {
                            if (isLoading &&
                                folder == null &&
                                analyses.isEmpty) {
                              return const FolderLoadingState();
                            }

                            if (generalError != null &&
                                folder == null &&
                                analyses.isEmpty) {
                              return FolderErrorState(
                                message: generalError,
                                onRetry: presenter.refresh,
                              );
                            }

                            if (generalError != null && analyses.isEmpty) {
                              return FolderErrorState(
                                message: generalError,
                                onRetry: presenter
                                    .loadAvailableAnalysesForEmptyFolder,
                              );
                            }

                            if (showAvailableAnalysisPicker) {
                              return FolderAvailableAnalysisPicker(
                                availableAnalyses: availableAnalyses,
                                selectedAnalysisIds:
                                    selectedAvailableAnalysisIds,
                                isLoading: isLoadingAvailableAnalyses,
                                isAdding: isAddingAvailableAnalyses,
                                onToggleSelection:
                                    presenter.toggleAvailableAnalysisSelection,
                                onConfirm:
                                    presenter.addSelectedAvailableAnalyses,
                                onRetry: presenter
                                    .loadAvailableAnalysesForEmptyFolder,
                              );
                            }

                            if (showEmptyState) {
                              return FolderEmptyState(
                                folderName: folder?.name ?? 'esta pasta',
                                onRefresh: presenter.refresh,
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                if (generalError != null) ...<Widget>[
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: tokens.danger.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: tokens.danger.withValues(
                                          alpha: 0.28,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      generalError,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: tokens.textPrimary,
                                            height: 1.4,
                                          ),
                                    ),
                                  ),
                                ],
                                Expanded(
                                  child: FolderAnalysisList(
                                    analyses: analyses,
                                    selectedIds:
                                        presenter.selectedAnalysisIds.value,
                                    isLoadingMore: presenter.isLoadingMore
                                        .watch(context),
                                    hasMore: presenter.hasMore.watch(context),
                                    formatCreatedAt: presenter.formatCreatedAt,
                                    onRefresh: presenter.refresh,
                                    onLoadMore: presenter.loadNextPage,
                                    onTapAnalysis: presenter.openAnalysis,
                                    onToggleSelection:
                                        presenter.toggleSelection,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasSelection)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 16,
                    child: FolderSelectionActionBar(
                      selectedCount: selectedCount,
                      isOperating: isOperating,
                      onMove: () {
                        unawaited(_showMoveAnalysesModal(context, presenter));
                      },
                      onArchive: () {
                        unawaited(_showArchiveDialog(context, presenter));
                      },
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
