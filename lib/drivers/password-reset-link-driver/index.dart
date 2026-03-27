import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/core/auth/interfaces/password_reset_link_driver.dart';
import 'package:animus/drivers/password-reset-link-driver/app_links/app_links_password_reset_link_driver.dart';

export 'package:animus/drivers/password-reset-link-driver/app_links/app_links_password_reset_link_driver.dart';

final Provider<PasswordResetLinkDriver> passwordResetLinkDriverProvider =
    Provider<PasswordResetLinkDriver>((Ref ref) {
      return AppLinksPasswordResetLinkDriver(appLinks: AppLinks());
    });
