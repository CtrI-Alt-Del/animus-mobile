import 'package:app_links/app_links.dart';

import 'package:animus/core/auth/interfaces/password_reset_link_driver.dart';

class AppLinksPasswordResetLinkDriver implements PasswordResetLinkDriver {
  final AppLinks _appLinks;

  AppLinksPasswordResetLinkDriver({AppLinks? appLinks})
    : _appLinks = appLinks ?? AppLinks();

  @override
  Stream<String> watchResetTokens() {
    return _appLinks.uriLinkStream
        .map(_extractToken)
        .where((String? token) => token != null)
        .cast<String>();
  }

  String? _extractToken(Uri? uri) {
    if (uri == null || uri.scheme != 'animus' || uri.host != 'reset-password') {
      return null;
    }

    final String? token = uri.queryParameters['token']?.trim();
    if (token == null || token.isEmpty) {
      return null;
    }

    return token;
  }
}
