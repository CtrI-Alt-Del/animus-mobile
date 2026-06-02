import 'package:flutter/material.dart';

import 'package:animus/ui/intake/widgets/components/ai_bubble/index.dart';

class DocumentPiecesNotFoundStateView extends StatelessWidget {
  final VoidCallback? onResendDocument;
  final String message;

  const DocumentPiecesNotFoundStateView({
    this.onResendDocument,
    required this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AiBubble(message: message, isTyping: false),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onResendDocument,
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Reenviar documento'),
          ),
        ),
      ],
    );
  }
}
