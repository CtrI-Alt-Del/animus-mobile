import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/constants/routes.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/case_assessment_briefing_dto.dart';
import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/components/ai_bubble/index.dart';
import 'package:animus/ui/intake/widgets/components/analysis_action_bar/index.dart';
import 'package:animus/ui/intake/widgets/components/analysis_header/archive_analysis_dialog/index.dart';
import 'package:animus/ui/intake/widgets/components/analysis_header/index.dart';
import 'package:animus/ui/intake/widgets/components/analysis_header/rename_analysis_dialog/index.dart';
import 'package:animus/ui/intake/widgets/components/analysis_header/unarchive_analysis_dialog/index.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_presenter.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/index.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/precedents_filters_dialog/index.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/precedents_limit_dialog/index.dart';
import 'package:animus/ui/intake/widgets/components/case_summary_card/index.dart';
import 'package:animus/ui/intake/widgets/components/message_box/index.dart';
import 'package:animus/ui/intake/widgets/components/regenerate_draft_dialog/index.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/index.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/generate_petition_draft_card/index.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/index.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/index.dart';
import 'package:animus/ui/intake/widgets/pages/first_instance_analysis_screen/dot_grid_background/index.dart';
import 'package:animus/ui/intake/widgets/pages/first_instance_analysis_screen/precedent_dialog/index.dart';

class CaseAssessmentAnalysisScreenView extends ConsumerStatefulWidget {
  final String analysisId;

  const CaseAssessmentAnalysisScreenView({required this.analysisId, super.key});

  @override
  ConsumerState<CaseAssessmentAnalysisScreenView> createState() =>
      _CaseAssessmentAnalysisScreenViewState();
}

