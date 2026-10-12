import '../../../../core/shared/shared_exports.dart';
import '../repositories/auth_repository.dart';

class DeleteAccountUsecase implements Usecase<void, String> {
  final IAuthRepository repository;

  DeleteAccountUsecase({required this.repository});

  @override
  Future<Result<void>> call(String accessToken) {
    return repository.deleteAccount(accessToken: accessToken);
  }
}
