import 'package:animus/theme.dart';
import 'package:flutter/material.dart';

class CreateFolderModalView extends StatefulWidget {
  final Future<void> Function(String name) onCreate;

  const CreateFolderModalView({super.key, required this.onCreate});

  @override
  State<CreateFolderModalView> createState() => _CreateFolderModalViewState();
}

class _CreateFolderModalViewState extends State<CreateFolderModalView> {
  final TextEditingController _controller = TextEditingController();
  bool _isCreating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      await widget.onCreate(name);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Não foi possível criar a pasta. Tente novamente em instantes.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surfacePage,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nova pasta',
              style: textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              style: textTheme.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Nome da pasta',
                labelStyle: textTheme.bodySmall,
                hintStyle: textTheme.bodySmall,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Ex: Ações Civis',
                errorText: _errorMessage,
              ),
              autofocus: true,
              enabled: !_isCreating,
              onSubmitted: (_) => _handleCreate(),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isCreating
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isCreating ? null : _handleCreate,
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Criar pasta'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
