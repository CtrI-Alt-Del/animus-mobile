import 'dart:async';

import 'package:flutter/material.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/components/save_status_indicator/save_status.dart';

class SaveStatusIndicatorView extends StatefulWidget {
  final SaveStatus status;

  const SaveStatusIndicatorView({required this.status, super.key});

  @override
  State<SaveStatusIndicatorView> createState() =>
      _SaveStatusIndicatorViewState();
}

class _SaveStatusIndicatorViewState extends State<SaveStatusIndicatorView> {
  static const Duration _savedVisibleDuration = Duration(seconds: 3);

  SaveStatus _visibleStatus = SaveStatus.idle;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _syncStatus(widget.status, shouldRebuild: false);
  }

  @override
  void didUpdateWidget(covariant SaveStatusIndicatorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status == widget.status) {
      return;
    }

    _syncStatus(widget.status);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _syncStatus(SaveStatus status, {bool shouldRebuild = true}) {
    _hideTimer?.cancel();
    _visibleStatus = status;

    if (_visibleStatus == SaveStatus.saved) {
      _hideTimer = Timer(_savedVisibleDuration, () {
        if (!mounted || _visibleStatus != SaveStatus.saved) {
          return;
        }

        setState(() {
          _visibleStatus = SaveStatus.idle;
        });
      });
    }

    if (mounted && shouldRebuild) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (_visibleStatus == SaveStatus.idle) {
      return const SizedBox.shrink();
    }

    Widget leading;
    String label;
    Color color;

    switch (_visibleStatus) {
      case SaveStatus.saving:
        leading = SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: tokens.accent,
          ),
        );
        label = 'Salvando...';
        color = tokens.textSecondary;
        break;
      case SaveStatus.saved:
        leading = Icon(
          Icons.check_circle_rounded,
          size: 16,
          color: tokens.success,
        );
        label = 'Salvo';
        color = tokens.success;
        break;
      case SaveStatus.error:
        leading = Icon(Icons.error_rounded, size: 16, color: tokens.danger);
        label = 'Erro ao salvar';
        color = tokens.danger;
        break;
      case SaveStatus.idle:
        return const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Container(
        key: ValueKey<SaveStatus>(_visibleStatus),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            leading,
            const SizedBox(width: 6),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
