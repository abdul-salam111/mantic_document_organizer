import '../../../../core/shared/shared_exports.dart';
import '../../data/models/request_models/login_user/login_user.dart';
import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

class SigninUsecase implements Usecase<AuthEntity, LoginUser> {
  final IAuthRepository repository;

  SigninUsecase({required this.repository});

  @override
  Future<Result<AuthEntity>> call(LoginUser loginUserById) {
    return repository.signinUser(loginUser: loginUserById);
  }
}
