import 'package:flutter/foundation.dart';

import '../../../../../routes/routes_exports.dart';
import '../../../../../core/networks/exceptions/app_exceptions.dart';
import '../../../../../core/services/services_exports.dart';
import '../../../../../core/shared/shared_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../data/models/request_models/signup_user/signup_user.dart';
import '../../../domain/entities/auth_entity.dart';
import '../../../domain/usecases/signup_usecase.dart';
import '../../../domain/usecases/social_signin_usecase.dart';

class SignupViewModel extends ChangeNotifier with UseCaseExecutor {
  final SignupUsecase _signupUsecase;
  final SocialSigninUsecase _socialSigninUsecase;

  SignupViewModel({
    required SignupUsecase signupUsecase,
    required SocialSigninUsecase socialSigninUsecase,
  }) : _signupUsecase = signupUsecase,
       _socialSigninUsecase = socialSigninUsecase;

  AuthEntity? _user;
  AuthEntity? get user => _user;
  SocialSignInProvider? _activeSocialProvider;

  bool get isEmailLoading => isLoading && _activeSocialProvider == null;
  bool get isAnyLoading => isLoading;
  bool get isGoogleLoading => isSocialLoading(SocialSignInProvider.google);
  bool get isAppleLoading => isSocialLoading(SocialSignInProvider.apple);
  bool isSocialLoading(SocialSignInProvider provider) =>
      isLoading && _activeSocialProvider == provider;

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

  Future<void> signUpWithGoogle() => _socialSignIn(SocialSignInProvider.google);
  Future<void> signUpWithApple() => _socialSignIn(SocialSignInProvider.apple);

  Future<void> _socialSignIn(SocialSignInProvider provider) async {
    _activeSocialProvider = provider;
    notifyListeners();
    try {
      await execute(
        call: () => _socialSigninUsecase(provider),
        showError: false,
        onError: (error) {
          if (error is! AuthenticationCancelledException) {
            AppToastsUtils.error(error.message);
          }
        },
        onSuccess: (user) async {
          _user = user;
          await SessionController.instance.saveUserInStorage(user);
          await SessionController.instance.loadUserFromStorage();
          AppNavigator.goNamed(RouteNames.home);
        },
      );
    } finally {
      _activeSocialProvider = null;
      notifyListeners();
    }
  }
}
