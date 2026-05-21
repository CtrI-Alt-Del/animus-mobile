import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/precedent_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/add_precedent_dialog/add_precedent_dialog_presenter.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/add_precedent_dialog/preview_card/index.dart';

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
                ReactiveDropdownField<CourtDto>(
                  formControlName: 'court',
                  decoration: _selectDecoration(
                    context: context,
                    label: 'Tribunal',
                  ),
                  style: textTheme.bodyMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  dropdownColor: tokens.surfaceElevated,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: tokens.textSecondary,
                  ),
                  items: AddPrecedentDialogPresenter.supportedCourts
                      .map(
                        (CourtDto court) => DropdownMenuItem<CourtDto>(
                          value: court,
                          child: Text(court.value),
                        ),
                      )
                      .toList(growable: false),
                  validationMessages: <String, ValidationMessageFunction>{
                    ValidationMessage.required: (_) => 'Campo obrigatorio.',
                  },
                ),
                const SizedBox(height: 12),
                ReactiveDropdownField<PrecedentKindDto>(
                  formControlName: 'kind',
                  decoration: _selectDecoration(
                    context: context,
                    label: 'Espécie',
                  ),
                  style: textTheme.bodyMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  dropdownColor: tokens.surfaceElevated,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: tokens.textSecondary,
                  ),
                  items: AddPrecedentDialogPresenter.supportedKinds
                      .map(
                        (PrecedentKindDto kind) =>
                            DropdownMenuItem<PrecedentKindDto>(
                              value: kind,
                              child: Text(kind.value),
                            ),
                      )
                      .toList(growable: false),
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
                    label: 'Número',
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

                  return PreviewCard(precedent: precedent);
                }),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Flexible(
                      flex: 4,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      flex: 5,
                      child: Watch((BuildContext context) {
                        final bool isSubmitting = presenter.isSubmitting.watch(
                          context,
                        );
                        final bool canSubmit = presenter.canSubmit.watch(
                          context,
                        );

                        return FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
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
                            isSubmitting ? 'Adicionando...' : 'Adicionar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  InputDecoration _selectDecoration({
    required BuildContext context,
    required String label,
  }) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return _inputDecoration(context: context, label: label).copyWith(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      suffixIconColor: tokens.textSecondary,
    );
  }
}
