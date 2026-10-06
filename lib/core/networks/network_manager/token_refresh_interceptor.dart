import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../constants/constants_exports.dart';
import '../../local_storage/local_storage_exports.dart';
import '../../services/services_exports.dart';
import '../../../features/auth/auth_exports.dart';

/// Transparently refreshes an expired access token on a 401 and retries the
/// original request once, instead of surfacing [UnauthorizedException] for
/// something routine — the access token is short-lived by design (see
/// `access_token_minutes` in the backend's `Settings`).
///
/// Deliberately a plain [Interceptor], not a [QueuedInterceptor]: Queued's
/// `onError` calls all share one internal queue and only advance to the next
/// queued call once the current one resolves its handler. The `/auth/refresh`
/// call below goes through this same [Dio] instance, so if it fails, its own
/// error has to pass back through this same interceptor's `onError` — which,
/// under a shared queue, can't be dequeued until the call that's still
/// awaiting it (this one) finishes. That's a deadlock, not a feature, and was
/// confirmed live: the backend answered in ~2s, but the app hung indefinitely
/// because the failure response could never reach this interceptor to be
/// delivered. [_inFlightRefresh] below is a manual single-flight guard
/// instead, which gets the same "don't call /auth/refresh twice
/// concurrently" property without any shared queue to deadlock on.
///
/// That single-flight guard matters because the backend's refresh token is
/// one-time-use and rotates on every call: two concurrent refreshes with the
/// same token would make the second one look like token reuse/theft and
/// revoke the whole session (see `AuthService.refresh` server-side).
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor(this._dio);

  final Dio _dio;

  static const _isRefreshCallKey = 'is_refresh_call';
  static const _hasRetriedAfterRefreshKey = 'has_retried_after_refresh';

  Future<String?>? _inFlightRefresh;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;
    final failedAuthHeader = requestOptions.headers['Authorization'] as String?;

    final shouldAttemptRefresh =
        err.response?.statusCode == 401 &&
        requestOptions.extra[_isRefreshCallKey] != true &&
        requestOptions.extra[_hasRetriedAfterRefreshKey] != true &&
        failedAuthHeader != null;

    if (!shouldAttemptRefresh) {
      handler.next(err);
      return;
    }

    // Another request already refreshed the token while this one was
    // in flight — just retry with the token that's now current.
    final currentToken = SessionController.instance.userToken;
    if (currentToken != null && 'Bearer $currentToken' != failedAuthHeader) {
      await _retry(requestOptions, currentToken, handler);
      return;
    }

    final newAccessToken = await (_inFlightRefresh ??= _refresh());
    if (newAccessToken == null) {
      // The refresh token itself is invalid/expired/revoked (or this was
      // already burned by a reuse-detection race) — there's no way to
      // recover the session silently. Fall through to the original 401 so
      // the usual "signed out" handling takes over.
      handler.next(err);
      return;
    }
    await _retry(requestOptions, newAccessToken, handler);
  }

  /// Owns the single in-flight `/auth/refresh` call. Concurrent callers all
  /// await the same [Future] via [_inFlightRefresh] instead of each starting
  /// their own. Returns the new access token, or `null` if refreshing failed.
  Future<String?> _refresh() async {
    try {
      final refreshToken = await storage.readValues(StorageKeys.refreshToken);
      if (refreshToken == null || refreshToken.isEmpty) return null;

      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndPoints.refresh,
        data: {'refresh_token': refreshToken},
        options: Options(extra: {_isRefreshCallKey: true}),
      );
      final data = response.data!;
      final newAccessToken = data['access_token'] as String;
      final newRefreshToken = data['refresh_token'] as String;
      await _persistRefreshedTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
      return newAccessToken;
    } on DioException {
      await SessionController.instance.clearSession();
      return null;
    } finally {
      _inFlightRefresh = null;
    }
  }

  Future<void> _retry(
    RequestOptions requestOptions,
    String accessToken,
    ErrorInterceptorHandler handler,
  ) async {
    requestOptions.headers['Authorization'] = 'Bearer $accessToken';
    requestOptions.extra[_hasRetriedAfterRefreshKey] = true;
    try {
      final response = await _dio.fetch<dynamic>(requestOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<void> _persistRefreshedTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final updatedUser = AuthEntity(
      id: SessionController.instance.userDetails.id,
      name: SessionController.instance.userDetails.name,
      email: SessionController.instance.userDetails.email,
      token: accessToken,
      refreshToken: refreshToken,
    );
    await storage.setValues(StorageKeys.token, accessToken);
    await storage.setValues(StorageKeys.refreshToken, refreshToken);
    await storage.setValues(
      StorageKeys.userDetails,
      jsonEncode(updatedUser.toJson()),
    );
    SessionController.instance.userToken = accessToken;
    SessionController.instance.userDetails = updatedUser;
  }
}
