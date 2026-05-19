import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'package:animus/constants/env.dart';
import 'package:animus/core/shared/interfaces/push_notification_driver.dart';

class OneSignalPushNotificationDriver implements PushNotificationDriver {
  static bool _foregroundListenerRegistered = false;
  static bool _clickListenerRegistered = false;

  const OneSignalPushNotificationDriver();

  @override
  Future<void> initialize() async {
    final String appId = Env.oneSignalAppId;

    try {
      if (kDebugMode) {
        await OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      }
    } catch (_) {}

    try {
      await OneSignal.initialize(appId);
    } catch (_) {}

    if (_foregroundListenerRegistered) {
      return;
    }

    try {
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        event.preventDefault();
      });
      _foregroundListenerRegistered = true;
    } catch (_) {}

    if (_clickListenerRegistered) {
      return;
    }

    try {
      OneSignal.Notifications.addClickListener((event) {
        final String analysisId = _extractAnalysisId(event.notification);
        if (analysisId.isEmpty) {
          return;
        }

        // _navigationDriver.goTo(Routes.getAnalysis(analysisId: analysisId));
      });
      _clickListenerRegistered = true;
    } catch (_) {}
  }

  static String _extractAnalysisId(OSNotification notification) {
    final Map<String, dynamic>? additionalData = notification.additionalData;
    if (additionalData == null) {
      return '';
    }

    final dynamic rawAnalysisId = additionalData['analysis_id'];
    if (rawAnalysisId == null) {
      return '';
    }

    return rawAnalysisId.toString().trim();
  }

  @override
  Future<bool> requestPermission({bool fallbackToSettings = false}) async {
    try {
      return await OneSignal.Notifications.requestPermission(
        fallbackToSettings,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> identifyUser(String accountId) async {
    final String normalizedAccountId = accountId.trim();
    if (normalizedAccountId.isEmpty) {
      return;
    }

    try {
      await OneSignal.login(normalizedAccountId);
    } catch (_) {}
  }

  @override
  Future<void> clearUser() async {
    try {
      await OneSignal.logout();
    } catch (_) {}
  }
}
