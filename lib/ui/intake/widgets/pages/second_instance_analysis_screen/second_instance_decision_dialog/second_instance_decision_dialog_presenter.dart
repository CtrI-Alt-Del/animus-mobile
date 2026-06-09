import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

typedef SecondInstanceDecisionDialogConfirmCallback =
    Future<String?> Function(String description);

class SecondInstanceDecisionDialogPresenter {
  static const String _emptyDescriptionMessage =
      'Descreva a orientação da decisão para continuar.';
  static const String _defaultSubmitErrorMessage =
      'Não foi possível confirmar a decisão agora. Tente novamente.';

  final SecondInstanceDecisionDialogConfirmCallback _onConfirm;

  final Signal<String> description;
  final Signal<bool> isSubmitting = signal<bool>(false);
  final Signal<String?> errorMessage = signal<String?>(null);

  late final ReadonlySignal<String> _normalizedDescription = computed<String>(
    () {
      return description.value.trim();
    },
  );

  late final ReadonlySignal<bool> canConfirm = computed<bool>(() {
    return _normalizedDescription.value.isNotEmpty && !isSubmitting.value;
  });

  SecondInstanceDecisionDialogPresenter({
    required String initialDescription,
    required SecondInstanceDecisionDialogConfirmCallback onConfirm,
  }) : _onConfirm = onConfirm,
       description = signal<String>(initialDescription);

  void updateDescription(String value) {
    description.value = value;
    if (value.trim().isNotEmpty) {
      errorMessage.value = null;
    }
  }

  Future<void> confirm(BuildContext context) async {
    final String normalizedDescription = _normalizedDescription.value;
    if (normalizedDescription.isEmpty) {
      errorMessage.value = _emptyDescriptionMessage;
      return;
    }

    if (isSubmitting.value) {
      return;
    }

    errorMessage.value = null;
    isSubmitting.value = true;

    try {
      final String? submitError = await _onConfirm(normalizedDescription);
      if (submitError == null) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      errorMessage.value = submitError.isEmpty
          ? _defaultSubmitErrorMessage
          : submitError;
    } catch (_) {
      errorMessage.value = _defaultSubmitErrorMessage;
    } finally {
      isSubmitting.value = false;
    }
  }

  void dispose() {
    description.dispose();
    isSubmitting.dispose();
    errorMessage.dispose();
    _normalizedDescription.dispose();
    canConfirm.dispose();
  }
}

final secondInstanceDecisionDialogPresenterProvider = Provider.autoDispose
    .family<
      SecondInstanceDecisionDialogPresenter,
      ({
        String initialDescription,
        SecondInstanceDecisionDialogConfirmCallback onConfirm,
      })
    >((
      Ref ref,
      ({
        String initialDescription,
        SecondInstanceDecisionDialogConfirmCallback onConfirm,
      })
      args,
    ) {
      final SecondInstanceDecisionDialogPresenter presenter =
          SecondInstanceDecisionDialogPresenter(
            initialDescription: args.initialDescription,
            onConfirm: args.onConfirm,
          );

      ref.onDispose(presenter.dispose);
      return presenter;
    });
