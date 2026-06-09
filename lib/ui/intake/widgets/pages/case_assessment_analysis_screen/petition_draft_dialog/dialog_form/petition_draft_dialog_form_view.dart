import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/components/dynamic_list_field/index.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/dialog_form/petition_draft_dialog_form_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/petition_draft_dialog_presenter.dart';

class PetitionDraftDialogFormView extends ConsumerWidget {
  final PetitionDraftDialogArgs args;

  const PetitionDraftDialogFormView({required this.args, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PetitionDraftDialogFormPresenter presenter = ref.watch(
      petitionDraftDialogFormPresenterProvider(args),
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: tokens.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: ReactiveForm(
          formGroup: presenter.form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Watch((BuildContext context) {
                final String? error = presenter.generalError.watch(context);
                if (error == null || error.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.danger.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: tokens.danger.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.error_outline, size: 16, color: tokens.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error,
                          style: textTheme.bodySmall?.copyWith(
                            color: tokens.danger,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              _buildSectionLabel(context, 'Fatos estruturados'),
              const SizedBox(height: 10),
              ReactiveTextField<String>(
                formControlName: 'structuredFacts',
                minLines: 5,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: PetitionDraftDialogFormPresenter.draftFieldFontSize,
                ),
                decoration: _inputDecoration(
                  context: context,
                  hint:
                      'Descreva os fatos estruturados que devem compor a minuta.',
                ),
                validationMessages: presenter.requiredValidationMessages(
                  'structuredFacts',
                ),
              ),
              const SizedBox(height: 18),
              _buildSectionLabel(context, 'Fundamentos jurídicos'),
              const SizedBox(height: 10),
              ReactiveTextField<String>(
                formControlName: 'legalGrounds',
                minLines: 5,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: PetitionDraftDialogFormPresenter.draftFieldFontSize,
                ),
                decoration: _inputDecoration(
                  context: context,
                  hint: 'Detalhe os fundamentos jurídicos aplicáveis ao caso.',
                ),
                validationMessages: presenter.requiredValidationMessages(
                  'legalGrounds',
                ),
              ),
              const SizedBox(height: 18),
              _buildSectionLabel(context, 'Tese central'),
              const SizedBox(height: 10),
              ReactiveTextField<String>(
                formControlName: 'centralThesis',
                minLines: 3,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: PetitionDraftDialogFormPresenter.draftFieldFontSize,
                ),
                decoration: _inputDecoration(
                  context: context,
                  hint: 'Explique a tese central que orienta a peça.',
                ),
                validationMessages: presenter.requiredValidationMessages(
                  'centralThesis',
                ),
              ),
              const SizedBox(height: 18),
              _buildSectionLabel(context, 'Pedidos'),
              const SizedBox(height: 10),
              Watch((BuildContext context) {
                final List<String> requests = List<String>.from(
                  presenter.requests.watch(context),
                );

                return DynamicListField(
                  items: requests,
                  onAdd: presenter.addRequest,
                  onRemove: presenter.removeRequest,
                  onUpdate: presenter.updateRequest,
                  addLabel: 'Adicionar pedido',
                  itemLabel: 'Pedido',
                  itemHintText: 'Descreva o pedido.',
                  itemErrorTextBuilder: (int index, String value) {
                    return presenter.listItemErrorMessage(
                      listFieldName: 'requests',
                      index: index,
                    );
                  },
                );
              }),
              const SizedBox(height: 18),
              _buildSectionLabel(context, 'Citações de precedentes'),
              const SizedBox(height: 10),
              Watch((BuildContext context) {
                final List<String> precedentCitations = List<String>.from(
                  presenter.precedentCitations.watch(context),
                );

                return DynamicListField(
                  items: precedentCitations,
                  onAdd: presenter.addPrecedentCitation,
                  onRemove: presenter.removePrecedentCitation,
                  onUpdate: presenter.updatePrecedentCitation,
                  addLabel: 'Adicionar citação',
                  itemLabel: 'Citação',
                  itemHintText: 'Informe a citação de precedente aplicável.',
                  itemErrorTextBuilder: (int index, String value) {
                    return presenter.listItemErrorMessage(
                      listFieldName: 'precedentCitations',
                      index: index,
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String title) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Text(
      title,
      style: textTheme.titleSmall?.copyWith(
        color: tokens.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String hint,
  }) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return InputDecoration(
      hintText: hint,
      alignLabelWithHint: true,
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
        borderSide: BorderSide(color: tokens.accent, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: tokens.danger, width: 1.2),
      ),
    );
  }
}
