import 'package:flutter/material.dart';

import 'package:animus/ui/intake/widgets/components/ai_bubble/index.dart';

class PetitionNotFoundStateView extends StatelessWidget {
  final VoidCallback? onResendDocument;

  const PetitionNotFoundStateView({this.onResendDocument, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AiBubble(
          message:
              'Nao encontramos a peticao inicial no PDF enviado. Reenvie um documento com texto selecionavel e com a peticao completa.',
          isTyping: false,
        ),
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
