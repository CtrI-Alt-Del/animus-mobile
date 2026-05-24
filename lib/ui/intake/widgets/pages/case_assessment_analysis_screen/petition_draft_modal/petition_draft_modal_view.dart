import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/theme.dart';

class PetitionDraftModalView extends StatelessWidget {
  final PetitionDraftDto draft;

  const PetitionDraftModalView({required this.draft, super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String normalizedContent = draft.content.trim();

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
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back, color: tokens.textPrimary),
                  ),
                  Expanded(
                    child: Text(
                      'Minuta de petição',
                      style: textTheme.titleLarge?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Container(
                  width: double.infinity,
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
                            Icons.article_outlined,
                            size: 18,
                            color: tokens.accent,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Conteúdo da minuta',
                            style: textTheme.titleMedium?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SelectableText(
                        normalizedContent.isEmpty
                            ? 'A minuta ainda não tem conteúdo disponível.'
                            : normalizedContent,
                        style: textTheme.bodyMedium?.copyWith(
                          color: tokens.textSecondary,
                          height: 1.55,
                        ),
                      ),
                    ],
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
