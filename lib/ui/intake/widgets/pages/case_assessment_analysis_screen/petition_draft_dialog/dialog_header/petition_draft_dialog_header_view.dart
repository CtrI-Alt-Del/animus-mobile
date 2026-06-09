import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/components/save_status_indicator/index.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/dialog_header/petition_draft_dialog_header_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/petition_draft_dialog_presenter.dart';

class PetitionDraftDialogHeaderView extends ConsumerWidget {
  final PetitionDraftDialogArgs args;
  final Future<bool> Function()? onRegenerate;

  const PetitionDraftDialogHeaderView({
    required this.args,
    this.onRegenerate,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PetitionDraftDialogHeaderPresenter presenter = ref.watch(
      petitionDraftDialogHeaderPresenterProvider(args),
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[tokens.surfaceElevated, tokens.surfaceCard],
        ),
        border: Border(bottom: BorderSide(color: tokens.borderSubtle)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Watch((BuildContext context) {
                final bool isClosing = presenter.isClosing.watch(context);

                return IconButton(
                  onPressed: isClosing
                      ? null
                      : () async {
                          final bool canClose = await presenter.closeDialog();
                          if (!context.mounted || !canClose) {
                            return;
                          }

                          Navigator.of(context).pop();
                        },
                  icon: Icon(Icons.arrow_back, color: tokens.textPrimary),
                );
              }),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Minuta de petição',
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
                  final SaveStatus saveStatus = presenter.saveStatus.watch(
                    context,
                  );

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
                (BuildContext context, AsyncSnapshot<ControlStatus> snapshot) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Watch((BuildContext context) {
                      presenter.requests.watch(context);
                      presenter.precedentCitations.watch(context);
                      final bool isExporting = presenter.isExportingDraft.watch(
                        context,
                      );
                      presenter.saveStatus.watch(context);

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          TextButton.icon(
                            onPressed: presenter.canExportDraft
                                ? () {
                                    unawaited(presenter.exportDraft());
                                  }
                                : null,
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
                              isExporting ? 'Exportando...' : 'Exportar minuta',
                            ),
                          ),
                          if (onRegenerate != null)
                            TextButton.icon(
                              onPressed: () async {
                                final bool didConfirm = await onRegenerate!
                                    .call();
                                if (!didConfirm || !context.mounted) {
                                  return;
                                }

                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
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
    );
  }
}
