abstract class GoogleAuthDriver {
  Future<String?> requestIdToken();

  Future<void> signOut();
}
