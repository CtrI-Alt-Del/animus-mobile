import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/case_assessment_briefing_dto.dart';
import 'package:animus/core/intake/dtos/case_assessment_analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/case_summary_dto.dart';
import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/core/intake/interfaces/intake_service.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/pdf_driver.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/drivers/cache/index.dart';
import 'package:animus/drivers/pdf-driver/index.dart';
import 'package:animus/rest/services/index.dart';

class CaseAssessmentAnalysisScreenPresenter {
  static const Duration pollingInterval = Duration(seconds: 3);
  static const Duration requestTimeout = Duration(seconds: 10);
  static const String failedMessage =
      'Não foi possível concluir esta etapa agora. Tente novamente.';
  static const String exportFailedMessage =
      'Não foi possível exportar o relatório agora. Tente novamente.';
  static const String loadFailedMessage =
      'Não foi possível carregar a análise agora. Tente novamente.';

  final IntakeService _intakeService;
  // ignore: unused_field
  final CacheDriver _cacheDriver;
  // ignore: unused_field
  final PdfDriver _pdfDriver;
  final String analysisId;
  bool _isDisposed = false;

  final Signal<AnalysisStatusDto> status = signal<AnalysisStatusDto>(
    AnalysisStatusDto.waitingBriefing,
  );
  final Signal<CaseAssessmentBriefingDto?> briefing =
      signal<CaseAssessmentBriefingDto?>(null);
  final Signal<CaseSummaryDto?> caseSummary = signal<CaseSummaryDto?>(null);
  final Signal<PetitionDraftDto?> petitionDraft = signal<PetitionDraftDto?>(
    null,
  );
  final Signal<String?> generalError = signal<String?>(null);
  final Signal<String> analysisName = signal<String>('Nova Análise');
  final Signal<bool> isArchived = signal<bool>(false);
  final Signal<bool> isManagingAnalysis = signal<bool>(false);
  final Signal<bool> isExportingReport = signal<bool>(false);
  final Signal<bool> precedentsReady = signal<bool>(false);
  final Signal<bool> hasChosenPrecedents = signal<bool>(false);

  late final ReadonlySignal<bool> canAnalyzeCase = computed(() {
    return briefing.value != null &&
        !isManagingAnalysis.value &&
        (status.value == AnalysisStatusDto.briefingSubmitted ||
            _isRecoverableCaseAnalysisFailure());
  });

  late final ReadonlySignal<bool> canRegenerateSummary = computed(() {
    return !isManagingAnalysis.value &&
        status.value == AnalysisStatusDto.caseAnalyzed;
  });

  late final ReadonlySignal<bool> canSearchPrecedents = computed(() {
    return !isManagingAnalysis.value &&
        status.value == AnalysisStatusDto.caseAnalyzed &&
        caseSummary.value != null;
  });

  late final ReadonlySignal<bool> canGeneratePetitionDraft = computed(() {
    return !isManagingAnalysis.value &&
        precedentsReady.value &&
        hasChosenPrecedents.value &&
        !_isPrecedentsProcessingStatus(status.value) &&
        status.value != AnalysisStatusDto.generatingPetitionDraft &&
        status.value != AnalysisStatusDto.generatingSynthesis;
  });

  late final ReadonlySignal<bool> canRegeneratePetitionDraft = computed(() {
    return !isManagingAnalysis.value &&
        status.value == AnalysisStatusDto.done &&
        hasChosenPrecedents.value &&
        petitionDraft.value != null;
  });

  late final ReadonlySignal<bool> showCaseProcessingBubble = computed(
    () => status.value == AnalysisStatusDto.analyzingCase,
  );

  late final ReadonlySignal<bool> showPetitionDraftProcessingCard = computed(
    () => status.value == AnalysisStatusDto.generatingPetitionDraft,
  );

  late final ReadonlySignal<bool> canExportReport = computed(() {
    return status.value == AnalysisStatusDto.done &&
        petitionDraft.value != null &&
        !isExportingReport.value;
  });

