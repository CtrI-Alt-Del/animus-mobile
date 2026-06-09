import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/case_assessment_briefing_dto.dart';
import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/legal_area_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/rest/services/index.dart';

class BriefingFormCardPresenter {
  static const String loadFailedMessage =
      'Não foi possível carregar o briefing agora. Tente novamente.';
  static const String submitFailedMessage =
      'Não foi possível salvar o briefing agora. Tente novamente.';

  final IntakeService _intakeService;
  final String analysisId;

  StreamSubscription<ControlStatus>? _formStatusSubscription;
  StreamSubscription<Object?>? _formValueSubscription;

  static const String blankValidationMessage = 'blank';

  final Signal<CaseAssessmentBriefingDto?> briefing =
      signal<CaseAssessmentBriefingDto?>(null);
  final Signal<bool> isSubmitting = signal<bool>(false);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<bool> isReadOnly = signal<bool>(false);
  final Signal<bool> _isFormValid = signal<bool>(false);

  static final List<LegalAreaDto> supportedLegalAreas =
      List<LegalAreaDto>.unmodifiable(LegalAreaDto.values);
  static final List<CourtDto> supportedCourts = List<CourtDto>.unmodifiable(
    CourtDto.values,
  );

  final FormGroup form = FormGroup(<String, AbstractControl<Object>>{
    'legalArea': FormControl<LegalAreaDto>(validators: [Validators.required]),
    'courtJurisdiction': FormControl<CourtDto>(
      validators: [Validators.required],
    ),
    'mainClaims': FormControl<String>(
      validators: [
        Validators.required,
        Validators.delegate(_trimmedRequiredValidator),
      ],
    ),
    'intendedThesis': FormControl<String>(
      validators: [
        Validators.required,
        Validators.delegate(_trimmedRequiredValidator),
      ],
    ),
  });

  late final ReadonlySignal<bool> canSubmit = computed(() {
    return _isFormValid.value && !isSubmitting.value && !isReadOnly.value;
  });

  BriefingFormCardPresenter({
    required IntakeService intakeService,
    required this.analysisId,
  }) : _intakeService = intakeService {
    _syncFormValidity();
    _formStatusSubscription = form.statusChanged.listen((_) {
      _syncFormValidity();
    });
    _formValueSubscription = form.valueChanges.listen((_) {
      if (isReadOnly.value && form.dirty) {
        isReadOnly.value = false;
      }
      _syncFormValidity();
    });
  }

  FormControl<LegalAreaDto> get legalAreaControl =>
      form.control('legalArea') as FormControl<LegalAreaDto>;

  FormControl<CourtDto> get courtJurisdictionControl =>
      form.control('courtJurisdiction') as FormControl<CourtDto>;

  FormControl<String> get mainClaimsControl =>
      form.control('mainClaims') as FormControl<String>;

  FormControl<String> get intendedThesisControl =>
      form.control('intendedThesis') as FormControl<String>;

  Map<String, ValidationMessageFunction> get legalAreaValidationMessages =>
      _requiredValidationMessages('Selecione a área jurídica.');

  Map<String, ValidationMessageFunction>
  get courtJurisdictionValidationMessages =>
      _requiredValidationMessages('Selecione o tribunal.');

  Map<String, ValidationMessageFunction> get mainClaimsValidationMessages =>
      _requiredValidationMessages('Descreva os pedidos principais.');

  Map<String, ValidationMessageFunction> get intendedThesisValidationMessages =>
      _requiredValidationMessages('Descreva a tese pretendida.');

  Future<void> load() async {
    generalError.value = null;

    final RestResponse<CaseAssessmentBriefingDto> response =
        await _intakeService.getCaseAssessmentBriefing(analysisId: analysisId);

    if (response.isFailure) {
      if (response.statusCode == HttpStatus.notFound) {
        briefing.value = null;
        return;
      }

      generalError.value = response.errorMessage.isNotEmpty
          ? response.errorMessage
          : loadFailedMessage;
      return;
    }

    briefing.value = response.body;
    fillForm(response.body);
    generalError.value = null;
  }

