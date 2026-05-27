import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/analysis_type_dto.dart';

final class AnalysisTypePresentation {
  const AnalysisTypePresentation._();

  static String shortLabelFor(AnalysisTypeDto type) {
    switch (type) {
      case AnalysisTypeDto.caseAssessment:
        return 'Avaliação de caso';
      case AnalysisTypeDto.firstInstance:
        return 'Primeira instância';
      case AnalysisTypeDto.secondInstance:
        return 'Segunda instância';
    }
  }

  static IconData iconFor(AnalysisTypeDto type) {
    switch (type) {
      case AnalysisTypeDto.caseAssessment:
        return Icons.fact_check_outlined;
      case AnalysisTypeDto.firstInstance:
        return Icons.gavel_outlined;
      case AnalysisTypeDto.secondInstance:
        return Icons.account_balance_outlined;
    }
  }

  /// Cor de identidade visual do tipo de análise.
  ///
  /// Usada como base para tints de fundo/borda em badges, mantendo
  /// distinção visual rápida entre os 3 tipos no dark theme do app.
  static Color colorFor(AnalysisTypeDto type) {
    switch (type) {
      case AnalysisTypeDto.caseAssessment:
        return const Color(0xFFB48BE6);
      case AnalysisTypeDto.firstInstance:
        return const Color(0xFFFBE26D);
      case AnalysisTypeDto.secondInstance:
        return const Color(0xFF7BC4E3);
    }
  }
}
