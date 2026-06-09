import 'dart:async';
import 'dart:io';

import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_judgment_draft_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/file_share_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/drivers/file-share-driver/index.dart';
import 'package:animus/drivers/file_storage/index.dart';
import 'package:animus/rest/services/index.dart';
import 'package:animus/ui/intake/widgets/components/save_status_indicator/save_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

typedef JudgmentDraftDialogArgs = ({
  String analysisId,
  SecondInstanceJudgmentDraftDto initialDraft,
  void Function(SecondInstanceJudgmentDraftDto draft)? onDraftUpdated,
});

class JudgmentDraftDialogPresenter {
  static const Duration autosaveDebounce = Duration(seconds: 1);
  static const String _saveFailedMessage =
      'Não foi possível salvar a minuta agora. Tente novamente.';
  static const String _closeBlockedMessage =
      'Corrija os campos obrigatórios antes de fechar a minuta.';
  static const String _exportFailedMessage =
      'Não foi possível exportar a minuta agora. Tente novamente.';

  final IntakeService _intakeService;
  final FileStorageDriver _fileStorageDriver;
  final FileShareDriver _fileShareDriver;
  final void Function(SecondInstanceJudgmentDraftDto draft)? _onDraftUpdated;
  final String analysisId;

  final FormGroup form = FormGroup(<String, AbstractControl<Object>>{
    'report': FormControl<String>(
      validators: <Validator<dynamic>>[
        Validators.required,
        Validators.delegate(_nonBlankValidator),
      ],
    ),
    'preliminary_issues': FormControl<String>(),
    'merit_analysis': FormControl<String>(
      validators: <Validator<dynamic>>[
        Validators.required,
        Validators.delegate(_nonBlankValidator),
      ],
    ),
    'precedent_adherence': FormControl<String>(
      validators: <Validator<dynamic>>[
        Validators.required,
        Validators.delegate(_nonBlankValidator),
      ],
    ),
    'no_applicable_notice': FormControl<String>(),
  });

  final Signal<List<String>> ruling = signal<List<String>>(<String>[]);
  final Signal<SaveStatus> saveStatus = signal<SaveStatus>(SaveStatus.idle);
  final Signal<bool> isExportingDraft = signal<bool>(false);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<String?> saveError = signal<String?>(null);

  final Signal<bool> _rulingTouched = signal<bool>(false);

  SecondInstanceJudgmentDraftDto _lastSavedDraft;
  StreamSubscription<Object?>? _formValueSubscription;
  Timer? _autosaveTimer;
  Completer<void>? _saveCompleter;
  bool _isDisposed = false;
  bool _isSaving = false;
  bool _isInitialized = false;

  JudgmentDraftDialogPresenter({
    required IntakeService intakeService,
    required FileStorageDriver fileStorageDriver,
    required FileShareDriver fileShareDriver,
    required this.analysisId,
    required SecondInstanceJudgmentDraftDto initialDraft,
    void Function(SecondInstanceJudgmentDraftDto draft)? onDraftUpdated,
  }) : _intakeService = intakeService,
       _fileStorageDriver = fileStorageDriver,
       _fileShareDriver = fileShareDriver,
       _onDraftUpdated = onDraftUpdated,
       _lastSavedDraft = _normalizeDraft(initialDraft, analysisId) {
    form.patchValue(<String, Object?>{
      'report': _lastSavedDraft.report,
      'preliminary_issues': _lastSavedDraft.preliminaryIssues,
      'merit_analysis': _lastSavedDraft.meritAnalysis,
      'precedent_adherence': _lastSavedDraft.precedentAdherenceAnalysis,
      'no_applicable_notice': _lastSavedDraft.noApplicablePrecedentNotice,
    });
    ruling.value = _normalizeItems(_lastSavedDraft.ruling);
  }

  SecondInstanceJudgmentDraftDto get currentDraft {
    return SecondInstanceJudgmentDraftDto(
      analysisId: analysisId,
      report: _requiredValue('report'),
      preliminaryIssues: _optionalValue('preliminary_issues'),
      meritAnalysis: _requiredValue('merit_analysis'),
      precedentAdherenceAnalysis: _requiredValue('precedent_adherence'),
      ruling: ruling.value
          .map((String item) => item.trim())
          .toList(growable: false),
      noApplicablePrecedentNotice: _optionalValue('no_applicable_notice'),
    );
  }

  bool get canRemoveRulingItems => ruling.value.length > 1;

  void init() {
    if (_isInitialized) {
      return;
    }

    _isInitialized = true;
    _formValueSubscription = form.valueChanges.listen((_) {
      _handleDraftChanged();
    });
  }

  void addRulingItem() {
    _rulingTouched.value = true;
    _updateRuling(<String>[...ruling.value, '']);
  }

