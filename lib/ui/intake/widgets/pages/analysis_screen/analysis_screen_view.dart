import 'dart:async';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/petition_dto.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/auth/widgets/pages/email_confirmation_screen/message_box/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/ai_bubble/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/analysis_action_bar/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/analysis_header/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/analysis_header/archive_analysis_dialog/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/analysis_header/rename_analysis_dialog/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/chosen_precedent_summary/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/dot_grid_background/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/petition_file_bubble/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/precedent_dialog/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/petition_summary_card/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/precedents_filters_dialog/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/precedents_limit_dialog/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart';

class AnalysisScreenView extends ConsumerStatefulWidget {
  final String analysisId;

  const AnalysisScreenView({required this.analysisId, super.key});

  @override
  ConsumerState<AnalysisScreenView> createState() => _AnalysisScreenViewState();
}

class _AnalysisScreenViewState extends ConsumerState<AnalysisScreenView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  void _jumpToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  void _scheduleJumpToBottom() {
    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _jumpToBottom();

      Future<void>.delayed(const Duration(milliseconds: 60), () {
        if (!mounted) {
          return;
        }

        _jumpToBottom();
      });

      Future<void>.delayed(const Duration(milliseconds: 160), () {
        if (!mounted) {
          return;
        }

        _jumpToBottom();
      });
    });
  }

  bool _isPrecedentsFlow(AnalysisStatusDto status) {
    return status == AnalysisStatusDto.searchingPrecedents ||
        status == AnalysisStatusDto.analyzingPrecedentsApplicability ||
        status == AnalysisStatusDto.generatingSynthesis ||
        status == AnalysisStatusDto.waitingPrecedentChoice ||
        status == AnalysisStatusDto.precedentChosen;
  }

  Future<void> _showPrecedentsLimitDialog(
    BuildContext context,
    AnalysisScreenPresenter presenter,
  ) async {
    int selectedLimit = presenter.precedentsLimit.value;

    final int? newLimit = await showDialog<int>(
      context: context,
      barrierColor: const Color(0x99000000),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return PrecedentsLimitDialog(
              currentValue: selectedLimit,
              minValue: 1,
              maxValue: 20,
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

    if (newLimit != null) {
      presenter.setPrecedentsLimit(newLimit);
    }
  }

  Future<void> _showPrecedentsFiltersDialog(
    BuildContext context,
    AnalysisScreenPresenter presenter,
  ) async {
    List<CourtDto> selectedCourts = List<CourtDto>.from(
      presenter.precedentsCourts.value,
    );
    List<PrecedentKindDto> selectedKinds = List<PrecedentKindDto>.from(
      presenter.precedentsKinds.value,
    );

    final ({List<CourtDto> courts, List<PrecedentKindDto> kinds})? result =
        await showDialog<
          ({List<CourtDto> courts, List<PrecedentKindDto> kinds})
        >(
          context: context,
          barrierColor: const Color(0x99000000),
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

    presenter.setPrecedentFilters(courts: result.courts, kinds: result.kinds);
  }

  Future<void> _showPrecedentDialog(
    BuildContext context,
    AnalysisPrecedentDto precedent,
  ) async {
    final RelevantPrecedentsBubblePresenter precedentsPresenter = ref.read(
      relevantPrecedentsBubblePresenterProvider(widget.analysisId),
    );
    final bool hadChosenPrecedentBefore =
        precedentsPresenter.selectedPrecedent.value?.isChosen ?? false;

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

    final bool hasChosenPrecedentNow =
        precedentsPresenter.selectedPrecedent.value?.isChosen ?? false;
    if (hadChosenPrecedentBefore || !hasChosenPrecedentNow) {
      return;
    }

    _scheduleJumpToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final AnalysisScreenPresenter presenter = ref.watch(
      analysisScreenPresenterProvider(widget.analysisId),
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

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
                      final bool isManagingAnalysis = presenter
                          .isManagingAnalysis
                          .watch(context);
                      final int appliedFiltersCount = presenter
                          .appliedPrecedentFiltersCount
                          .watch(context);

                      return AnalysisHeader(
                        onBack: () => Navigator.of(context).maybePop(),
                        title: analysisName,
                        onPrecedentsCount: isManagingAnalysis
                            ? null
                            : () {
                                unawaited(
                                  _showPrecedentsLimitDialog(
                                    context,
                                    presenter,
                                  ),
                                );
                              },
                        onRename: isManagingAnalysis
                            ? null
                            : () async {
                                if (!context.mounted) {
                                  return;
                                }

                                final BuildContext dialogHostContext =
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).context;

                                final String? newName =
                                    await showDialog<String>(
                                      context: dialogHostContext,
                                      barrierColor: const Color(0x99000000),
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
                        onFilters: isManagingAnalysis
                            ? null
                            : () {
                                unawaited(
                                  _showPrecedentsFiltersDialog(
                                    context,
                                    presenter,
                                  ),
                                );
                              },
                        onArchive: isManagingAnalysis
                            ? null
                            : () async {
                                if (!context.mounted) {
                                  return;
                                }

                                final BuildContext dialogHostContext =
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).context;

                                final bool shouldArchive =
                                    await showDialog<bool>(
                                      context: dialogHostContext,
                                      barrierColor: const Color(0x99000000),
                                      builder: (_) =>
                                          const ArchiveAnalysisDialog(),
                                    ) ??
                                    false;

                                if (!shouldArchive) {
                                  return;
                                }

                                final bool archived = await presenter
                                    .archiveAnalysis();
                                if (!context.mounted || !archived) {
                                  return;
                                }

                                Navigator.of(context).maybePop();
                              },
                        appliedFiltersCount: appliedFiltersCount,
                        isMenuEnabled: !isManagingAnalysis,
                      );
                    }),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            const AiBubble(
                              message:
                                  'Envie a petição inicial para começarmos a análise. Vamos resumir o caso e destacar os pontos jurídicos mais importantes.',
                              isTyping: false,
                              footerText: null,
                            ),
                            Watch((BuildContext context) {
                              final AnalysisStatusDto status = presenter.status
                                  .watch(context);

                              if (status != AnalysisStatusDto.waitingPetition) {
                                return const SizedBox(height: 16);
                              }

                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: 10,
                                  bottom: 16,
                                ),
                                child: Text(
                                  'Formatos aceitos: PDF, DOCX • Máx. 20MB',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: tokens.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }),
                            Watch((BuildContext context) {
                              final File? file = presenter.selectedFile.watch(
                                context,
                              );
                              final PetitionDto? petition = presenter.petition
                                  .watch(context);

                              if (file == null && petition == null) {
                                return const SizedBox.shrink();
                              }

                              final String fileName = petition != null
                                  ? petition.document.name
                                  : presenter.fileName(file!);
                              final String fileSizeLabel = file != null
                                  ? presenter.formatFileSize(file.lengthSync())
                                  : 'Documento enviado';

                              return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: PetitionFileBubble(
                                      fileName: fileName,
                                      fileSizeLabel: fileSizeLabel,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 280.ms)
                                  .slideY(
                                    begin: 0.08,
                                    end: 0,
                                    duration: 280.ms,
                                    curve: Curves.easeOutCubic,
                                  );
                            }),
                            Watch((BuildContext context) {
                              final bool show = presenter.showProcessingBubble
                                  .watch(context);

                              if (!show) {
                                return const SizedBox.shrink();
                              }

                              return const Padding(
                                    padding: EdgeInsets.only(bottom: 16),
                                    child: AiBubble(
                                      message: 'Analisando a petição enviada.',
                                      isTyping: true,
                                      footerText:
                                          'Aguarde enquanto processamos o documento e montamos o resumo.',
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 260.ms)
                                  .slideY(
                                    begin: 0.08,
                                    end: 0,
                                    duration: 260.ms,
                                    curve: Curves.easeOutCubic,
                                  );
                            }),
                            Watch((BuildContext context) {
                              final String? error = presenter.generalError
                                  .watch(context);
                              final AnalysisStatusDto status = presenter.status
                                  .watch(context);

                              if (error == null || error.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              final Color color =
                                  status == AnalysisStatusDto.failed
                                  ? tokens.danger
                                  : tokens.warning;

                              return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: MessageBox(
                                      message: error,
                                      color: color,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 220.ms)
                                  .slideY(
                                    begin: 0.06,
                                    end: 0,
                                    duration: 220.ms,
                                    curve: Curves.easeOutCubic,
                                  );
                            }),
                            Watch((BuildContext context) {
                              final summary = presenter.summary.watch(context);
                              final AnalysisStatusDto status = presenter.status
                                  .watch(context);
                              final bool showRelevantPrecedents =
                                  _isPrecedentsFlow(status);

                              if (summary == null ||
                                  (status !=
                                          AnalysisStatusDto.petitionAnalyzed &&
                                      !showRelevantPrecedents)) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      PetitionSummaryCard(summary: summary),
                                      if (status ==
                                          AnalysisStatusDto
                                              .petitionAnalyzed) ...<Widget>[
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerRight,
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
                                            label: const Text(
                                              'Tentar resumo novamente',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  )
                                  .animate()
                                  .fadeIn(duration: 320.ms)
                                  .slideY(
                                    begin: 0.1,
                                    end: 0,
                                    duration: 320.ms,
                                    curve: Curves.easeOutCubic,
                                  );
                            }),
                            Watch((BuildContext context) {
                              final AnalysisStatusDto status = presenter.status
                                  .watch(context);
                              final bool showRelevantPrecedents =
                                  _isPrecedentsFlow(status);

                              if (!showRelevantPrecedents) {
                                return const SizedBox.shrink();
                              }

                              final RelevantPrecedentsBubblePresenter
                              precedentsPresenter = ref.watch(
                                relevantPrecedentsBubblePresenterProvider(
                                  widget.analysisId,
                                ),
                              );
                              precedentsPresenter.syncSelectedLimit(
                                presenter.precedentsLimit.value,
                              );
                              precedentsPresenter.syncSelectedFilters(
                                courts: presenter.precedentsCourts.value,
                                kinds: presenter.precedentsKinds.value,
                              );

                              final AnalysisPrecedentDto? selectedPrecedent =
                                  precedentsPresenter.selectedPrecedent.watch(
                                    context,
                                  );

                              return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 16,
                                          bottom: 16,
                                        ),
                                        child: RelevantPrecedentsBubble(
                                          analysisId: widget.analysisId,
                                          analysisStatus: status,
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
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child:
                                            selectedPrecedent == null ||
                                                !selectedPrecedent.isChosen
                                            ? const SizedBox.shrink()
                                            : ChosenPrecedentSummary(
                                                selectedPrecedent:
                                                    selectedPrecedent,
                                              ),
                                      ),
                                    ],
                                  )
                                  .animate()
                                  .fadeIn(duration: 280.ms)
                                  .slideY(
                                    begin: 0.08,
                                    end: 0,
                                    duration: 280.ms,
                                    curve: Curves.easeOutCubic,
                                  );
                            }),
                          ],
                        ),
                      ),
                    ),
                    Watch((BuildContext context) {
                      final String fileActionLabel = presenter.fileActionLabel
                          .watch(context);
                      final String primaryActionLabel = presenter
                          .primaryActionLabel
                          .watch(context);
                      final bool canPickDocument = presenter.canPickDocument
                          .watch(context);
                      final bool canAnalyze = presenter.canAnalyze.watch(
                        context,
                      );
                      final bool isUploading = presenter.isUploading.watch(
                        context,
                      );
                      final AnalysisStatusDto status = presenter.status.watch(
                        context,
                      );
                      final bool showRelevantPrecedents = _isPrecedentsFlow(
                        status,
                      );

                      if (showRelevantPrecedents) {
                        return const SizedBox.shrink();
                      }

                      final bool showFileAction =
                          status == AnalysisStatusDto.waitingPetition ||
                          status == AnalysisStatusDto.petitionUploaded ||
                          status == AnalysisStatusDto.petitionAnalyzed;

                      return AnalysisActionBar(
                        showFileAction: showFileAction,
                        fileActionLabel: fileActionLabel,
                        onFileAction: isUploading
                            ? null
                            : canPickDocument
                            ? () {
                                if (status ==
                                    AnalysisStatusDto.petitionAnalyzed) {
                                  unawaited(presenter.replaceDocument());
                                  return;
                                }

                                unawaited(presenter.pickDocument());
                              }
                            : null,
                        primaryActionLabel: primaryActionLabel,
                        onPrimaryAction: isUploading
                            ? null
                            : status == AnalysisStatusDto.petitionAnalyzed
                            ? presenter.confirmAndViewPrecedents
                            : canAnalyze
                            ? () {
                                unawaited(presenter.analyze());
                              }
                            : null,
                        isPrimaryBusy: isUploading,
                        helperText: null,
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
