import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../../core/shared/shared_exports.dart';
import '../../../domain/usecases/email_verification_usecases.dart';

class EmailVerificationViewModel extends ChangeNotifier with UseCaseExecutor {
  final VerifyEmailUsecase _verifyEmailUsecase;
  final ResendVerificationEmailUsecase _resendVerificationEmailUsecase;
  Timer? _resendTimer;
  int _secondsUntilResend = 0;

  EmailVerificationViewModel({
    required VerifyEmailUsecase verifyEmailUsecase,
    required ResendVerificationEmailUsecase resendVerificationEmailUsecase,
  }) : _verifyEmailUsecase = verifyEmailUsecase,
       _resendVerificationEmailUsecase = resendVerificationEmailUsecase;

  int get secondsUntilResend => _secondsUntilResend;
  bool get canResend => _secondsUntilResend == 0;

  void beginResendCooldown() {
    _resendTimer?.cancel();
    _secondsUntilResend = 60;
    notifyListeners();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsUntilResend--;
      if (_secondsUntilResend <= 0) {
        _secondsUntilResend = 0;
        timer.cancel();
      }
      notifyListeners();
    });
  }

  Future<void> verify({required String email, required String code}) async {
    await execute(
      call: () =>
          _verifyEmailUsecase(VerifyEmailParams(email: email, code: code)),
    );
  }

  Future<bool> resend({required String email}) async {
    if (!canResend) return false;
    var wasSent = false;
    await execute<void>(
      call: () => _resendVerificationEmailUsecase(email),
      onSuccess: (_) => wasSent = true,
      successMessage: 'A new verification code has been sent.',
    );
    if (wasSent) beginResendCooldown();
    return wasSent;
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}
