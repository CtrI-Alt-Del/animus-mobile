import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/storage/widgets/pages/library_screen/create_folder_modal/index.dart';
import 'package:animus/ui/storage/widgets/pages/library_screen/folder_grid_card/index.dart';
import 'package:animus/ui/storage/widgets/pages/library_screen/library_screen_presenter.dart';
import 'package:animus/ui/storage/widgets/pages/library_screen/library_tabs/index.dart';
import 'package:animus/ui/storage/widgets/pages/library_screen/new_folder_button/index.dart';
import 'package:animus/ui/storage/widgets/pages/library_screen/unfoldered_analysis_tile/index.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final presenter = ref.watch(libraryScreenPresenterProvider);
    ref.watch(libraryScreenInitializationProvider);

    final isLoading = presenter.isLoading.watch(context);
    final hasError = presenter.hasError.watch(context);

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
        child: Builder(
          builder: (context) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.error_outline, size: 48, color: tokens.danger),
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

            final List<FolderDto> folders = presenter.folders.watch(context);
            final List<AnalysisDto> unfolderedAnalyses = presenter
                .unfolderedAnalyses
                .watch(context);
            final int selectedTab = presenter.selectedTabIndex.watch(context);

            if (folders.isEmpty && unfolderedAnalyses.isEmpty) {
              return _EmptyState(
                onCreateFolder: () => _showCreateFolderModal(context, presenter),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: <Widget>[
                LibraryTabs(
                  selectedIndex: selectedTab,
                  onSelected: presenter.selectTab,
                ),
                const SizedBox(height: 24),
                if (selectedTab == 0 && unfolderedAnalyses.isNotEmpty) ...<Widget>[
                  _SectionHeader(label: 'Sem pasta'),
                  const SizedBox(height: 12),
                  ...List<Widget>.generate(unfolderedAnalyses.length, (
                    int index,
                  ) {
                    final AnalysisDto analysis = unfolderedAnalyses[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == unfolderedAnalyses.length - 1
                            ? 0
                            : 12,
                      ),
                      child: UnfoldedAnalysisTile(
                        title: analysis.name,
                        relativeDateLabel: presenter.formatRelativeDate(
                          analysis.createdAt,
                        ),
                        onTap: () => presenter.openAnalysis(analysis),
                      ),
                    );
                  }),
                  const SizedBox(height: 28),
                ],
                _SectionHeader(label: 'Pastas'),
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
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Text(
      label,
      style: textTheme.titleSmall?.copyWith(
        color: tokens.accent,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateFolder;

  const _EmptyState({required this.onCreateFolder});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.folder_off_outlined,
              size: 64,
              color: tokens.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Sua biblioteca está vazia',
              style: textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crie uma pasta para organizar suas análises.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: tokens.textMuted),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onCreateFolder,
              icon: const Icon(Icons.add),
              label: const Text('Criar primeira pasta'),
            ),
          ],
        ),
      ),
    );
  }
}
