import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/library/dtos/folder_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/move_analyses_modal/move_analyses_modal_presenter.dart';

class MoveAnalysesModalView extends ConsumerStatefulWidget {
  final String currentFolderId;
  final int selectedCount;
  final bool showUnfolderedDestination;
  final Future<bool> Function(String? folderId) onMove;

  const MoveAnalysesModalView({
    required this.currentFolderId,
    required this.selectedCount,
    required this.onMove,
    this.showUnfolderedDestination = true,
    super.key,
  });

  @override
  ConsumerState<MoveAnalysesModalView> createState() =>
      _MoveAnalysesModalViewState();
}

class _MoveAnalysesModalViewState extends ConsumerState<MoveAnalysesModalView> {
  bool _isSubmitting = false;
  String? _submitError;

  Future<void> _handleMove(MoveAnalysesModalPresenter presenter) async {
    if (!presenter.hasSelectedDestination.value) {
      setState(() {
        _submitError = 'Escolha uma pasta de destino antes de mover.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final bool moved = await widget.onMove(presenter.selectedFolderId.value);
    if (!mounted) {
      return;
    }

    if (moved) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _submitError =
          'Nao foi possivel mover as analises selecionadas agora. Tente novamente.';
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final MoveAnalysesModalPresenter presenter = ref.watch(
      moveAnalysesModalPresenterProvider(widget.currentFolderId),
    );

    Future<void>.microtask(presenter.load);

    final bool isLoading = presenter.isLoading.watch(context);
    final List<FolderDto> folders = presenter.folders.watch(context);
    final String? generalError = presenter.generalError.watch(context);
    final String? selectedFolderId = presenter.selectedFolderId.watch(context);
    final bool hasSelectedDestination = presenter.hasSelectedDestination.watch(
      context,
    );
    final bool canSubmitMove =
        !isLoading &&
        !_isSubmitting &&
        generalError == null &&
        hasSelectedDestination;

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
                'Mover analises',
                style: textTheme.titleMedium?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.selectedCount} analise${widget.selectedCount == 1 ? '' : 's'} selecionada${widget.selectedCount == 1 ? '' : 's'}',
                style: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
              ),
              const SizedBox(height: 20),
              if (generalError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    generalError,
                    style: textTheme.bodySmall?.copyWith(color: tokens.danger),
                  ),
                ),
              if (_submitError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _submitError!,
                    style: textTheme.bodySmall?.copyWith(color: tokens.danger),
                  ),
                ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (generalError != null)
                const SizedBox.shrink()
              else if (!widget.showUnfolderedDestination && folders.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Crie uma pasta antes de mover analises de Sem pasta.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: tokens.textMuted,
                      height: 1.35,
                    ),
                  ),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        if (widget.showUnfolderedDestination) ...<Widget>[
                          _DestinationTile(
                            title: 'Sem pasta',
                            subtitle: 'Remover da pasta atual',
                            value: null,
                            isSelected:
                                hasSelectedDestination &&
                                selectedFolderId == null,
                            onChanged: presenter.selectFolder,
                          ),
                          const SizedBox(height: 10),
                        ],
                        ...folders.map(
                          (FolderDto folder) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _DestinationTile(
                              title: folder.name,
                              subtitle: '${folder.analysisCount} analises',
                              value: folder.id,
                              isSelected:
                                  hasSelectedDestination &&
                                  folder.id == selectedFolderId,
                              onChanged: presenter.selectFolder,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: canSubmitMove
                          ? () => _handleMove(presenter)
                          : null,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Mover'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? value;
  final bool isSelected;
  final void Function(String? folderId) onChanged;

  const _DestinationTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title, $subtitle',
      value: isSelected ? 'Selecionado' : 'Nao selecionado',
      hint: 'Toque para selecionar este destino',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tokens.surfaceCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? tokens.accent : tokens.borderSubtle,
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: textTheme.bodyMedium?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: textTheme.bodySmall?.copyWith(
                            color: tokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ExcludeSemantics(
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? tokens.accent : tokens.borderStrong,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: tokens.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
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
