import 'package:flutter/material.dart';

class GeneralErrorAlertView extends StatelessWidget {
  final String? message;

  const GeneralErrorAlertView({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF3A1D25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE55454)),
        ),
        child: Text(
          message!,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFFFFB8B8)),
        ),
      ),
    );
  }
}
