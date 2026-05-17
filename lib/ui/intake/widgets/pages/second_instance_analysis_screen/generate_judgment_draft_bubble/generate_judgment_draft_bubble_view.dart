import 'package:flutter/material.dart';

import 'package:animus/ui/intake/widgets/components/ai_bubble/index.dart';

class GenerateJudgmentDraftBubbleView extends StatelessWidget {
  const GenerateJudgmentDraftBubbleView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AiBubble(
      message:
          'Gerando minuta de sentenca com base no resumo do caso e nos precedentes encontrados.',
      isTyping: true,
    );
  }
}
