import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_type_dto.dart';

final class CreateAnalysisTypeDialogPresenter {
  static const List<AnalysisTypeDto> orderedTypes = <AnalysisTypeDto>[
    AnalysisTypeDto.caseAssessment,
    AnalysisTypeDto.firstInstance,
    AnalysisTypeDto.secondInstance,
  ];

  late final Signal<AnalysisTypeDto> selectedType;

  CreateAnalysisTypeDialogPresenter({
    AnalysisTypeDto initialType = AnalysisTypeDto.firstInstance,
  }) {
    selectedType = signal<AnalysisTypeDto>(initialType);
  }

  AnalysisTypeDto get selected => selectedType.value;

  bool isSelected(AnalysisTypeDto type) {
    return selectedType.value == type;
  }

  void selectType(AnalysisTypeDto type) {
    if (selectedType.value == type) {
      return;
    }
    selectedType.value = type;
  }

  String titleFor(AnalysisTypeDto type) {
    switch (type) {
      case AnalysisTypeDto.caseAssessment:
        return 'Avaliacao de caso';
      case AnalysisTypeDto.firstInstance:
        return 'Primeira instancia';
      case AnalysisTypeDto.secondInstance:
        return 'Segunda instancia';
    }
  }

  String descriptionFor(AnalysisTypeDto type) {
    switch (type) {
      case AnalysisTypeDto.caseAssessment:
        return 'Diagnostico inicial do caso';
      case AnalysisTypeDto.firstInstance:
        return 'Resposta a peticao inicial';
      case AnalysisTypeDto.secondInstance:
        return 'Revisao de decisao em grau de recurso';
    }
  }

  IconData iconFor(AnalysisTypeDto type) {
    switch (type) {
      case AnalysisTypeDto.caseAssessment:
        return Icons.fact_check_outlined;
      case AnalysisTypeDto.firstInstance:
        return Icons.gavel_outlined;
      case AnalysisTypeDto.secondInstance:
        return Icons.account_balance_outlined;
    }
  }

  void dispose() {
    selectedType.dispose();
  }
}
