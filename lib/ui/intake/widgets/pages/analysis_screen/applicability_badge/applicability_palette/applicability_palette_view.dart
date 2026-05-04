import 'package:flutter/material.dart';

class ApplicabilityPaletteView extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final bool showBorder;
  final TextOverflow overflow;
  final int maxLines;

  const ApplicabilityPaletteView({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    this.showBorder = true,
    this.overflow = TextOverflow.visible,
    this.maxLines = 1,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: showBorder ? Border.all(color: borderColor) : null,
      ),
      child: Text(
        label,
        maxLines: maxLines,
        overflow: overflow,
        style: textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ApplicabilityPaletteData {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  const ApplicabilityPaletteData({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });
}
