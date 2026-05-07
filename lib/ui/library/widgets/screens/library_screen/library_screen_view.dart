import 'dart:async';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/archive_selected_analyses_dialog/index.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/folder_analysis_card/index.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/folder_selection_action_bar/index.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/move_analyses_modal/index.dart';
import 'package:animus/ui/library/widgets/screens/library_screen/create_folder_modal/index.dart';
import 'package:animus/ui/library/widgets/screens/library_screen/empty_state/index.dart';
import 'package:animus/ui/library/widgets/screens/library_screen/folder_grid_card/index.dart';
import 'package:animus/ui/library/widgets/screens/library_screen/inline_operation_error/index.dart';
import 'package:animus/ui/library/widgets/screens/library_screen/library_screen_presenter.dart';
import 'package:animus/ui/library/widgets/screens/library_screen/library_tabs/index.dart';
import 'package:animus/ui/library/widgets/screens/library_screen/new_folder_button/index.dart';
import 'package:animus/ui/library/widgets/screens/library_screen/section_header/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

class LibraryScreenView extends ConsumerWidget {
  const LibraryScreenView({super.key});

  void _showCreateFolderModal(
    BuildContext context,
    LibraryScreenPresenter presenter,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CreateFolderModal(
          onCreate: (name) => presenter.createFolder(name),
        );
      },
    );
  }

  Future<void> _showMoveAnalysesModal(
    BuildContext context,
    LibraryScreenPresenter presenter,
  ) async {
    final bool moved =
        await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) {
            return MoveAnalysesModal(
              currentFolderId: '',
              selectedCount: presenter.selectedUnfolderedCount.value,
              showUnfolderedDestination: false,
              onMove: presenter.moveSelectedUnfolderedAnalyses,
            );
          },
        ) ??
        false;

    if (!context.mounted || moved) {
      return;
    }

    _showFeedback(context, presenter.operationError.value);
  }

  Future<void> _showArchiveDialog(
    BuildContext context,
    LibraryScreenPresenter presenter,
  ) async {
    final bool shouldArchive =
        await showDialog<bool>(
          context: context,
          barrierColor: const Color(0x99000000),
          builder: (_) => ArchiveSelectedAnalysesDialog(
            selectedCount: presenter.selectedUnfolderedCount.value,
          ),
        ) ??
        false;

    if (!shouldArchive) {
      return;
    }

    final bool archived = await presenter.archiveSelectedUnfolderedAnalyses();
    if (!context.mounted || archived) {
      return;
    }

    _showFeedback(context, presenter.operationError.value);
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
    final TextTheme textTheme = Theme.of(context).textTheme;

    final LibraryScreenPresenter presenter = ref.watch(
      libraryScreenPresenterProvider,
    );
    ref.watch(libraryScreenInitializationProvider);

    final bool isLoading = presenter.isLoading.watch(context);
    final bool hasError = presenter.hasError.watch(context);
    final bool hasUnfolderedSelection = presenter.hasUnfolderedSelection.watch(
      context,
    );
    final int selectedUnfolderedCount = presenter.selectedUnfolderedCount.watch(
      context,
    );
    final bool isOperatingOnUnfolderedAnalyses = presenter
        .isOperatingOnUnfolderedAnalyses
        .watch(context);

    return Scaffold(
      backgroundColor: tokens.surfacePage,
      appBar: AppBar(
        title: const Text('Biblioteca'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: NewFolderButton(
              onTap: () => _showCreateFolderModal(context, presenter),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: <Widget>[
            Builder(
              builder: (context) {
                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: tokens.danger,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Não foi possível carregar sua biblioteca.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              color: tokens.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: presenter.retry,
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final List<FolderDto> folders = presenter.folders.watch(
                  context,
                );
                final List<AnalysisDto> unfolderedAnalyses = presenter
                    .unfolderedAnalyses
                    .watch(context);
                final int selectedTab = presenter.selectedTabIndex.watch(
                  context,
                );
                final String? operationError = presenter.operationError.watch(
                  context,
                );
                final Set<String> selectedUnfolderedAnalysisIds = presenter
                    .selectedUnfolderedAnalysisIds
                    .watch(context);

                if (folders.isEmpty && unfolderedAnalyses.isEmpty) {
                  return EmptyState(
                    onCreateFolder: () =>
                        _showCreateFolderModal(context, presenter),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                  children: <Widget>[
                    LibraryTabs(
                      selectedIndex: selectedTab,
                      onSelected: presenter.selectTab,
                    ),
                    if (operationError != null) ...<Widget>[
                      const SizedBox(height: 16),
                      InlineOperationError(message: operationError),
                    ],
                    const SizedBox(height: 24),
                    if (selectedTab == 0 &&
                        unfolderedAnalyses.isNotEmpty) ...<Widget>[
                      SectionHeader(label: 'Sem pasta'),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: ListView.separated(
                          primary: false,
                          shrinkWrap: true,
                          itemCount: unfolderedAnalyses.length,
                          separatorBuilder: (context, index) {
                            return const SizedBox(height: 12);
                          },
                          itemBuilder: (context, index) {
                            final AnalysisDto analysis =
                                unfolderedAnalyses[index];
                            final String analysisId = (analysis.id ?? '')
                                .trim();

                            return FolderAnalysisCard(
                              analysis: analysis,
                              dateLabel: presenter.formatRelativeDate(
                                analysis.createdAt,
                              ),
                              isSelected: selectedUnfolderedAnalysisIds
                                  .contains(analysisId),
                              onTap: () {
                                unawaited(presenter.openAnalysis(analysis));
                              },
                              onToggleSelection: () {
                                presenter.toggleUnfolderedSelection(analysisId);
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                    SectionHeader(label: 'Pastas'),
                    const SizedBox(height: 12),
                    if (folders.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Nenhuma pasta criada ainda.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: tokens.textMuted,
                            ),
                          ),
                        ),
                      )
                    else
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.45,
                        children: folders.map((FolderDto folder) {
                          return FolderGridCard(
                            folder: folder,
                            onTap: () {
                              if (folder.id != null) {
                                presenter.openFolder(folder.id!);
                              }
                            },
                          );
                        }).toList(),
                      ),
                  ],
                );
              },
            ),
            if (hasUnfolderedSelection)
              Positioned(
                left: 20,
                right: 20,
                bottom: 16,
                child: FolderSelectionActionBar(
                  selectedCount: selectedUnfolderedCount,
                  isOperating: isOperatingOnUnfolderedAnalyses,
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
    );
  }
}
