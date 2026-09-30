import '../../../../core/shared/shared_exports.dart';
import '../../data/models/request_models/login_user/login_user.dart';
import '../../data/models/request_models/signup_user/signup_user.dart';
import '../entities/auth_entity.dart';

abstract interface class IAuthRepository {
  Future<Result<AuthEntity>> signinUser({required LoginUser loginUser});
  Future<Result<AuthEntity>> signupUser({required SignupUser signupUser});
  Future<Result<AuthEntity>> signInWithGoogle();
  Future<Result<AuthEntity>> signInWithApple();
  Future<Result<void>> signOut({required String refreshToken});
  Future<Result<AuthEntity>> verifyEmail({
    required String email,
    required String code,
  });
  Future<Result<void>> resendVerificationEmail({required String email});
}
