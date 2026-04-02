import 'package:flutter/material.dart';

class ProfileDividerView extends StatelessWidget {
  final Color color;

  const ProfileDividerView({required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: color);
  }
}
