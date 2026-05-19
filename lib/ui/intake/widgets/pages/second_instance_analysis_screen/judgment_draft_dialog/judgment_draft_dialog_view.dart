import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/second_instance_judgment_draft_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/draft_section/index.dart';

class JudgmentDraftDialogView extends StatelessWidget {
  final SecondInstanceJudgmentDraftDto draft;

  const JudgmentDraftDialogView({required this.draft, super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: tokens.surfacePage,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[tokens.surfaceElevated, tokens.surfaceCard],
                ),
                border: Border(bottom: BorderSide(color: tokens.borderSubtle)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.arrow_back, color: tokens.textPrimary),
                      ),
                      Expanded(
                        child: Text(
                          'Minuta de Sentença',
                          style: textTheme.titleLarge?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    DraftSection(
                      icon: Icons.article_outlined,
                      title: 'Relatório',
                      content: draft.report,
                      emptyText: 'O relatório não foi disponibilizado.',
                      emphasize: true,
                    ),
                    if (_hasContent(draft.preliminaryIssues)) ...<Widget>[
                      const SizedBox(height: 16),
                      DraftSection(
                        icon: Icons.rule_folder_outlined,
                        title: 'Questões Preliminares',
                        content: draft.preliminaryIssues!,
                        emptyText:
                            'Sem questões preliminares disponibilizadas.',
                      ),
                    ],
                    const SizedBox(height: 16),
                    DraftSection(
                      icon: Icons.balance_outlined,
                      title: 'Análise do Mérito',
                      content: draft.meritAnalysis,
                      emptyText: 'A análise do mérito não foi disponibilizada.',
                    ),
                    const SizedBox(height: 16),
                    DraftSection(
                      icon: Icons.account_tree_outlined,
                      title: 'Aderência aos Precedentes',
                      content: draft.precedentAdherenceAnalysis,
                      emptyText:
                          'A análise de aderência aos precedentes não foi disponibilizada.',
                    ),
                    if (_hasContent(
                      draft.noApplicablePrecedentNotice,
                    )) ...<Widget>[
                      const SizedBox(height: 16),
                      DraftSection(
                        icon: Icons.info_outline,
                        title: 'Aviso',
                        content: draft.noApplicablePrecedentNotice!,
                        emptyText: '',
                        accentColor: tokens.warning,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: tokens.surfaceCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: tokens.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.gavel_outlined,
                                size: 18,
                                color: tokens.accent,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Dispositivo',
                                style: textTheme.titleMedium?.copyWith(
                                  color: tokens.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (draft.ruling.isEmpty)
                            Text(
                              'O dispositivo não foi disponibilizado.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: tokens.textSecondary,
                                height: 1.5,
                              ),
                            )
                          else
                            ...draft.ruling.map(
                              (String item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: tokens.accent,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: tokens.textSecondary,
                                          height: 1.55,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasContent(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