class _CaseAssessmentAnalysisScreenViewState
    extends ConsumerState<CaseAssessmentAnalysisScreenView> {
  final ScrollController _scrollController = ScrollController();
  bool _wasShowingCaseProcessing = false;
  bool _wasShowingDraftProcessing = false;

  void _syncChosenPrecedentsIfNeeded(
    CaseAssessmentAnalysisScreenPresenter presenter,
    List<AnalysisPrecedentDto> chosenPrecedents,
  ) {
    presenter.syncChosenPrecedents(chosenPrecedents);
  }

  Widget _animatedEntry(
    Widget child, {
    Duration duration = const Duration(milliseconds: 260),
  }) {
    return child
        .animate()
        .fadeIn(duration: duration)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }

  void _jumpToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _scheduleJumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _jumpToBottom();
      Future<void>.delayed(const Duration(milliseconds: 80), () {
        if (!mounted) {
          return;
        }

        _jumpToBottom();
      });
    });
  }

  bool _isPrecedentsFlow(AnalysisStatusDto status) {
    return status == AnalysisStatusDto.searchingPrecedents ||
        status == AnalysisStatusDto.precedentsSearched ||
        status == AnalysisStatusDto.analyzingPrecedentsSimilarity ||
        status == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        status == AnalysisStatusDto.generatingSynthesis ||
        status == AnalysisStatusDto.generatingPetitionDraft ||
        status == AnalysisStatusDto.done;
  }

  Future<void> _showPrecedentDialog(
    BuildContext context,
    AnalysisPrecedentDto precedent,
  ) async {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) {
          return PrecedentDialog(
            analysisId: widget.analysisId,
            precedent: precedent,
          );
        },
      ),
    );
  }

  Future<void> _showPetitionDraftDialog(
    BuildContext context,
    CaseAssessmentAnalysisScreenPresenter presenter,
    PetitionDraftDto draft,
  ) async {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) {
          return PetitionDraftDialog(
            analysisId: widget.analysisId,
            analysisName: presenter.analysisName.value,
            initialDraft: draft,
            onRegenerate: () {
              return _showRegeneratePetitionDraftDialog(context, presenter);
            },
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    await presenter.reloadPetitionDraft();
  }

  Future<bool> _showRegeneratePetitionDraftDialog(
    BuildContext context,
    CaseAssessmentAnalysisScreenPresenter presenter,
  ) async {
    final bool? didConfirm = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x99000000),
      builder: (BuildContext context) {
        return RegenerateDraftDialog(
          title: 'Regerar minuta de petição',
          description:
              'Descreva quais ajustes você deseja para gerar uma nova versão da minuta. Ao confirmar, a nova geração substituirá a versão editada manualmente.',
          textFieldLabel: 'O que deseja alterar?',
          confirmLabel: 'Confirmar',
          onConfirm: presenter.regeneratePetitionDraft,
        );
      },
    );

    if (didConfirm != true) {
      return false;
    }

    _scheduleJumpToBottom();
    return true;
  }

  Future<void> _submitBriefingAndAnalyze(
    CaseAssessmentAnalysisScreenPresenter presenter,
  ) async {
    if (presenter.status.value == AnalysisStatusDto.waitingBriefing) {
      final BriefingFormCardPresenter briefingPresenter = ref.read(
        briefingFormCardPresenterProvider(widget.analysisId),
      );
      final CaseAssessmentBriefingDto? briefing = await briefingPresenter
          .submitBriefing();

      if (briefing == null) {
        return;
      }

      presenter.markBriefingSubmitted(briefing);
    }

    await presenter.analyzeCase();

    if (!mounted) {
      return;
    }

    _scheduleJumpToBottom();
  }

  Future<void> _showPrecedentsLimitDialog(
    BuildContext context,
    AnalysisPrecedentsBubblePresenter presenter,
  ) async {
    int selectedLimit = presenter.selectedLimit.value;

    final int? newLimit = await showDialog<int>(
      context: context,
      barrierColor:
          (Theme.of(context).extension<AppThemeTokens>()?.scrim ??
          AppTheme.tokens.scrim),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return PrecedentsLimitDialog(
              currentValue: selectedLimit,
              minValue: AnalysisPrecedentsBubblePresenter.minLimit,
              maxValue: AnalysisPrecedentsBubblePresenter.maxLimit,
              onChanged: (int value) {
                setState(() {
                  selectedLimit = value;
                });
              },
              onCancel: () => Navigator.of(context).pop(),
              onApply: () => Navigator.of(context).pop(selectedLimit),
            );
          },
        );
      },
    );

    if (newLimit == null || newLimit == presenter.selectedLimit.value) {
      return;
    }

    presenter.syncSelectedLimit(newLimit);
  }

  Future<void> _showPrecedentsFiltersDialog(
    BuildContext context,
    AnalysisPrecedentsBubblePresenter presenter,
  ) async {
    List<CourtDto> selectedCourts = List<CourtDto>.from(
      presenter.selectedCourts.value,
    );
    List<PrecedentKindDto> selectedKinds = List<PrecedentKindDto>.from(
      presenter.selectedKinds.value,
    );

    final ({List<CourtDto> courts, List<PrecedentKindDto> kinds})? result =
        await showDialog<
          ({List<CourtDto> courts, List<PrecedentKindDto> kinds})
        >(
          context: context,
          barrierColor:
              (Theme.of(context).extension<AppThemeTokens>()?.scrim ??
              AppTheme.tokens.scrim),
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return PrecedentsFiltersDialog(
                  selectedCourts: selectedCourts,
                  selectedKinds: selectedKinds,
                  onToggleCourt: (CourtDto court) {
                    setState(() {
                      if (selectedCourts.contains(court)) {
                        selectedCourts.remove(court);
                      } else {
                        selectedCourts.add(court);
                      }
                    });
                  },
                  onToggleKind: (PrecedentKindDto kind) {
                    setState(() {
                      if (selectedKinds.contains(kind)) {
                        selectedKinds.remove(kind);
                      } else {
                        selectedKinds.add(kind);
                      }
                    });
                  },
                  onClear: () {
                    setState(() {
                      selectedCourts = <CourtDto>[];
                      selectedKinds = <PrecedentKindDto>[];
                    });
                  },
                  onApply: () {
                    Navigator.of(context).pop((
                      courts: List<CourtDto>.from(selectedCourts),
                      kinds: List<PrecedentKindDto>.from(selectedKinds),
                    ));
                  },
                );
              },
            );
          },
        );

    if (result == null) {
      return;
    }

    final bool didChangeCourts =
        result.courts.length != presenter.selectedCourts.value.length ||
        !result.courts.every(presenter.selectedCourts.value.contains);
    final bool didChangeKinds =
        result.kinds.length != presenter.selectedKinds.value.length ||
        !result.kinds.every(presenter.selectedKinds.value.contains);

    if (!didChangeCourts && !didChangeKinds) {
      return;
    }

    presenter.syncSelectedFilters(courts: result.courts, kinds: result.kinds);
  }

  Future<void> _handleExportReport(
    BuildContext context,
    CaseAssessmentAnalysisScreenPresenter presenter,
  ) async {
    final bool exported = await presenter.exportAnalysisReport();
    if (!mounted || !context.mounted || !exported) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Relatório exportado com sucesso.'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CaseAssessmentAnalysisScreenPresenter presenter = ref.watch(
      caseAssessmentAnalysisScreenPresenterProvider(widget.analysisId),
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return Scaffold(
      backgroundColor: tokens.surfacePage,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints viewport) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints.tightFor(
                  width: viewport.maxWidth > 402 ? 402 : viewport.maxWidth,
                  height: viewport.maxHeight,
                ),
                child: Stack(
                  children: <Widget>[
                    const Positioned.fill(child: DotGridBackground()),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Watch((BuildContext context) {
                          final String analysisName = presenter.analysisName
                              .watch(context);
                          final bool isArchived = presenter.isArchived.watch(
                            context,
                          );
                          final bool isManaging = presenter.isManagingAnalysis
                              .watch(context);
                          final bool isExportingReport = presenter
                              .isExportingReport
                              .watch(context);
                          final AnalysisStatusDto status = presenter.status
                              .watch(context);
                          final bool canExportReport = presenter.canExportReport
                              .watch(context);
                          final bool showExportReport =
                              status == AnalysisStatusDto.done;
                          final bool showPrecedentsActions = _isPrecedentsFlow(
                            status,
                          );
                          int appliedFiltersCount = 0;
                          AnalysisPrecedentsBubblePresenter?
                          precedentsPresenter;
                          if (showPrecedentsActions) {
                            final AnalysisPrecedentsBubblePresenter
                            currentPrecedentsPresenter = ref.watch(
                              analysisPrecedentsBubblePresenterProvider(
                                widget.analysisId,
                              ),
                            );
                            precedentsPresenter = currentPrecedentsPresenter;
                            appliedFiltersCount =
                                currentPrecedentsPresenter.selectedCourts
                                    .watch(context)
                                    .length +
                                currentPrecedentsPresenter.selectedKinds
                                    .watch(context)
                                    .length;
                          }

                          return AnalysisHeader(
                            onBack: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                                return;
                              }

                              context.go(Routes.home);
                            },
                            onExportReport: canExportReport
                                ? () {
                                    unawaited(
                                      _handleExportReport(context, presenter),
                                    );
                                  }
                                : null,
                            title: analysisName,
                            isArchived: isArchived,
                            onPrecedentsCount:
                                isManaging || !showPrecedentsActions
                                ? null
                                : () {
                                    unawaited(
                                      _showPrecedentsLimitDialog(
                                        context,
                                        precedentsPresenter!,
                                      ),
                                    );
                                  },
                            onFilters: isManaging || !showPrecedentsActions
                                ? null
                                : () {
                                    unawaited(
                                      _showPrecedentsFiltersDialog(
                                        context,
                                        precedentsPresenter!,
                                      ),
                                    );
                                  },
                            onRename: isManaging
                                ? null
                                : () async {
                                    final BuildContext dialogContext =
                                        Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).context;

                                    final String? newName =
                                        await showDialog<String>(
                                          context: dialogContext,
                                          barrierColor:
                                              (Theme.of(context)
                                                  .extension<AppThemeTokens>()
                                                  ?.scrim ??
                                              AppTheme.tokens.scrim),
                                          builder: (_) => RenameAnalysisDialog(
                                            initialName:
                                                presenter.analysisName.value,
                                          ),
                                        );

                                    if (newName == null) {
                                      return;
                                    }

                                    await presenter.renameAnalysis(newName);
                                  },
                            onArchive: isManaging
                                ? null
                                : () async {
                                    final BuildContext dialogContext =
                                        Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).context;

                                    final bool? confirm =
                                        await showDialog<bool>(
                                          context: dialogContext,
                                          barrierColor:
                                              (Theme.of(context)
                                                  .extension<AppThemeTokens>()
                                                  ?.scrim ??
                                              AppTheme.tokens.scrim),
                                          builder: (_) => isArchived
                                              ? const UnarchiveAnalysisDialog()
                                              : const ArchiveAnalysisDialog(),
                                        );

                                    if (confirm == true) {
                                      final bool changed = isArchived
                                          ? await presenter.unarchiveAnalysis()
                                          : await presenter.archiveAnalysis();
                                      if (!context.mounted || !changed) {
                                        return;
                                      }

                                      if (!isArchived) {
                                        Navigator.of(context).maybePop();
                                      }
                                    }
                                  },
                            appliedFiltersCount: appliedFiltersCount,
                            isMenuEnabled: !isManaging,
                            showExportReport: showExportReport,
                            isExportingReport: isExportingReport,
                          );
                        }),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                            child: Watch((BuildContext context) {
                              final AnalysisStatusDto status = presenter.status
                                  .watch(context);
                              final String? generalError = presenter
                                  .generalError
                                  .watch(context);
                              final bool showProcessing = presenter
                                  .showCaseProcessingBubble
                                  .watch(context);
                              final bool showDraftProcessing = presenter
                                  .showPetitionDraftProcessingCard
                                  .watch(context);
                              final summary = presenter.caseSummary.watch(
                                context,
                              );
                              final bool showSummary = summary != null;
                              final draft = presenter.petitionDraft.watch(
                                context,
                              );
                              final bool showDraft =
                                  draft != null &&
                                  status !=
                                      AnalysisStatusDto.generatingPetitionDraft;
                              final bool isManaging = presenter
                                  .isManagingAnalysis
                                  .watch(context);
                              final bool canRegenerateSummary = presenter
                                  .canRegenerateSummary
                                  .watch(context);
                              const bool showBriefingCard = true;
                              final bool showPrecedents =
                                  status ==
                                      AnalysisStatusDto.searchingPrecedents ||
                                  status ==
                                      AnalysisStatusDto.precedentsSearched ||
                                  status ==
                                      AnalysisStatusDto
                                          .analyzingPrecedentsSimilarity ||
                                  status ==
                                      AnalysisStatusDto
                                          .analyzingPrecedentsApplicability ||
                                  status ==
                                      AnalysisStatusDto.generatingSynthesis ||
                                  status ==
                                      AnalysisStatusDto
                                          .generatingPetitionDraft ||
                                  status == AnalysisStatusDto.done;

                              if (showProcessing &&
                                  !_wasShowingCaseProcessing) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (!mounted) {
                                    return;
                                  }

                                  _scheduleJumpToBottom();
                                });
                              }
                              _wasShowingCaseProcessing = showProcessing;

                              if (showDraftProcessing &&
                                  !_wasShowingDraftProcessing) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (!mounted) {
                                    return;
                                  }

                                  _scheduleJumpToBottom();
                                });
                              }
                              _wasShowingDraftProcessing = showDraftProcessing;

                              AnalysisPrecedentsBubblePresenter?
                              precedentsBubblePresenter;
                              if (showPrecedents) {
                                precedentsBubblePresenter = ref.watch(
                                  analysisPrecedentsBubblePresenterProvider(
                                    widget.analysisId,
                                  ),
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  if (showBriefingCard)
                                    _animatedEntry(
                                      const AiBubble(
                                        message:
                                            'Preencha o briefing do caso e, se desejar, anexe documentos de apoio para iniciar a análise.',
                                        isTyping: false,
                                      ),
                                    ),
                                  if (showBriefingCard) ...<Widget>[
                                    const SizedBox(height: 12),
                                    _animatedEntry(
                                      BriefingFormCard(
                                        analysisId: widget.analysisId,
                                        enabled: !isManaging,
                                        onSubmitted:
                                            (
                                              CaseAssessmentBriefingDto
                                              briefing,
                                            ) async {
                                              presenter.markBriefingSubmitted(
                                                briefing,
                                              );
                                            },
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  if (showProcessing) ...<Widget>[
                                    _animatedEntry(
                                      const AiBubble(
                                        message:
                                            'Analisando o briefing enviado e montando o resumo do caso.',
                                        isTyping: true,
                                        footerText:
                                            'Isso pode levar alguns instantes.',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  if (showSummary) ...<Widget>[
                                    _animatedEntry(
                                      CaseSummaryCard(summary: summary),
                                    ),
                                    if (canRegenerateSummary)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 10,
                                          ),
                                          child: TextButton.icon(
                                            onPressed: () {
                                              unawaited(
                                                presenter.retrySummary(),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.refresh,
                                              size: 16,
                                            ),
                                            label: const Text('Regerar resumo'),
                                          ),
                                        ),
                                      ),
                                  ],
                                  if (showPrecedents) ...<Widget>[
                                    const SizedBox(height: 12),
                                    Watch((BuildContext context) {
                                      final List<AnalysisPrecedentDto>
                                      chosenPrecedents =
                                          precedentsBubblePresenter!
                                              .chosenPrecedents
                                              .watch(context);

                                      _syncChosenPrecedentsIfNeeded(
                                        presenter,
                                        chosenPrecedents,
                                      );

                                      return const SizedBox.shrink();
                                    }),
                                    _animatedEntry(
                                      AnalysisPrecedentsBubble(
                                        analysisId: widget.analysisId,
                                        analysisStatus: status,
                                        onPrecedentsReady:
                                            presenter.markPrecedentsReady,
                                        onPrecedentTap:
                                            (AnalysisPrecedentDto precedent) {
                                              unawaited(
                                                _showPrecedentDialog(
                                                  context,
                                                  precedent,
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  if (showDraftProcessing) ...<Widget>[
                                    _animatedEntry(
                                      const GeneratePetitionDraftCard(),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  if (showDraft) ...<Widget>[
                                    _animatedEntry(
                                      PetitionDraftCard(
                                        draft: draft,
                                        onOpenDialog: () {
                                          unawaited(
                                            _showPetitionDraftDialog(
                                              context,
                                              presenter,
                                              draft,
                                            ),
                                          );
                                        },
                                        onRegenerate: () {
                                          return _showRegeneratePetitionDraftDialog(
                                            context,
                                            presenter,
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  if (generalError != null &&
                                      generalError.isNotEmpty)
                                    _animatedEntry(
                                      MessageBox(
                                        message: generalError,
                                        color: tokens.danger,
                                      ),
                                    ),
                                ],
                              );
                            }),
                          ),
                        ),
                        Watch((BuildContext context) {
                          final BriefingFormCardPresenter briefingPresenter =
                              ref.watch(
                                briefingFormCardPresenterProvider(
                                  widget.analysisId,
                                ),
                              );
                          final bool canSubmitBriefing = briefingPresenter
                              .canSubmit
                              .watch(context);
                          final bool isSubmittingBriefing = briefingPresenter
                              .isSubmitting
                              .watch(context);
                          final bool canAnalyzeCase = presenter.canAnalyzeCase
                              .watch(context);
                          final bool canSearchPrecedents = presenter
                              .canSearchPrecedents
                              .watch(context);
                          final bool canGeneratePetitionDraft = presenter
                              .canGeneratePetitionDraft
                              .watch(context);
                          final bool canRegeneratePetitionDraft = presenter
                              .canRegeneratePetitionDraft
                              .watch(context);
                          final bool precedentsReady = presenter.precedentsReady
                              .watch(context);
                          final bool hasChosenPrecedents = presenter
                              .hasChosenPrecedents
                              .watch(context);
                          final bool isManaging = presenter.isManagingAnalysis
                              .watch(context);
                          final AnalysisStatusDto status = presenter.status
                              .watch(context);
                          final summary = presenter.caseSummary.watch(context);
                          final String primaryActionLabel = presenter
                              .primaryActionLabel
                              .watch(context);
                          final bool isProcessingPrecedents =
                              status == AnalysisStatusDto.searchingPrecedents ||
                              status ==
                                  AnalysisStatusDto
                                      .analyzingPrecedentsSimilarity ||
                              status ==
                                  AnalysisStatusDto
                                      .analyzingPrecedentsApplicability ||
                              status == AnalysisStatusDto.generatingSynthesis;

                          final bool hasPrimaryAction =
                              (status == AnalysisStatusDto.waitingBriefing &&
                                  canSubmitBriefing) ||
                              canRegeneratePetitionDraft ||
                              canGeneratePetitionDraft ||
                              canSearchPrecedents ||
                              canAnalyzeCase ||
                              (status == AnalysisStatusDto.failed &&
                                  (summary != null ||
                                      (precedentsReady &&
                                          hasChosenPrecedents)));
                          final bool shouldShowChoosePrecedentHelper =
                              precedentsReady &&
                              !hasChosenPrecedents &&
                              !canGeneratePetitionDraft &&
                              !canRegeneratePetitionDraft;

                          return AnalysisActionBar(
                            showFileAction: false,
                            fileActionLabel: '',
                            onFileAction: null,
                            primaryActionLabel: primaryActionLabel,
                            showPrimaryAction: true,
                            onPrimaryAction: !hasPrimaryAction
                                ? null
                                : () {
                                    if (status ==
                                        AnalysisStatusDto.waitingBriefing) {
                                      unawaited(
                                        _submitBriefingAndAnalyze(presenter),
                                      );
                                      return;
                                    }

                                    if (canRegeneratePetitionDraft) {
                                      unawaited(
                                        _showRegeneratePetitionDraftDialog(
                                          context,
                                          presenter,
                                        ),
                                      );
                                      return;
                                    }

                                    if (canGeneratePetitionDraft) {
                                      unawaited(
                                        presenter.requestPetitionDraft(),
                                      );
                                      _scheduleJumpToBottom();
                                      return;
                                    }

                                    if (status == AnalysisStatusDto.failed) {
                                      if (precedentsReady &&
                                          hasChosenPrecedents) {
                                        unawaited(
                                          presenter.requestPetitionDraft(
                                            force: true,
                                          ),
                                        );
                                        _scheduleJumpToBottom();
                                        return;
                                      }

                                      if (summary != null) {
                                        presenter.confirmAndViewPrecedents();
                                        _scheduleJumpToBottom();
                                        return;
                                      }

                                      if (canAnalyzeCase) {
                                        unawaited(
                                          _submitBriefingAndAnalyze(presenter),
                                        );
                                        return;
                                      }
                                    }

                                    if (canSearchPrecedents) {
                                      presenter.confirmAndViewPrecedents();
                                      _scheduleJumpToBottom();
                                      return;
                                    }

                                    if (canAnalyzeCase) {
                                      unawaited(
                                        _submitBriefingAndAnalyze(presenter),
                                      );
                                      return;
                                    }
                                  },
                            isPrimaryBusy:
                                isSubmittingBriefing ||
                                isManaging ||
                                isProcessingPrecedents,
                            helperText: shouldShowChoosePrecedentHelper
                                ? 'É necessário marcar pelo menos um precedente como escolhido para gerar a minuta.'
                                : null,
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
