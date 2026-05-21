import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class PreviewTextBlockView extends StatefulWidget {
  final String label;
  final String value;

  const PreviewTextBlockView({
    required this.label,
    required this.value,
    super.key,
  });

  @override
  State<PreviewTextBlockView> createState() => _PreviewTextBlockViewState();
}

class _PreviewTextBlockViewState extends State<PreviewTextBlockView> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String resolvedValue = widget.value.trim().isEmpty
        ? 'Nao informado.'
        : widget.value.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.label,
          style: textTheme.labelSmall?.copyWith(
            color: tokens.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          resolvedValue,
          maxLines: _isExpanded ? null : 2,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
        ),
        if (resolvedValue.length > 120)
          TextButton(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(_isExpanded ? 'Mostrar menos' : 'Mostrar mais'),
          ),
      ],
    );
  }
}
