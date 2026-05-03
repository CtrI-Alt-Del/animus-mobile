import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'package:animus/constants/env.dart';
import 'package:animus/core/shared/interfaces/push_notification_driver.dart';

class OneSignalPushNotificationDriver implements PushNotificationDriver {
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
      print('OneSignal initialized');
    } catch (_) {}
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
