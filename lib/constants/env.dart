class Env {
  static const String animusServerAppUrl = String.fromEnvironment(
    'ANIMUS_SERVER_APP_URL',
    defaultValue: 'https://example.invalid',
  );
}
