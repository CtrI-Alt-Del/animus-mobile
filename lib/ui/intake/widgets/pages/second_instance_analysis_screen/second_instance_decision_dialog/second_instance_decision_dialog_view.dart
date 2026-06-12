import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_decision_dialog/second_instance_decision_dialog_presenter.dart';

class SecondInstanceDecisionDialogView extends ConsumerStatefulWidget {
  final String initialDescription;
  final Future<String?> Function(String description) onConfirm;

  const SecondInstanceDecisionDialogView({
    required this.onConfirm,
    this.initialDescription = '',
    super.key,
  });

  @override
  ConsumerState<SecondInstanceDecisionDialogView> createState() {
    return _SecondInstanceDecisionDialogViewState();
  }
}

class _SecondInstanceDecisionDialogViewState
    extends ConsumerState<SecondInstanceDecisionDialogView> {
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SecondInstanceDecisionDialogPresenter presenter = ref.watch(
      secondInstanceDecisionDialogPresenterProvider((
        initialDescription: widget.initialDescription,
        onConfirm: widget.onConfirm,
      )),
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: tokens.surfacePage,
      appBar: AppBar(
        backgroundColor: tokens.surfacePage,
        foregroundColor: tokens.textPrimary,
        title: const Text('Orientação da decisão'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: 'Fechar',
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Descreva como a decisão deve ser orientada para apoiar a análise e a geração da minuta.',
                style: textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Watch((BuildContext context) {
                presenter.description.watch(context);
                final String? errorMessage = presenter.errorMessage.watch(
                  context,
                );

                return TextField(
                  controller: _descriptionController,
                  autofocus: true,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  minLines: 10,
                  maxLines: 16,
                  onChanged: presenter.updateDescription,
                  style: textTheme.bodyMedium?.copyWith(
                    color: tokens.textPrimary,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Descreva a orientação da sua decisão...',
                    hintStyle: textTheme.bodySmall?.copyWith(
                      color: tokens.textMuted,
                      height: 1.5,
                    ),
                    errorText: errorMessage,
                    filled: true,
                    fillColor: tokens.surfaceCard,
                    contentPadding: const EdgeInsets.all(18),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: tokens.borderStrong),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: tokens.accent, width: 1.4),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: tokens.danger),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: tokens.danger, width: 1.4),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: tokens.surfacePage,
            border: Border(top: BorderSide(color: tokens.borderSubtle)),
          ),
          child: Watch((BuildContext context) {
            final bool canConfirm = presenter.canConfirm.watch(context);
            final bool isSubmitting = presenter.isSubmitting.watch(context);

            return FilledButton.icon(
              onPressed: canConfirm
                  ? () {
                      unawaited(presenter.confirm(context));
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
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: tokens.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(
                'Confirmar',
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF0B0B0E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
