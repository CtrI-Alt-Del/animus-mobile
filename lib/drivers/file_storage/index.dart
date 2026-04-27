import 'package:animus/rest/clients/gcs_rest_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/drivers/file_storage/gcs_file_storage_driver.dart';

final Provider<FileStorageDriver> fileStorageDriverProvider =
    Provider<FileStorageDriver>((Ref ref) {
      return GcsFileStorageDriver(restClient: ref.watch(gcsRestClientProvider));
    });
