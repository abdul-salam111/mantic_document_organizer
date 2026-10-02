import 'package:flutter/material.dart';

import '../../../core/di/di_exports.dart';
import '../../../core/localization/localization_exports.dart';
import '../../../core/security/security_exports.dart';
import '../../../core/theme/theme_exports.dart';
import '../../../core/utils/utils_exports.dart';
import '../../../core/widgets/widgets_exports.dart';
import '../viewmodel/splash_viewmodel.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      lazy: false,
      create: (_) => sl<SplashViewModel>()..resolveNextRoute(),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: context.primary,
          child: ClipRect(
            child: Center(
              child: Consumer<SplashViewModel>(
                builder: (context, vm, _) => AnimatedBuilder(
                  animation: _entranceController,
                  builder: (context, _) {
                    final entrance = Curves.easeOutCubic.transform(
                      _entranceController.value,
                    );
                    final logoScale = 1 + (1 - entrance) * 5.2;
                    final copyProgress = ((entrance - 0.62) / 0.38).clamp(
                      0.0,
                      1.0,
                    );
                    final copyOpacity = Curves.easeOut.transform(copyProgress);

                    return Column(
                      mainAxisSize: .min,
                      children: [
                        Opacity(
                          opacity: 0.72 + (0.28 * entrance),
                          child: Transform.scale(
                            scale: logoScale,
                            child: const AppLogo(
                              height: 96,
                              width: 96,
                            ).withRoundedCorners(22),
                          ),
                        ),
                        heightBox(20),
                        Opacity(
                          opacity: copyOpacity,
                          child: Transform.translate(
                            offset: Offset(0, 12 * (1 - copyProgress)),
                            child: Column(
                              children: [
                                Text(
                                  'DOCKETLY',
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
                              ],
                            ),
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
        ),
      ),
    );
  }
}