  late final ReadonlySignal<String> primaryActionLabel = computed(() {
    if (status.value == AnalysisStatusDto.waitingBriefing ||
        status.value == AnalysisStatusDto.briefingSubmitted) {
      return 'Analisar';
    }

    if (status.value == AnalysisStatusDto.failed) {
      if (precedentsReady.value && hasChosenPrecedents.value) {
        return 'Tentar gerar minuta novamente';
      }

      if (caseSummary.value != null) {
        return 'Tentar buscar precedentes novamente';
      }

      return 'Tentar analisar novamente';
    }

    if (status.value == AnalysisStatusDto.done) {
      return 'Regerar minuta';
    }

    if (_isPrecedentsProcessingStatus(status.value)) {
      return 'Buscando precedentes';
    }

    if (status.value == AnalysisStatusDto.generatingPetitionDraft ||
        canGeneratePetitionDraft.value ||
        precedentsReady.value) {
      return 'Gerar minuta';
    }

    if (canSearchPrecedents.value) {
      return 'Buscar precedentes';
    }

    return 'Analisar';
  });

  CaseAssessmentAnalysisScreenPresenter({
    required IntakeService intakeService,
    required CacheDriver cacheDriver,
    required PdfDriver pdfDriver,
    required this.analysisId,
  }) : _intakeService = intakeService,
       _cacheDriver = cacheDriver,
       _pdfDriver = pdfDriver;

  Future<void> load() async {
    generalError.value = null;

    final RestResponse<AnalysisDto> analysisResponse = await _intakeService
        .getAnalysis(analysisId: analysisId);

    if (analysisResponse.isFailure) {
      status.value = AnalysisStatusDto.waitingBriefing;
      generalError.value = analysisResponse.errorMessage.isNotEmpty
          ? analysisResponse.errorMessage
          : loadFailedMessage;
      return;
    }

    final AnalysisDto analysis = analysisResponse.body;
    analysisName.value = analysis.name;
    isArchived.value = analysis.isArchived;
    status.value = analysis.status;
    precedentsReady.value = _isPrecedentsReadyStatus(analysis.status);

    if (analysis.status != AnalysisStatusDto.waitingBriefing) {
      final RestResponse<CaseAssessmentBriefingDto> briefingResponse =
          await _intakeService.getCaseAssessmentBriefing(
            analysisId: analysisId,
          );
      if (briefingResponse.isSuccessful) {
        briefing.value = briefingResponse.body;
      }
    }

    if (_shouldLoadSummary(analysis.status)) {
      final RestResponse<CaseSummaryDto> summaryResponse = await _intakeService
          .getCaseSummary(analysisId: analysisId);
      if (summaryResponse.isSuccessful) {
        caseSummary.value = summaryResponse.body;
      }
    }

    if (_shouldLoadPetitionDraft(analysis.status)) {
      final bool didLoadDraft = await _tryLoadPetitionDraft();
      if (!didLoadDraft && _shouldResumePetitionDraftPolling(analysis.status)) {
        status.value = AnalysisStatusDto.generatingPetitionDraft;
        unawaited(_pollUntilPetitionDraftReady());
      }
    }

    if (analysis.status == AnalysisStatusDto.analyzingCase) {
      unawaited(_pollUntilCaseReady());
    }
  }

  void markBriefingSubmitted(CaseAssessmentBriefingDto briefing) {
    this.briefing.value = briefing;

    if (status.value == AnalysisStatusDto.waitingBriefing ||
        _isRecoverableCaseAnalysisFailure()) {
      status.value = AnalysisStatusDto.briefingSubmitted;
    }

    generalError.value = null;
  }

  Future<void> analyzeCase() async {
    if (!canAnalyzeCase.value) {
      return;
    }

    generalError.value = null;
    status.value = AnalysisStatusDto.analyzingCase;
    isManagingAnalysis.value = true;

    try {
      final RestResponse<void> response = await _intakeService
          .triggerCaseAssessmentCaseSummarization(analysisId: analysisId)
          .timeout(
            requestTimeout,
            onTimeout: () => RestResponse<void>(
              statusCode: HttpStatus.requestTimeout,
              errorMessage: _buildTimeoutMessage(),
            ),
          );

      if (response.isFailure) {
        await _applyFailure(response.errorMessage);
        return;
      }

      await _pollUntilCaseReady();
    } finally {
      isManagingAnalysis.value = false;
    }
  }

  Future<void> reanalyzeCase() async {
    if (!canRegenerateSummary.value) {
      return;
    }

    generalError.value = null;
    status.value = AnalysisStatusDto.briefingSubmitted;
    caseSummary.value = null;
    petitionDraft.value = null;
    precedentsReady.value = false;
    hasChosenPrecedents.value = false;
    await analyzeCase();
  }

