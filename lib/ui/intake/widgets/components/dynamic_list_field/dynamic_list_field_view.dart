import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class DynamicListFieldView extends StatelessWidget {
  final List<String> items;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(int index, String value) onUpdate;
  final String addLabel;
  final String itemLabel;
  final String itemHintText;
  final int minItems;
  final int minLines;
  final int maxLines;
  final String emptyItemErrorText;
  final String? Function(int index, String value)? itemErrorTextBuilder;

  const DynamicListFieldView({
    required this.items,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
    required this.addLabel,
    required this.itemLabel,
    required this.itemHintText,
    this.minItems = 1,
    this.minLines = 2,
    this.maxLines = 4,
    this.emptyItemErrorText = 'Campo obrigatório.',
    this.itemErrorTextBuilder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;

    return Column(
      children: <Widget>[
        ...items.asMap().entries.map((MapEntry<int, String> entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DynamicListItemField(
              key: ValueKey<int>(entry.key),
              index: entry.key,
              value: entry.value,
              itemCount: items.length,
              itemLabel: itemLabel,
              itemHintText: itemHintText,
              minItems: minItems,
              minLines: minLines,
              maxLines: maxLines,
              emptyItemErrorText: emptyItemErrorText,
              itemErrorTextBuilder: itemErrorTextBuilder,
              onChanged: (String value) => onUpdate(entry.key, value),
              onRemove: () => onRemove(entry.key),
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onAdd,
            icon: Icon(Icons.add_rounded, color: tokens.accent),
            label: Text(addLabel),
          ),
        ),
      ],
    );
  }
}

class _DynamicListItemField extends StatefulWidget {
  final int index;
  final String value;
  final int itemCount;
  final String itemLabel;
  final String itemHintText;
  final int minItems;
  final int minLines;
  final int maxLines;
  final String emptyItemErrorText;
  final String? Function(int index, String value)? itemErrorTextBuilder;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  const _DynamicListItemField({
    required this.index,
    required this.value,
    required this.itemCount,
    required this.itemLabel,
    required this.itemHintText,
    required this.minItems,
    required this.minLines,
    required this.maxLines,
    required this.emptyItemErrorText,
    required this.itemErrorTextBuilder,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  @override
  State<_DynamicListItemField> createState() => _DynamicListItemFieldState();
}

class _DynamicListItemFieldState extends State<_DynamicListItemField> {
  static const double _fieldFontSize = 14;

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _DynamicListItemField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text == widget.value) {
      return;
    }

    _controller.value = TextEditingValue(
      text: widget.value,
      selection: TextSelection.collapsed(offset: widget.value.length),
    );
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
    final bool canRemove = widget.itemCount > widget.minItems;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: TextFormField(
            controller: _controller,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            onChanged: widget.onChanged,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: _fieldFontSize),
            decoration: InputDecoration(
              labelText: '${widget.itemLabel} ${widget.index + 1}',
              hintText: widget.itemHintText,
              alignLabelWithHint: true,
              errorText: _errorText(widget.value),
              filled: true,
              fillColor: tokens.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tokens.borderStrong),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tokens.borderStrong),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tokens.accent, width: 1.2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tokens.danger),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tokens.danger, width: 1.2),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: IconButton(
            onPressed: canRemove ? widget.onRemove : null,
            tooltip: canRemove
                ? 'Remover item'
                : 'É necessário manter ao menos ${widget.minItems} item.',
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ],
    );
  }

  String? _errorText(String value) {
    if (widget.itemErrorTextBuilder != null) {
      return widget.itemErrorTextBuilder!(widget.index, value);
    }

    if (value.trim().isNotEmpty) {
      return null;
    }

    return widget.emptyItemErrorText;
  }
}
