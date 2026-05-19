import 'package:flutter/material.dart';

import 'package:animus/ui/intake/widgets/components/ai_bubble/index.dart';

class ProcessingBubbleView extends StatelessWidget {
  final String message;
  final String? footerText;

  const ProcessingBubbleView({
    required this.message,
    this.footerText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AiBubble(message: message, isTyping: true, footerText: footerText);
  }
}
