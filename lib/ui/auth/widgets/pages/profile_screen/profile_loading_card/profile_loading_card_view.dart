import 'package:flutter/material.dart';

const Color _profileLoadingSurfaceColor = Color(0xFF1E1E24);
const Color _profileLoadingBorderColor = Color(0x33FBE26D);

class ProfileLoadingCardView extends StatelessWidget {
  const ProfileLoadingCardView({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _profileLoadingSurfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _profileLoadingBorderColor),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
