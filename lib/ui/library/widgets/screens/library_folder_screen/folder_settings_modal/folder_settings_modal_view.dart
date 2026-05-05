import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/folder_settings_modal/folder_settings_modal_presenter.dart';

class FolderSettingsModalView extends ConsumerStatefulWidget {
  final String folderId;
  final FolderDto folder;

  const FolderSettingsModalView({
    required this.folderId,
    required this.folder,
    super.key,
  });

  @override
  ConsumerState<FolderSettingsModalView> createState() =>
      _FolderSettingsModalViewState();
}

class _FolderSettingsModalViewState
    extends ConsumerState<FolderSettingsModalView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.folder.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRename(FolderSettingsModalPresenter presenter) async {
    final bool renamed = await presenter.submitRename();
    if (!mounted || !renamed) {
      return;
    }

    Navigator.of(context).pop();
  }

  Future<void> _handleArchive(FolderSettingsModalPresenter presenter) async {
    final bool archived = await presenter.submitArchiveFolder();
    if (!mounted || !archived) {
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final FolderSettingsModalPresenter presenter = ref.watch(
      folderSettingsModalPresenterProvider((
        folderId: widget.folderId,
        initialName: widget.folder.name,
      )),
    );

    final bool isSavingName = presenter.isSavingName.watch(context);
    final bool isArchivingFolder = presenter.isArchivingFolder.watch(context);
    final String? nameError = presenter.nameError.watch(context);
    final String? generalError = presenter.generalError.watch(context);
    final bool canSaveName = presenter.canSaveName.watch(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surfacePage,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Configuracoes da pasta',
                style: textTheme.titleMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                autofocus: true,
                enabled: !isSavingName && !isArchivingFolder,
                onChanged: presenter.setName,
                style: textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Nome da pasta',
                  hintText: 'Ex: Trabalhista',
                  errorText: nameError,
                ),
              ),
              const SizedBox(height: 16),
              if (generalError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    generalError,
                    style: textTheme.bodySmall?.copyWith(color: tokens.danger),
                  ),
                ),
              FilledButton(
                onPressed: !canSaveName || isSavingName || isArchivingFolder
                    ? null
                    : () => _handleRename(presenter),
                child: isSavingName
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Atualizar nome'),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: tokens.danger.withValues(alpha: 0.24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Area de perigo',
                      style: textTheme.bodyMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ao arquivar a pasta, as analises deixam de pertencer a ela e voltam para Sem pasta.',
                      style: textTheme.bodySmall?.copyWith(
                        color: tokens.textMuted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: isSavingName || isArchivingFolder
                          ? null
                          : () => _handleArchive(presenter),
                      style: FilledButton.styleFrom(
                        backgroundColor: tokens.danger,
                        foregroundColor: tokens.white,
                      ),
                      child: isArchivingFolder
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Arquivar pasta'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: isSavingName || isArchivingFolder
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
