import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart' as crypto;
import 'package:state/features/auth/domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Sign in aborted by user');

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _firebaseAuth.signInWithCredential(credential);
  }

  /// Generates a cryptographically secure random nonce (raw) and its SHA-256 hash.
  (String raw, String sha256) _generateNoncePair([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final rand = Random.secure();
    final raw =
        List.generate(
          length,
          (_) => charset[rand.nextInt(charset.length)],
        ).join();
    final digest = crypto.sha256.convert(utf8.encode(raw)).toString();
    return (raw, digest);
  }

  @override
  Future<void> signInWithApple() async {
    // Request Apple credential
    final (rawNonce, hashedNonce) = _generateNoncePair();
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.fullName,
          AppleIDAuthorizationScopes.email,
        ],
        nonce: hashedNonce,
      );

      final oauthCredential = OAuthProvider(
        'apple.com',
      ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

      await _firebaseAuth.signInWithCredential(oauthCredential);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw Exception('Sign in with Apple cancelled');
      }
      rethrow;
    }
  }

  @override
  Future<void> createUserEntry() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      final docRef = _firestore.collection('users').doc(user.uid);

      final doc = await docRef.get();
      if (!doc.exists) {
        final String? displayName = user.displayName;
        final String? email = user.email;
        final String? photoUrl = user.photoURL;
        final String? phoneNumber = user.phoneNumber;

        await docRef.set({
          'displayName': displayName,
          'email': email,
          'photoUrl': photoUrl,
          'phoneNumber': phoneNumber,
        });
      }
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  @override
  Future<bool> isSignedIn() async {
    return _firebaseAuth.currentUser != null;
  }
}
