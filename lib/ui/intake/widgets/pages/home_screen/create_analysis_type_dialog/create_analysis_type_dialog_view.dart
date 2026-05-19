import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_dialog_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_option/index.dart';

class CreateAnalysisTypeDialogView extends StatefulWidget {
  final AnalysisTypeDto initialType;

  const CreateAnalysisTypeDialogView({
    this.initialType = AnalysisTypeDto.firstInstance,
    super.key,
  });

  @override
  State<CreateAnalysisTypeDialogView> createState() =>
      _CreateAnalysisTypeDialogViewState();
}

class _CreateAnalysisTypeDialogViewState
    extends State<CreateAnalysisTypeDialogView> {
  late final CreateAnalysisTypeDialogPresenter _presenter;

  @override
  void initState() {
    super.initState();
    _presenter = CreateAnalysisTypeDialogPresenter(
      initialType: widget.initialType,
    );
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 352),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: tokens.surfaceCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Nova analise',
              style: textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha o tipo da analise.',
              style: textTheme.bodySmall?.copyWith(
                color: tokens.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Watch((BuildContext context) {
              final List<Widget> tiles = <Widget>[];
              for (
                int index = 0;
                index < CreateAnalysisTypeDialogPresenter.orderedTypes.length;
                index++
              ) {
                if (index > 0) {
                  tiles.add(const SizedBox(height: 8));
                }
                final AnalysisTypeDto type =
                    CreateAnalysisTypeDialogPresenter.orderedTypes[index];
                tiles.add(
                  CreateAnalysisTypeOption(
                    title: _presenter.titleFor(type),
                    description: _presenter.descriptionFor(type),
                    icon: _presenter.iconFor(type),
                    isSelected: _presenter.isSelected(type),
                    onTap: () => _presenter.selectType(type),
                  ),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: tiles,
              );
            }),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: BorderSide(color: tokens.borderSubtle),
                      backgroundColor: tokens.surfaceElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: textTheme.bodyMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop<AnalysisTypeDto>(_presenter.selected),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: tokens.accent,
                      foregroundColor: const Color(0xFF0B0B0E),
                    ),
                    child: Text(
                      'Criar',
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF0B0B0E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
