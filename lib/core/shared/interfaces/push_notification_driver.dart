abstract class PushNotificationDriver {
  Future<void> initialize();

  Future<bool> requestPermission({bool fallbackToSettings = false});

  Future<void> identifyUser(String accountId);

  Future<void> clearUser();
}
