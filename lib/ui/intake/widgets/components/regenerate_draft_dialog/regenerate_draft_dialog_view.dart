import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/components/regenerate_draft_dialog/regenerate_draft_dialog_presenter.dart';

class RegenerateDraftDialogView extends ConsumerWidget {
  final String title;
  final String description;
  final String textFieldLabel;
  final String confirmLabel;
  final Future<void> Function(String comments) onConfirm;

  const RegenerateDraftDialogView({
    required this.title,
    required this.description,
    required this.textFieldLabel,
    required this.confirmLabel,
    required this.onConfirm,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RegenerateDraftDialogPresenter presenter = ref.watch(
      regenerateDraftDialogPresenterProvider,
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom - 48;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: availableHeight > 240 ? availableHeight : 240,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: tokens.surfaceCard,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: tokens.borderStrong),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: tokens.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: tokens.accent.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: tokens.accent,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tokens.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tokens.borderSubtle),
                  ),
                  child: Text(
                    description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Watch((BuildContext context) {
                  presenter.comments.watch(context);
                  final String? validationError = presenter.validationError
                      .watch(context);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Text(
                          textFieldLabel,
                          style: textTheme.labelLarge?.copyWith(
                            color: tokens.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextField(
                        autofocus: true,
                        textInputAction: TextInputAction.newline,
                        minLines: 5,
                        maxLines: 8,
                        onChanged: presenter.updateComments,
                        style: textTheme.bodySmall?.copyWith(
                          color: tokens.textPrimary,
                          height: 1.45,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Descreva os ajustes esperados na nova minuta.',
                          hintStyle: textTheme.bodyMedium?.copyWith(
                            color: tokens.textMuted,
                            height: 1.45,
                          ),
                          errorText: validationError,
                          filled: true,
                          fillColor: tokens.surfacePage,
                          contentPadding: const EdgeInsets.all(18),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: tokens.borderStrong),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: tokens.accent,
                              width: 1.4,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: tokens.danger),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: tokens.danger,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Watch((BuildContext context) {
                        final bool isSubmitting = presenter.isSubmitting.watch(
                          context,
                        );

                        return OutlinedButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            side: BorderSide(color: tokens.borderSubtle),
                            backgroundColor: tokens.surfaceElevated,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: textTheme.bodyMedium?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Watch((BuildContext context) {
                        final bool canConfirm = presenter.canConfirm.watch(
                          context,
                        );
                        final bool isSubmitting = presenter.isSubmitting.watch(
                          context,
                        );

                        return FilledButton.icon(
                          onPressed: canConfirm
                              ? () {
                                  unawaited(() async {
                                    final bool didConfirm = await presenter
                                        .confirm(onConfirm);
                                    if (!didConfirm || !context.mounted) {
                                      return;
                                    }

                                    Navigator.of(context).pop(true);
                                  }());
                                }
                              : null,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: tokens.accent,
                            foregroundColor: const Color(0xFF0B0B0E),
                          ),
                          icon: isSubmitting
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: tokens.white,
                                  ),
                                )
                              : const SizedBox(),
                          label: Text(
                            confirmLabel,
                            style: textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF0B0B0E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
