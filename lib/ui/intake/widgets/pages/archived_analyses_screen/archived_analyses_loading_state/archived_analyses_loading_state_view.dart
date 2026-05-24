import 'package:flutter/material.dart';

import 'package:animus/ui/intake/widgets/pages/archived_analyses_screen/archived_analyses_skeleton_card/index.dart';

class ArchivedAnalysesLoadingStateView extends StatelessWidget {
  const ArchivedAnalysesLoadingStateView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        return const ArchivedAnalysesSkeletonCard();
      },
    );
  }
}
