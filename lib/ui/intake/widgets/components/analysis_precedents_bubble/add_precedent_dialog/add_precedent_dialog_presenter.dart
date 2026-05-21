import 'dart:io';

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
  StreamSubscription<ControlStatus>? _formStatusSubscription;

  final Signal<bool> isFetchingPreview = signal<bool>(false);
  final Signal<bool> isSubmitting = signal<bool>(false);
  final Signal<PrecedentDto?> previewPrecedent = signal<PrecedentDto?>(null);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<bool> hasValidIdentifier = signal<bool>(false);

  static final List<CourtDto> supportedCourts = List<CourtDto>.unmodifiable(
    CourtDto.values,
  );
  static final List<PrecedentKindDto> supportedKinds =
      List<PrecedentKindDto>.unmodifiable(PrecedentKindDto.values);

  final FormGroup form = FormGroup(<String, AbstractControl<Object>>{
    'court': FormControl<CourtDto>(validators: [Validators.required]),
    'kind': FormControl<PrecedentKindDto>(validators: [Validators.required]),
    'number': FormControl<String>(
      validators: [Validators.required, Validators.number()],
    ),
  });

  late final ReadonlySignal<bool> canFetchPreview = computed(() {
    return !isFetchingPreview.value &&
        !isSubmitting.value &&
        hasValidIdentifier.value;
  });

  late final ReadonlySignal<bool> canSubmit = computed(() {
    return !isFetchingPreview.value &&
        !isSubmitting.value &&
        hasValidIdentifier.value &&
        previewPrecedent.value != null;
  });

  AddPrecedentDialogPresenter({
    required IntakeService intakeService,
    required AnalysisPrecedentsBubblePresenter bubblePresenter,
    required this.analysisId,
  }) : _intakeService = intakeService,
       _bubblePresenter = bubblePresenter {
    _syncFormState();
    clearPreviewOnIdentifierChange();
  }

  FormControl<CourtDto> get courtControl =>
      form.control('court') as FormControl<CourtDto>;

  FormControl<PrecedentKindDto> get kindControl =>
      form.control('kind') as FormControl<PrecedentKindDto>;

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
      generalError.value = response.statusCode == HttpStatus.notFound
          ? 'Precedente não encontrado.'
          : 'Não foi possivel buscar o precedente agora. Verifique o identificador e tente novamente.';
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
          'Não foi possivel adicionar o precedente agora. Tente novamente.';
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
      _syncFormState();
      previewPrecedent.value = null;
      generalError.value = null;
    });

    _formStatusSubscription?.cancel();
    _formStatusSubscription = form.statusChanged.listen((_) {
      _syncFormState();
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
    final CourtDto? court = courtControl.value;
    final PrecedentKindDto? kind = kindControl.value;
    final int? number = int.tryParse((numberControl.value ?? '').trim());

    if (court == null || kind == null || number == null) {
      return null;
    }

    return PrecedentIdentifierDto(court: court, kind: kind, number: number);
  }

  void _syncFormState() {
    final bool hasValidCourt = courtControl.valid && courtControl.value != null;
    final bool hasValidKind = kindControl.valid && kindControl.value != null;
    final bool hasValidNumber = numberControl.valid;

    hasValidIdentifier.value = hasValidCourt && hasValidKind && hasValidNumber;
  }

  void dispose() {
    _identifierChangeSubscription?.cancel();
    _formStatusSubscription?.cancel();
    isFetchingPreview.dispose();
    isSubmitting.dispose();
    previewPrecedent.dispose();
    generalError.dispose();
    hasValidIdentifier.dispose();
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
