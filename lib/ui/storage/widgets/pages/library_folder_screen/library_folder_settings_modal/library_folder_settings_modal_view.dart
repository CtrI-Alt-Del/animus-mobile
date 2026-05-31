import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/theme.dart';

import 'library_folder_settings_modal_presenter.dart';

class LibraryFolderSettingsModalView extends StatefulWidget {
  final FolderDto folder;
  final Future<bool> Function(String name) onRename;
  final Future<bool> Function() onArchive;

  const LibraryFolderSettingsModalView({
    required this.folder,
    required this.onRename,
    required this.onArchive,
    super.key,
  });

  @override
  State<LibraryFolderSettingsModalView> createState() =>
      _LibraryFolderSettingsModalViewState();
}

class _LibraryFolderSettingsModalViewState
    extends State<LibraryFolderSettingsModalView> {
  late final TextEditingController _controller;
  late LibraryFolderSettingsModalPresenter _presenter;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.folder.name);
    _presenter = _createPresenter();
  }

  @override
  void didUpdateWidget(LibraryFolderSettingsModalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onRename != widget.onRename ||
        oldWidget.onArchive != widget.onArchive) {
      _presenter.dispose();
      _presenter = _createPresenter();
    }
    if (oldWidget.folder.name != widget.folder.name &&
        _controller.text != widget.folder.name) {
      _controller.text = widget.folder.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _presenter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tokens.borderSubtle),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: tokens.scrim.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Configuracoes da pasta',
                    textAlign: TextAlign.center,
                    style: textTheme.titleSmall?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Renomeie ou arquive esta pasta. As análises serão movidas para Sem pasta.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: tokens.textMuted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLength: 50,
                    textInputAction: TextInputAction.done,
                    style: textTheme.bodyMedium?.copyWith(
                      color: tokens.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Nome da pasta',
                      prefixIcon: Icon(Icons.folder_outlined),
                      counterText: '',
                    ),
                    onSubmitted: (_) {
                      unawaited(_submitName());
                    },
                  ),
                  const SizedBox(height: 16),
                  Watch((BuildContext context) {
                    final bool isUpdating = _presenter.isUpdatingName.watch(
                      context,
                    );
                    return FilledButton(
                      onPressed: isUpdating
                          ? null
                          : () {
                              unawaited(_submitName());
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: tokens.accent,
                        foregroundColor: tokens.onAccent,
                      ),
                      child: isUpdating
                          ? _SmallProgress(color: tokens.onAccent)
                          : const Text('Atualizar nome'),
                    );
                  }),
                  const SizedBox(height: 20),
                  Divider(color: tokens.borderSubtle),
                  const SizedBox(height: 12),
                  Text(
                    'Arquivar pasta',
                    style: textTheme.labelSmall?.copyWith(
                      color: tokens.danger,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A pasta será arquivada e as análises continuarão disponíveis em Sem pasta.',
                    style: textTheme.bodySmall?.copyWith(
                      color: tokens.textMuted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Watch((BuildContext context) {
                    final String? errorMessage = _presenter.errorMessage.watch(
                      context,
                    );
                    if (errorMessage == null || errorMessage.trim().isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        errorMessage,
                        style: textTheme.bodySmall?.copyWith(
                          color: tokens.danger,
                        ),
                      ),
                    );
                  }),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Watch((BuildContext context) {
                          final bool isArchiving = _presenter.isArchivingFolder
                              .watch(context);
                          return OutlinedButton.icon(
                            onPressed: isArchiving
                                ? null
                                : () {
                                    unawaited(_archiveFolder());
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: tokens.danger,
                              side: BorderSide(
                                color: tokens.danger.withValues(alpha: 0.45),
                              ),
                            ),
                            icon: isArchiving
                                ? _SmallProgress(color: tokens.danger)
                                : const Icon(Icons.archive_outlined, size: 18),
                            label: const Text('Arquivar'),
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  LibraryFolderSettingsModalPresenter _createPresenter() {
    return LibraryFolderSettingsModalPresenter(
      onRename: widget.onRename,
      onArchive: widget.onArchive,
    );
  }

  Future<void> _submitName() async {
    final bool didRename = await _presenter.submitName(_controller.text);
    if (didRename && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _archiveFolder() async {
    final bool didArchive = await _presenter.confirmArchive();
    if (didArchive && mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

class _SmallProgress extends StatelessWidget {
  final Color color;

  const _SmallProgress({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