  void removeRulingItem(int index) {
    _rulingTouched.value = true;
    if (!canRemoveRulingItems || index < 0 || index >= ruling.value.length) {
      return;
    }

    final List<String> nextItems = List<String>.from(ruling.value)
      ..removeAt(index);
    _updateRuling(nextItems);
  }

  void updateRulingItem(int index, String value) {
    _rulingTouched.value = true;
    if (index < 0 || index >= ruling.value.length) {
      return;
    }

    final List<String> nextItems = List<String>.from(ruling.value);
    nextItems[index] = value;
    _updateRuling(nextItems);
  }

  String? fieldErrorMessage({
    FormControl<Object?>? control,
    String? listFieldName,
    int? index,
  }) {
    if (control != null) {
      if (!control.invalid || (!control.touched && !control.dirty)) {
        return null;
      }

      if (control.hasError(ValidationMessage.required)) {
        return 'Campo obrigatório.';
      }

      return 'Campo inválido.';
    }

    if (listFieldName != 'ruling' || !_rulingTouched.value) {
      return null;
    }

    if (index != null) {
      if (index < 0 ||
          index >= ruling.value.length ||
          !_isBlank(ruling.value[index])) {
        return null;
      }

      return 'Campo obrigatório.';
    }

    if (ruling.value.isEmpty) {
      return 'Adicione pelo menos um item.';
    }

    if (ruling.value.any(_isBlank)) {
      return 'Preencha todos os itens.';
    }

    return null;
  }

  Future<bool> flush() async {
    _autosaveTimer?.cancel();

    if (_draftsEqual(_lastSavedDraft, currentDraft)) {
      return true;
    }

    _touchAllFields();
    if (!_isDraftValid()) {
      saveError.value = null;
      generalError.value = _closeBlockedMessage;
      saveStatus.value = SaveStatus.idle;
      return false;
    }

    await _save();
    return _draftsEqual(_lastSavedDraft, currentDraft);
  }

  Future<bool> retrySave() async {
    _autosaveTimer?.cancel();
    _touchAllFields();

    if (!_isDraftValid()) {
      saveError.value = null;
      saveStatus.value = SaveStatus.idle;
      return false;
    }

    await _save();
    return _draftsEqual(_lastSavedDraft, currentDraft);
  }

  Future<bool> exportJudgmentDraft() async {
    if (isExportingDraft.value) {
      return false;
    }

    isExportingDraft.value = true;
    generalError.value = null;

    try {
      final RestResponse<AnalysisDocumentDto> response = await _intakeService
          .exportJudgmentDraft(analysisId: analysisId);

      if (response.isFailure || response.body.filePath.trim().isEmpty) {
        generalError.value = _exportFailedMessage;
        return false;
      }

      final File? file = await _fileStorageDriver.getFile(
        response.body.filePath,
      );
      if (file == null) {
        generalError.value = _exportFailedMessage;
        return false;
      }

      final String filename = _buildDraftFilename();
      await _fileShareDriver.shareFile(file: file, filename: filename);
      generalError.value = null;
      return true;
    } catch (_) {
      generalError.value = _exportFailedMessage;
      return false;
    } finally {
      isExportingDraft.value = false;
    }
  }

  void dispose() {
    _isDisposed = true;
    _autosaveTimer?.cancel();
    _formValueSubscription?.cancel();
    form.dispose();
    ruling.dispose();
    saveStatus.dispose();
    isExportingDraft.dispose();
    generalError.dispose();
    saveError.dispose();
    _rulingTouched.dispose();
  }

  String _buildDraftFilename() {
    return 'Analise-$analysisId - Minuta de Sentenca.docx';
  }

  void _updateRuling(List<String> items) {
    ruling.value = List<String>.unmodifiable(items);
    _handleDraftChanged();
  }

  void _handleDraftChanged() {
    if (_isDisposed) {
      return;
    }

    if (!_isSaving) {
      saveStatus.value = SaveStatus.idle;
    }

    saveError.value = null;
    generalError.value = null;
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(autosaveDebounce, () {
      unawaited(_save());
    });
  }

