import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/file_share_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/drivers/file-share-driver/index.dart';
import 'package:animus/drivers/file_storage/index.dart';
import 'package:animus/rest/services/index.dart';
import 'package:animus/ui/intake/widgets/components/save_status_indicator/save_status.dart';

typedef PetitionDraftDialogArgs = ({
  String analysisId,
  String analysisName,
  PetitionDraftDto initialDraft,
});

class PetitionDraftDialogPresenter {
  static const Duration autosaveDebounce = Duration(seconds: 2);
  static const String _saveFailedMessage =
      'Não foi possível salvar a minuta agora. Tente novamente.';
  static const String _closeBlockedMessage =
      'Corrija os campos obrigatórios antes de fechar a minuta.';
  static const String _exportValidationMessage =
      'Preencha todos os campos da minuta antes de exportar.';
  static const String _exportFailedMessage =
      'Não foi possível exportar a minuta agora. Tente novamente.';

  final IntakeService _intakeService;
  final FileStorageDriver _fileStorageDriver;
  final FileShareDriver _fileShareDriver;
  final String analysisId;
  final String analysisName;

  final FormGroup form = FormGroup(<String, AbstractControl<Object>>{
    'structuredFacts': FormControl<String>(
      validators: <Validator<dynamic>>[
        Validators.required,
        Validators.delegate(_nonBlankValidator),
      ],
    ),
    'legalGrounds': FormControl<String>(
      validators: <Validator<dynamic>>[
        Validators.required,
        Validators.delegate(_nonBlankValidator),
      ],
    ),
    'centralThesis': FormControl<String>(
      validators: <Validator<dynamic>>[
        Validators.required,
        Validators.delegate(_nonBlankValidator),
      ],
    ),
  });

  final Signal<List<String>> requests = signal<List<String>>(<String>[]);
  final Signal<List<String>> precedentCitations = signal<List<String>>(
    <String>[],
  );
  final Signal<SaveStatus> saveStatus = signal<SaveStatus>(SaveStatus.idle);
  final Signal<bool> isExportingDraft = signal<bool>(false);
  final Signal<String?> generalError = signal<String?>(null);

  final Signal<bool> _requestsTouched = signal<bool>(false);
  final Signal<bool> _precedentCitationsTouched = signal<bool>(false);

  PetitionDraftDto _lastSavedDraft;
  StreamSubscription<Object?>? _formValueSubscription;
  Timer? _autosaveTimer;
  Completer<void>? _saveCompleter;
  bool _isDisposed = false;
  bool _isSaving = false;
  bool _isInitialized = false;

  PetitionDraftDialogPresenter({
    required IntakeService intakeService,
    required FileStorageDriver fileStorageDriver,
    required FileShareDriver fileShareDriver,
    required this.analysisId,
    required this.analysisName,
    required PetitionDraftDto initialDraft,
  }) : _intakeService = intakeService,
       _fileStorageDriver = fileStorageDriver,
       _fileShareDriver = fileShareDriver,
       _lastSavedDraft = initialDraft {
    form.patchValue(<String, Object?>{
      'structuredFacts': initialDraft.structuredFacts,
      'legalGrounds': initialDraft.legalGrounds,
      'centralThesis': initialDraft.centralThesis,
    });
    requests.value = _normalizeItems(initialDraft.requests);
    precedentCitations.value = _normalizeItems(initialDraft.precedentCitations);
  }

  PetitionDraftDto get currentDraft {
    return PetitionDraftDto(
      analysisId: analysisId,
      structuredFacts: (form.control('structuredFacts').value as String? ?? '')
          .trim(),
      legalGrounds: (form.control('legalGrounds').value as String? ?? '')
          .trim(),
      centralThesis: (form.control('centralThesis').value as String? ?? '')
          .trim(),
      requests: requests.value
          .map((String item) => item.trim())
          .toList(growable: false),
      precedentCitations: precedentCitations.value
          .map((String item) => item.trim())
          .toList(growable: false),
    );
  }

  bool get canRemoveRequests => requests.value.length > 1;

  bool get canRemovePrecedentCitations => precedentCitations.value.length > 1;

  bool get canExportDraft =>
      !isExportingDraft.value &&
      saveStatus.value != SaveStatus.saving &&
      _isDraftValid();

