import 'package:flutter/material.dart';

import 'package:animus/theme.dart';
import 'archived_analyses_search_bar_presenter.dart';

class ArchivedAnalysesSearchBarView extends StatefulWidget {
  final String initialQuery;
  final void Function(String value) onQueryChanged;
  final VoidCallback onClear;

  const ArchivedAnalysesSearchBarView({
    required this.initialQuery,
    required this.onQueryChanged,
    required this.onClear,
    super.key,
  });

  @override
  State<ArchivedAnalysesSearchBarView> createState() =>
      _ArchivedAnalysesSearchBarViewState();
}

class _ArchivedAnalysesSearchBarViewState
    extends State<ArchivedAnalysesSearchBarView> {
  late final ArchivedAnalysesSearchBarPresenter _presenter;

  @override
  void initState() {
    super.initState();
    _presenter = ArchivedAnalysesSearchBarPresenter(
      initialQuery: widget.initialQuery,
      onQueryChanged: (String value) {
        widget.onQueryChanged(value);
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasText = _presenter.controller.text.isNotEmpty;

    return TextField(
      controller: _presenter.controller,
      style: textTheme.bodyMedium?.copyWith(color: tokens.textPrimary),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar por nome...',
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.textMuted),
        prefixIcon: Icon(Icons.search, color: tokens.textMuted, size: 20),
        suffixIcon: hasText
            ? IconButton(
                tooltip: 'Limpar busca',
                icon: Icon(Icons.close, color: tokens.textMuted, size: 18),
                onPressed: () {
                  _presenter.clear();
                  widget.onClear();
                },
              )
            : null,
        filled: true,
        fillColor: tokens.surfaceCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.accent),
        ),
      ),
    );
  }
}
