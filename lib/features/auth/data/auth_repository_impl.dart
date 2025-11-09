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

      // Identity token must be present to sign in with Firebase
      if (appleCredential.identityToken == null ||
          (appleCredential.identityToken?.isEmpty ?? true)) {
        throw Exception(
          'Apple did not return an identity token. On Simulator, ensure you are signed into an Apple ID (Settings → Apple ID) or enable Developer → Sign in with Apple testing. Otherwise test on a real device.',
        );
      }

      final oauthCredential = OAuthProvider(
        'apple.com',
      ).credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode, // Required by Firebase for Apple OAuth
      );

      await _firebaseAuth.signInWithCredential(oauthCredential);

      // After successful sign-in, update display name if provided on first sign-in
      final String? givenName = appleCredential.givenName;
      final String? familyName = appleCredential.familyName;
      final String? email = appleCredential.email;
      final String? appleUserId = appleCredential.userIdentifier;

      final user = _firebaseAuth.currentUser;
      if (user != null) {
        String? fullName;
        if ((givenName != null && givenName.isNotEmpty) ||
            (familyName != null && familyName.isNotEmpty)) {
          fullName = [givenName, familyName].where((e) => (e ?? '').isNotEmpty).join(' ').trim();
        }

        // Update FirebaseAuth profile display name if we have one
        if (fullName != null && fullName.isNotEmpty) {
          await user.updateDisplayName(fullName);
        }

        // Upsert Apple-specific fields in Firestore (merge)
        final Map<String, dynamic> update = {};
        if (appleUserId != null && appleUserId.isNotEmpty) {
          update['appleUserId'] = appleUserId;
        }
        if (fullName != null && fullName.isNotEmpty) {
          update['displayName'] = fullName;
        }
        if (email != null && email.isNotEmpty) {
          update['email'] = email;
        }
        if (update.isNotEmpty) {
          await _firestore.collection('users').doc(user.uid).set(update, SetOptions(merge: true));
        }
      }
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

  @override
  Future<bool> isAppleCredentialRevoked() async {
    try {
      // Only applicable if user is signed in and we have an Apple user identifier stored
      final user = _firebaseAuth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final appleUserId = userDoc.data()?['appleUserId'] as String?;
      if (appleUserId == null || appleUserId.isEmpty) {
        return false;
      }

      final state = await SignInWithApple.getCredentialState(appleUserId);
      return state == CredentialState.revoked;
    } catch (_) {
      // If API is unavailable or throws, assume not revoked to avoid false sign-outs
      return false;
    }
  }
}
