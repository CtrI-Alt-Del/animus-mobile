import 'package:flutter/material.dart';

class SignUpSubmitButtonView extends StatelessWidget {
  final bool isSubmitting;
  final bool enabled;
  final VoidCallback onPressed;

  const SignUpSubmitButtonView({
    required this.isSubmitting,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: enabled
              ? const LinearGradient(
                  colors: <Color>[Color(0xFF6970FF), Color(0xFF5760F5)],
                )
              : const LinearGradient(
                  colors: <Color>[Color(0xFF33374D), Color(0xFF2B2F42)],
                ),
        ),
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: isSubmitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Criar Conta',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