  Future<CaseAssessmentBriefingDto?> submitBriefing() async {
    if (!canSubmit.value) {
      form.markAllAsTouched();
      return null;
    }

    final CaseAssessmentBriefingDto? nextBriefing = buildBriefingFromForm();
    if (nextBriefing == null) {
      form.markAllAsTouched();
      return null;
    }

    generalError.value = null;
    isSubmitting.value = true;

    final RestResponse<CaseAssessmentBriefingDto> response =
        await _intakeService.submitCaseAssessmentBriefing(
          analysisId: analysisId,
          briefing: nextBriefing,
        );

    if (response.isFailure) {
      generalError.value = response.errorMessage.isNotEmpty
          ? response.errorMessage
          : submitFailedMessage;
      isSubmitting.value = false;
      return null;
    }

    briefing.value = response.body;
    fillForm(response.body);
    generalError.value = null;
    isSubmitting.value = false;
    return response.body;
  }

  CaseAssessmentBriefingDto? buildBriefingFromForm() {
    final LegalAreaDto? legalArea = legalAreaControl.value;
    final CourtDto? court = courtJurisdictionControl.value;
    final String mainClaims = (mainClaimsControl.value ?? '').trim();
    final String intendedThesis = (intendedThesisControl.value ?? '').trim();

    if (legalArea == null ||
        court == null ||
        mainClaims.isEmpty ||
        intendedThesis.isEmpty) {
      return null;
    }

    return CaseAssessmentBriefingDto(
      analysisId: analysisId,
      legalArea: legalArea,
      courtJurisdiction: court,
      mainClaims: mainClaims,
      intendedThesis: intendedThesis,
    );
  }

  void fillForm(CaseAssessmentBriefingDto value) {
    form.patchValue(<String, Object?>{
      'legalArea': value.legalArea,
      'courtJurisdiction': value.courtJurisdiction,
      'mainClaims': value.mainClaims,
      'intendedThesis': value.intendedThesis,
    });
    form.markAsPristine();
    form.markAsUntouched();
    isReadOnly.value = true;
    _syncFormValidity();
  }

  String? fieldErrorMessage(FormControl<Object?> control) {
    if (!control.invalid || (!control.touched && !control.dirty)) {
      return null;
    }

    if (control.hasError(ValidationMessage.required)) {
      return 'Campo obrigatório.';
    }

    return 'Campo inválido.';
  }

  void _syncFormValidity() {
    _isFormValid.value = form.valid;
  }

  void resetAfterResubmit() {
    generalError.value = null;
    isReadOnly.value = false;
  }

  static Map<String, ValidationMessageFunction> _requiredValidationMessages(
    String message,
  ) {
    return <String, ValidationMessageFunction>{
      ValidationMessage.required: (_) => message,
      blankValidationMessage: (_) => message,
    };
  }

  static Map<String, dynamic>? _trimmedRequiredValidator(
    AbstractControl<dynamic> control,
  ) {
    final String value = (control.value as String? ?? '').trim();
    if (value.isEmpty) {
      return <String, dynamic>{blankValidationMessage: true};
    }

    return null;
  }

  void dispose() {
    _formStatusSubscription?.cancel();
    _formValueSubscription?.cancel();
    briefing.dispose();
    isSubmitting.dispose();
    generalError.dispose();
    isReadOnly.dispose();
    _isFormValid.dispose();
    canSubmit.dispose();
    form.dispose();
  }
}

final briefingFormCardPresenterProvider = Provider.autoDispose
    .family<BriefingFormCardPresenter, String>((Ref ref, String analysisId) {
      final IntakeService intakeService = ref.watch(intakeServiceProvider);

      final BriefingFormCardPresenter presenter = BriefingFormCardPresenter(
        intakeService: intakeService,
        analysisId: analysisId,
      );

      unawaited(presenter.load());

      ref.onDispose(presenter.dispose);
      return presenter;
    });
