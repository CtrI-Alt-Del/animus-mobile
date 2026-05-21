import 'package:flutter/material.dart';

class ArchivedAnalysesSearchBarPresenter {
  final TextEditingController controller;
  final void Function(String value) onQueryChanged;

  ArchivedAnalysesSearchBarPresenter({
    required String initialQuery,
    required this.onQueryChanged,
  }) : controller = TextEditingController(text: initialQuery) {
    controller.addListener(_handleChange);
  }

  void _handleChange() {
    onQueryChanged(controller.text);
  }

  void clear() {
    if (controller.text.isEmpty) {
      return;
    }
    controller.clear();
  }

  void dispose() {
    controller.removeListener(_handleChange);
    controller.dispose();
  }
}