  void init() {
    if (_isInitialized) {
      return;
    }

    _isInitialized = true;
    _formValueSubscription = form.valueChanges.listen((_) {
      _handleDraftChanged();
    });
  }

  void addRequest() {
    _requestsTouched.value = true;
    _updateRequests(<String>[...requests.value, '']);
  }

  void removeRequest(int index) {
    _requestsTouched.value = true;
    if (!canRemoveRequests || index < 0 || index >= requests.value.length) {
      return;
    }

    final List<String> nextItems = List<String>.from(requests.value)
      ..removeAt(index);
    _updateRequests(nextItems);
  }

  void updateRequest(int index, String value) {
    _requestsTouched.value = true;
    if (index < 0 || index >= requests.value.length) {
      return;
    }

    final List<String> nextItems = List<String>.from(requests.value);
    nextItems[index] = value;
    _updateRequests(nextItems);
  }

  void addPrecedentCitation() {
    _precedentCitationsTouched.value = true;
    _updatePrecedentCitations(<String>[...precedentCitations.value, '']);
  }

  void removePrecedentCitation(int index) {
    _precedentCitationsTouched.value = true;
    if (!canRemovePrecedentCitations ||
        index < 0 ||
        index >= precedentCitations.value.length) {
      return;
    }

    final List<String> nextItems = List<String>.from(precedentCitations.value)
      ..removeAt(index);
    _updatePrecedentCitations(nextItems);
  }

  void updatePrecedentCitation(int index, String value) {
    _precedentCitationsTouched.value = true;
    if (index < 0 || index >= precedentCitations.value.length) {
      return;
    }

    final List<String> nextItems = List<String>.from(precedentCitations.value);
    nextItems[index] = value;
    _updatePrecedentCitations(nextItems);
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

    if (listFieldName == null) {
      return null;
    }

    final List<String> items = listFieldName == 'requests'
        ? requests.value
        : precedentCitations.value;
    final bool isTouched = listFieldName == 'requests'
        ? _requestsTouched.value
        : _precedentCitationsTouched.value;

    if (!isTouched) {
      return null;
    }

    if (index != null) {
      if (index < 0 || index >= items.length || !_isBlank(items[index])) {
        return null;
      }

      return 'Campo obrigatório.';
    }

    if (items.isEmpty) {
      return 'Adicione pelo menos um item.';
    }

    if (items.any(_isBlank)) {
      return 'Preencha todos os itens.';
    }

    return null;
  }

  Future<bool> flushPendingChanges() async {
    _autosaveTimer?.cancel();

    if (_draftsEqual(_lastSavedDraft, currentDraft)) {
      return true;
    }

    _touchAllFields();
    if (!_isDraftValid()) {
      generalError.value = _closeBlockedMessage;
      saveStatus.value = SaveStatus.idle;
      return false;
    }

    await _save();
    return _draftsEqual(_lastSavedDraft, currentDraft);
  }

