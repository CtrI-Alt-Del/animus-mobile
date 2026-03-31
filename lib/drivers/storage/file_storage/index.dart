import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/drivers/storage/file_storage/gcs_file_storage_driver.dart';

final Provider<FileStorageDriver> fileStorageDriverProvider =
    Provider<FileStorageDriver>((Ref ref) {
      return GcsFileStorageDriver(dio: Dio());
    });
