import 'package:flutter/foundation.dart';

import '../../../core/local_storage/local_storage_exports.dart';
import '../../../routes/routes_exports.dart';

class OnboardingViewModel extends ChangeNotifier {
  Future<void> completeOnboarding() async {
    await storage.setValues(StorageKeys.hasSeenOnboarding, 'true');
    AppNavigator.goNamed(RouteNames.home);
  }
}