  Future<bool> exportPetitionDraft() async {
    if (isExportingDraft.value) {
      return false;
    }

    _autosaveTimer?.cancel();
    _touchAllFields();

    if (!_isDraftValid()) {
      generalError.value = _exportValidationMessage;
      saveStatus.value = SaveStatus.idle;
      return false;
    }

    await _save();
    if (!_draftsEqual(_lastSavedDraft, currentDraft)) {
      generalError.value = _saveFailedMessage;
      return false;
    }

    isExportingDraft.value = true;
    generalError.value = null;

    try {
      final RestResponse<AnalysisDocumentDto> response = await _intakeService
          .exportPetitionDraft(analysisId: analysisId);

      if (response.isFailure || response.body.filePath.trim().isEmpty) {
        generalError.value = response.errorMessage;
        return false;
      }

      final File? file = await _fileStorageDriver.getFile(
        response.body.filePath,
      );

      if (file == null) {
        generalError.value = _exportFailedMessage;
        return false;
      }

      final String filename = _buildDraftFilename(analysisName);
      final File shareableFile = await _prepareShareableFile(
        source: file,
        filename: filename,
      );

      await _fileShareDriver.shareFile(file: shareableFile, filename: filename);
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
    requests.dispose();
    precedentCitations.dispose();
    saveStatus.dispose();
    isExportingDraft.dispose();
    generalError.dispose();
    _requestsTouched.dispose();
    _precedentCitationsTouched.dispose();
  }

  void _updateRequests(List<String> items) {
    requests.value = List<String>.unmodifiable(items);
    _handleDraftChanged();
  }

  void _updatePrecedentCitations(List<String> items) {
    precedentCitations.value = List<String>.unmodifiable(items);
    _handleDraftChanged();
  }

  void _handleDraftChanged() {
    if (_isDisposed) {
      return;
    }

    if (!_isSaving) {
      saveStatus.value = SaveStatus.idle;
    }

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
      saveStatus.value = SaveStatus.idle;
      return;
    }

    final PetitionDraftDto draft = currentDraft;
    if (_draftsEqual(_lastSavedDraft, draft)) {
      return;
    }

    _isSaving = true;
    _saveCompleter = Completer<void>();
    saveStatus.value = SaveStatus.saving;

    try {
      final RestResponse<PetitionDraftDto> response = await _intakeService
          .updatePetitionDraft(analysisId: analysisId, draft: draft);

      if (_isDisposed) {
        return;
      }

      if (response.isFailure) {
        saveStatus.value = SaveStatus.error;
        generalError.value = _saveFailedMessage;
        return;
      }

      _lastSavedDraft = response.body;
      generalError.value = null;
      saveStatus.value = SaveStatus.saved;

      if (!_draftsEqual(_lastSavedDraft, currentDraft)) {
        saveStatus.value = SaveStatus.idle;
        _scheduleAutosave();
      }
    } catch (_) {
      if (!_isDisposed) {
        saveStatus.value = SaveStatus.error;
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
    _requestsTouched.value = true;
    _precedentCitationsTouched.value = true;
  }

  bool _isDraftValid() {
    return form.valid &&
        _isValidList(requests.value) &&
        _isValidList(precedentCitations.value);
  }

  bool _isValidList(List<String> items) {
    return items.isNotEmpty && items.every((String item) => !_isBlank(item));
  }

  bool _draftsEqual(PetitionDraftDto left, PetitionDraftDto right) {
    return left.analysisId == right.analysisId &&
        left.structuredFacts == right.structuredFacts &&
        left.legalGrounds == right.legalGrounds &&
        left.centralThesis == right.centralThesis &&
        _listsEqual(left.requests, right.requests) &&
        _listsEqual(left.precedentCitations, right.precedentCitations);
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

  Future<File> _prepareShareableFile({
    required File source,
    required String filename,
  }) async {
    final String targetPath =
        '${Directory.systemTemp.path}${Platform.pathSeparator}$filename';
    if (source.path == targetPath) {
      return source;
    }

    final File targetFile = File(targetPath);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    return source.copy(targetPath);
  }

  String _buildDraftFilename(String rawAnalysisName) {
    final String normalizedName = rawAnalysisName.trim();
    final String fallbackName = 'Analise-$analysisId';
    final String baseName = normalizedName.isEmpty
        ? fallbackName
        : normalizedName;
    final String sanitizedName = baseName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final String safeName = sanitizedName.isEmpty
        ? fallbackName
        : sanitizedName;

    return '$safeName — Minuta.docx';
  }

  List<String> _normalizeItems(List<String> items) {
    if (items.isEmpty) {
      return const <String>[''];
    }

    return List<String>.unmodifiable(items);
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

final petitionDraftDialogPresenterProvider = Provider.autoDispose
    .family<PetitionDraftDialogPresenter, PetitionDraftDialogArgs>((
      Ref ref,
      PetitionDraftDialogArgs args,
    ) {
      final IntakeService intakeService = ref.watch(intakeServiceProvider);
      final FileStorageDriver fileStorageDriver = ref.watch(
        fileStorageDriverProvider,
      );
      final FileShareDriver fileShareDriver = ref.watch(
        fileShareDriverProvider,
      );

      final PetitionDraftDialogPresenter presenter =
          PetitionDraftDialogPresenter(
            intakeService: intakeService,
            fileStorageDriver: fileStorageDriver,
            fileShareDriver: fileShareDriver,
            analysisId: args.analysisId,
            analysisName: args.analysisName,
            initialDraft: args.initialDraft,
          );

      presenter.init();
      ref.onDispose(presenter.dispose);
      return presenter;
    });
