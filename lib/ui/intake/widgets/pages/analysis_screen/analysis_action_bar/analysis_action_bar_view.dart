import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class AnalysisActionBarView extends StatelessWidget {
  final bool showFileAction;
  final String fileActionLabel;
  final VoidCallback? onFileAction;
  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final bool isPrimaryBusy;
  final String? helperText;

  const AnalysisActionBarView({
    this.showFileAction = true,
    required this.fileActionLabel,
    required this.onFileAction,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.isPrimaryBusy,
    required this.helperText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        border: Border(top: BorderSide(color: tokens.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showFileAction) ...<Widget>[
            _FileActionButton(label: fileActionLabel, onPressed: onFileAction),
            const SizedBox(height: 12),
          ],
          if (helperText != null && helperText!.isNotEmpty) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                helperText!,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
            ),
          ],
          _PrimaryActionButton(
            label: primaryActionLabel,
            onPressed: isPrimaryBusy ? null : onPrimaryAction,
            isBusy: isPrimaryBusy,
          ),
        ],
      ),
    );
  }
}

class _FileActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _FileActionButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.borderStrong, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.upload_file, color: tokens.textPrimary, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isBusy;

  const _PrimaryActionButton({
    required this.label,
    required this.onPressed,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Opacity(
      opacity: onPressed == null && !isBusy ? 0.5 : 1,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[tokens.accent, tokens.accentStrong],
            ),
          ),
          child: Center(
            child: isBusy
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tokens.surfacePage,
                    ),
                  )
                : Text(
                    label,
                    style: textTheme.labelLarge?.copyWith(
                      color: tokens.surfacePage,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
