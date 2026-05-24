import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/core/intake/dtos/petition_draft_dto.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/index.dart';

class PetitionDraftCardPresenter {
  String buildPreview(PetitionDraftDto draft, {int maxLength = 420}) {
    final String normalized = draft.content.trim();
    if (normalized.length <= maxLength) {
      return normalized;
    }

    return '${normalized.substring(0, maxLength).trimRight()}...';
  }

  Future<void> openDraftDialog(BuildContext context, PetitionDraftDto draft) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) {
          return PetitionDraftDialog(draft: draft);
        },
      ),
    );
  }
}

final petitionDraftCardPresenterProvider =
    Provider.autoDispose<PetitionDraftCardPresenter>((Ref ref) {
      return PetitionDraftCardPresenter();
    });
