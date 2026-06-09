import 'dart:io';

abstract class FileShareDriver {
  Future<void> shareFile({required File file, required String filename});
}
