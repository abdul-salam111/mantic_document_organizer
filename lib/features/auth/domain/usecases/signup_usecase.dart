import '../../../../core/shared/shared_exports.dart';
import '../../data/models/request_models/signup_user/signup_user.dart';
import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

class SignupUsecase implements Usecase<AuthEntity, SignupUser> {
  final IAuthRepository repository;

  SignupUsecase({required this.repository});

  @override
  Future<Result<AuthEntity>> call(SignupUser signupUser) {
    return repository.signupUser(signupUser: signupUser);
  }
}