  Future<void> retrySummary() async {
    if (status.value == AnalysisStatusDto.caseAnalyzed) {
      await reanalyzeCase();
      return;
    }

    if (status.value == AnalysisStatusDto.failed) {
      status.value = AnalysisStatusDto.briefingSubmitted;
      caseSummary.value = null;
      petitionDraft.value = null;
      precedentsReady.value = false;
      hasChosenPrecedents.value = false;
      await analyzeCase();
    }
  }

  void confirmAndViewPrecedents() {
    if (status.value != AnalysisStatusDto.caseAnalyzed) {
      return;
    }

    if (caseSummary.value == null) {
      generalError.value = failedMessage;
      return;
    }

    generalError.value = null;
    precedentsReady.value = false;
    hasChosenPrecedents.value = false;
    status.value = AnalysisStatusDto.searchingPrecedents;
  }

  void markPrecedentsReady() {
    precedentsReady.value = true;

    if (status.value == AnalysisStatusDto.searchingPrecedents ||
        status.value == AnalysisStatusDto.precedentsSearched ||
        status.value == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        status.value == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        status.value == AnalysisStatusDto.generatingSynthesis) {
      status.value = AnalysisStatusDto.precedentsSearched;
    }
  }

  void syncChosenPrecedents(List<AnalysisPrecedentDto> precedents) {
    hasChosenPrecedents.value = precedents.isNotEmpty;
  }

  Future<void> requestPetitionDraft({bool force = false}) async {
    if (!force &&
        !canGeneratePetitionDraft.value &&
        !canRegeneratePetitionDraft.value) {
      return;
    }

    generalError.value = null;
    status.value = AnalysisStatusDto.generatingPetitionDraft;
    isManagingAnalysis.value = true;

    try {
      final RestResponse<void> response = await _intakeService
          .triggerPetitionDraftGeneration(analysisId: analysisId)
          .timeout(
            requestTimeout,
            onTimeout: () => RestResponse<void>(
              statusCode: HttpStatus.requestTimeout,
              errorMessage: _buildTimeoutMessage(),
            ),
          );

      if (response.isFailure) {
        await _applyFailure(response.errorMessage);
        return;
      }

      await _pollUntilPetitionDraftReady();
    } finally {
      isManagingAnalysis.value = false;
    }
  }

  Future<void> regeneratePetitionDraft(String comments) async {
    if (!canRegeneratePetitionDraft.value) {
      return;
    }

    generalError.value = null;
    status.value = AnalysisStatusDto.generatingPetitionDraft;
    isManagingAnalysis.value = true;

    try {
      final RestResponse<void> response = await _intakeService
          .regeneratePetitionDraft(analysisId: analysisId, comments: comments)
          .timeout(
            requestTimeout,
            onTimeout: () => RestResponse<void>(
              statusCode: HttpStatus.requestTimeout,
              errorMessage: _buildTimeoutMessage(),
            ),
          );

      if (response.isFailure) {
        await _applyFailure(response.errorMessage);
        return;
      }

      await _pollUntilPetitionDraftReady(forceReloadOnDone: true);
    } finally {
      isManagingAnalysis.value = false;
    }
  }

  Future<bool> reloadPetitionDraft() async {
    return _tryLoadPetitionDraft();
  }

  Future<bool> renameAnalysis(String name) async {
    if (isManagingAnalysis.value || isExportingReport.value) {
      return false;
    }

    final String normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      generalError.value = 'Informe um nome válido para a análise.';
      return false;
    }

    isManagingAnalysis.value = true;
    final RestResponse<AnalysisDto> response = await _intakeService
        .renameAnalysis(analysisId: analysisId, name: normalizedName);
    isManagingAnalysis.value = false;

    if (response.isFailure) {
      generalError.value = response.errorMessage;
      return false;
    }

