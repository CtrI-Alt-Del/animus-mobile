import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/analysis_type_presentation/analysis_type_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalysisTypePresentation', () {
    test('shortLabelFor retorna o rotulo PT-BR para cada tipo', () {
      expect(
        AnalysisTypePresentation.shortLabelFor(AnalysisTypeDto.caseAssessment),
        'Avaliação de caso',
      );
      expect(
        AnalysisTypePresentation.shortLabelFor(AnalysisTypeDto.firstInstance),
        'Primeira instância',
      );
      expect(
        AnalysisTypePresentation.shortLabelFor(AnalysisTypeDto.secondInstance),
        'Segunda instância',
      );
    });

    test('iconFor retorna icones Material distintos para cada tipo', () {
      expect(
        AnalysisTypePresentation.iconFor(AnalysisTypeDto.caseAssessment),
        Icons.fact_check_outlined,
      );
      expect(
        AnalysisTypePresentation.iconFor(AnalysisTypeDto.firstInstance),
        Icons.gavel_outlined,
      );
      expect(
        AnalysisTypePresentation.iconFor(AnalysisTypeDto.secondInstance),
        Icons.account_balance_outlined,
      );
    });
  });
}
