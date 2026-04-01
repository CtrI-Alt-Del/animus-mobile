import 'package:flutter/material.dart';

import 'package:animus/theme.dart';

class HomeBottomNavigationView extends StatelessWidget {
  static const List<({String label, IconData icon, IconData selectedIcon})>
  _destinations = <({String label, IconData icon, IconData selectedIcon})>[
    (
      label: 'HOME',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_outlined,
    ),
    (
      label: 'PERFIL',
      icon: Icons.person_outline,
      selectedIcon: Icons.person_outline,
    ),
    (
      label: 'BIBLIOTECA',
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder_outlined,
    ),
  ];

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const HomeBottomNavigationView({
    required this.currentIndex,
    required this.onDestinationSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: tokens.accent.withValues(alpha: 0.35),
              width: 2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              children: List<Widget>.generate(_destinations.length, (
                int index,
              ) {
                final ({String label, IconData icon, IconData selectedIcon})
                destination = _destinations[index];
                final bool isSelected = currentIndex == index;
                final Color foregroundColor =
                    isSelected ? tokens.accent : tokens.textSecondary;

                return Expanded(
                  child: InkWell(
                    onTap: () {
                      onDestinationSelected(index);
                    },
                    borderRadius: BorderRadius.circular(26),
                    child: SizedBox(
                      height: 58,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            isSelected
                                ? destination.selectedIcon
                                : destination.icon,
                            size: 24,
                            color: foregroundColor,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            destination.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.6,
                              color: foregroundColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
