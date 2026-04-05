import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/applicability_badge/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/dot_grid_background/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/relevant_precedents_bubble_presenter.dart';

class PrecedentDialogView extends ConsumerWidget {
  final String analysisId;
  final AnalysisPrecedentDto precedent;

  const PrecedentDialogView({
    required this.analysisId,
    required this.precedent,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RelevantPrecedentsBubblePresenter presenter = ref.watch(
      relevantPrecedentsBubblePresenterProvider(analysisId),
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String synthesis = precedent.synthesis.trim();
    final String synthesisText = synthesis.isEmpty
        ? 'Síntese não disponibilizada para este precedente.'
        : synthesis;
    final bool isChosen = precedent.isChosen;
    final String identifier =
        '${precedent.precedent.identifier.court.value} ${precedent.precedent.identifier.kind.value} ${precedent.precedent.identifier.number}';
    final String precedentDescription =
        precedent.precedent.enunciation.trim().isEmpty
        ? 'Selecione o precedente mais aderente ao caso para liberar a síntese explicativa final e a confirmação da análise.'
        : precedent.precedent.enunciation.trim();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0E),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            const Positioned.fill(child: DotGridBackground()),
            Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 24, 8),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFFFAFAF9),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Visualização de Precedente',
                          style: textTheme.titleLarge?.copyWith(
                            color: const Color(0xFFFAFAF9),
                            fontFamily: 'Fraunces',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isChosen
                                  ? tokens.accent
                                  : const Color(0xFFFAFAF9),
                            ),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Color(0x18FBE26D),
                                Color(0x08FBE26D),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    isChosen
                                        ? 'Precedente Escolhido'
                                        : 'Precedente*',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: isChosen
                                          ? const Color(0xFFFBE26D)
                                          : const Color(0xFF6B6B70),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ApplicabilityBadge(
                                      percentage:
                                          precedent.applicabilityPercentage,
                                      percentageText:
                                          '${precedent.applicabilityPercentage}',
                                      classificationLevel:
                                          precedent.classificationLevel,
                                      showBorder: false,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                identifier,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: const Color(0xFFFAFAF9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                precedentDescription,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF6B6B70),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFFBE26D),
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  unawaited(presenter.openPangea(precedent));
                                },
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: const Text('Acessar Pangea'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(height: 1, color: const Color(0xFF2A2A2E)),
                        const SizedBox(height: 16),
                        Text(
                          'Síntese Explicativa',
                          style: textTheme.titleMedium?.copyWith(
                            color: const Color(0xFFFAFAF9),
                            fontFamily: 'Fraunces',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.book_outlined,
                              size: 16,
                              color: Color(0xFFFBE26D),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Texto correspondente à síntese do precedente escolhido',
                                style: textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF8E8E93),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E24),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            synthesisText,
                            style: textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6B6B70),
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1E),
                  border: Border(top: BorderSide(color: Color(0xFF2A2A2E))),
                ),
                child: SizedBox(
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0xFFFBE26D), Color(0xFFC4A535)],
                      ),
                    ),
                    child: FilledButton.icon(
                      onPressed: () {
                        if (isChosen) {
                          Navigator.of(context).pop();
                          return;
                        }

                        unawaited(
                          Future<void>(() async {
                            presenter.choosePrecedent(precedent);
                            final bool didConfirm = await presenter
                                .confirmPrecedentChoice();
                            if (!didConfirm) {
                              return;
                            }

                            if (!context.mounted) {
                              return;
                            }

                            Navigator.of(context).pop();
                          }),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        isChosen
                            ? Icons.check_circle_outline
                            : Icons.balance_outlined,
                        color: const Color(0xFF0B0B0E),
                      ),
                      label: Text(
                        isChosen
                            ? 'Precedente escolhido'
                            : 'Escolher Precedente',
                        style: textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF0B0B0E),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
