import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/ui/storage/widgets/pages/library_folder_screen/library_folder_screen_presenter.dart';

class FolderSettingsModalPresenter {
  final String initialName;
  final Future<bool> Function(String name) _onRename;
  final Future<bool> Function() _onArchiveFolder;

  final Signal<String> name;
  final Signal<bool> isSavingName = signal<bool>(false);
  final Signal<bool> isArchivingFolder = signal<bool>(false);
  final Signal<String?> nameError = signal<String?>(null);
  final Signal<String?> generalError = signal<String?>(null);

  late final ReadonlySignal<bool> canSaveName = computed(() {
    final int length = name.value.trim().length;
    return length >= 1 && length <= 50;
  });

  FolderSettingsModalPresenter({
    required this.initialName,
    required Future<bool> Function(String name) onRename,
    required Future<bool> Function() onArchiveFolder,
  }) : _onRename = onRename,
       _onArchiveFolder = onArchiveFolder,
       name = signal<String>(initialName);

  void setName(String value) {
    name.value = value;
    nameError.value = null;
    generalError.value = null;
  }

  Future<bool> submitRename() async {
    final String normalizedName = name.value.trim();
    if (normalizedName.isEmpty || normalizedName.length > 50) {
      nameError.value = 'Informe um nome entre 1 e 50 caracteres.';
      return false;
    }

    isSavingName.value = true;
    generalError.value = null;

    final bool renamed = await _onRename(normalizedName);
    isSavingName.value = false;

    if (!renamed) {
      generalError.value = 'Nao foi possivel atualizar o nome da pasta agora.';
      return false;
    }

    return true;
  }

  Future<bool> submitArchiveFolder() async {
    isArchivingFolder.value = true;
    generalError.value = null;

    final bool archived = await _onArchiveFolder();
    isArchivingFolder.value = false;

    if (!archived) {
      generalError.value = 'Nao foi possivel remover esta pasta agora.';
      return false;
    }

    return true;
  }

  void dispose() {
    name.dispose();
    isSavingName.dispose();
    isArchivingFolder.dispose();
    nameError.dispose();
    generalError.dispose();
    canSaveName.dispose();
  }
}

final folderSettingsModalPresenterProvider = Provider.autoDispose
    .family<
      FolderSettingsModalPresenter,
      ({String folderId, String initialName})
    >((Ref ref, ({String folderId, String initialName}) args) {
      final LibraryFolderScreenPresenter screenPresenter = ref.watch(
        libraryFolderScreenPresenterProvider(args.folderId),
      );

      final FolderSettingsModalPresenter presenter =
          FolderSettingsModalPresenter(
            initialName: args.initialName,
            onRename: screenPresenter.renameFolder,
            onArchiveFolder: screenPresenter.archiveFolder,
          );

      ref.onDispose(presenter.dispose);
      return presenter;
    });
