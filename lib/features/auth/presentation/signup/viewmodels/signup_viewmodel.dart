import 'package:flutter/foundation.dart';

import '../../../../../routes/routes_exports.dart';
import '../../../../../core/shared/shared_exports.dart';
import '../../../data/models/request_models/signup_user/signup_user.dart';
import '../../../domain/entities/auth_entity.dart';
import '../../../domain/usecases/signup_usecase.dart';

class SignupViewModel extends ChangeNotifier with UseCaseExecutor {
  final SignupUsecase _signupUsecase;

  SignupViewModel({required SignupUsecase signupUsecase})
    : _signupUsecase = signupUsecase;

  AuthEntity? _user;
  AuthEntity? get user => _user;

  Future<void> signup(String name, String email, String password) async {
    await execute(
      call: () => _signupUsecase(
        SignupUser(name: name, email: email, password: password),
      ),
      onSuccess: (user) {
        _user = user;
        // The backend sends the verification email during sign-up. Its
        // response intentionally has no session tokens, so continue with OTP
        // verification before allowing the account to sign in.
        AppNavigator.goNamed(RouteNames.verifyEmail, extra: user.email);
      },
    );
  }
}
