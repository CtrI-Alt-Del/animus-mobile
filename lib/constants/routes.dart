import 'package:animus/core/intake/dtos/analysis_type_dto.dart';

class Routes {
  static const String home = '/';
  static const String library = '/library';
  static const String libraryUnfoldered = '/library/unfoldered';
  static const String libraryFolder = '/library/folders/:folderId';
  static const String signIn = '/auth/sign_in';
  static const String signUp = '/auth/sign_up';
  static const String emailConfirmation = '/auth/email_confirmation';
  static const String forgotPassword = '/auth/forgot_password';
  static const String checkEmail = '/auth/check_email';
  static const String newPassword = '/auth/new_password';
  static const String profile = '/auth/profile';
  static const String analysis = '/analyses/:analysisId';
  static const String secondInstanceAnalysis =
      '/analyses/:analysisId/second-instance';

  static String getLibraryFolder({required String folderId}) {
    final Uri uri = Uri(
      path: '/library/folders/${Uri.encodeComponent(folderId)}',
    );
    return uri.toString();
  }

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

  static String getAnalysis({
    required String analysisId,
    required AnalysisTypeDto analysisType,
  }) {
    switch (analysisType) {
      case AnalysisTypeDto.firstInstance:
        return Routes.getFirstInstanceAnalysis(analysisId: analysisId);
      case AnalysisTypeDto.secondInstance:
        return Routes.getSecondInstanceAnalysis(analysisId: analysisId);
      case AnalysisTypeDto.caseAssessment:
        return Routes.getSecondInstanceAnalysis(analysisId: analysisId);
    }
  }

  static String getFirstInstanceAnalysis({required String analysisId}) {
    final Uri uri = Uri(path: '/analyses/${Uri.encodeComponent(analysisId)}');
    return uri.toString();
  }

  static String getSecondInstanceAnalysis({required String analysisId}) {
    final Uri uri = Uri(
      path: '/analyses/${Uri.encodeComponent(analysisId)}/second-instance',
    );
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
