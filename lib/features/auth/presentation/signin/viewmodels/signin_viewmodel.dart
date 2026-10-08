import 'package:flutter/foundation.dart';

import '../../../../../routes/routes_exports.dart';
import '../../../../../core/services/services_exports.dart';
import '../../../../../core/local_storage/local_storage_exports.dart';
import '../../../../../core/networks/exceptions/app_exceptions.dart';
import '../../../../../core/shared/shared_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../data/models/request_models/login_user/login_user.dart';
import '../../../domain/entities/auth_entity.dart';
import '../../../domain/usecases/signin_usecase.dart';
import '../../../domain/usecases/social_signin_usecase.dart';

class SigninViewModel extends ChangeNotifier with UseCaseExecutor {
  final SigninUsecase _signinUsecase;
  final SocialSigninUsecase _socialSigninUsecase;
  final DeepLinkService _deepLinkService;

  SigninViewModel({
    required SigninUsecase signinUsecase,
    required SocialSigninUsecase socialSigninUsecase,
    required DeepLinkService deepLinkService,
  }) : _signinUsecase = signinUsecase,
       _socialSigninUsecase = socialSigninUsecase,
       _deepLinkService = deepLinkService;

  AuthEntity? _user;
  AuthEntity? get user => _user;
  SocialSignInProvider? _activeSocialProvider;

  bool get isEmailLoading => isLoading && _activeSocialProvider == null;
  bool get isAnyLoading => isLoading;
  bool get isGoogleLoading => isSocialLoading(SocialSignInProvider.google);
  bool get isAppleLoading => isSocialLoading(SocialSignInProvider.apple);
  bool isSocialLoading(SocialSignInProvider provider) =>
      isLoading && _activeSocialProvider == provider;

  Future<void> signin(String userId, String password) async {
    await _signIn(
      call: () => _signinUsecase(LoginUser(email: userId, password: password)),
    );
  }

  Future<void> signInWithGoogle() async {
    await _socialSignIn(SocialSignInProvider.google);
  }

  Future<void> signInWithApple() async {
    await _socialSignIn(SocialSignInProvider.apple);
  }

  Future<void> _socialSignIn(SocialSignInProvider provider) async {
    _activeSocialProvider = provider;
    notifyListeners();
    try {
      await _signIn(
        call: () => _socialSigninUsecase(provider),
        suppressCancellationToast: true,
      );
    } finally {
      _activeSocialProvider = null;
      notifyListeners();
    }
  }

  Future<void> _signIn({
    required Future<Result<AuthEntity>> Function() call,
    bool suppressCancellationToast = false,
  }) async {
    await execute(
      call: call,
      showError: !suppressCancellationToast,
      onError: suppressCancellationToast
          ? (error) {
              if (error is! AuthenticationCancelledException) {
                AppToastsUtils.error(error.message);
              }
            }
          : null,
      onSuccess: (user) async {
        _user = user;
        await SessionController.instance.saveUserInStorage(user);
        await SessionController.instance.loadUserFromStorage();

        // A deep-linked invitation/join-link caught while signed out takes
        // priority -- it's what actually brought this person to sign in.
        final pendingJoinToken = await storage.readValues(
          StorageKeys.pendingSpaceJoinToken,
        );
        if (pendingJoinToken != null && pendingJoinToken.isNotEmpty) {
          await _deepLinkService.resumePendingIfAny();
          return;
        }

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
