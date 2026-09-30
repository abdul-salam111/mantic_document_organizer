import 'package:flutter/foundation.dart';

import '../../../../../routes/routes_exports.dart';
import '../../../../../core/services/services_exports.dart';
import '../../../../../core/local_storage/local_storage_exports.dart';
import '../../../../../core/shared/shared_exports.dart';
import '../../../data/models/request_models/login_user/login_user.dart';
import '../../../domain/entities/auth_entity.dart';
import '../../../domain/usecases/signin_usecase.dart';
import '../../../domain/usecases/social_signin_usecase.dart';

class SigninViewModel extends ChangeNotifier with UseCaseExecutor {
  final SigninUsecase _signinUsecase;
  final SocialSigninUsecase _socialSigninUsecase;

  SigninViewModel({
    required SigninUsecase signinUsecase,
    required SocialSigninUsecase socialSigninUsecase,
  }) : _signinUsecase = signinUsecase,
       _socialSigninUsecase = socialSigninUsecase;

  AuthEntity? _user;
  AuthEntity? get user => _user;

  Future<void> signin(String userId, String password) async {
    await _signIn(
      call: () => _signinUsecase(LoginUser(email: userId, password: password)),
    );
  }

  Future<void> signInWithGoogle() async {
    await _signIn(
      call: () => _socialSigninUsecase(SocialSignInProvider.google),
    );
  }

  Future<void> signInWithApple() async {
    await _signIn(call: () => _socialSigninUsecase(SocialSignInProvider.apple));
  }

  Future<void> _signIn({
    required Future<Result<AuthEntity>> Function() call,
  }) async {
    await execute(
      call: call,
      onSuccess: (user) async {
        _user = user;
        await SessionController.instance.saveUserInStorage(user);
        await SessionController.instance.loadUserFromStorage();
        final pendingBackup = await storage.readValues(
          StorageKeys.pendingBackupSetup,
        );
        if (pendingBackup == 'true') {
          await storage.clearValues(StorageKeys.pendingBackupSetup);
          AppNavigator.goNamed(RouteNames.backupSetup);
        } else {
          AppNavigator.goNamed(RouteNames.home);
        }
      },
    );
  }
}
