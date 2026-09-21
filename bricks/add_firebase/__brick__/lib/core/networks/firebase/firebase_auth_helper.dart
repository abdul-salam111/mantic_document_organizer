// FILE: lib/core/networks/firebase/firebase_auth_helper.dart

import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../exceptions/app_exceptions.dart';
import '../exceptions/firebase_auth_exceptions.dart';

/// Firebase-Auth counterpart to `DioHelper` — same job (fire the actual
/// call, translate every failure into this app's [AppException]
/// vocabulary) for Firebase's SDK instead of a REST endpoint. Anything
/// above this (repository impls, usecases, viewmodels) never sees a raw
/// [fb.FirebaseAuthException] or [fb.User].
class FirebaseAuthHelper {
  final fb.FirebaseAuth _auth;

  FirebaseAuthHelper(this._auth);

  fb.User? get currentUser => _auth.currentUser;

  Future<fb.User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _requireUser(credential.user, 'Sign-in');
    } on fb.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<fb.User> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _requireUser(credential.user, 'Sign-up');

      if (displayName != null && displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
        await user.reload();
      }

      // updateDisplayName/reload mutate the SDK's cached user in place,
      // but `user` (from the create call above) is a snapshot from before
      // that mutation — re-read `currentUser` so the returned name is
      // current instead of stale/null.
      return _auth.currentUser ?? user;
    } on fb.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on fb.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// Firebase's SDK types `credential.user` as nullable even on success
  /// (it's only ever actually null if the call itself threw, which the
  /// `on fb.FirebaseAuthException`/`catch` above already handles) — this
  /// turns that theoretical null into a clear [AppException] instead of a
  /// null-check crash, so `FirebaseAuthHelper`'s public methods can return
  /// a non-nullable [fb.User].
  fb.User _requireUser(fb.User? user, String action) {
    if (user == null) {
      throw FirebaseUnknownAuthException(
        '$action succeeded but returned no user.',
      );
    }
    return user;
  }
}
