import '../../../../core/shared/shared_exports.dart';
import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

enum SocialSignInProvider { google, apple }

class SocialSigninUsecase implements Usecase<AuthEntity, SocialSignInProvider> {
  final IAuthRepository repository;

  SocialSigninUsecase({required this.repository});

  @override
  Future<Result<AuthEntity>> call(SocialSignInProvider provider) {
    return switch (provider) {
      SocialSignInProvider.google => repository.signInWithGoogle(),
      SocialSignInProvider.apple => repository.signInWithApple(),
    };
  }
}
