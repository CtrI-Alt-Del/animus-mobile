import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:animus/core/storage/interfaces/drivers/document_picker_driver.dart';

class FilePickerDocumentPickerDriver implements DocumentPickerDriver {
  const FilePickerDocumentPickerDriver();

  @override
  Future<File?> pickDocument({required List<String> allowedExtensions}) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: allowedExtensions,
      withData: false,
    );

    final String? path = result?.files.single.path;
    if (path == null || path.isEmpty) {
      return null;
    }

    return File(path);
  }
}
