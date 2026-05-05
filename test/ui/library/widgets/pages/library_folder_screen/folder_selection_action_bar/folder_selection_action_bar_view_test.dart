import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/library/widgets/screens/library_folder_screen/folder_selection_action_bar/index.dart';

void main() {
  testWidgets(
    'renderiza em largura finita sem herdar largura infinita do tema global',
    (WidgetTester tester) async {
      bool moved = false;
      bool archived = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: FolderSelectionActionBar(
                  selectedCount: 2,
                  isOperating: false,
                  onMove: () {
                    moved = true;
                  },
                  onArchive: () {
                    archived = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('2'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open_outlined), findsOneWidget);
      expect(find.byIcon(Icons.archive_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.folder_open_outlined));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.archive_outlined));
      await tester.pump();

      expect(moved, isTrue);
      expect(archived, isTrue);
    },
  );
}
