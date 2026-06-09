import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/support_documents_section/support_document_item/support_document_item_view.dart';

import '../../../../../../../../fakers/intake/first_instance_analysis_report_dto_faker.dart';

void main() {
  testWidgets('should render upload state with progress and disabled remove', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _createWidget(
        SupportDocumentItemView(
          document: AnalysisDocumentDtoFaker.fake(name: 'briefing.pdf'),
          progress: 0.4,
          isUploading: true,
          enabled: true,
          onRemove: () {},
        ),
      ),
    );

    expect(find.text('briefing.pdf'), findsOneWidget);
    expect(find.text('Enviando documento de apoio...'), findsOneWidget);
    expect(find.text('40% concluído'), findsOneWidget);

    final IconButton removeButton = tester.widget<IconButton>(
      find.byType(IconButton),
    );
    expect(removeButton.onPressed, isNull);
  });

  testWidgets('should render attached document and call remove when enabled', (
    WidgetTester tester,
  ) async {
    int removeCalls = 0;

    await tester.pumpWidget(
      _createWidget(
        SupportDocumentItemView(
          document: AnalysisDocumentDtoFaker.fake(name: 'contrato.docx'),
          progress: null,
          isUploading: false,
          enabled: true,
          onRemove: () {
            removeCalls++;
          },
        ),
      ),
    );

    expect(find.text('Documento anexado'), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);

    await tester.tap(find.byTooltip('Remover documento'));
    await tester.pump();

    expect(removeCalls, 1);
  });
}

Widget _createWidget(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}
