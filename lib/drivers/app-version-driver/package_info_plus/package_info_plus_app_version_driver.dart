import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:animus/core/shared/interfaces/app_version_driver.dart';

final Provider<AppVersionDriver> appVersionDriverProvider =
    Provider<AppVersionDriver>((Ref ref) {
      return const PackageInfoPlusAppVersionDriver();
    });

class PackageInfoPlusAppVersionDriver implements AppVersionDriver {
  const PackageInfoPlusAppVersionDriver();

  @override
  Future<String> getVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}
