import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/dialog_form/index.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/dialog_header/index.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/petition_draft_dialog_presenter.dart';

class PetitionDraftDialogView extends ConsumerWidget {
  final String analysisId;
  final String analysisName;
  final PetitionDraftDto initialDraft;
  final Future<bool> Function()? onRegenerate;

  const PetitionDraftDialogView({
    required this.analysisId,
    required this.analysisName,
    required this.initialDraft,
    this.onRegenerate,
    super.key,
  });

  PetitionDraftDialogArgs get _args => (
    analysisId: analysisId,
    analysisName: analysisName,
    initialDraft: initialDraft,
  );

  Future<void> _handleClose(BuildContext context, WidgetRef ref) async {
    final PetitionDraftDialogHeaderPresenter presenter = ref.read(
      petitionDraftDialogHeaderPresenterProvider(_args),
    );
    final bool canClose = await presenter.closeDialog();
    if (!context.mounted || !canClose) {
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, void result) async {
        if (didPop) {
          return;
        }

        await _handleClose(context, ref);
      },
      child: Scaffold(
        backgroundColor: tokens.surfacePage,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              PetitionDraftDialogHeader(
                args: _args,
                onRegenerate: onRegenerate,
              ),
              Expanded(child: PetitionDraftDialogForm(args: _args)),
            ],
          ),
        ),
      ),
    );
  }
}
