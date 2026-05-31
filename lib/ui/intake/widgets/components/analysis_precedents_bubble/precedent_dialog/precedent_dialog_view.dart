import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_presenter.dart';
import 'package:animus/ui/intake/widgets/pages/first_instance_analysis_screen/applicability_badge/index.dart';
import 'package:animus/ui/intake/widgets/pages/first_instance_analysis_screen/dot_grid_background/index.dart';
import 'package:animus/ui/intake/widgets/pages/first_instance_analysis_screen/precedent_status_formatter.dart';

class AnalysisPrecedentDialogView extends ConsumerWidget {
  final String analysisId;
  final AnalysisPrecedentDto precedent;

  const AnalysisPrecedentDialogView({
    required this.analysisId,
    required this.precedent,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AnalysisPrecedentsBubblePresenter presenter = ref.watch(
      analysisPrecedentsBubblePresenterProvider(analysisId),
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final AnalysisPrecedentDto currentPrecedent = _resolveCurrentPrecedent(
      presenter: presenter,
    );
    final String synthesis = currentPrecedent.synthesis.trim();
    final String synthesisText = synthesis.isEmpty
        ? 'Síntese não disponibilizada para este precedente.'
        : synthesis;
    final bool isChosen = currentPrecedent.isChosen;
    final String status = formatPrecedentStatus(
      currentPrecedent.precedent.status,
    );
    final String identifier =
        '${currentPrecedent.precedent.identifier.court.value} ${currentPrecedent.precedent.identifier.kind.value} ${currentPrecedent.precedent.identifier.number}';
    final String precedentDescription =
        currentPrecedent.precedent.enunciation.trim().isEmpty
        ? 'Selecione o precedente mais aderente ao caso para liberar a síntese explicativa final e a confirmação da análise.'
        : currentPrecedent.precedent.enunciation.trim();

    return Scaffold(
      backgroundColor: tokens.surfacePage,
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
                        icon: Icon(Icons.arrow_back, color: tokens.textPrimary),
                      ),
                      Expanded(
                        child: Text(
                          'Visualização de Precedente',
                          style: textTheme.titleLarge?.copyWith(
                            color: tokens.textPrimary,
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
                                  : tokens.textPrimary,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                tokens.accent.withValues(alpha: 0.09),
                                tokens.accent.withValues(alpha: 0.03),
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
                                          ? tokens.accent
                                          : tokens.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: currentPrecedent.isManuallyAdded
                                        ? _ManuallyAddedBadge()
                                        : ApplicabilityBadge(
                                            classificationLevel:
                                                currentPrecedent
                                                    .applicabilityLevel,
                                            showScore: false,
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
                                  color: tokens.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: tokens.surfaceElevated,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: tokens.borderSubtle,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(
                                      Icons.gavel_outlined,
                                      size: 16,
                                      color: tokens.accent,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        status,
                                        style: textTheme.labelMedium?.copyWith(
                                          color: tokens.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                precedentDescription,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: tokens.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: tokens.accent,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  unawaited(
                                    presenter.openPangea(currentPrecedent),
                                  );
                                },
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: const Text('Acessar Pangea'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(height: 1, color: tokens.borderSubtle),
                        const SizedBox(height: 16),
                        Text(
                          'Síntese Explicativa',
                          style: textTheme.titleMedium?.copyWith(
                            color: tokens.textPrimary,
                            fontFamily: 'Fraunces',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.book_outlined,
                              size: 16,
                              color: tokens.accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Texto correspondente à síntese do precedente escolhido',
                                style: textTheme.bodySmall?.copyWith(
                                  color: tokens.textMuted,
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
                            color: tokens.surfaceElevated,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            synthesisText,
                            style: textTheme.bodyMedium?.copyWith(
                              color: tokens.textSecondary,
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
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated,
                  border: Border(top: BorderSide(color: tokens.borderSubtle)),
                ),
                child: SizedBox(
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[tokens.accent, tokens.accentStrong],
                      ),
                    ),
                    child: FilledButton.icon(
                      onPressed: () {
                        unawaited(
                          Future<void>(() async {
                            final bool didUpdate = isChosen
                                ? await presenter.unchoosePrecedent(
                                    currentPrecedent,
                                  )
                                : await _confirmPrecedentChoice(
                                    presenter: presenter,
                                    precedent: currentPrecedent,
                                  );
                            if (!didUpdate || !context.mounted) {
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
                            ? Icons.remove_done_outlined
                            : Icons.balance_outlined,
                        color: tokens.surfacePage,
                      ),
                      label: Text(
                        isChosen
                            ? 'Desescolher precedente'
                            : 'Escolher Precedente',
                        style: textTheme.labelLarge?.copyWith(
                          color: tokens.surfacePage,
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

  AnalysisPrecedentDto _resolveCurrentPrecedent({
    required AnalysisPrecedentsBubblePresenter presenter,
  }) {
    final AnalysisPrecedentDto? focused = presenter.focusedPrecedent.value;
    if (focused != null && _isSamePrecedent(focused, precedent)) {
      return focused;
    }

    for (final AnalysisPrecedentDto item in presenter.precedents.value) {
      if (_isSamePrecedent(item, precedent)) {
        return item;
      }
    }

    return precedent;
  }

  bool _isSamePrecedent(AnalysisPrecedentDto left, AnalysisPrecedentDto right) {
    final leftIdentifier = left.precedent.identifier;
    final rightIdentifier = right.precedent.identifier;

    return leftIdentifier.court == rightIdentifier.court &&
        leftIdentifier.kind == rightIdentifier.kind &&
        leftIdentifier.number == rightIdentifier.number;
  }

  Future<bool> _confirmPrecedentChoice({
    required AnalysisPrecedentsBubblePresenter presenter,
    required AnalysisPrecedentDto precedent,
  }) async {
    presenter.focusPrecedent(precedent);
    return presenter.confirmPrecedentChoice();
  }
}

class _ManuallyAddedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.textMuted.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.textMuted.withValues(alpha: 0.28)),
      ),
      child: Text(
        'Manualmente adicionado',
        style: textTheme.labelSmall?.copyWith(
          color: tokens.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
