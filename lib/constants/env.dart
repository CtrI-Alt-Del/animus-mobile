import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static late final String animusServerAppUrl;

  static void init() {
    animusServerAppUrl = _validateUrl('ANIMUS_SERVER_APP_URL');
  }

  static String _validateUrl(String key) {
    final configuredValue = (dotenv.env[key] ?? '').trim();
    if (configuredValue.isEmpty) {
      throw StateError('$key is empty. Configure it in .env.');
    }

    final uri = Uri.tryParse(configuredValue);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError(
        '$key must be a valid absolute URL. Current value: $configuredValue',
      );
    }

    return configuredValue;
  }
}
