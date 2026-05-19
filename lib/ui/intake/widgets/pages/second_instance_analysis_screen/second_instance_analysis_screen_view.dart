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
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/components/ai_bubble/index.dart';
import 'package:animus/ui/intake/widgets/components/analysis_action_bar/index.dart';
import 'package:animus/ui/intake/widgets/components/analysis_header/archive_analysis_dialog/index.dart';
import 'package:animus/ui/intake/widgets/components/analysis_header/index.dart';
import 'package:animus/ui/intake/widgets/components/analysis_header/rename_analysis_dialog/index.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_presenter.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/index.dart';
import 'package:animus/ui/intake/widgets/components/case_summary_card/index.dart';
import 'package:animus/ui/intake/widgets/components/document_file_bubble/index.dart';
import 'package:animus/ui/intake/widgets/components/message_box/index.dart';
import 'package:animus/ui/intake/widgets/pages/first_instance_analysis_screen/dot_grid_background/index.dart';
import 'package:animus/ui/intake/widgets/pages/first_instance_analysis_screen/precedent_dialog/index.dart';
import 'package:animus/ui/intake/widgets/pages/second_instance_analysis_screen/generate_judgment_draft_card/index.dart';
import 'package:animus/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_card/index.dart';
import 'package:animus/ui/intake/widgets/pages/second_instance_analysis_screen/petition_not_found_state/index.dart';
import 'package:animus/ui/intake/widgets/pages/second_instance_analysis_screen/processing_bubble/index.dart';
import 'package:animus/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart';

class SecondInstanceAnalysisScreenView extends ConsumerStatefulWidget {
  final String analysisId;

  const SecondInstanceAnalysisScreenView({required this.analysisId, super.key});

  @override
  ConsumerState<SecondInstanceAnalysisScreenView> createState() =>
      _SecondInstanceAnalysisScreenViewState();
}

