import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/case_assessment_briefing_dto.dart';
import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/legal_area_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/briefing_form_card_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/support_documents_section/index.dart';

class BriefingFormCardView extends ConsumerWidget {
  final String analysisId;
  final bool enabled;
  final Future<void> Function(CaseAssessmentBriefingDto briefing)? onSubmitted;

  const BriefingFormCardView({
    required this.analysisId,
    required this.enabled,
    this.onSubmitted,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BriefingFormCardPresenter presenter = ref.watch(
      briefingFormCardPresenterProvider(analysisId),
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: ReactiveForm(
        formGroup: presenter.form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Briefing do caso',
              style: textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preencha os dados jurídicos essenciais para orientar a análise do caso.',
              style: textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
            ),
            const SizedBox(height: 16),
            IgnorePointer(
              ignoring: !enabled,
              child: Opacity(
                opacity: enabled ? 1 : 0.65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ReactiveDropdownField<LegalAreaDto>(
                      formControlName: 'legalArea',
                      isExpanded: true,
                      decoration: _selectDecoration(
                        context: context,
                        label: 'Área jurídica',
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
                      items: BriefingFormCardPresenter.supportedLegalAreas
                          .map(
                            (LegalAreaDto legalArea) =>
                                DropdownMenuItem<LegalAreaDto>(
                                  value: legalArea,
                                  child: Text(
                                    _legalAreaLabel(legalArea),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                          )
                          .toList(growable: false),
                      validationMessages: presenter.legalAreaValidationMessages,
                    ),
                    const SizedBox(height: 12),
                    ReactiveDropdownField<CourtDto>(
                      formControlName: 'courtJurisdiction',
                      isExpanded: true,
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
                      items: BriefingFormCardPresenter.supportedCourts
                          .map(
                            (CourtDto court) => DropdownMenuItem<CourtDto>(
                              value: court,
                              child: Text(
                                court.value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      validationMessages:
                          presenter.courtJurisdictionValidationMessages,
                    ),
                    const SizedBox(height: 12),
                    ReactiveTextField<String>(
                      formControlName: 'mainClaims',
                      minLines: 4,
                      maxLines: 6,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      style: textTheme.bodyMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _inputDecoration(
                        context: context,
                        label: 'Pedidos principais',
                        hint:
                            'Descreva os pedidos centrais que devem ser defendidos na análise.',
                      ),
                      validationMessages:
                          presenter.mainClaimsValidationMessages,
                    ),
                    const SizedBox(height: 12),
                    ReactiveTextField<String>(
                      formControlName: 'intendedThesis',
                      minLines: 4,
                      maxLines: 6,
                      textInputAction: TextInputAction.newline,
                      keyboardType: TextInputType.multiline,
                      style: textTheme.bodySmall?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: _inputDecoration(
                        context: context,
                        label: 'Tese pretendida',
                        hint:
                            'Explique a linha argumentativa que deve orientar a construção da peça.',
                      ),
                      validationMessages:
                          presenter.intendedThesisValidationMessages,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Watch((BuildContext context) {
              final String? error = presenter.generalError.watch(context);
              if (error == null || error.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
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
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
            SupportDocumentsSection(analysisId: analysisId, enabled: enabled),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Watch((BuildContext context) {
                final bool isSubmitting = presenter.isSubmitting.watch(context);
                final bool canSubmit = presenter.canSubmit.watch(context);

                return FilledButton.icon(
                  onPressed: enabled && canSubmit
                      ? () {
                          unawaited(
                            Future<void>(() async {
                              final CaseAssessmentBriefingDto? briefing =
                                  await presenter.submitBriefing();
                              if (briefing == null) {
                                return;
                              }

                              await onSubmitted?.call(briefing);
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
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    isSubmitting ? 'Salvando briefing...' : 'Salvar briefing',
                    style: textTheme.bodyMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _legalAreaLabel(LegalAreaDto legalArea) {
    final List<String> parts = legalArea.value.split('_');
    return parts
        .map((String part) {
          if (part.isEmpty) {
            return part;
          }

          final String lower = part.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String label,
    String? hint,
  }) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: true,
      filled: true,
      fillColor: tokens.surfaceElevated,
      hintStyle: textTheme.bodySmall?.copyWith(color: tokens.textTertiary),
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
