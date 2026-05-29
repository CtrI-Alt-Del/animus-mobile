import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/theme.dart';

import 'folder_destination_picker_presenter.dart';

class FolderDestinationPickerView extends ConsumerWidget {
  final String currentFolderId;
  final bool showUnfolderedDestination;
  final Future<void> Function(String? folderId) onSelected;

  const FolderDestinationPickerView({
    required this.currentFolderId,
    required this.onSelected,
    this.showUnfolderedDestination = true,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FolderDestinationPickerPresenter presenter = ref.watch(
      folderDestinationPickerPresenterProvider(currentFolderId),
    );
    Future<void>.microtask(presenter.load);

    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: tokens.borderSubtle)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Mover para',
                style: textTheme.titleSmall?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Escolha uma pasta de destino para as análises selecionadas.',
                style: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
              ),
              const SizedBox(height: 16),
              if (showUnfolderedDestination) ...<Widget>[
                _DestinationTile(
                  icon: Icons.inbox_outlined,
                  title: 'Sem pasta',
                  subtitle: 'Remover organização das análises',
                  onTap: () => _select(context, null),
                ),
                const SizedBox(height: 12),
              ],
              Flexible(
                child: Watch((BuildContext context) {
                  final bool isLoading = presenter.isLoading.watch(context);
                  final String? errorMessage = presenter.errorMessage.watch(
                    context,
                  );
                  final List<FolderDto> folders = presenter.folders.watch(
                    context,
                  );

                  if (isLoading) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            tokens.accent,
                          ),
                        ),
                      ),
                    );
                  }

                  if (errorMessage != null) {
                    return _DestinationError(
                      message: errorMessage,
                      onRetry: presenter.retry,
                    );
                  }

                  if (folders.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Nenhuma outra pasta disponível.',
                          style: textTheme.bodySmall?.copyWith(
                            color: tokens.textMuted,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: folders.length,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int index) {
                      final FolderDto folder = folders[index];
                      final String folderId = (folder.id ?? '').trim();

                      return _DestinationTile(
                        icon: Icons.folder_outlined,
                        title: folder.name,
                        subtitle: '${folder.analysisCount} análises',
                        onTap: () => _select(context, folderId),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _select(BuildContext context, String? folderId) {
    Navigator.of(context).pop();
    unawaited(onSelected(folderId));
  }
}

class _DestinationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DestinationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: tokens.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title.trim().isEmpty ? 'Pasta sem nome' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.chevron_right, color: tokens.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinationError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _DestinationError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => unawaited(onRetry()),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
