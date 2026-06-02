import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedents_search_filters_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/precedent_identifier_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/external_link_driver.dart';
import 'package:animus/core/shared/responses/list_response.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/constants/env.dart';
import 'package:animus/drivers/external-link-driver/index.dart';
import 'package:animus/rest/services/index.dart';

class AnalysisPrecedentsBubblePresenter {
  static const Duration _pollingInterval = Duration(seconds: 3);
  static const Duration _requestRetryDelay = Duration(milliseconds: 450);
  static const int defaultLimit = 5;
  static const int minLimit = 1;
  static const int maxLimit = 10;
  static const int _legacyFinalRankBase = 100000;

  final IntakeService _intakeService;
  final ExternalLinkDriver? _externalLinkDriver;
  final String analysisId;

  Timer? _pollingTimer;
  int _flowId = 0;
  bool _isInitializing = false;
  bool _isPollingRequestInFlight = false;

  final Signal<List<AnalysisPrecedentDto>> precedents =
      signal<List<AnalysisPrecedentDto>>(const <AnalysisPrecedentDto>[]);
  final Signal<AnalysisStatusDto?> processingStatus =
      signal<AnalysisStatusDto?>(null);
  final Signal<bool> isLoading = signal<bool>(false);
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<int> selectedLimit = signal<int>(defaultLimit);
  final Signal<List<CourtDto>> selectedCourts = signal<List<CourtDto>>(
    const <CourtDto>[],
  );
  final Signal<List<PrecedentKindDto>> selectedKinds =
      signal<List<PrecedentKindDto>>(const <PrecedentKindDto>[]);
  final Signal<int> draftLimit = signal<int>(defaultLimit);
  final Signal<bool> isLimitDialogOpen = signal<bool>(false);
  final Signal<AnalysisPrecedentDto?> focusedPrecedent =
      signal<AnalysisPrecedentDto?>(null);

  late final ReadonlySignal<String> loadingMessage = computed(() {
    final AnalysisStatusDto? status = processingStatus.value;

    if (status == AnalysisStatusDto.searchingPrecedents) {
      return 'Buscando precedentes relevantes na base nacional.';
    }

    if (status == AnalysisStatusDto.analyzingPrecedentsApplicability) {
      return 'Analisando a proximidade e a aplicabilidade dos precedentes.';
    }

    if (status == AnalysisStatusDto.generatingSynthesis) {
      return 'Gerando as sínteses explicativas dos precedentes.';
    }

    return 'Iniciando a busca de precedentes relevantes.';
  });

  late final ReadonlySignal<int> totalCount = computed(
    () => precedents.value.length,
  );

  late final ReadonlySignal<bool> showEmptyState = computed(() {
    return !isLoading.value &&
        generalError.value == null &&
        precedents.value.isEmpty;
  });

  late final ReadonlySignal<bool> isPendingSelection = computed(() {
    return processingStatus.value != AnalysisStatusDto.precedentChosen;
  });

  late final ReadonlySignal<List<AnalysisPrecedentDto>> chosenPrecedents =
      computed(
        () => List<AnalysisPrecedentDto>.unmodifiable(
          precedents.value.where(
            (AnalysisPrecedentDto precedent) => precedent.isChosen,
          ),
        ),
      );

  late final ReadonlySignal<bool> hasChosenPrecedents = computed(
    () => chosenPrecedents.value.isNotEmpty,
  );

  AnalysisPrecedentsBubblePresenter({
    required IntakeService intakeService,
    required this.analysisId,
    ExternalLinkDriver? externalLinkDriver,
  }) : _intakeService = intakeService,
       _externalLinkDriver = externalLinkDriver;

