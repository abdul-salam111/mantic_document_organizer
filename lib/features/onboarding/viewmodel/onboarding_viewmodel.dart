import 'package:flutter/foundation.dart';

import '../../../core/local_storage/local_storage_exports.dart';
import '../../../routes/routes_exports.dart';

class OnboardingViewModel extends ChangeNotifier {
  // Signup/login is mandatory past onboarding; Bulk Import's own first-time
  // prompt is triggered later, as a popup once Home is actually reached
  // (see NavbarView), not from here.
  Future<void> completeOnboarding() async {
    await storage.setValues(StorageKeys.hasSeenOnboarding, 'true');
    AppNavigator.goNamed(RouteNames.signup);
  }
}
