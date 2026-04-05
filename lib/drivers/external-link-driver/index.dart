import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/core/shared/interfaces/external_link_driver.dart';
import 'package:animus/drivers/external-link-driver/url_launcher/url_launcher_external_link_driver.dart';

export 'package:animus/drivers/external-link-driver/url_launcher/url_launcher_external_link_driver.dart';

final Provider<ExternalLinkDriver> externalLinkDriverProvider =
    Provider<ExternalLinkDriver>((Ref ref) {
      return const UrlLauncherExternalLinkDriver();
    });
