import 'dart:io';

abstract class DocumentPickerDriver {
  Future<File?> pickDocument({required List<String> allowedExtensions});
}
