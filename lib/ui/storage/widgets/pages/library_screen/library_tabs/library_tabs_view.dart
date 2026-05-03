import 'package:animus/theme.dart';
import 'package:flutter/material.dart';

class LibraryTabsView extends StatelessWidget {
  static const List<String> _labels = <String>['Todas', 'Pastas'];

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const LibraryTabsView({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Row(
        children: List<Widget>.generate(_labels.length, (int index) {
          final bool isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[tokens.accent, tokens.accentStrong],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _labels[index],
                  style: textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? tokens.surfacePage
                        : tokens.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
