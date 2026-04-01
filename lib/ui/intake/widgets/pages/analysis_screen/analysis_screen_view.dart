import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/auth/widgets/pages/email_confirmation_screen/message_box/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/ai_bubble/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/analysis_action_bar/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/analysis_screen_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/petition_file_bubble/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/petition_summary_card/index.dart';

class AnalysisScreenView extends ConsumerWidget {
  final String analysisId;

  const AnalysisScreenView({required this.analysisId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AnalysisScreenPresenter presenter = ref.watch(
      analysisScreenPresenterProvider(analysisId),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Nova Analise',
                          style: textTheme.headlineSmall?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Envie a petição inicial para resumirmos os pontos principais antes da busca de precedentes.',
                          style: textTheme.bodySmall?.copyWith(
                            color: tokens.textSecondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const AiBubble(
                          message:
                              'Envie a petição inicial para comecarmos a analise. Vamos resumir o caso e destacar os pontos juridicos mais importantes.',
                          isTyping: false,
                          footerText: 'Formatos aceitos: PDF, DOCX • Max. 20MB',
                        ),
                        const SizedBox(height: 16),
                        Watch((BuildContext context) {
                          final File? file = presenter.selectedFile.watch(
                            context,
                          );

                          if (file == null) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: PetitionFileBubble(
                              fileName: presenter.fileName(file),
                              fileSizeLabel: presenter.formatFileSize(
                                file.lengthSync(),
                              ),
                            ),
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
                          );
                        }),
                        Watch((BuildContext context) {
                          final String? error = presenter.generalError.watch(
                            context,
                          );
                          final AnalysisStatusDto status = presenter.status
                              .watch(context);

                          if (error == null || error.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final Color color = status == AnalysisStatusDto.failed
                              ? tokens.danger
                              : tokens.warning;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: MessageBox(message: error, color: color),
                          );
                        }),
                        Watch((BuildContext context) {
                          final summary = presenter.summary.watch(context);
                          final AnalysisStatusDto status = presenter.status
                              .watch(context);

                          if (summary == null ||
                              status != AnalysisStatusDto.petitionAnalyzed) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              PetitionSummaryCard(summary: summary),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: presenter.retrySummary,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry resumo'),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                Watch((BuildContext context) {
                  final String fileActionLabel = presenter.fileActionLabel
                      .watch(context);
                  final String primaryActionLabel = presenter.primaryActionLabel
                      .watch(context);
                  final bool canPickDocument = presenter.canPickDocument.watch(
                    context,
                  );
                  final bool canAnalyze = presenter.canAnalyze.watch(context);
                  final bool isUploading = presenter.isUploading.watch(context);
                  final double? uploadProgress = presenter.uploadProgress.watch(
                    context,
                  );
                  final AnalysisStatusDto status = presenter.status.watch(
                    context,
                  );

                  return AnalysisActionBar(
                    fileActionLabel: fileActionLabel,
                    onFileAction: canPickDocument
                        ? () {
                            if (status == AnalysisStatusDto.petitionAnalyzed) {
                              presenter.replaceDocument();
                              return;
                            }

                            presenter.pickDocument();
                          }
                        : null,
                    primaryActionLabel: primaryActionLabel,
                    onPrimaryAction:
                        status == AnalysisStatusDto.petitionAnalyzed
                        ? presenter.confirmAndViewPrecedents
                        : canAnalyze
                        ? presenter.analyze
                        : null,
                    isPrimaryBusy: isUploading,
                    uploadProgress: uploadProgress,
                    helperText: status == AnalysisStatusDto.petitionAnalyzed
                        ? 'Substitui o documento atual e reinicia a analise desta etapa.'
                        : null,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
