import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/drivers/storage/file_storage/gcs_file_storage_driver.dart';
import 'package:animus/rest/dio/dio_rest_client.dart';

final Provider<FileStorageDriver> fileStorageDriverProvider =
    Provider<FileStorageDriver>((Ref ref) {
      final DioRestClient restclient = DioRestClient();
      return GcsFileStorageDriver(restClient: restclient);
    });