    analysisName.value = response.body.name;
    generalError.value = null;
    return true;
  }

  Future<bool> archiveAnalysis() async {
    if (isManagingAnalysis.value || isExportingReport.value) {
      return false;
    }

    isManagingAnalysis.value = true;
    final RestResponse<List<AnalysisDto>> response = await _intakeService
        .archiveAnalysis(analysisId: analysisId);
    isManagingAnalysis.value = false;

    if (response.isFailure) {
      generalError.value = response.errorMessage;
      return false;
    }

    final AnalysisDto? archivedAnalysis = _findArchivedAnalysis(response.body);
    if (archivedAnalysis == null) {
      generalError.value = failedMessage;
      return false;
    }

    isArchived.value = archivedAnalysis.isArchived;
    generalError.value = null;
    return true;
  }

  Future<bool> unarchiveAnalysis() async {
    if (isManagingAnalysis.value || isExportingReport.value) {
      return false;
    }

    isManagingAnalysis.value = true;
    final RestResponse<AnalysisDto> response = await _intakeService
        .unarchiveAnalysis(analysisId: analysisId);
    isManagingAnalysis.value = false;

    if (response.isFailure) {
      generalError.value = response.errorMessage;
      return false;
    }

    isArchived.value = response.body.isArchived;
    generalError.value = null;
    return true;
  }

  AnalysisDto? _findArchivedAnalysis(List<AnalysisDto> analyses) {
    for (final AnalysisDto analysis in analyses) {
      if (analysis.id == analysisId) {
        return analysis;
      }
    }

    return analyses.isEmpty ? null : analyses.first;
  }

  Future<bool> exportAnalysisReport() async {
    if (!canExportReport.value || isManagingAnalysis.value) {
      return false;
    }

    isExportingReport.value = true;
    isManagingAnalysis.value = true;
    generalError.value = null;

    try {
      final RestResponse<CaseAssessmentAnalysisReportDto> reportResponse =
          await _intakeService.getCaseAssessmentAnalysisReport(
            analysisId: analysisId,
          );

      if (reportResponse.isFailure) {
        generalError.value = exportFailedMessage;
        return false;
      }

      final CaseAssessmentAnalysisReportDto report = reportResponse.body;
      final Uint8List bytes = await _pdfDriver
          .generateCaseAssessmentAnalysisReport(report: report);
      final String filename = _buildReportFilename(report.analysis.name);

      await _pdfDriver.sharePdf(bytes: bytes, filename: filename);
      return true;
    } catch (_) {
      generalError.value = exportFailedMessage;
      return false;
    } finally {
      isManagingAnalysis.value = false;
      isExportingReport.value = false;
    }
  }

  String _buildReportFilename(String rawAnalysisName) {
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

    return '$safeName - Relatorio da Analise do Caso.pdf';
  }

  void dispose() {
    _isDisposed = true;

    status.dispose();
    briefing.dispose();
    caseSummary.dispose();
    petitionDraft.dispose();
    generalError.dispose();
    analysisName.dispose();
    isArchived.dispose();
    isManagingAnalysis.dispose();
    isExportingReport.dispose();
    precedentsReady.dispose();
    hasChosenPrecedents.dispose();
    canAnalyzeCase.dispose();
    canRegenerateSummary.dispose();
    canSearchPrecedents.dispose();
    canGeneratePetitionDraft.dispose();
    canRegeneratePetitionDraft.dispose();
    showCaseProcessingBubble.dispose();
    showPetitionDraftProcessingCard.dispose();
    canExportReport.dispose();
    primaryActionLabel.dispose();
  }

  Future<void> _pollUntilCaseReady() async {
    while (true) {
      if (_isDisposed) {
        return;
      }

      final RestResponse<AnalysisDto> analysisResponse = await _intakeService
          .getAnalysis(analysisId: analysisId)
          .timeout(
            requestTimeout,
            onTimeout: () => RestResponse<AnalysisDto>(
              statusCode: HttpStatus.requestTimeout,
              errorMessage: _buildTimeoutMessage(),
            ),
          );

      if (analysisResponse.isFailure) {
        await _applyFailure(analysisResponse.errorMessage);
        return;
      }

      final AnalysisStatusDto currentStatus = analysisResponse.body.status;
      status.value = currentStatus;

      if (currentStatus == AnalysisStatusDto.caseAnalyzed) {
        final RestResponse<CaseSummaryDto> summaryResponse =
            await _intakeService.getCaseSummary(analysisId: analysisId);

        if (summaryResponse.isFailure) {
          await _applyFailure(summaryResponse.errorMessage);
          return;
        }

        caseSummary.value = summaryResponse.body;
        precedentsReady.value = false;
        generalError.value = null;
        return;
      }

      if (currentStatus == AnalysisStatusDto.failed) {
        await _applyFailure();
        return;
      }

      await Future<void>.delayed(pollingInterval);
    }
  }

  Future<void> _pollUntilPetitionDraftReady({
    bool forceReloadOnDone = false,
  }) async {
    while (true) {
      if (_isDisposed) {
        return;
      }

      final RestResponse<AnalysisDto> analysisResponse = await _intakeService
          .getAnalysis(analysisId: analysisId)
          .timeout(
            requestTimeout,
            onTimeout: () => RestResponse<AnalysisDto>(
              statusCode: HttpStatus.requestTimeout,
              errorMessage: _buildTimeoutMessage(),
            ),
          );

      if (analysisResponse.isFailure) {
        await _applyFailure(analysisResponse.errorMessage);
        return;
      }

      final AnalysisStatusDto currentStatus = analysisResponse.body.status;

      if (currentStatus == AnalysisStatusDto.done) {
        if (!forceReloadOnDone && petitionDraft.value != null) {
          status.value = currentStatus;
          generalError.value = null;
          return;
        }

        final bool didLoadDraft = await _tryLoadPetitionDraft();
        if (!didLoadDraft) {
          status.value = AnalysisStatusDto.generatingPetitionDraft;
          await Future<void>.delayed(pollingInterval);
          continue;
        }

        status.value = currentStatus;
        generalError.value = null;
        return;
      }

      if (_shouldLoadPetitionDraft(currentStatus)) {
        await _tryLoadPetitionDraft();
      }

      status.value = _isPetitionDraftPendingStatus(currentStatus)
          ? AnalysisStatusDto.generatingPetitionDraft
          : currentStatus;

      if (currentStatus == AnalysisStatusDto.failed) {
        await _applyFailure();
        return;
      }

      await Future<void>.delayed(pollingInterval);
    }
  }

  Future<bool> _tryLoadPetitionDraft() async {
    final RestResponse<PetitionDraftDto> draftResponse = await _intakeService
        .getPetitionDraft(analysisId: analysisId);

    if (draftResponse.isFailure) {
      return false;
    }

    petitionDraft.value = draftResponse.body;
    return true;
  }

  Future<void> _applyFailure([String? message]) async {
    if (_isDisposed) {
      return;
    }

    final String errorMessage = message == null || message.isEmpty
        ? failedMessage
        : message;
    generalError.value = errorMessage;
    status.value = AnalysisStatusDto.failed;
  }

  bool _shouldLoadSummary(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.caseAnalyzed ||
        value == AnalysisStatusDto.searchingPrecedents ||
        value == AnalysisStatusDto.precedentsSearched ||
        value == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        value == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        value == AnalysisStatusDto.generatingSynthesis ||
        value == AnalysisStatusDto.generatingPetitionDraft ||
        value == AnalysisStatusDto.done;
  }

  bool _shouldLoadPetitionDraft(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.generatingPetitionDraft ||
        value == AnalysisStatusDto.done;
  }

  bool _isPetitionDraftPendingStatus(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.precedentsSearched ||
        value == AnalysisStatusDto.generatingSynthesis ||
        value == AnalysisStatusDto.generatingPetitionDraft;
  }

  bool _shouldResumePetitionDraftPolling(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.generatingPetitionDraft ||
        value == AnalysisStatusDto.done;
  }

  bool _isPrecedentsReadyStatus(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.precedentsSearched ||
        value == AnalysisStatusDto.generatingPetitionDraft ||
        value == AnalysisStatusDto.done;
  }

  bool _isPrecedentsProcessingStatus(AnalysisStatusDto value) {
    return value == AnalysisStatusDto.searchingPrecedents ||
        value == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        value == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        value == AnalysisStatusDto.generatingSynthesis;
  }

  bool _isRecoverableCaseAnalysisFailure() {
    return status.value == AnalysisStatusDto.failed &&
        briefing.value != null &&
        caseSummary.value == null &&
        petitionDraft.value == null &&
        !precedentsReady.value &&
        !hasChosenPrecedents.value;
  }

  String _buildTimeoutMessage() {
    return '$failedMessage A requisição excedeu o tempo limite de ${requestTimeout.inSeconds} segundos.';
  }
}

final caseAssessmentAnalysisScreenPresenterProvider = Provider.autoDispose
    .family<CaseAssessmentAnalysisScreenPresenter, String>((
      Ref ref,
      String analysisId,
    ) {
      final IntakeService intakeService = ref.watch(intakeServiceProvider);
      final CacheDriver cacheDriver = ref.watch(cacheDriverProvider);
      final PdfDriver pdfDriver = ref.watch(pdfDriverProvider);

      final CaseAssessmentAnalysisScreenPresenter presenter =
          CaseAssessmentAnalysisScreenPresenter(
            intakeService: intakeService,
            cacheDriver: cacheDriver,
            pdfDriver: pdfDriver,
            analysisId: analysisId,
          );

      unawaited(presenter.load());

      ref.onDispose(presenter.dispose);
      return presenter;
    });
