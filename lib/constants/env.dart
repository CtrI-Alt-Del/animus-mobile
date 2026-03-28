import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get animusServerAppUrl => dotenv.env['ANIMUS_SERVER_APP_URL']!;

  static String? get googleIosClientId =>
      _nullableValue('ANIMUS_GOOGLE_IOS_CLIENT_ID');

  static String? get googleServerClientId =>
      _nullableValue('ANIMUS_GOOGLE_SERVER_CLIENT_ID');

  static String? _nullableValue(String key) {
    final String? value;
    try {
      value = dotenv.env[key];
    } catch (_) {
      return null;
    }

    if (value == null) {
      return null;
    }

    final String trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return null;
    }

    return trimmedValue;
  }
}