  Future<void> initialize() async {
    if (_isInitializing) {
      return;
    }

    _isInitializing = true;
    final int currentFlowId = ++_flowId;

    try {
      await _startFlow(currentFlowId: currentFlowId, canTriggerSearch: false);
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> retry() async {
    final int currentFlowId = ++_flowId;
    _stopPolling();
    _isPollingRequestInFlight = false;
    precedents.value = const <AnalysisPrecedentDto>[];
    focusedPrecedent.value = null;
    processingStatus.value = AnalysisStatusDto.searchingPrecedents;
    generalError.value = null;
    isLoading.value = true;

    await _triggerPrecedentSearch(currentFlowId: currentFlowId);
  }

  void openLimitDialog() {
    draftLimit.value = selectedLimit.value;
    isLimitDialogOpen.value = true;
  }

  void closeLimitDialog() {
    isLimitDialogOpen.value = false;
    draftLimit.value = selectedLimit.value;
  }

  void updateSelectedLimit(int value) {
    draftLimit.value = value.clamp(minLimit, maxLimit);
  }

  Future<void> applySelectedLimit() async {
    selectedLimit.value = draftLimit.value.clamp(minLimit, maxLimit);
    isLimitDialogOpen.value = false;
  }

  void syncSelectedLimit(int value) {
    final int normalizedValue = value.clamp(minLimit, maxLimit);
    if (selectedLimit.value == normalizedValue) {
      return;
    }

    selectedLimit.value = normalizedValue;
    draftLimit.value = normalizedValue;
  }

  void syncSelectedFilters({
    required List<CourtDto> courts,
    required List<PrecedentKindDto> kinds,
  }) {
    final List<PrecedentKindDto> validKinds =
        PrecedentKindDto.getValidKindsForCourts(courts);
    final List<PrecedentKindDto> filteredKinds = kinds
        .where((PrecedentKindDto kind) => validKinds.contains(kind))
        .toList(growable: false);

    selectedCourts.value = List<CourtDto>.unmodifiable(courts);
    selectedKinds.value = List<PrecedentKindDto>.unmodifiable(filteredKinds);
  }

  Future<void> refreshProcessingStatus() async {
    await _refreshProcessingStatus(currentFlowId: _flowId);
  }

  Future<void> loadPrecedents() async {
    await _loadPrecedents(currentFlowId: _flowId);
  }

  void syncAnalysisStatus(AnalysisStatusDto status) {
    if (!_isPrecedentsOrchestrationStatus(status)) {
      return;
    }

    final AnalysisStatusDto? currentStatus = processingStatus.value;

    if (currentStatus != null &&
        _statusOrder(status) < _statusOrder(currentStatus)) {
      return;
    }

    if (currentStatus == status) {
      return;
    }

    processingStatus.value = status;

    if (_isProcessingStatus(status) ||
        (status == AnalysisStatusDto.caseAnalyzed &&
            precedents.value.isEmpty)) {
      isLoading.value = true;
      return;
    }

    isLoading.value = false;
  }

  void focusPrecedent(AnalysisPrecedentDto precedent) {
    focusedPrecedent.value = precedent;
  }

  Uri buildPangeaUri(PrecedentIdentifierDto identifier) {
    final Uri baseUri = Uri.parse(Env.pangeaUrl);
    return baseUri.replace(
      path: '/pesquisa',
      queryParameters: <String, String>{
        'orgao': identifier.court.value.toLowerCase(),
        'tipo': identifier.kind.value,
        'nr': identifier.number.toString(),
      },
    );
  }

  Future<void> openPangea(AnalysisPrecedentDto precedent) async {
    if (_externalLinkDriver == null) {
      generalError.value =
          'Não foi possível abrir o Pangea agora. Tente novamente.';
      return;
    }

    try {
      final Uri uri = buildPangeaUri(precedent.precedent.identifier);
      await _externalLinkDriver.openUrl(uri.toString());
    } catch (_) {
      generalError.value =
          'Não foi possível abrir o Pangea agora. Tente novamente.';
    }
  }

  Future<bool> confirmPrecedentChoice() async {
    final AnalysisPrecedentDto? precedent = focusedPrecedent.value;
    if (precedent == null) {
      generalError.value =
          'Selecione um precedente antes de confirmar a escolha.';
      return false;
    }

    isLoading.value = true;

    final RestResponse<AnalysisStatusDto> response =
        await _requestWithRetry<AnalysisStatusDto>(
          request: () => _intakeService.chooseAnalysisPrecedent(
            analysisId: analysisId,
            identifier: precedent.precedent.identifier,
          ),
        );

    if (response.isFailure) {
      isLoading.value = false;
      generalError.value =
          'Não foi possível escolher o precedente agora. Tente novamente.';
      return false;
    }

    processingStatus.value = AnalysisStatusDto.precedentChosen;
    focusedPrecedent.value = AnalysisPrecedentDto(
      analysisId: precedent.analysisId,
      precedent: precedent.precedent,
      isChosen: true,
      synthesis: precedent.synthesis,
      similarityScore: precedent.similarityScore,
      finalRank: precedent.finalRank,
      applicabilityLevel: precedent.applicabilityLevel,
      isManuallyAdded: precedent.isManuallyAdded,
    );
    precedents.value = List<AnalysisPrecedentDto>.unmodifiable(
      precedents.value.map((AnalysisPrecedentDto item) {
        final bool isSelected = _isSamePrecedent(item, precedent);

        return AnalysisPrecedentDto(
          analysisId: item.analysisId,
          precedent: item.precedent,
          isChosen: isSelected ? true : item.isChosen,
          synthesis: item.synthesis,
          similarityScore: item.similarityScore,
          finalRank: item.finalRank,
          applicabilityLevel: item.applicabilityLevel,
          isManuallyAdded: item.isManuallyAdded,
        );
      }),
    );
    isLoading.value = false;
    generalError.value = null;
    return true;
  }

  Future<bool> unchoosePrecedent(AnalysisPrecedentDto precedent) async {
    isLoading.value = true;

    final RestResponse<AnalysisStatusDto> response =
        await _requestWithRetry<AnalysisStatusDto>(
          request: () => _intakeService.unchooseAnalysisPrecedent(
            analysisId: analysisId,
            identifier: precedent.precedent.identifier,
          ),
        );

    if (response.isFailure) {
      isLoading.value = false;
      generalError.value =
          'Não foi possível desfazer a escolha do precedente agora. Tente novamente.';
      return false;
    }

    precedents.value = List<AnalysisPrecedentDto>.unmodifiable(
      precedents.value.map((AnalysisPrecedentDto item) {
        if (!_isSamePrecedent(item, precedent)) {
          return item;
        }

        return AnalysisPrecedentDto(
          analysisId: item.analysisId,
          precedent: item.precedent,
          isChosen: false,
          synthesis: item.synthesis,
          similarityScore: item.similarityScore,
          finalRank: item.finalRank,
          applicabilityLevel: item.applicabilityLevel,
          isManuallyAdded: item.isManuallyAdded,
        );
      }),
    );

    final AnalysisPrecedentDto? focused = focusedPrecedent.value;
    if (focused != null && _isSamePrecedent(focused, precedent)) {
      focusedPrecedent.value = AnalysisPrecedentDto(
        analysisId: focused.analysisId,
        precedent: focused.precedent,
        isChosen: false,
        synthesis: focused.synthesis,
        similarityScore: focused.similarityScore,
        finalRank: focused.finalRank,
        applicabilityLevel: focused.applicabilityLevel,
        isManuallyAdded: focused.isManuallyAdded,
      );
    }

    isLoading.value = false;
    generalError.value = null;
    return true;
  }

  Future<void> reloadPrecedents() async {
    await _loadPrecedents(currentFlowId: _flowId);
  }

  void dispose() {
    _stopPolling();
    precedents.dispose();
    processingStatus.dispose();
    isLoading.dispose();
    generalError.dispose();
    selectedLimit.dispose();
    selectedCourts.dispose();
    selectedKinds.dispose();
    draftLimit.dispose();
    isLimitDialogOpen.dispose();
    focusedPrecedent.dispose();
    loadingMessage.dispose();
    totalCount.dispose();
    showEmptyState.dispose();
    isPendingSelection.dispose();
    chosenPrecedents.dispose();
    hasChosenPrecedents.dispose();
  }

  Future<void> _startFlow({
    required int currentFlowId,
    required bool canTriggerSearch,
  }) async {
    if (currentFlowId != _flowId) {
      return;
    }

    isLoading.value = true;
    generalError.value = null;

    final RestResponse<dynamic> analysisResponse =
        await _requestWithRetry<dynamic>(
          request: () => _intakeService.getAnalysis(analysisId: analysisId),
        );

    if (currentFlowId != _flowId) {
      return;
    }

    if (analysisResponse.isFailure) {
      _applyError(
        'Não foi possível carregar o status da análise. Tente novamente.',
      );
      return;
    }

    final AnalysisStatusDto status = analysisResponse.body.status;
    processingStatus.value = status;

    if (status == AnalysisStatusDto.caseAnalyzed && canTriggerSearch) {
      await _triggerPrecedentSearch(currentFlowId: currentFlowId);
      return;
    }

    if (_isProcessingStatus(status)) {
      _startPolling(currentFlowId: currentFlowId);
      await _refreshProcessingStatus(currentFlowId: currentFlowId);
      return;
    }

    if (_isFinalPrecedentStatus(status)) {
      await _loadPrecedents(currentFlowId: currentFlowId, status: status);
      return;
    }

    if (status == AnalysisStatusDto.failed) {
      _applyError('A análise falhou durante a busca de precedentes.');
      return;
    }

    _applyError('A busca de precedentes ainda não foi iniciada.');
  }

  Future<void> _triggerPrecedentSearch({required int currentFlowId}) async {
    if (currentFlowId != _flowId) {
      return;
    }

    final RestResponse<void> searchResponse = await _requestWithRetry<void>(
      request: () => _intakeService.searchAnalysisPrecedents(
        analysisId: analysisId,
        filters: AnalysisPrecedentsSearchFiltersDto(
          courts: selectedCourts.value,
          precedentKinds: selectedKinds.value,
          limit: selectedLimit.value,
        ),
      ),
    );

    if (currentFlowId != _flowId) {
      return;
    }

    if (searchResponse.isFailure) {
      _applyError('Não foi possível iniciar a busca de precedentes.');
      return;
    }

    processingStatus.value = AnalysisStatusDto.searchingPrecedents;
    _startPolling(currentFlowId: currentFlowId);
  }

  Future<void> _refreshProcessingStatus({required int currentFlowId}) async {
    if (currentFlowId != _flowId) {
      return;
    }

    if (_isPollingRequestInFlight) {
      return;
    }

    _isPollingRequestInFlight = true;

    try {
      final RestResponse<dynamic> analysisResponse =
          await _requestWithRetry<dynamic>(
            request: () => _intakeService.getAnalysis(analysisId: analysisId),
          );

      if (currentFlowId != _flowId) {
        return;
      }

      if (analysisResponse.isFailure) {
        _applyError('Não foi possível atualizar o status dos precedentes.');
        return;
      }

      final AnalysisStatusDto status = analysisResponse.body.status;
      processingStatus.value = status;

      if (_isProcessingStatus(status) ||
          status == AnalysisStatusDto.caseAnalyzed) {
        isLoading.value = true;
        return;
      }

      if (_isFinalPrecedentStatus(status)) {
        _stopPolling();
        await _loadPrecedents(currentFlowId: currentFlowId, status: status);
        return;
      }

      if (status == AnalysisStatusDto.failed) {
        _applyError('A análise falhou durante a busca de precedentes.');
        return;
      }

      _applyError('Não foi possível interpretar o status atual da análise.');
    } finally {
      _isPollingRequestInFlight = false;
    }
  }

  Future<void> _loadPrecedents({
    required int currentFlowId,
    AnalysisStatusDto? status,
  }) async {
    if (currentFlowId != _flowId) {
      return;
    }

    isLoading.value = true;

    final RestResponse<ListResponse<AnalysisPrecedentDto>> response =
        await _requestWithRetry<ListResponse<AnalysisPrecedentDto>>(
          request: () =>
              _intakeService.listAnalysisPrecedents(analysisId: analysisId),
        );

    if (currentFlowId != _flowId) {
      return;
    }

    if (response.isFailure) {
      _applyError('Não foi possível carregar os precedentes agora.');
      return;
    }

    final List<AnalysisPrecedentDto> sortedPrecedents =
        List<AnalysisPrecedentDto>.from(response.body.items)
          ..sort(_comparePrecedents);

    precedents.value = List<AnalysisPrecedentDto>.unmodifiable(
      sortedPrecedents,
    );
    processingStatus.value = status ?? processingStatus.value;

    final AnalysisPrecedentDto? focused = focusedPrecedent.value;
    if (focused != null) {
      focusedPrecedent.value = _findMatchingPrecedent(
        source: sortedPrecedents,
        target: focused,
      );
    }

    isLoading.value = false;
    generalError.value = null;
  }

  void _startPolling({required int currentFlowId}) {
    _stopPolling();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      unawaited(_refreshProcessingStatus(currentFlowId: currentFlowId));
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  bool _isProcessingStatus(AnalysisStatusDto status) {
    return status == AnalysisStatusDto.searchingPrecedents ||
        status == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        status == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        status == AnalysisStatusDto.generatingSynthesis;
  }

  bool _isFinalPrecedentStatus(AnalysisStatusDto status) {
    return status == AnalysisStatusDto.precedentsSearched ||
        status == AnalysisStatusDto.generatingPetitionDraft ||
        status == AnalysisStatusDto.generatingJudgmentDraft ||
        status == AnalysisStatusDto.done ||
        status == AnalysisStatusDto.waitingPrecedentChoice ||
        status == AnalysisStatusDto.precedentChosen;
  }

  int _comparePrecedents(
    AnalysisPrecedentDto left,
    AnalysisPrecedentDto right,
  ) {
    final int rankComparison = _sortableFinalRank(
      left,
    ).compareTo(_sortableFinalRank(right));
    if (rankComparison != 0) {
      return rankComparison;
    }

    return right.similarityScore.compareTo(left.similarityScore);
  }

  int _sortableFinalRank(AnalysisPrecedentDto precedent) {
    if (precedent.finalRank > 0) {
      return precedent.finalRank;
    }

    return _legacyFinalRankBase -
        precedent.similarityScore.clamp(0, 100).round();
  }

  bool _isSamePrecedent(AnalysisPrecedentDto left, AnalysisPrecedentDto right) {
    return left.precedent.identifier.court ==
            right.precedent.identifier.court &&
        left.precedent.identifier.kind == right.precedent.identifier.kind &&
        left.precedent.identifier.number == right.precedent.identifier.number;
  }

  AnalysisPrecedentDto? _findMatchingPrecedent({
    required List<AnalysisPrecedentDto> source,
    required AnalysisPrecedentDto target,
  }) {
    for (final AnalysisPrecedentDto item in source) {
      if (_isSamePrecedent(item, target)) {
        return item;
      }
    }

    return null;
  }

  bool _isPrecedentsOrchestrationStatus(AnalysisStatusDto status) {
    return status == AnalysisStatusDto.caseAnalyzed ||
        _isProcessingStatus(status) ||
        _isFinalPrecedentStatus(status);
  }

  int _statusOrder(AnalysisStatusDto status) {
    switch (status) {
      case AnalysisStatusDto.caseAnalyzed:
        return 0;
      case AnalysisStatusDto.searchingPrecedents:
        return 1;
      case AnalysisStatusDto.analyzingPrecedentsApplicability:
        return 2;
      case AnalysisStatusDto.generatingSynthesis:
        return 3;
      case AnalysisStatusDto.precedentsSearched:
        return 4;
      case AnalysisStatusDto.generatingPetitionDraft:
      case AnalysisStatusDto.generatingJudgmentDraft:
        return 5;
      case AnalysisStatusDto.waitingPrecedentChoice:
        return 6;
      case AnalysisStatusDto.precedentChosen:
      case AnalysisStatusDto.done:
        return 7;
      default:
        return -1;
    }
  }

  void _applyError(String fallbackMessage) {
    _stopPolling();
    isLoading.value = false;
    generalError.value = fallbackMessage;
  }

  Future<RestResponse<T>> _requestWithRetry<T>({
    required Future<RestResponse<T>> Function() request,
  }) async {
    final RestResponse<T> firstResponse = await request();
    if (!firstResponse.isFailure) {
      return firstResponse;
    }

    await Future<void>.delayed(_requestRetryDelay);
    return request();
  }
}

final analysisPrecedentsBubblePresenterProvider = Provider.autoDispose
    .family<AnalysisPrecedentsBubblePresenter, String>((
      Ref ref,
      String analysisId,
    ) {
      final IntakeService intakeService = ref.watch(intakeServiceProvider);
      final ExternalLinkDriver externalLinkDriver = ref.watch(
        externalLinkDriverProvider,
      );

      final AnalysisPrecedentsBubblePresenter presenter =
          AnalysisPrecedentsBubblePresenter(
            intakeService: intakeService,
            analysisId: analysisId,
            externalLinkDriver: externalLinkDriver,
          );

      unawaited(presenter.initialize());
      ref.onDispose(presenter.dispose);
      return presenter;
    });
