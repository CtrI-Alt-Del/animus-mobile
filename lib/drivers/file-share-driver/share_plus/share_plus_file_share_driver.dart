import 'dart:io';

import 'package:animus/core/shared/interfaces/file_share_driver.dart';
import 'package:share_plus/share_plus.dart';

class SharePlusFileShareDriver implements FileShareDriver {
  const SharePlusFileShareDriver();

  @override
  Future<void> shareFile({required File file, required String filename}) async {
    await Share.shareXFiles(
      <XFile>[XFile(file.path, name: filename)],
      fileNameOverrides: <String>[filename],
    );
  }
}
