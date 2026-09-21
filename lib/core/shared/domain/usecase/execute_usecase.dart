import 'package:flutter/foundation.dart';

import '../../../networks/networks_exports.dart';
import '../../../utils/utils_exports.dart';
import '../result/result.dart';

/// Mixin for automatic state management
mixin UseCaseExecutor on ChangeNotifier {
  ApiStatus _status = ApiStatus.initial;
  AppException? _error;
  bool _disposed = false;

  ApiStatus get status => _status;
  AppException? get error => _error;
  bool get isLoading => _status == ApiStatus.loading;
  bool get isSuccess => _status == ApiStatus.success;
  bool get isError => _status == ApiStatus.error;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Safe to call after the ViewModel may have been disposed mid-await
  /// (e.g. the user navigated away while a request was in flight).
  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// Execute UseCase - Automatic loading management! 🔥
  /// ✨ NO CONTEXT NEEDED ANYMORE!
  Future<T?> execute<T>({
    required Future<Result<T>> Function() call,
    Function(T data)? onSuccess,
    Function(AppException error)? onError,
    bool showError = true,
    String? successMessage,
  }) async {
    _status = ApiStatus.loading;
    _error = null;
    _safeNotify();

    try {
      final result = await call();

      return result.fold(
        onFailure: (error) {
          _status = ApiStatus.error;
          _error = error;
          _safeNotify();

          if (showError) {
            AppToastsUtils.error(error.toString()); // 🎯 No context!
          }
          onError?.call(error);
          return null;
        },
        onSuccess: (data) {
          _status = ApiStatus.success;
          _error = null;
          _safeNotify();

          // Optional success message
          if (successMessage != null) {
            AppToastsUtils.success(successMessage);
          }

          onSuccess?.call(data);
          return data;
        },
      );
    } catch (e) {
      _status = ApiStatus.error;
      _error = AppException(e.toString());
      _safeNotify();

      if (showError) {
        AppToastsUtils.error(e.toString());
      }
      return null;
    }
  }

  /// Multiple calls without changing loading state
  Future<T?> executeQuiet<T>({
    required Future<Result<T>> Function() call,
    Function(T data)? onSuccess,
    Function(AppException error)? onError,
    bool showError = false,
    String? successMessage,
  }) async {
    try {
      final result = await call();

      return result.fold(
        onFailure: (error) {
          if (showError) {
            AppToastsUtils.error(error.toString());
          }
          onError?.call(error);
          return null;
        },
        onSuccess: (data) {
          if (successMessage != null) {
            AppToastsUtils.success(successMessage);
          }
          onSuccess?.call(data);
          return data;
        },
      );
    } catch (e) {
      if (showError) {
        AppToastsUtils.error(e.toString());
      }
      return null;
    }
  }

  void resetState() {
    _status = ApiStatus.initial;
    _error = null;
    _safeNotify();
  }
}
