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
}