class _SecondInstanceAnalysisScreenViewState
    extends ConsumerState<SecondInstanceAnalysisScreenView> {
  final ScrollController _scrollController = ScrollController();

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SecondInstanceFirstInstanceAnalysisScreenPresenter presenter = ref
        .watch(
          secondInstanceFirstInstanceAnalysisScreenPresenterProvider(
            widget.analysisId,
          ),
        );
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

                      return AnalysisHeader(
                        onBack: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                            return;
                          }

                          context.go(Routes.home);
                        },
                        onExportReport: null,
                        title: analysisName,
                        isArchived: isArchived,
                        onPrecedentsCount: null,
                        onFilters: null,
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
                        onArchive: isManaging
                            ? null
                            : () async {
                                final BuildContext dialogContext = Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).context;

                                final bool? confirm = await showDialog<bool>(
                                  context: dialogContext,
                                  barrierColor: const Color(0x99000000),
                                  builder: (_) => const ArchiveAnalysisDialog(),
                                );

                                if (confirm == true) {
                                  await presenter.archiveAnalysis();
                                }
                              },
                        appliedFiltersCount: 0,
                        isMenuEnabled: !isManaging,
                        showExportReport: false,
                        isExportingReport: false,
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
                          final bool showPetitionNotFound = presenter
                              .showPetitionNotFound
                              .watch(context);
                          final bool showDraftProcessing = presenter
                              .showJudgmentDraftProcessingBubble
                              .watch(context);
                          final bool showSummary =
                              presenter.caseSummary.watch(context) != null;
                          final bool showDraft =
                              presenter.judgmentDraft.watch(context) != null;
                          final bool showPrecedents =
                              status == AnalysisStatusDto.searchingPrecedents ||
                              status == AnalysisStatusDto.precedentsSearched ||
                              status ==
                                  AnalysisStatusDto
                                      .analyzingPrecedentsSimilarity ||
                              status ==
                                  AnalysisStatusDto
                                      .analyzingPrecedentsApplicability ||
                              status ==
                                  AnalysisStatusDto.generatingJudgmentDraft ||
                              status == AnalysisStatusDto.generatingSynthesis ||
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
                                        'Envie os autos em PDF para iniciar a analise de segunda instancia.',
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
                                  ProcessingBubble(
                                    message:
                                        status ==
                                            AnalysisStatusDto.extractingPetition
                                        ? 'Extraindo a peticao inicial dos autos enviados.'
                                        : 'Analisando o caso e estruturando a sintese juridica.',
                                    footerText:
                                        'Isso pode levar alguns instantes.',
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (showPetitionNotFound) ...<Widget>[
                                _animatedEntry(
                                  PetitionNotFoundState(
                                    onResendDocument: () {
                                      unawaited(presenter.resendDocument());
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (showSummary) ...<Widget>[
                                const SizedBox(height: 12),
                                _animatedEntry(
                                  CaseSummaryCard(
                                    summary: presenter.caseSummary.value!,
                                  ),
                                ),
                                Watch((BuildContext context) {
                                  final bool canReanalyze = presenter
                                      .canRegenerateSummary
                                      .watch(context);

                                  if (!canReanalyze) {
                                    return const SizedBox.shrink();
                                  }

                                  return Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: TextButton.icon(
                                        onPressed: () {
                                          unawaited(presenter.reanalyzeCase());
                                        },
                                        icon: const Icon(
                                          Icons.refresh,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Regerar análise do processo',
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                              if (showPrecedents) ...<Widget>[
                                const SizedBox(height: 12),
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
                                  const GenerateJudgmentDraftCard(),
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (showDraft) ...<Widget>[
                                _animatedEntry(
                                  JudgmentDraftCard(
                                    draft: presenter.judgmentDraft.value!,
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
                      final bool canAnalyze = presenter.canAnalyzeCase.watch(
                        context,
                      );
                      final summary = presenter.caseSummary.watch(context);
                      final bool canSearch = presenter.canSearchPrecedents
                          .watch(context);
                      final bool canGenerate = presenter
                          .canGenerateJudgmentDraft
                          .watch(context);
                      final bool canRegenerate = presenter
                          .canRegenerateJudgmentDraft
                          .watch(context);
                      final bool canPick = presenter.canPickDocument.watch(
                        context,
                      );
                      final bool isUploading = presenter.isUploading.watch(
                        context,
                      );
                      final AnalysisStatusDto status = presenter.status.watch(
                        context,
                      );
                      final bool isManaging = presenter.isManagingAnalysis
                          .watch(context);
                      final bool showPrimaryAction =
                          status != AnalysisStatusDto.waitingDocumentUpload;
                      final bool showFileAction =
                          !isUploading &&
                          (status == AnalysisStatusDto.waitingDocumentUpload ||
                              status == AnalysisStatusDto.documentUploaded);
                      final bool hasPrimaryAction =
                          canRegenerate ||
                          canGenerate ||
                          canSearch ||
                          canAnalyze ||
                          canPick;
                      final precedentsPresenter = ref.read(
                        analysisPrecedentsBubblePresenterProvider(
                          widget.analysisId,
                        ),
                      );

                      return AnalysisActionBar(
                        showFileAction: showFileAction,
                        fileActionLabel: 'Selecionar processo',
                        onFileAction: canPick
                            ? () {
                                unawaited(presenter.pickDocument());
                              }
                            : null,
                        primaryActionLabel: presenter.primaryActionLabel.watch(
                          context,
                        ),
                        showPrimaryAction: showPrimaryAction,
                        onPrimaryAction: hasPrimaryAction
                            ? () {
                                if (canRegenerate) {
                                  unawaited(
                                    presenter.regenerateJudgmentDraft(),
                                  );
                                  _scheduleJumpToBottom();
                                  return;
                                }

                                if (canGenerate) {
                                  unawaited(presenter.requestJudgmentDraft());
                                  _scheduleJumpToBottom();
                                  return;
                                }

                                if (status == AnalysisStatusDto.failed) {
                                  if (presenter.precedentsReady.value) {
                                    unawaited(presenter.requestJudgmentDraft());
                                    _scheduleJumpToBottom();
                                    return;
                                  }

                                  if (summary != null) {
                                    presenter.markPrecedentsReady();
                                    presenter.status.value =
                                        AnalysisStatusDto.searchingPrecedents;
                                    unawaited(precedentsPresenter.retry());
                                    _scheduleJumpToBottom();
                                    return;
                                  }

                                  if (canAnalyze) {
                                    unawaited(presenter.analyzeCase());
                                    _scheduleJumpToBottom();
                                    return;
                                  }
                                }

                                if (canSearch) {
                                  presenter.markPrecedentsReady();
                                  presenter.status.value =
                                      AnalysisStatusDto.searchingPrecedents;
                                  _scheduleJumpToBottom();
                                  return;
                                }

                                if (canAnalyze) {
                                  unawaited(presenter.analyzeCase());
                                  _scheduleJumpToBottom();
                                  return;
                                }

                                if (canPick) {
                                  unawaited(presenter.pickDocument());
                                  _scheduleJumpToBottom();
                                }
                              }
                            : null,
                        isPrimaryBusy: isUploading || isManaging,
                        helperText: showFileAction
                            ? 'Somente PDF com ate 50MB. O processamento pode levar alguns minutos.'
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
