final class ProfileUpdateNameDialogPresenter {
  const ProfileUpdateNameDialogPresenter();

  String sanitizeName(String value) {
    return value.trim();
  }

  bool canSubmit({required String initialName, required String currentName}) {
    final String sanitizedInitialName = sanitizeName(initialName);
    final String sanitizedCurrentName = sanitizeName(currentName);

    return sanitizedCurrentName.isNotEmpty &&
        sanitizedCurrentName != sanitizedInitialName;
  }
}
