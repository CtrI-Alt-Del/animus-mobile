import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

class CourtFilterSectionPresenter {
  final Signal<Set<String>> expandedGroups;

  CourtFilterSectionPresenter({required Set<String> initialExpandedGroups})
    : expandedGroups = signal<Set<String>>(initialExpandedGroups);

  void toggleGroup(String title) {
    final Set<String> nextGroups = Set<String>.from(expandedGroups.value);

    if (nextGroups.contains(title)) {
      nextGroups.remove(title);
    } else {
      nextGroups.add(title);
    }

    expandedGroups.value = nextGroups;
  }

  void dispose() {
    expandedGroups.dispose();
  }
}

final courtFilterSectionPresenterProvider = Provider.autoDispose
    .family<CourtFilterSectionPresenter, String>((
      Ref ref,
      String initialExpandedGroup,
    ) {
      final CourtFilterSectionPresenter presenter = CourtFilterSectionPresenter(
        initialExpandedGroups: <String>{initialExpandedGroup},
      );

      ref.onDispose(presenter.dispose);

      return presenter;
    });
