import 'package:signals_flutter/signals_flutter.dart';

class LibraryFolderSettingsModalPresenter {
  final Future<bool> Function(String name) _onRename;
  final Future<bool> Function() _onArchive;

  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<bool> isUpdatingName = signal<bool>(false);
  final Signal<bool> isArchivingFolder = signal<bool>(false);

  LibraryFolderSettingsModalPresenter({
    required Future<bool> Function(String name) onRename,
    required Future<bool> Function() onArchive,
  }) : _onRename = onRename,
       _onArchive = onArchive;

  Future<bool> submitName(String name) async {
    final String normalizedName = name.trim();
    errorMessage.value = null;

    if (normalizedName.isEmpty) {
      errorMessage.value = 'Informe o nome da pasta.';
      return false;
    }

    if (normalizedName.length > 50) {
      errorMessage.value = 'O nome deve ter ate 50 caracteres.';
      return false;
    }

    if (isUpdatingName.value || isArchivingFolder.value) {
      return false;
    }

    isUpdatingName.value = true;
    final bool didRename = await _onRename(normalizedName);
    isUpdatingName.value = false;

    if (!didRename) {
      errorMessage.value = 'Não foi possível atualizar o nome da pasta.';
    }

    return didRename;
  }

  Future<bool> confirmArchive() async {
    errorMessage.value = null;

    if (isUpdatingName.value || isArchivingFolder.value) {
      return false;
    }

    isArchivingFolder.value = true;
    final bool didArchive = await _onArchive();
    isArchivingFolder.value = false;

    if (!didArchive) {
      errorMessage.value = 'Não foi possível arquivar a pasta.';
    }

    return didArchive;
  }

  void dispose() {
    errorMessage.dispose();
    isUpdatingName.dispose();
    isArchivingFolder.dispose();
  }
}
