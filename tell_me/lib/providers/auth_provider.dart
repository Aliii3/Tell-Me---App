import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streams Firebase auth state changes — null means signed out.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// ChangeNotifier that fires whenever auth state changes.
/// Used as GoRouter's refreshListenable so the redirect guard re-evaluates.
class AuthNotifier extends ChangeNotifier {
  AuthNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, next) => notifyListeners());
  }
}

final authNotifierProvider =
    ChangeNotifierProvider<AuthNotifier>((ref) => AuthNotifier(ref));
