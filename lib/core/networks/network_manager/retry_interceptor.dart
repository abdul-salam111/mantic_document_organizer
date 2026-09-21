import 'dart:async';

import 'package:dio/dio.dart';

/// Retries GET requests with bounded exponential backoff on transient
/// network failures (connection errors and timeouts) — see
/// TEMPLATE_REVIEW.txt §2.5.
///
/// Deliberately GET-only: retrying a POST/PUT/PATCH/DELETE that may have
/// already reached the server before the "failure" risks a duplicate side
/// effect (double-charging, double-creating a resource, ...) without an
/// idempotency-key mechanism, which this template doesn't have. GET is
/// safe to retry because it isn't supposed to mutate anything.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._dio, {
    this.maxRetries = 2,
    this.initialDelay = const Duration(milliseconds: 500),
  });

  final Dio _dio;
  final int maxRetries;
  final Duration initialDelay;

  static const _retryCountKey = 'retry_count';

  static const _retryableErrorTypes = {
    DioExceptionType.connectionError,
    DioExceptionType.connectionTimeout,
    DioExceptionType.receiveTimeout,
  };

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;
    final isGet = requestOptions.method.toUpperCase() == 'GET';
    final isRetryableError = _retryableErrorTypes.contains(err.type);
    final attempt = (requestOptions.extra[_retryCountKey] as int?) ?? 0;

    if (!isGet || !isRetryableError || attempt >= maxRetries) {
      handler.next(err);
      return;
    }

    // Exponential backoff: initialDelay * 2^attempt (500ms, 1s, 2s, ...).
    final delay = initialDelay * (1 << attempt);
    await Future.delayed(delay);

    try {
      requestOptions.extra[_retryCountKey] = attempt + 1;
      final response = await _dio.fetch<dynamic>(requestOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
