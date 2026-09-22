import 'package:flutter/foundation.dart';

import '../../../../../routes/routes_exports.dart';
import '../../../../../core/services/services_exports.dart';
import '../../../../../core/shared/shared_exports.dart';
import '../../../data/models/request_models/login_user/login_user.dart';
import '../../../domain/entities/auth_entity.dart';
import '../../../domain/usecases/signin_usecase.dart';

class SigninViewModel extends ChangeNotifier with UseCaseExecutor {
  final SigninUsecase _signinUsecase;

  SigninViewModel({required SigninUsecase signinUsecase})
    : _signinUsecase = signinUsecase;

  AuthEntity? _user;
  AuthEntity? get user => _user;

  Future<void> signin(String userId, String password) async {
    await execute(
      call: () => _signinUsecase(LoginUser(email: userId, password: password)),
      onSuccess: (user) async {
        _user = user;
        await SessionController.instance.saveUserInStorage(user);
        await SessionController.instance.loadUserFromStorage();
        AppNavigator.goNamed(RouteNames.home);
      },
    );
  }
}
