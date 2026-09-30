import '../../../../core/shared/shared_exports.dart';
import '../repositories/auth_repository.dart';

class SignoutUsecase implements Usecase<void, String> {
  final IAuthRepository repository;

  SignoutUsecase({required this.repository});

  @override
  Future<Result<void>> call(String refreshToken) {
    return repository.signOut(refreshToken: refreshToken);
  }
}
