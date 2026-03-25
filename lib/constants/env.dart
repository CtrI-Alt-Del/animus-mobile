import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get animusServerAppUrl => dotenv.env['ANIMUS_SERVER_APP_URL']!;
}
