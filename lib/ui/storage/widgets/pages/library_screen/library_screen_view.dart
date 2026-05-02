import 'package:animus/theme.dart';
import 'package:animus/ui/storage/widgets/pages/library_screen/components/folder_list_item.dart';
import 'package:animus/ui/storage/widgets/pages/library_screen/create_folder_modal/create_folder_modal_view.dart';
import 'package:animus/ui/storage/widgets/pages/library_screen/library_screen_presenter.dart';
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
        return CreateFolderModalView(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => _showCreateFolderModal(context, presenter),
            tooltip: 'Nova pasta',
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
                    children: [
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

            final folders = presenter.folders.watch(context);
            final unfolderedCount = presenter.unfolderedCount.watch(context);

            if (folders.isEmpty && unfolderedCount == 0) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                        style: textTheme.bodyMedium?.copyWith(
                          color: tokens.textMuted,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _showCreateFolderModal(context, presenter),
                        icon: const Icon(Icons.add),
                        label: const Text('Criar primeira pasta'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildUnfolderedCard(
                  context,
                  tokens,
                  textTheme,
                  unfolderedCount,
                  presenter,
                ),
                const SizedBox(height: 32),
                Text(
                  'Pastas',
                  style: textTheme.titleMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
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
                  ...folders.map(
                    (f) => FolderListItem(
                      folder: f,
                      onTap: () {
                        if (f.id != null) {
                          presenter.openFolder(f.id!);
                        }
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUnfolderedCard(
    BuildContext context,
    AppThemeTokens tokens,
    TextTheme textTheme,
    int unfolderedCount,
    LibraryScreenPresenter presenter,
  ) {
    return Card(
      child: InkWell(
        onTap: () {
          presenter.openUnfoldered();
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.inbox_outlined, color: tokens.textPrimary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sem pasta',
                      style: textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$unfolderedCount análises não organizadas',
                      style: textTheme.bodyMedium?.copyWith(
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: tokens.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
