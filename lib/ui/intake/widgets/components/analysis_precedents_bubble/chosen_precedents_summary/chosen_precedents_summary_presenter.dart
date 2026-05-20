import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_presenter.dart';

class ChosenPrecedentsSummaryPresenter {
  final AnalysisPrecedentsBubblePresenter _bubblePresenter;

  ChosenPrecedentsSummaryPresenter({
    required AnalysisPrecedentsBubblePresenter bubblePresenter,
  }) : _bubblePresenter = bubblePresenter;

  Future<bool> unchoosePrecedent(AnalysisPrecedentDto precedent) {
    return _bubblePresenter.unchoosePrecedent(precedent);
  }

  String buildIdentifierLabel(AnalysisPrecedentDto precedent) {
    final String court = precedent.precedent.identifier.court.value;
    final String kind = precedent.precedent.identifier.kind.value;
    final int number = precedent.precedent.identifier.number;
    return '$court $kind $number';
  }
}

final chosenPrecedentsSummaryPresenterProvider = Provider.autoDispose
    .family<ChosenPrecedentsSummaryPresenter, String>((
      Ref ref,
      String analysisId,
    ) {
      final AnalysisPrecedentsBubblePresenter bubblePresenter = ref.watch(
        analysisPrecedentsBubblePresenterProvider(analysisId),
      );

      return ChosenPrecedentsSummaryPresenter(bubblePresenter: bubblePresenter);
    });
