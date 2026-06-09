import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/ui/intake/widgets/components/save_status_indicator/save_status.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/petition_draft_dialog_presenter.dart';

class PetitionDraftDialogHeaderPresenter {
  final PetitionDraftDialogPresenter _dialogPresenter;

  final Signal<bool> isClosing = signal<bool>(false);

  PetitionDraftDialogHeaderPresenter({
    required PetitionDraftDialogPresenter dialogPresenter,
  }) : _dialogPresenter = dialogPresenter;

  Signal<SaveStatus> get saveStatus => _dialogPresenter.saveStatus;

  Signal<bool> get isExportingDraft => _dialogPresenter.isExportingDraft;

  Signal<List<String>> get requests => _dialogPresenter.requests;

  Signal<List<String>> get precedentCitations =>
      _dialogPresenter.precedentCitations;

  FormGroup get form => _dialogPresenter.form;

  bool get canExportDraft => _dialogPresenter.canExportDraft;

  Future<void> exportDraft() async {
    await _dialogPresenter.exportPetitionDraft();
  }

  Future<bool> closeDialog() async {
    if (isClosing.value) {
      return false;
    }

    isClosing.value = true;
    final bool canClose = await _dialogPresenter.flushPendingChanges();
    if (!canClose) {
      isClosing.value = false;
    }

    return canClose;
  }

  void dispose() {
    isClosing.dispose();
  }
}

final petitionDraftDialogHeaderPresenterProvider = Provider.autoDispose
    .family<PetitionDraftDialogHeaderPresenter, PetitionDraftDialogArgs>((
      Ref ref,
      PetitionDraftDialogArgs args,
    ) {
      final PetitionDraftDialogPresenter dialogPresenter = ref.watch(
        petitionDraftDialogPresenterProvider(args),
      );

      final PetitionDraftDialogHeaderPresenter presenter =
          PetitionDraftDialogHeaderPresenter(dialogPresenter: dialogPresenter);

      ref.onDispose(presenter.dispose);
      return presenter;
    });
