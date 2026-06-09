import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/petition_draft_dialog_presenter.dart';

class PetitionDraftDialogFormPresenter {
  static const double draftFieldFontSize = 14;

  final PetitionDraftDialogPresenter _dialogPresenter;

  PetitionDraftDialogFormPresenter({
    required PetitionDraftDialogPresenter dialogPresenter,
  }) : _dialogPresenter = dialogPresenter;

  FormGroup get form => _dialogPresenter.form;

  Signal<String?> get generalError => _dialogPresenter.generalError;

  Signal<List<String>> get requests => _dialogPresenter.requests;

  Signal<List<String>> get precedentCitations =>
      _dialogPresenter.precedentCitations;

  bool get canRemoveRequests => _dialogPresenter.canRemoveRequests;

  bool get canRemovePrecedentCitations =>
      _dialogPresenter.canRemovePrecedentCitations;

  void addRequest() => _dialogPresenter.addRequest();

  void removeRequest(int index) => _dialogPresenter.removeRequest(index);

  void updateRequest(int index, String value) =>
      _dialogPresenter.updateRequest(index, value);

  void addPrecedentCitation() => _dialogPresenter.addPrecedentCitation();

  void removePrecedentCitation(int index) =>
      _dialogPresenter.removePrecedentCitation(index);

  void updatePrecedentCitation(int index, String value) =>
      _dialogPresenter.updatePrecedentCitation(index, value);

  Map<String, ValidationMessageFunction> requiredValidationMessages(
    String controlName,
  ) {
    return <String, ValidationMessageFunction>{
      ValidationMessage.required: (_) {
        final FormControl<Object?> control =
            form.control(controlName) as FormControl<Object?>;
        return _dialogPresenter.fieldErrorMessage(control: control) ??
            'Campo obrigatório.';
      },
    };
  }

  String? listItemErrorMessage({
    required String listFieldName,
    required int index,
  }) {
    return _dialogPresenter.fieldErrorMessage(
      listFieldName: listFieldName,
      index: index,
    );
  }
}

final petitionDraftDialogFormPresenterProvider = Provider.autoDispose
    .family<PetitionDraftDialogFormPresenter, PetitionDraftDialogArgs>((
      Ref ref,
      PetitionDraftDialogArgs args,
    ) {
      final PetitionDraftDialogPresenter dialogPresenter = ref.watch(
        petitionDraftDialogPresenterProvider(args),
      );

      return PetitionDraftDialogFormPresenter(dialogPresenter: dialogPresenter);
    });
