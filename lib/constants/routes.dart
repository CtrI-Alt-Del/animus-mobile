class Routes {
  static const String home = '/';
  static const String signIn = '/auth/sign_in';
  static const String signUp = '/auth/sign_up';
  static const String emailConfirmation = '/auth/email_confirmation';
  static const String profile = '/auth/profile';
  static const String analysis = '/intake/analysis';

  static String getEmailConfirmation({required String email}) {
    final Uri uri = Uri(
      path: emailConfirmation,
      queryParameters: <String, String>{'email': email},
    );
    return uri.toString();
  }
}
