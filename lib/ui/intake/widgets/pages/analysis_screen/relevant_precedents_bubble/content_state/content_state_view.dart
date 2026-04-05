import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/relevant_precedents_bubble/precedent_list_item/index.dart';

class ContentStateView extends StatelessWidget {
  final List<AnalysisPrecedentDto> precedents;
  final ValueChanged<AnalysisPrecedentDto> onTap;

  const ContentStateView({
    required this.precedents,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return Column(
      children: List<Widget>.generate(precedents.length, (int index) {
        final AnalysisPrecedentDto precedent = precedents[index];

        return Container(
          decoration: BoxDecoration(
            border: index == 0
                ? null
                : Border(top: BorderSide(color: tokens.borderSubtle)),
          ),
          child: PrecedentListItem(
            title:
                '${precedent.precedent.identifier.court.value} ${precedent.precedent.identifier.kind.value} ${precedent.precedent.identifier.number}',
            applicabilityPercentage: precedent.applicabilityPercentage,
            classificationLevel: precedent.classificationLevel,
            onTap: () {
              onTap(precedent);
            },
          ),
        );
      }),
    );
  }
}
