class Routes {
  static const String home = '/';
  static const String library = '/library';
  static const String signIn = '/auth/sign_in';
  static const String signUp = '/auth/sign_up';
  static const String emailConfirmation = '/auth/email_confirmation';
  static const String forgotPassword = '/auth/forgot_password';
  static const String checkEmail = '/auth/check_email';
  static const String newPassword = '/auth/new_password';
  static const String profile = '/auth/profile';
  static const String analysis = '/analyses/:analysisId';

  static String getForgotPassword({String? previousRoute}) {
    final Map<String, String> queryParameters = <String, String>{};
    if (previousRoute != null && previousRoute.trim().isNotEmpty) {
      queryParameters['from'] = previousRoute;
    }

    final Uri uri = Uri(
      path: forgotPassword,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return uri.toString();
  }

  static String getCheckEmail({required String email}) {
    final Uri uri = Uri(
      path: checkEmail,
      queryParameters: <String, String>{'email': email},
    );
    return uri.toString();
  }

  static String getEmailConfirmation({required String email}) {
    final Uri uri = Uri(
      path: emailConfirmation,
      queryParameters: <String, String>{'email': email},
    );
    return uri.toString();
  }

  static String getAnalysis({required String analysisId}) {
    final Uri uri = Uri(path: '/analyses/${Uri.encodeComponent(analysisId)}');
    return uri.toString();
  }

  static String getNewPassword({required String resetContext}) {
    final Uri uri = Uri(
      path: newPassword,
      queryParameters: <String, String>{'resetContext': resetContext},
    );
    return uri.toString();
  }
}
