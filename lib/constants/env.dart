import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get animusServerAppUrl => dotenv.env['ANIMUS_SERVER_APP_URL']!;

  static String get googleIosClientId =>
      _nullableValue('ANIMUS_GOOGLE_IOS_CLIENT_ID');

  static String get googleServerClientId =>
      _nullableValue('ANIMUS_GOOGLE_SERVER_CLIENT_ID');

  static String get gcsUrl => _nullableValue('GCS_URL');

  static String _nullableValue(String key) {
    final String? value;
    try {
      value = dotenv.env[key];
    } catch (_) {
      throw Exception(
        'Nenhuma variável de ambiente encontrada para a chave $key.',
      );
    }

    if (value == null) {
      throw Exception(
        'Nenhuma variável de ambiente encontrada para a chave $key.',
      );
    }

    final String trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      throw Exception(
        'Nenhuma variável de ambiente encontrada para a chave $key.',
      );
    }

    return trimmedValue;
  }
}
