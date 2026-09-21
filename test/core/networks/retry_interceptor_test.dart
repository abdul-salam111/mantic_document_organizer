// Regression tests for TEMPLATE_REVIEW.txt §2.5's retry half: bounded
// exponential-backoff retry for GET requests on transient connection
// errors, and specifically NOT retrying mutating requests.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_template/core/networks/network_manager/retry_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

/// A scripted [HttpClientAdapter] that returns the next entry in
/// [responses] on each call to [fetch] — either a successful
/// [ResponseBody] or a [DioExceptionType] to throw.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.responses);

  final List<Object> responses;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final scripted = responses[callCount];
    callCount++;
    if (scripted is DioExceptionType) {
      throw DioException(requestOptions: options, type: scripted);
    }
    return scripted as ResponseBody;
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Map<String, dynamic> body) => ResponseBody.fromString(
  jsonEncode(body),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  test('retries a GET on connection errors and succeeds once the '
      'underlying call does', () async {
    final adapter = _ScriptedAdapter([
      DioExceptionType.connectionError,
      DioExceptionType.connectionError,
      _jsonResponse({'ok': true}),
    ]);
    final dio = Dio()..httpClientAdapter = adapter;
    dio.interceptors.add(
      RetryInterceptor(dio, initialDelay: Duration.zero, maxRetries: 2),
    );

    final response = await dio.get<Map<String, dynamic>>('https://example.test/x');

    expect(response.data, {'ok': true});
    expect(adapter.callCount, 3);
  });

  test('gives up after maxRetries and surfaces the original-shaped error', () async {
    final adapter = _ScriptedAdapter([
      DioExceptionType.connectionError,
      DioExceptionType.connectionError,
      DioExceptionType.connectionError,
      DioExceptionType.connectionError,
    ]);
    final dio = Dio()..httpClientAdapter = adapter;
    dio.interceptors.add(
      RetryInterceptor(dio, initialDelay: Duration.zero, maxRetries: 2),
    );

    await expectLater(
      dio.get<dynamic>('https://example.test/x'),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.connectionError,
        ),
      ),
    );
    // Initial attempt + 2 retries = 3 calls, then it gives up.
    expect(adapter.callCount, 3);
  });

  test('does not retry a mutating request (POST) on the same error', () async {
    final adapter = _ScriptedAdapter([DioExceptionType.connectionError]);
    final dio = Dio()..httpClientAdapter = adapter;
    dio.interceptors.add(
      RetryInterceptor(dio, initialDelay: Duration.zero, maxRetries: 2),
    );

    await expectLater(
      dio.post<dynamic>('https://example.test/x'),
      throwsA(isA<DioException>()),
    );
    // No retries — a single call.
    expect(adapter.callCount, 1);
  });

  test('does not retry a non-retryable error type (e.g. badResponse) '
      'even on GET', () async {
    final adapter = _ScriptedAdapter([DioExceptionType.badResponse]);
    final dio = Dio()..httpClientAdapter = adapter;
    dio.interceptors.add(
      RetryInterceptor(dio, initialDelay: Duration.zero, maxRetries: 2),
    );

    await expectLater(
      dio.get<dynamic>('https://example.test/x'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.callCount, 1);
  });
}
