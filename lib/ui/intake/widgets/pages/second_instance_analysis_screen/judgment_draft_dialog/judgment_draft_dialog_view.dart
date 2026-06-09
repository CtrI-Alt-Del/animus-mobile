import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/second_instance_judgment_draft_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/components/dynamic_list_field/index.dart';
import 'package:animus/ui/intake/widgets/components/save_status_indicator/index.dart';
import 'package:animus/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/draft_section/index.dart';
import 'package:animus/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_presenter.dart';

class JudgmentDraftDialogView extends ConsumerStatefulWidget {
  final String analysisId;
  final SecondInstanceJudgmentDraftDto draft;
  final void Function(SecondInstanceJudgmentDraftDto draft)? onDraftUpdated;
  final Future<bool> Function()? onRegenerate;

  const JudgmentDraftDialogView({
    required this.analysisId,
    required this.draft,
    this.onDraftUpdated,
    this.onRegenerate,
    super.key,
  });

  @override
  ConsumerState<JudgmentDraftDialogView> createState() =>
      _JudgmentDraftDialogViewState();
}

class _JudgmentDraftDialogViewState
    extends ConsumerState<JudgmentDraftDialogView> {
  JudgmentDraftDialogArgs get _args => (
    analysisId: widget.analysisId,
    initialDraft: widget.draft,
    onDraftUpdated: widget.onDraftUpdated,
  );

  @override
  void dispose() {
    unawaited(ref.read(judgmentDraftDialogPresenterProvider(_args)).flush());
    super.dispose();
  }

  Future<void> _handleClose(BuildContext context) async {
    final JudgmentDraftDialogPresenter presenter = ref.read(
      judgmentDraftDialogPresenterProvider((
        analysisId: widget.analysisId,
        initialDraft: widget.draft,
        onDraftUpdated: widget.onDraftUpdated,
      )),
    );
    final bool canClose = await presenter.flush();
    if (!context.mounted || !canClose) {
      return;
    }

    Navigator.of(context).pop();
  }

  Future<void> _handleRegenerate(BuildContext context) async {
    final Future<bool> Function()? onRegenerate = widget.onRegenerate;
    if (onRegenerate == null) {
      return;
    }

    final bool didConfirm = await onRegenerate.call();
    if (!didConfirm || !context.mounted) {
      return;
    }

    await _handleClose(context);
  }

  @override
  Widget build(BuildContext context) {
    final JudgmentDraftDialogPresenter presenter = ref.watch(
      judgmentDraftDialogPresenterProvider(_args),
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, void result) async {
        if (didPop) {
          return;
        }

        await _handleClose(context);
      },
      child: Scaffold(
        backgroundColor: tokens.surfacePage,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[tokens.surfaceElevated, tokens.surfaceCard],
                  ),
                  border: Border(
                    bottom: BorderSide(color: tokens.borderSubtle),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        IconButton(
                          onPressed: () async {
                            await _handleClose(context);
                          },
                          icon: Icon(
                            Icons.arrow_back,
                            color: tokens.textPrimary,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Minuta de sentença',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: tokens.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'As alterações são salvas automaticamente.',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: tokens.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Watch((BuildContext context) {
                            final SaveStatus saveStatus = presenter.saveStatus
                                .watch(context);

                            return SaveStatusIndicator(status: saveStatus);
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<ControlStatus>(
                      stream: presenter.form.statusChanged,
                      initialData: presenter.form.status,
                      builder:
                          (
                            BuildContext context,
                            AsyncSnapshot<ControlStatus> snapshot,
                          ) {
                            return Align(
                              alignment: Alignment.centerRight,
                              child: Watch((BuildContext context) {
                                presenter.ruling.watch(context);
                                presenter.saveStatus.watch(context);
                                final bool isExporting = presenter
                                    .isExportingDraft
                                    .watch(context);

                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: <Widget>[
                                    TextButton.icon(
                                      onPressed: isExporting
                                          ? null
                                          : () async {
                                              await presenter
                                                  .exportJudgmentDraft();
                                            },
                                      icon: isExporting
                                          ? SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: tokens.accent,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.file_download_outlined,
                                              size: 16,
                                            ),
                                      label: Text(
                                        isExporting
                                            ? 'Exportando...'
                                            : 'Exportar minuta',
                                      ),
                                    ),
                                    if (widget.onRegenerate != null)
                                      TextButton.icon(
                                        onPressed: () async {
                                          await _handleRegenerate(context);
                                        },
                                        icon: const Icon(
                                          Icons.refresh_rounded,
                                          size: 16,
                                        ),
                                        label: const Text('Regerar minuta'),
                                      ),
                                  ],
                                );
                              }),
                            );
                          },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReactiveForm(
                  formGroup: presenter.form,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Watch((BuildContext context) {
                          final String? error = presenter.generalError.watch(
                            context,
                          );
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
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        DraftSection(
                          icon: Icons.article_outlined,
                          title: 'Relatório',
                          content: widget.draft.report,
                          emptyText: 'O relatório não foi disponibilizado.',
                          emphasize: true,
                          editableContent: _buildTextField(
                            context: context,
                            textTheme: textTheme,
                            presenter: presenter,
                            formControlName: 'report',
                            hint: 'Descreva o relatório da minuta.',
                            minLines: 6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DraftSection(
                          icon: Icons.rule_folder_outlined,
                          title: 'Questões Preliminares',
                          content: widget.draft.preliminaryIssues ?? '',
                          emptyText:
                              'Sem questões preliminares disponibilizadas.',
                          editableContent: _buildTextField(
                            context: context,
                            textTheme: textTheme,
                            presenter: presenter,
                            formControlName: 'preliminary_issues',
                            hint:
                                'Detalhe as questões preliminares, se houver.',
                            minLines: 4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DraftSection(
                          icon: Icons.balance_outlined,
                          title: 'Análise do Mérito',
                          content: widget.draft.meritAnalysis,
                          emptyText:
                              'A análise do mérito não foi disponibilizada.',
                          editableContent: _buildTextField(
                            context: context,
                            textTheme: textTheme,
                            presenter: presenter,
                            formControlName: 'merit_analysis',
                            hint: 'Descreva a análise do mérito.',
                            minLines: 6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DraftSection(
                          icon: Icons.account_tree_outlined,
                          title: 'Aderência aos Precedentes',
                          content: widget.draft.precedentAdherenceAnalysis,
                          emptyText:
                              'A análise de aderência aos precedentes não foi disponibilizada.',
                          editableContent: _buildTextField(
                            context: context,
                            textTheme: textTheme,
                            presenter: presenter,
                            formControlName: 'precedent_adherence',
                            hint:
                                'Explique a aderência da minuta aos precedentes selecionados.',
                            minLines: 5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DraftSection(
                          icon: Icons.info_outline,
                          title: 'Aviso',
                          content:
                              widget.draft.noApplicablePrecedentNotice ?? '',
                          emptyText: '',
                          accentColor: tokens.warning,
                          editableContent: _buildTextField(
                            context: context,
                            textTheme: textTheme,
                            presenter: presenter,
                            formControlName: 'no_applicable_notice',
                            hint:
                                'Informe um aviso opcional sobre precedentes aplicáveis.',
                            minLines: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DraftSection(
                          icon: Icons.gavel_outlined,
                          title: 'Dispositivo',
                          content: widget.draft.ruling.join('\n'),
                          emptyText: 'O dispositivo não foi disponibilizado.',
                          editableContent: Watch((BuildContext context) {
                            final List<String> ruling = List<String>.from(
                              presenter.ruling.watch(context),
                            );

                            return DynamicListField(
                              items: ruling,
                              onAdd: presenter.addRulingItem,
                              onRemove: presenter.removeRulingItem,
                              onUpdate: presenter.updateRulingItem,
                              addLabel: 'Adicionar item',
                              itemLabel: 'Item do dispositivo',
                              itemHintText: 'Descreva um item do dispositivo.',
                              minItems: 1,
                              itemErrorTextBuilder: (int index, String value) {
                                return presenter.fieldErrorMessage(
                                  listFieldName: 'ruling',
                                  index: index,
                                );
                              },
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextTheme textTheme,
    required JudgmentDraftDialogPresenter presenter,
    required String formControlName,
    required String hint,
    required int minLines,
  }) {
    return ReactiveTextField<String>(
      formControlName: formControlName,
      minLines: minLines,
      maxLines: null,
      textInputAction: TextInputAction.newline,
      keyboardType: TextInputType.multiline,
      style: textTheme.bodyMedium?.copyWith(fontSize: 14),
      decoration: _inputDecoration(context: context, hint: hint),
      validationMessages: <String, ValidationMessageFunction>{
        ValidationMessage.required: (_) {
          return presenter.fieldErrorMessage(
                control:
                    presenter.form.control(formControlName)
                        as FormControl<Object?>,
              ) ??
              'Campo obrigatório.';
        },
      },
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
