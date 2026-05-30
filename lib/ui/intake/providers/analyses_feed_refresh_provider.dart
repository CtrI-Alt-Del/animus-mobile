import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalysesFeedRefreshNotifier extends ChangeNotifier {
  void notifyChanged() {
    notifyListeners();
  }
}

final Provider<AnalysesFeedRefreshNotifier>
analysesFeedRefreshNotifierProvider = Provider<AnalysesFeedRefreshNotifier>((
  Ref ref,
) {
  return AnalysesFeedRefreshNotifier();
});
