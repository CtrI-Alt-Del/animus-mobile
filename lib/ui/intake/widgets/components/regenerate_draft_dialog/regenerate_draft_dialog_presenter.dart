import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

final class RegenerateDraftDialogPresenter {
  final Signal<String> comments = signal<String>('');
  final Signal<String?> validationError = signal<String?>(null);
  final Signal<bool> isSubmitting = signal<bool>(false);

  late final ReadonlySignal<String> normalizedComments = computed<String>(() {
    return comments.value.trim();
  });

  late final ReadonlySignal<bool> canConfirm = computed<bool>(() {
    return normalizedComments.value.isNotEmpty && !isSubmitting.value;
  });

  void updateComments(String value) {
    comments.value = value;
    if (value.trim().isNotEmpty) {
      validationError.value = null;
    }
  }

  Future<bool> confirm(Future<void> Function(String comments) onConfirm) async {
    final String normalized = normalizedComments.value;
    if (normalized.isEmpty) {
      validationError.value =
          'Descreva as alterações desejadas para regerar a minuta.';
      return false;
    }

    validationError.value = null;
    isSubmitting.value = true;

    unawaited(Future<void>.sync(() => onConfirm(normalized)));
    return true;
  }

  void dispose() {
    comments.dispose();
    validationError.dispose();
    isSubmitting.dispose();
    normalizedComments.dispose();
    canConfirm.dispose();
  }
}

final regenerateDraftDialogPresenterProvider =
    Provider.autoDispose<RegenerateDraftDialogPresenter>((Ref ref) {
      final RegenerateDraftDialogPresenter presenter =
          RegenerateDraftDialogPresenter();
      ref.onDispose(presenter.dispose);
      return presenter;
    });