  Future<void> _save() async {
    if (_isDisposed) {
      return;
    }

    if (_isSaving) {
      await _saveCompleter?.future;
      return;
    }

    _touchAllFields();
    if (!_isDraftValid()) {
      saveError.value = null;
      saveStatus.value = SaveStatus.idle;
      return;
    }

    final SecondInstanceJudgmentDraftDto draft = currentDraft;
    if (_draftsEqual(_lastSavedDraft, draft)) {
      return;
    }

    _isSaving = true;
    _saveCompleter = Completer<void>();
    saveStatus.value = SaveStatus.saving;

    try {
      final RestResponse<SecondInstanceJudgmentDraftDto> response =
          await _intakeService.updateSecondInstanceJudgmentDraft(
            analysisId: analysisId,
            dto: draft,
          );

      if (_isDisposed) {
        return;
      }

      if (response.isFailure) {
        saveStatus.value = SaveStatus.error;
        saveError.value = _saveFailedMessage;
        generalError.value = _saveFailedMessage;
        return;
      }

      _lastSavedDraft = _normalizeDraft(response.body, analysisId);
      saveError.value = null;
      generalError.value = null;
      saveStatus.value = SaveStatus.saved;
      _onDraftUpdated?.call(_lastSavedDraft);

      if (!_draftsEqual(_lastSavedDraft, currentDraft)) {
        saveStatus.value = SaveStatus.idle;
        _scheduleAutosave();
      }
    } catch (_) {
      if (!_isDisposed) {
        saveStatus.value = SaveStatus.error;
        saveError.value = _saveFailedMessage;
        generalError.value = _saveFailedMessage;
      }
    } finally {
      _isSaving = false;
      _saveCompleter?.complete();
      _saveCompleter = null;
    }
  }

  void _touchAllFields() {
    form.markAllAsTouched();
    _rulingTouched.value = true;
  }

  bool _isDraftValid() {
    return form.valid && _isValidList(ruling.value);
  }

  bool _isValidList(List<String> items) {
    return items.isNotEmpty && items.every((String item) => !_isBlank(item));
  }

  bool _draftsEqual(
    SecondInstanceJudgmentDraftDto left,
    SecondInstanceJudgmentDraftDto right,
  ) {
    return left.analysisId == right.analysisId &&
        left.report == right.report &&
        left.preliminaryIssues == right.preliminaryIssues &&
        left.meritAnalysis == right.meritAnalysis &&
        left.precedentAdherenceAnalysis == right.precedentAdherenceAnalysis &&
        left.noApplicablePrecedentNotice == right.noApplicablePrecedentNotice &&
        _listsEqual(left.ruling, right.ruling);
  }

  bool _listsEqual(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }

    for (int index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }

    return true;
  }

  String _requiredValue(String controlName) {
    return (form.control(controlName).value as String? ?? '').trim();
  }

  String? _optionalValue(String controlName) {
    final String value = (form.control(controlName).value as String? ?? '')
        .trim();
    if (value.isEmpty) {
      return null;
    }

    return value;
  }

  static SecondInstanceJudgmentDraftDto _normalizeDraft(
    SecondInstanceJudgmentDraftDto draft,
    String analysisId,
  ) {
    return SecondInstanceJudgmentDraftDto(
      analysisId: analysisId,
      report: draft.report.trim(),
      preliminaryIssues: _normalizeOptionalText(draft.preliminaryIssues),
      meritAnalysis: draft.meritAnalysis.trim(),
      precedentAdherenceAnalysis: draft.precedentAdherenceAnalysis.trim(),
      ruling: draft.ruling
          .map((String item) => item.trim())
          .toList(growable: false),
      noApplicablePrecedentNotice: _normalizeOptionalText(
        draft.noApplicablePrecedentNotice,
      ),
    );
  }

  static String? _normalizeOptionalText(String? value) {
    final String normalized = (value ?? '').trim();
    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  List<String> _normalizeItems(List<String> items) {
    if (items.isEmpty) {
      return const <String>[''];
    }

    return List<String>.unmodifiable(
      items.map((String item) => item.trim()).toList(growable: false),
    );
  }

  static Map<String, dynamic>? _nonBlankValidator(
    AbstractControl<dynamic> control,
  ) {
    final String value = (control.value as String? ?? '').trim();
    if (value.isEmpty) {
      return <String, dynamic>{ValidationMessage.required: true};
    }

    return null;
  }

  bool _isBlank(String value) => value.trim().isEmpty;
}

final judgmentDraftDialogPresenterProvider = Provider.autoDispose
    .family<JudgmentDraftDialogPresenter, JudgmentDraftDialogArgs>((
      Ref ref,
      JudgmentDraftDialogArgs args,
    ) {
      final IntakeService intakeService = ref.watch(intakeServiceProvider);
      final FileStorageDriver fileStorageDriver = ref.watch(
        fileStorageDriverProvider,
      );
      final FileShareDriver fileShareDriver = ref.watch(
        fileShareDriverProvider,
      );

      final JudgmentDraftDialogPresenter presenter =
          JudgmentDraftDialogPresenter(
            intakeService: intakeService,
            fileStorageDriver: fileStorageDriver,
            fileShareDriver: fileShareDriver,
            analysisId: args.analysisId,
            initialDraft: args.initialDraft,
            onDraftUpdated: args.onDraftUpdated,
          );

      presenter.init();
      ref.onDispose(presenter.dispose);
      return presenter;
    });
