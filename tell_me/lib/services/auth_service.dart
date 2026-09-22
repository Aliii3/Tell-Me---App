import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'storage_service.dart';
import 'sync_service.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  // Reuse one instance so Google's sign-in session state is preserved.
  final _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> createAccount(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<UserCredential?> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential?> signInWithApple() async {
    final nonce = _generateNonce();
    final hashedNonce = _sha256(nonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: nonce,
    );
    return _auth.signInWithCredential(oauthCredential);
  }

  Future<UserCredential> signInAnonymously() => _auth.signInAnonymously();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Deletes the current user's account and all of their data.
  ///
  /// Firebase requires a recent sign-in before it allows account deletion,
  /// so non-anonymous accounts are re-authenticated first, reusing the same
  /// credential flows as sign-in. [password] is required only for
  /// email/password accounts.
  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (!user.isAnonymous) {
      final providerId =
          user.providerData.isNotEmpty ? user.providerData.first.providerId : '';
      switch (providerId) {
        case 'google.com':
          final account = await _googleSignIn.signIn();
          if (account == null) {
            throw Exception('Re-authentication was cancelled.');
          }
          final auth = await account.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: auth.accessToken,
            idToken: auth.idToken,
          );
          await user.reauthenticateWithCredential(credential);
          break;
        case 'apple.com':
          final nonce = _generateNonce();
          final hashedNonce = _sha256(nonce);
          final appleCredential = await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: hashedNonce,
          );
          final oauthCredential = OAuthProvider('apple.com').credential(
            idToken: appleCredential.identityToken,
            rawNonce: nonce,
          );
          await user.reauthenticateWithCredential(oauthCredential);
          break;
        default:
          if (password == null || password.isEmpty) {
            throw Exception('Password required to delete this account.');
          }
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );
          await user.reauthenticateWithCredential(credential);
      }
    }

    await SyncService.instance.deleteAllUserData(user.uid);
    await StorageService.instance.clearAll();
    await user.delete();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _generateNonce([int length = 32]) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random.secure();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)])
        .join();
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}

/// Maps Firebase Auth error codes to human-readable messages.
String authErrorMessage(String code) {
  switch (code) {
    case 'wrong-password':
    case 'invalid-credential':
      return 'Incorrect email or password.';
    case 'user-not-found':
      return 'No account found with this email.';
    case 'email-already-in-use':
      return 'An account already exists with this email.';
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'weak-password':
      return 'Password must be at least 6 characters.';
    case 'network-request-failed':
      return 'No internet connection. Please try again.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment.';
    default:
      return 'Something went wrong. Please try again.';
  }
}
