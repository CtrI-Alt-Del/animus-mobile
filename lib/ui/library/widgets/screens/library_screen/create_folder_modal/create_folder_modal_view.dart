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
          color: tokens.surfaceCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: tokens.borderSubtle),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.borderStrong,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Icon(
                  Icons.create_new_folder_outlined,
                  color: tokens.accent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Nova pasta',
                  style: textTheme.titleMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_isCreating,
              textInputAction: TextInputAction.done,
              style: textTheme.bodyMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Ex: Ações Civis',
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: tokens.danger),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: tokens.danger),
                ),
                errorText: _errorMessage,
                errorStyle: textTheme.bodySmall?.copyWith(color: tokens.danger),
              ),
              onSubmitted: (_) => _handleCreate(),
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isCreating
                        ? null
                        : () => Navigator.of(context).pop(),
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
                    onPressed: _isCreating ? null : _handleCreate,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: tokens.accent,
                      foregroundColor: tokens.onAccent,
                      disabledBackgroundColor: tokens.accent.withValues(
                        alpha: 0.4,
                      ),
                      disabledForegroundColor: tokens.surfacePage.withValues(
                        alpha: 0.6,
                      ),
                    ),
                    child: _isCreating
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                tokens.surfacePage,
                              ),
                            ),
                          )
                        : Text(
                            'Criar pasta',
                            style: textTheme.bodyMedium?.copyWith(
                              color: tokens.surfacePage,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
