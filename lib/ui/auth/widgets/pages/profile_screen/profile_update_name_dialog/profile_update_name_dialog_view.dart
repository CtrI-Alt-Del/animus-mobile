import 'package:flutter/material.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/auth/widgets/pages/profile_screen/profile_update_name_dialog/profile_update_name_dialog_presenter.dart';

class ProfileUpdateNameDialogView extends StatefulWidget {
  final String initialName;

  const ProfileUpdateNameDialogView({required this.initialName, super.key});

  @override
  State<ProfileUpdateNameDialogView> createState() =>
      _ProfileUpdateNameDialogViewState();
}

class _ProfileUpdateNameDialogViewState
    extends State<ProfileUpdateNameDialogView> {
  static const ProfileUpdateNameDialogPresenter _presenter =
      ProfileUpdateNameDialogPresenter();

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 352),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: tokens.surfaceCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Atualizar nome',
              style: textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder:
                  (
                    BuildContext context,
                    TextEditingValue value,
                    Widget? child,
                  ) {
                    final bool isEnabled = _presenter.canSubmit(
                      initialName: widget.initialName,
                      currentName: value.text,
                    );

                    return TextField(
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      style: textTheme.bodyMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      onSubmitted: (_) {
                        if (!isEnabled) {
                          return;
                        }
                        Navigator.of(
                          context,
                        ).pop(_presenter.sanitizeName(_controller.text));
                      },
                      decoration: InputDecoration(
                        hintText: 'Nome completo',
                        hintStyle: textTheme.bodyMedium?.copyWith(
                          color: tokens.textMuted,
                        ),
                        filled: true,
                        fillColor: tokens.surfacePage,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: tokens.borderStrong),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: tokens.accent),
                        ),
                      ),
                    );
                  },
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder:
                  (
                    BuildContext context,
                    TextEditingValue value,
                    Widget? child,
                  ) {
                    final bool isEnabled = _presenter.canSubmit(
                      initialName: widget.initialName,
                      currentName: value.text,
                    );

                    return Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              side: BorderSide(color: tokens.borderSubtle),
                              backgroundColor: tokens.surfaceElevated,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancelar',
                              style: textTheme.bodyMedium?.copyWith(
                                color: tokens.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: !isEnabled
                                ? null
                                : () => Navigator.of(context).pop(
                                    _presenter.sanitizeName(_controller.text),
                                  ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: tokens.accent,
                              foregroundColor: const Color(0xFF0B0B0E),
                            ),
                            child: Text(
                              'Atualizar',
                              style: textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF0B0B0E),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
            ),
          ],
        ),
      ),
    );
  }
}
