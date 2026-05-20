import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/precedent_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/add_precedent_dialog/add_precedent_dialog_presenter.dart';

class AddPrecedentDialogView extends ConsumerWidget {
  final String analysisId;

  const AddPrecedentDialogView({required this.analysisId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AddPrecedentDialogPresenter presenter = ref.watch(
      addPrecedentDialogPresenterProvider(analysisId),
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: tokens.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: ReactiveForm(
          formGroup: presenter.form,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Adicionar precedente',
                  style: textTheme.titleMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Informe tribunal, tipo e numero para buscar o precedente na base nacional.',
                  style: textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ReactiveTextField<String>(
                  formControlName: 'court',
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDecoration(
                    context: context,
                    label: 'Court',
                  ),
                  validationMessages: <String, ValidationMessageFunction>{
                    ValidationMessage.required: (_) => 'Campo obrigatorio.',
                  },
                ),
                const SizedBox(height: 12),
                ReactiveTextField<String>(
                  formControlName: 'kind',
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDecoration(context: context, label: 'Kind'),
                  validationMessages: <String, ValidationMessageFunction>{
                    ValidationMessage.required: (_) => 'Campo obrigatorio.',
                  },
                ),
                const SizedBox(height: 12),
                ReactiveTextField<String>(
                  formControlName: 'number',
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => unawaited(presenter.fetchPreview()),
                  decoration: _inputDecoration(
                    context: context,
                    label: 'Number',
                  ),
                  validationMessages: <String, ValidationMessageFunction>{
                    ValidationMessage.required: (_) => 'Campo obrigatorio.',
                    ValidationMessage.number: (_) =>
                        'Informe um numero valido.',
                  },
                ),
                const SizedBox(height: 12),
                Watch((BuildContext context) {
                  final bool isFetchingPreview = presenter.isFetchingPreview
                      .watch(context);
                  final bool canFetchPreview = presenter.canFetchPreview.watch(
                    context,
                  );

                  return FilledButton.icon(
                    onPressed: canFetchPreview
                        ? () => unawaited(presenter.fetchPreview())
                        : null,
                    icon: isFetchingPreview
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: tokens.white,
                            ),
                          )
                        : const Icon(Icons.search, size: 18),
                    label: Text(
                      isFetchingPreview
                          ? 'Buscando precedente...'
                          : 'Buscar precedente',
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Watch((BuildContext context) {
                  final String? error = presenter.generalError.watch(context);
                  if (error == null || error.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tokens.danger.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          Icons.error_outline,
                          size: 16,
                          color: tokens.danger,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error,
                            style: textTheme.bodySmall?.copyWith(
                              color: tokens.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Watch((BuildContext context) {
                  final PrecedentDto? precedent = presenter.previewPrecedent
                      .watch(context);
                  if (precedent == null) {
                    return const SizedBox.shrink();
                  }

                  return _PreviewCard(precedent: precedent);
                }),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Watch((BuildContext context) {
                        final bool isSubmitting = presenter.isSubmitting.watch(
                          context,
                        );
                        final bool canSubmit = presenter.canSubmit.watch(
                          context,
                        );

                        return FilledButton.icon(
                          onPressed: canSubmit
                              ? () {
                                  unawaited(
                                    Future<void>(() async {
                                      final bool didSubmit = await presenter
                                          .submit();
                                      if (!didSubmit || !context.mounted) {
                                        return;
                                      }

                                      Navigator.of(context).pop(true);
                                    }),
                                  );
                                }
                              : null,
                          icon: isSubmitting
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: tokens.white,
                                  ),
                                )
                              : const Icon(Icons.add, size: 18),
                          label: Text(
                            isSubmitting
                                ? 'Adicionando...'
                                : 'Adicionar precedente',
                          ),
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
    );
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String label,
  }) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: tokens.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.accent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.danger),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final PrecedentDto precedent;

  const _PreviewCard({required this.precedent});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String identifier =
        '${precedent.identifier.court.value} ${precedent.identifier.kind.value} ${precedent.identifier.number}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.balance_outlined, size: 16, color: tokens.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  identifier,
                  style: textTheme.bodyMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PreviewTextBlock(label: 'Status', value: precedent.status),
          const SizedBox(height: 8),
          _PreviewTextBlock(label: 'Enunciado', value: precedent.enunciation),
          const SizedBox(height: 8),
          _PreviewTextBlock(label: 'Tese', value: precedent.thesis),
        ],
      ),
    );
  }
}

class _PreviewTextBlock extends StatefulWidget {
  final String label;
  final String value;

  const _PreviewTextBlock({required this.label, required this.value});

  @override
  State<_PreviewTextBlock> createState() => _PreviewTextBlockState();
}

class _PreviewTextBlockState extends State<_PreviewTextBlock> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String resolvedValue = widget.value.trim().isEmpty
        ? 'Nao informado.'
        : widget.value.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.label,
          style: textTheme.labelSmall?.copyWith(
            color: tokens.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          resolvedValue,
          maxLines: _isExpanded ? null : 2,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
        ),
        if (resolvedValue.length > 120)
          TextButton(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(_isExpanded ? 'Mostrar menos' : 'Expandir'),
          ),
      ],
    );
  }
}
