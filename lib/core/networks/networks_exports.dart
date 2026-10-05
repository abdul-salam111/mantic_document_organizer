// Barrel export for lib/core/networks — import this to get AppException
// and subclasses, DioHelper, the Dio client factory (with debug-only
// request/response logging via pretty_dio_logger), API status enums, and
// NetworkPreferenceController (Wi-Fi-only vs. mobile-data sync setting).
export 'exceptions/app_exceptions.dart';
export 'network_manager/api_status_enums.dart';
export 'network_manager/dio_client.dart';
export 'network_manager/dio_helper.dart';
export 'network_manager/network_preference_controller.dart';
