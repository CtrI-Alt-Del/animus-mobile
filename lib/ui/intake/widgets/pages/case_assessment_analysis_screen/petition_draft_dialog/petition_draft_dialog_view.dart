import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/draft_content_section/index.dart';

class PetitionDraftDialogView extends StatelessWidget {
  final PetitionDraftDto draft;

  const PetitionDraftDialogView({required this.draft, super.key});

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
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back, color: tokens.textPrimary),
                  ),
                  Expanded(
                    child: Text(
                      'Minuta de Petição Inicial',
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
                child: DraftContentSection(
                  icon: Icons.description_outlined,
                  title: 'Conteúdo da Minuta',
                  content: draft.content,
                  emphasize: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
