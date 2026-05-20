import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/precedent_dto.dart';
import 'package:animus/core/intake/dtos/precedent_identifier_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/rest/services/index.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_presenter.dart';

class AddPrecedentDialogPresenter {
  final IntakeService _intakeService;
  final AnalysisPrecedentsBubblePresenter _bubblePresenter;
  final String analysisId;

  StreamSubscription<Object?>? _identifierChangeSubscription;

  final Signal<bool> isFetchingPreview = signal<bool>(false);
  final Signal<bool> isSubmitting = signal<bool>(false);
  final Signal<PrecedentDto?> previewPrecedent = signal<PrecedentDto?>(null);
  final Signal<String?> generalError = signal<String?>(null);

  final FormGroup form = FormGroup(<String, AbstractControl<Object>>{
    'court': FormControl<String>(validators: [Validators.required]),
    'kind': FormControl<String>(validators: [Validators.required]),
    'number': FormControl<String>(
      validators: [Validators.required, Validators.number()],
    ),
  });

  late final ReadonlySignal<bool> canFetchPreview = computed(() {
    return !isFetchingPreview.value && !isSubmitting.value && form.valid;
  });

  late final ReadonlySignal<bool> canSubmit = computed(() {
    return !isFetchingPreview.value &&
        !isSubmitting.value &&
        form.valid &&
        previewPrecedent.value != null;
  });

  AddPrecedentDialogPresenter({
    required IntakeService intakeService,
    required AnalysisPrecedentsBubblePresenter bubblePresenter,
    required this.analysisId,
  }) : _intakeService = intakeService,
       _bubblePresenter = bubblePresenter {
    clearPreviewOnIdentifierChange();
  }

  FormControl<String> get courtControl =>
      form.control('court') as FormControl<String>;

  FormControl<String> get kindControl =>
      form.control('kind') as FormControl<String>;

  FormControl<String> get numberControl =>
      form.control('number') as FormControl<String>;

  Future<void> fetchPreview() async {
    if (!canFetchPreview.value) {
      form.markAllAsTouched();
      return;
    }

    final PrecedentIdentifierDto? identifier = _buildIdentifier();
    if (identifier == null) {
      form.markAllAsTouched();
      return;
    }

    generalError.value = null;
    isFetchingPreview.value = true;

    final RestResponse<PrecedentDto> response = await _intakeService
        .getPrecedent(identifier: identifier);

    if (response.isFailure) {
      previewPrecedent.value = null;
      generalError.value =
          'Nao foi possivel buscar o precedente agora. Verifique o identificador e tente novamente.';
      isFetchingPreview.value = false;
      return;
    }

    previewPrecedent.value = response.body;
    generalError.value = null;
    isFetchingPreview.value = false;
  }

  Future<bool> submit() async {
    if (!canSubmit.value) {
      form.markAllAsTouched();
      return false;
    }

    final PrecedentIdentifierDto? identifier = _buildIdentifier();
    if (identifier == null) {
      form.markAllAsTouched();
      return false;
    }

    generalError.value = null;
    isSubmitting.value = true;

    final RestResponse<AnalysisPrecedentDto> response = await _intakeService
        .addAnalysisPrecedent(analysisId: analysisId, identifier: identifier);

    if (response.isFailure) {
      generalError.value =
          'Nao foi possivel adicionar o precedente agora. Tente novamente.';
      isSubmitting.value = false;
      return false;
    }

    await _bubblePresenter.reloadPrecedents();
    isSubmitting.value = false;
    return true;
  }

  void clearPreviewOnIdentifierChange() {
    _identifierChangeSubscription?.cancel();
    _identifierChangeSubscription = form.valueChanges.listen((_) {
      previewPrecedent.value = null;
      generalError.value = null;
    });
  }

  String? fieldErrorMessage(FormControl<Object?> control) {
    if (!control.invalid || (!control.touched && !control.dirty)) {
      return null;
    }

    if (control.hasError(ValidationMessage.required)) {
      return 'Campo obrigatorio.';
    }
    if (control.hasError(ValidationMessage.number)) {
      return 'Informe um numero valido.';
    }

    return 'Campo invalido.';
  }

  PrecedentIdentifierDto? _buildIdentifier() {
    final CourtDto? court = _parseCourt(courtControl.value);
    final PrecedentKindDto? kind = _parseKind(kindControl.value);
    final int? number = int.tryParse((numberControl.value ?? '').trim());

    if (court == null || kind == null || number == null) {
      return null;
    }

    return PrecedentIdentifierDto(court: court, kind: kind, number: number);
  }

  CourtDto? _parseCourt(String? value) {
    if (value == null) {
      return null;
    }

    final String normalized = value.trim().toUpperCase();
    for (final CourtDto item in CourtDto.values) {
      if (item.value == normalized) {
        return item;
      }
    }

    return null;
  }

  PrecedentKindDto? _parseKind(String? value) {
    if (value == null) {
      return null;
    }

    final String normalized = value.trim().toUpperCase();
    for (final PrecedentKindDto item in PrecedentKindDto.values) {
      if (item.value == normalized) {
        return item;
      }
    }

    return null;
  }

  void dispose() {
    _identifierChangeSubscription?.cancel();
    isFetchingPreview.dispose();
    isSubmitting.dispose();
    previewPrecedent.dispose();
    generalError.dispose();
    canFetchPreview.dispose();
    canSubmit.dispose();
    form.dispose();
  }
}

final addPrecedentDialogPresenterProvider = Provider.autoDispose
    .family<AddPrecedentDialogPresenter, String>((Ref ref, String analysisId) {
      final IntakeService intakeService = ref.watch(intakeServiceProvider);
      final AnalysisPrecedentsBubblePresenter bubblePresenter = ref.watch(
        analysisPrecedentsBubblePresenterProvider(analysisId),
      );

      final AddPrecedentDialogPresenter presenter = AddPrecedentDialogPresenter(
        intakeService: intakeService,
        bubblePresenter: bubblePresenter,
        analysisId: analysisId,
      );

      ref.onDispose(presenter.dispose);
      return presenter;
    });
