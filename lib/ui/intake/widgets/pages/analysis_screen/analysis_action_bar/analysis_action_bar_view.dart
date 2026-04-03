import 'package:flutter/material.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/analysis_action_bar/file_action_button/index.dart';
import 'package:animus/ui/intake/widgets/pages/analysis_screen/analysis_action_bar/primary_action_button/index.dart';

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
            FileActionButton(label: fileActionLabel, onPressed: onFileAction),
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
          PrimaryActionButton(
            label: primaryActionLabel,
            onPressed: isPrimaryBusy ? null : onPrimaryAction,
            isBusy: isPrimaryBusy,
          ),
        ],
      ),
    );
  }
}
