abstract class AuthRepository {
  Future<void> signInWithGoogle();
  Future<void> createUserEntry();
  Future<void> signOut();
  Future<bool> isSignedIn();
}
