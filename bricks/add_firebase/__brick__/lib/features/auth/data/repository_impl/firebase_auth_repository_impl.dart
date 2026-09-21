// FILE: lib/features/auth/data/repository_impl/firebase_auth_repository_impl.dart

import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../../core/networks/firebase/firebase_auth_helper.dart';
import '../../../../core/shared/shared_exports.dart';
import '../models/request_models/login_user/login_user.dart';
import '../models/request_models/signup_user/signup_user.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Firebase-Auth-backed alternative to [AuthRepositoryImpl] — implements
/// the exact same [IAuthRepository] contract that one does, so nothing
/// above the repository boundary (usecases, viewmodels, views,
/// SessionController) needs to change to use it: [AuthEntity] already has
/// no REST-specific shape, and `LoginUser`/`SignupUser` already only carry
/// email/password/name, which is exactly what Firebase's email/password
/// auth needs too.
///
/// NOT registered in injection_container.dart by default — the REST-backed
/// `AuthRepositoryImpl` stays the active `IAuthRepository` implementation
/// so running this brick doesn't silently change your app's auth backend.
/// See this brick's own console output (and firebase_auth_helper.dart's
/// registration in injection_container.dart) for the one-line DI swap that
/// switches auth over to Firebase.
class FirebaseAuthRepositoryImpl extends BaseRepository
    implements IAuthRepository {
  final FirebaseAuthHelper firebaseAuthHelper;

  FirebaseAuthRepositoryImpl({required this.firebaseAuthHelper});

  @override
  Future<Result<AuthEntity>> signinUser({required LoginUser loginUser}) {
    return execute(
      call: () async {
        final user = await firebaseAuthHelper.signInWithEmail(
          email: loginUser.email ?? '',
          password: loginUser.password ?? '',
        );
        return _toEntity(user);
      },
    );
  }

  @override
  Future<Result<AuthEntity>> signupUser({required SignupUser signupUser}) {
    return execute(
      call: () async {
        final user = await firebaseAuthHelper.signUpWithEmail(
          email: signupUser.email ?? '',
          password: signupUser.password ?? '',
          displayName: signupUser.name,
        );
        return _toEntity(user);
      },
    );
  }

  /// Maps Firebase's [fb.User] to this feature's domain entity, so nothing
  /// above the repository boundary needs to know about Firebase's SDK
  /// types — mirrors [AuthRepositoryImpl]'s `_toEntity(UserModel)`.
  Future<AuthEntity> _toEntity(fb.User user) async {
    final token = await user.getIdToken();
    return AuthEntity(
      id: user.uid,
      name: user.displayName,
      email: user.email,
      token: token,
    );
  }
}
