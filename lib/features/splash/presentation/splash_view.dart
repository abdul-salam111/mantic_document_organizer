import 'package:flutter/material.dart';

import '../../../core/services/services_exports.dart';
import '../../../core/theme/theme_exports.dart';
import '../../../core/widgets/widgets_exports.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  SplashServices splashServices = SplashServices();
  @override
  void initState() {
    super.initState();
    splashServices.isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(child: AppLogo()),
    );
  }
}
