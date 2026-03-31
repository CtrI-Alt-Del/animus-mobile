import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class AnalysisActionBarView extends StatelessWidget {
  final String fileActionLabel;
  final VoidCallback? onFileAction;
  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final bool isPrimaryBusy;
  final double? uploadProgress;
  final String? helperText;

  const AnalysisActionBarView({
    required this.fileActionLabel,
    required this.onFileAction,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.isPrimaryBusy,
    required this.uploadProgress,
    required this.helperText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: tokens.surfacePage,
        border: Border(top: BorderSide(color: tokens.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (uploadProgress != null) ...<Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: uploadProgress,
                minHeight: 6,
                backgroundColor: tokens.borderSubtle,
                valueColor: AlwaysStoppedAnimation<Color>(tokens.accent),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (helperText != null && helperText!.isNotEmpty) ...<Widget>[
            Text(
              helperText!,
              style: textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: onFileAction,
                  child: Text(fileActionLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: isPrimaryBusy ? null : onPrimaryAction,
                  child: isPrimaryBusy
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: tokens.surfacePage,
                          ),
                        )
                      : Text(primaryActionLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
