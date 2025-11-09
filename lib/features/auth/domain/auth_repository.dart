abstract class AuthRepository {
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> createUserEntry();
  Future<void> signOut();
  Future<bool> isSignedIn();
  /// iOS only: returns true if Apple credential is revoked for the stored Apple user ID.
  Future<bool> isAppleCredentialRevoked();
}
