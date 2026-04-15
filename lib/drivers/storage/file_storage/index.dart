import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:animus/constants/env.dart';
import 'package:animus/core/storage/interfaces/drivers/file_storage_driver.dart';
import 'package:animus/drivers/storage/file_storage/supabase_file_storage_driver.dart';

final Provider<FileStorageDriver> fileStorageDriverProvider =
    Provider<FileStorageDriver>((Ref ref) {
      return SupabaseFileStorageDriver(
        supabaseClient: SupabaseClient(Env.supabaseUrl, Env.supabaseKey),
        bucketName: Env.supabaseStorageBucket,
      );
    });
