import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/core/shared/interfaces/push_notification_driver.dart';
import 'package:animus/drivers/push-notification-driver/onesignal/onesignal_push_notification_driver.dart';

export 'package:animus/drivers/push-notification-driver/onesignal/onesignal_push_notification_driver.dart';

final Provider<PushNotificationDriver> pushNotificationDriverProvider =
    Provider<PushNotificationDriver>((Ref ref) {
      return const OneSignalPushNotificationDriver();
    });
