import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/core/shared/interfaces/file_share_driver.dart';
import 'package:animus/drivers/file-share-driver/share_plus/share_plus_file_share_driver.dart';

final Provider<FileShareDriver> fileShareDriverProvider =
    Provider<FileShareDriver>((Ref ref) {
      return const SharePlusFileShareDriver();
    });
