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

class RelevantPrecedentsBubblePresenter {
  static const Duration _pollingInterval = Duration(seconds: 3);
  static const Duration _requestRetryDelay = Duration(milliseconds: 450);
  static const int defaultLimit = 5;
  static const int minLimit = 1;
  static const int maxLimit = 20;

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
  final Signal<AnalysisPrecedentDto?> selectedPrecedent =
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
      return 'Gerando as sinteses explicativas dos precedentes.';
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

  RelevantPrecedentsBubblePresenter({
    required IntakeService intakeService,
    required this.analysisId,
    ExternalLinkDriver? externalLinkDriver,
    String? pangeaUrl,
  }) : _intakeService = intakeService,
       _externalLinkDriver = externalLinkDriver;

  Future<void> initialize() async {
    if (_isInitializing) {
      return;
    }

    _isInitializing = true;
    final int currentFlowId = ++_flowId;

    try {
      await _startFlow(currentFlowId: currentFlowId, canTriggerSearch: true);
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> retry() async {
    final int currentFlowId = ++_flowId;
    _stopPolling();
    _isPollingRequestInFlight = false;
    precedents.value = const <AnalysisPrecedentDto>[];
    selectedPrecedent.value = null;
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
    selectedCourts.value = List<CourtDto>.unmodifiable(courts);
    selectedKinds.value = List<PrecedentKindDto>.unmodifiable(kinds);
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
        (status == AnalysisStatusDto.petitionAnalyzed &&
            precedents.value.isEmpty &&
            selectedPrecedent.value == null)) {
      isLoading.value = true;
      return;
    }

    isLoading.value = false;
  }

  void choosePrecedent(AnalysisPrecedentDto precedent) {
    selectedPrecedent.value = precedent;
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
          'Nao foi possivel abrir o Pangea agora. Tente novamente.';
      return;
    }

    try {
      final Uri uri = buildPangeaUri(precedent.precedent.identifier);
      await _externalLinkDriver.openUrl(uri.toString());
    } catch (_) {
      generalError.value =
          'Nao foi possivel abrir o Pangea agora. Tente novamente.';
    }
  }

  Future<bool> confirmPrecedentChoice() async {
    final AnalysisPrecedentDto? precedent = selectedPrecedent.value;
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
          'Nao foi possivel escolher o precedente agora. Tente novamente.';
      return false;
    }

    processingStatus.value = AnalysisStatusDto.precedentChosen;
    selectedPrecedent.value = AnalysisPrecedentDto(
      analysisId: precedent.analysisId,
      precedent: precedent.precedent,
      isChosen: true,
      applicabilityPercentage: precedent.applicabilityPercentage,
      synthesis: precedent.synthesis,
    );
    precedents.value = List<AnalysisPrecedentDto>.unmodifiable(
      precedents.value.map((AnalysisPrecedentDto item) {
        final bool isSelected =
            item.precedent.identifier.court ==
                precedent.precedent.identifier.court &&
            item.precedent.identifier.kind ==
                precedent.precedent.identifier.kind &&
            item.precedent.identifier.number ==
                precedent.precedent.identifier.number;

        return AnalysisPrecedentDto(
          analysisId: item.analysisId,
          precedent: item.precedent,
          isChosen: isSelected,
          applicabilityPercentage: item.applicabilityPercentage,
          synthesis: item.synthesis,
        );
      }),
    );
    isLoading.value = false;
    generalError.value = null;
    return true;
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
    selectedPrecedent.dispose();
    loadingMessage.dispose();
    totalCount.dispose();
    showEmptyState.dispose();
    isPendingSelection.dispose();
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
        'Nao foi possivel carregar o status da analise. Tente novamente.',
      );
      return;
    }

    final AnalysisStatusDto status = analysisResponse.body.status;
    processingStatus.value = status;

    if (status == AnalysisStatusDto.petitionAnalyzed && canTriggerSearch) {
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
      _applyError('A analise falhou durante a busca de precedentes.');
      return;
    }

    _applyError('A busca de precedentes ainda nao foi iniciada.');
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
      _applyError('Nao foi possivel iniciar a busca de precedentes.');
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
        _applyError('Nao foi possivel atualizar o status dos precedentes.');
        return;
      }

      final AnalysisStatusDto status = analysisResponse.body.status;
      processingStatus.value = status;

      if (_isProcessingStatus(status) ||
          status == AnalysisStatusDto.petitionAnalyzed) {
        isLoading.value = true;
        return;
      }

      if (_isFinalPrecedentStatus(status)) {
        _stopPolling();
        await _loadPrecedents(currentFlowId: currentFlowId, status: status);
        return;
      }

      if (status == AnalysisStatusDto.failed) {
        _applyError('A analise falhou durante a busca de precedentes.');
        return;
      }

      _applyError('Nao foi possivel interpretar o status atual da analise.');
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
      _applyError('Nao foi possivel carregar os precedentes agora.');
      return;
    }

    final List<AnalysisPrecedentDto> sortedPrecedents =
        List<AnalysisPrecedentDto>.from(response.body.items)..sort(
          (AnalysisPrecedentDto left, AnalysisPrecedentDto right) => right
              .applicabilityPercentage
              .compareTo(left.applicabilityPercentage),
        );

    precedents.value = List<AnalysisPrecedentDto>.unmodifiable(
      sortedPrecedents,
    );
    processingStatus.value = status ?? processingStatus.value;

    AnalysisPrecedentDto? chosenFromApi;
    for (final AnalysisPrecedentDto precedent in sortedPrecedents) {
      if (precedent.isChosen) {
        chosenFromApi = precedent;
        break;
      }
    }

    if (chosenFromApi != null) {
      selectedPrecedent.value = chosenFromApi;
      processingStatus.value = AnalysisStatusDto.precedentChosen;
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
        status == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        status == AnalysisStatusDto.generatingSynthesis;
  }

  bool _isFinalPrecedentStatus(AnalysisStatusDto status) {
    return status == AnalysisStatusDto.waitingPrecedentChoice ||
        status == AnalysisStatusDto.precedentChosen;
  }

  bool _isPrecedentsOrchestrationStatus(AnalysisStatusDto status) {
    return status == AnalysisStatusDto.petitionAnalyzed ||
        _isProcessingStatus(status) ||
        _isFinalPrecedentStatus(status);
  }

  int _statusOrder(AnalysisStatusDto status) {
    switch (status) {
      case AnalysisStatusDto.petitionAnalyzed:
        return 0;
      case AnalysisStatusDto.searchingPrecedents:
        return 1;
      case AnalysisStatusDto.analyzingPrecedentsApplicability:
        return 2;
      case AnalysisStatusDto.generatingSynthesis:
        return 3;
      case AnalysisStatusDto.waitingPrecedentChoice:
        return 4;
      case AnalysisStatusDto.precedentChosen:
        return 5;
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

final relevantPrecedentsBubblePresenterProvider = Provider.autoDispose
    .family<RelevantPrecedentsBubblePresenter, String>((
      Ref ref,
      String analysisId,
    ) {
      final IntakeService intakeService = ref.watch(intakeServiceProvider);
      final ExternalLinkDriver externalLinkDriver = ref.watch(
        externalLinkDriverProvider,
      );

      final RelevantPrecedentsBubblePresenter presenter =
          RelevantPrecedentsBubblePresenter(
            intakeService: intakeService,
            analysisId: analysisId,
            externalLinkDriver: externalLinkDriver,
          );

      unawaited(presenter.initialize());
      ref.onDispose(presenter.dispose);
      return presenter;
    });
