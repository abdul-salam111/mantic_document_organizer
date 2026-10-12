import 'package:in_app_review/in_app_review.dart';

import '../constants/app_constants.dart';

/// Wraps the native "rate this app" flow: the OS's own in-app review
/// prompt (StoreKit on iOS, the Play In-App Review API on Android) when
/// it's available, falling back to the store listing page directly
/// otherwise -- e.g. once the OS has already shown the native prompt too
/// many times recently.
class AppReviewUtils {
  const AppReviewUtils._();

  static Future<void> requestReview() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
      return;
    }
    await inAppReview.openStoreListing(appStoreId: AppConstants.iosAppStoreId);
  }
}
