import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/constants/routes.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
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
import 'package:animus/ui/intake/widgets/components/document_file_bubble/index.dart';
import 'package:animus/ui/intake/widgets/components/message_box/index.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/generate_petition_draft_card/index.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/index.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_modal/index.dart';
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

  Future<void> _showPetitionDraftModal(
    BuildContext context,
    PetitionDraftDto draft,
  ) async {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) {
          return PetitionDraftModal(draft: draft);
        },
      ),
    );
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
    final AnalysisPrecedentsBubblePresenter precedentsBubblePresenter = ref
        .watch(analysisPrecedentsBubblePresenterProvider(widget.analysisId));
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return Scaffold(
      backgroundColor: tokens.surfacePage,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 402),
            child: Stack(
              children: <Widget>[
                const Positioned.fill(child: DotGridBackground()),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Watch((BuildContext context) {
                      final String analysisName = presenter.analysisName.watch(
                        context,
                      );
                      final bool isArchived = presenter.isArchived.watch(
                        context,
                      );
                      final bool isManaging = presenter.isManagingAnalysis
                          .watch(context);
                      final bool isExportingReport = presenter.isExportingReport
                          .watch(context);
                      final AnalysisStatusDto status = presenter.status.watch(
                        context,
                      );
                      final bool canExportReport = presenter.canExportReport
                          .watch(context);
                      final bool showExportReport =
                          status == AnalysisStatusDto.done;
                      final bool showPrecedentsActions = _isPrecedentsFlow(
                        status,
                      );
                      final int appliedFiltersCount =
                          precedentsBubblePresenter.selectedCourts
                              .watch(context)
                              .length +
                          precedentsBubblePresenter.selectedKinds
                              .watch(context)
                              .length;

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
                        onPrecedentsCount: isManaging || !showPrecedentsActions
                            ? null
                            : () {
                                unawaited(
                                  _showPrecedentsLimitDialog(
                                    context,
                                    precedentsBubblePresenter,
                                  ),
                                );
                              },
                        onFilters: isManaging || !showPrecedentsActions
                            ? null
                            : () {
                                unawaited(
                                  _showPrecedentsFiltersDialog(
                                    context,
                                    precedentsBubblePresenter,
                                  ),
                                );
                              },
                        onRename: isManaging
                            ? null
                            : () async {
                                final BuildContext dialogContext = Navigator.of(
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
                                final BuildContext dialogContext = Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).context;

                                final bool? confirm = await showDialog<bool>(
                                  context: dialogContext,
                                  barrierColor:
                                      (Theme.of(
                                        context,
                                      ).extension<AppThemeTokens>()?.scrim ??
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
                          final File? selectedFile = presenter.selectedFile
                              .watch(context);
                          final analysisDocument = presenter.analysisDocument
                              .watch(context);
                          final bool isUploading = presenter.isUploading.watch(
                            context,
                          );
                          final double? progress = presenter.uploadProgress
                              .watch(context);
                          final String? generalError = presenter.generalError
                              .watch(context);
                          final bool showProcessing = presenter
                              .showCaseProcessingBubble
                              .watch(context);
                          final bool showDraftProcessing = presenter
                              .showPetitionDraftProcessingCard
                              .watch(context);
                          final summary = presenter.caseSummary.watch(context);
                          final bool showSummary = summary != null;
                          final draft = presenter.petitionDraft.watch(context);
                          final bool showDraft =
                              draft != null &&
                              status !=
                                  AnalysisStatusDto.generatingPetitionDraft;
                          final bool canRegenerateSummary = presenter
                              .canRegenerateSummary
                              .watch(context);
                          final bool showPrecedents =
                              status == AnalysisStatusDto.searchingPrecedents ||
                              status == AnalysisStatusDto.precedentsSearched ||
                              status ==
                                  AnalysisStatusDto
                                      .analyzingPrecedentsSimilarity ||
                              status ==
                                  AnalysisStatusDto
                                      .analyzingPrecedentsApplicability ||
                              status == AnalysisStatusDto.generatingSynthesis ||
                              status ==
                                  AnalysisStatusDto.generatingPetitionDraft ||
                              status == AnalysisStatusDto.done;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              if (selectedFile == null &&
                                  analysisDocument == null &&
                                  !showProcessing)
                                _animatedEntry(
                                  const AiBubble(
                                    message:
                                        'Envie o documento do caso (PDF ou DOCX) para iniciar a análise.',
                                    isTyping: false,
                                  ),
                                ),
                              if (selectedFile != null ||
                                  analysisDocument != null) ...<Widget>[
                                if (selectedFile != null)
                                  _animatedEntry(
                                    Builder(
                                      builder: (BuildContext context) {
                                        final int fileSize = selectedFile
                                            .lengthSync();
                                        final String fileSizeLabel = isUploading
                                            ? progress == null
                                                  ? 'Enviando arquivo...'
                                                  : 'Enviando ${(progress * 100).toStringAsFixed(0)}%'
                                            : presenter.formatFileSize(
                                                fileSize,
                                              );

                                        return DocumentFileBubble(
                                          fileName: presenter.fileName(
                                            selectedFile,
                                          ),
                                          fileSizeLabel: fileSizeLabel,
                                          isLoading: isUploading,
                                        );
                                      },
                                    ),
                                  )
                                else
                                  _animatedEntry(
                                    DocumentFileBubble(
                                      fileName: analysisDocument!.name,
                                      fileSizeLabel: 'Documento enviado',
                                    ),
                                  ),
                                const SizedBox(height: 12),
                              ],
                              if (showProcessing) ...<Widget>[
                                _animatedEntry(
                                  const AiBubble(
                                    message:
                                        'Analisando o documento do caso enviado e montando o resumo do caso.',
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
                                      padding: const EdgeInsets.only(top: 10),
                                      child: TextButton.icon(
                                        onPressed: () {
                                          unawaited(presenter.retrySummary());
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
                                  chosenPrecedents = precedentsBubblePresenter
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
                                    onOpenModal: () {
                                      unawaited(
                                        _showPetitionDraftModal(context, draft),
                                      );
                                    },
                                    onRegenerate: () {
                                      unawaited(
                                        presenter.regeneratePetitionDraft(),
                                      );
                                      _scheduleJumpToBottom();
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
                      final bool canPickDocument = presenter.canPickDocument
                          .watch(context);
                      final bool isUploading = presenter.isUploading.watch(
                        context,
                      );
                      final bool isManaging = presenter.isManagingAnalysis
                          .watch(context);
                      final AnalysisStatusDto status = presenter.status.watch(
                        context,
                      );
                      final summary = presenter.caseSummary.watch(context);
                      final String primaryActionLabel = presenter
                          .primaryActionLabel
                          .watch(context);
                      final String fileActionLabel = presenter.fileActionLabel
                          .watch(context);

                      final bool showPrimaryAction =
                          status != AnalysisStatusDto.waitingDocumentUpload;
                      final bool showFileAction =
                          !isUploading &&
                          (status == AnalysisStatusDto.waitingDocumentUpload ||
                              status == AnalysisStatusDto.documentUploaded ||
                              status == AnalysisStatusDto.caseAnalyzed);
                      final bool hasPrimaryAction =
                          canRegeneratePetitionDraft ||
                          canGeneratePetitionDraft ||
                          canSearchPrecedents ||
                          canAnalyzeCase ||
                          (status == AnalysisStatusDto.failed &&
                              canPickDocument);
                      final bool shouldShowChoosePrecedentHelper =
                          precedentsReady &&
                          !hasChosenPrecedents &&
                          !canGeneratePetitionDraft &&
                          !canRegeneratePetitionDraft;

                      return AnalysisActionBar(
                        showFileAction: showFileAction,
                        fileActionLabel: fileActionLabel,
                        onFileAction: isUploading
                            ? null
                            : canPickDocument
                            ? () {
                                if (status == AnalysisStatusDto.caseAnalyzed) {
                                  unawaited(presenter.replaceDocument());
                                  return;
                                }

                                unawaited(presenter.pickDocument());
                              }
                            : null,
                        primaryActionLabel: primaryActionLabel,
                        showPrimaryAction: showPrimaryAction,
                        onPrimaryAction: !hasPrimaryAction
                            ? null
                            : () {
                                if (canRegeneratePetitionDraft) {
                                  unawaited(
                                    presenter.regeneratePetitionDraft(),
                                  );
                                  _scheduleJumpToBottom();
                                  return;
                                }

                                if (canGeneratePetitionDraft) {
                                  unawaited(presenter.requestPetitionDraft());
                                  _scheduleJumpToBottom();
                                  return;
                                }

                                if (status == AnalysisStatusDto.failed) {
                                  if (summary != null) {
                                    presenter.confirmAndViewPrecedents();
                                    _scheduleJumpToBottom();
                                    return;
                                  }

                                  if (canAnalyzeCase) {
                                    unawaited(presenter.analyzeCase());
                                    _scheduleJumpToBottom();
                                    return;
                                  }
                                }

                                if (canSearchPrecedents) {
                                  presenter.confirmAndViewPrecedents();
                                  _scheduleJumpToBottom();
                                  return;
                                }

                                if (canAnalyzeCase) {
                                  unawaited(presenter.analyzeCase());
                                  _scheduleJumpToBottom();
                                  return;
                                }
                              },
                        isPrimaryBusy: isUploading || isManaging,
                        helperText: shouldShowChoosePrecedentHelper
                            ? 'É necessário marcar pelo menos um precedente como escolhido para gerar a minuta.'
                            : showFileAction
                            ? 'PDF ou DOCX com até 100MB. O processamento pode levar alguns minutos.'
                            : null,
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
