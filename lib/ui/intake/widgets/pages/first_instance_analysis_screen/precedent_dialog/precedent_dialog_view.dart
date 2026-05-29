import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:flutter/material.dart';

import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/precedent_dialog/precedent_dialog_view.dart';

class PrecedentDialogView extends StatelessWidget {
  final String analysisId;
  final AnalysisPrecedentDto precedent;

  const PrecedentDialogView({
    required this.analysisId,
    required this.precedent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnalysisPrecedentDialogView(
      analysisId: analysisId,
      precedent: precedent,
    );
  }
}
