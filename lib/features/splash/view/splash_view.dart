import 'package:flutter/material.dart';

import '../../../core/di/di_exports.dart';
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
            child: Column(
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
                  'Document Organizer',
                  style: context.bodyMedium.copyWith(
                    color: context.white.withValues(alpha: 0.8),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
