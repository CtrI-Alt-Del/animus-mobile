import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/core/storage/interfaces/drivers/document_picker_driver.dart';
import 'package:animus/drivers/document-picker-driver/file_picker/file_picker_document_picker_driver.dart';

final Provider<DocumentPickerDriver> documentPickerDriverProvider =
    Provider<DocumentPickerDriver>((Ref ref) {
      return const FilePickerDocumentPickerDriver();
    });
