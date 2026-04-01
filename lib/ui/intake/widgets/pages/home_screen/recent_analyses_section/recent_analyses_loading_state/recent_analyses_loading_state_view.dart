import 'package:flutter/material.dart';

import 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_skeleton_card/index.dart';

class RecentAnalysesLoadingStateView extends StatelessWidget {
  const RecentAnalysesLoadingStateView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder:
          (BuildContext context, int index) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        return const RecentAnalysesSkeletonCard();
      },
    );
  }
}
