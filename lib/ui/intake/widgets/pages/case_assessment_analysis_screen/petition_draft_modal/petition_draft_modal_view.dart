import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/theme.dart';

class PetitionDraftModalView extends StatelessWidget {
  final PetitionDraftDto draft;
  final Future<bool> Function()? onRegenerate;

  const PetitionDraftModalView({
    required this.draft,
    this.onRegenerate,
    super.key,
  });

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back, color: tokens.textPrimary),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Minuta de petição',
                            style: textTheme.titleLarge?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                          if (onRegenerate != null) ...<Widget>[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () async {
                                  final bool didConfirm = await onRegenerate!
                                      .call();
                                  if (!didConfirm || !context.mounted) {
                                    return;
                                  }

                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                ),
                                label: const Text('Regerar minuta'),
                              ),
                            ),
                          ],
                        ],
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
                      _buildSection(
                        context,
                        title: 'Fatos estruturados',
                        content: draft.structuredFacts,
                        emptyText:
                            'Os fatos estruturados ainda não estão disponíveis.',
                      ),
                      const SizedBox(height: 18),
                      _buildSection(
                        context,
                        title: 'Fundamentos jurídicos',
                        content: draft.legalGrounds,
                        emptyText:
                            'Os fundamentos jurídicos ainda não estão disponíveis.',
                      ),
                      const SizedBox(height: 18),
                      _buildSection(
                        context,
                        title: 'Tese central',
                        content: draft.centralThesis,
                        emptyText: 'A tese central ainda não está disponível.',
                      ),
                      const SizedBox(height: 18),
                      _buildListSection(
                        context,
                        title: 'Pedidos',
                        items: draft.requests,
                        emptyText: 'Os pedidos ainda não estão disponíveis.',
                      ),
                      const SizedBox(height: 18),
                      _buildListSection(
                        context,
                        title: 'Citações de precedentes',
                        items: draft.precedentCitations,
                        emptyText:
                            'As citações de precedentes ainda não estão disponíveis.',
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

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
    required String emptyText,
  }) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String normalizedContent = content.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        SelectableText(
          normalizedContent.isEmpty ? emptyText : normalizedContent,
          style: textTheme.bodyMedium?.copyWith(
            color: tokens.textSecondary,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  Widget _buildListSection(
    BuildContext context, {
    required String title,
    required List<String> items,
    required String emptyText,
  }) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<String> normalizedItems = items
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (normalizedItems.isEmpty)
          SelectableText(
            emptyText,
            style: textTheme.bodyMedium?.copyWith(
              color: tokens.textSecondary,
              height: 1.55,
            ),
          )
        else
          ...normalizedItems.map(
            (String item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SelectableText(
                '• $item',
                style: textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                  height: 1.55,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
