import '../../../../core/shared/shared_exports.dart';
import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

class VerifyEmailParams {
  final String email;
  final String code;

  const VerifyEmailParams({required this.email, required this.code});
}

class VerifyEmailUsecase implements Usecase<AuthEntity, VerifyEmailParams> {
  final IAuthRepository repository;

  VerifyEmailUsecase({required this.repository});

  @override
  Future<Result<AuthEntity>> call(VerifyEmailParams params) {
    return repository.verifyEmail(email: params.email, code: params.code);
  }
}

class ResendVerificationEmailUsecase implements Usecase<void, String> {
  final IAuthRepository repository;

  ResendVerificationEmailUsecase({required this.repository});

  @override
  Future<Result<void>> call(String email) {
    return repository.resendVerificationEmail(email: email);
  }
}
