import 'package:flutter/material.dart';

import '../../../core/di/di_exports.dart';
import '../../../core/localization/localization_exports.dart';
import '../../../core/security/security_exports.dart';
import '../../../core/theme/theme_exports.dart';
import '../../../core/utils/utils_exports.dart';
import '../../../core/widgets/widgets_exports.dart';
import '../viewmodel/splash_viewmodel.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      lazy: false,
      create: (_) => sl<SplashViewModel>()..resolveNextRoute(),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: .topLeft,
              end: .bottomRight,
              colors: [
                context.primaryDark,
                context.primary,
                context.primaryLight,
              ],
            ),
          ),
          child: Center(
            child: Consumer<SplashViewModel>(
              builder: (context, vm, _) {
                return Column(
                  mainAxisSize: .min,
                  children: [
                    const AppLogo(height: 96, width: 96).withRoundedCorners(22),
                    heightBox(20),
                    Text(
                      'MANTIC',
                      style: context.headlineSmall.copyWith(
                        color: context.white,
                        fontWeight: .bold,
                        letterSpacing: 6,
                      ),
                    ),
                    heightBox(6),
                    Text(
                      AppLocalizations.of(context).splashTagline,
                      style: context.bodyMedium.copyWith(
                        color: context.white.withValues(alpha: 0.8),
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (vm.showUnlockRetry) ...[
                      heightBox(28),
                      Icon(
                        biometricIconFor(vm.biometricKind),
                        color: context.white,
                        size: 32,
                      ),
                      heightBox(10),
                      InkWell(
                        onTap: vm.retryUnlock,
                        borderRadius: .circular(8),
                        child: Padding(
                          padding: const .symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            AppLocalizations.of(context).unlock,
                            style: context.bodyMedium.copyWith(
                              color: context.white,
                              fontWeight: .bold,
                              decoration: .underline,
                              decorationColor: context.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
