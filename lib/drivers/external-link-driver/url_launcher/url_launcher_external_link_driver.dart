import 'package:url_launcher/url_launcher.dart';

import 'package:animus/core/shared/interfaces/external_link_driver.dart';

class UrlLauncherExternalLinkDriver implements ExternalLinkDriver {
  const UrlLauncherExternalLinkDriver();

  @override
  Future<void> openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      throw Exception('Não foi possível abrir o link externo informado.');
    }
  }
}
