import 'dart:io'; // <-- Add this for HttpClient
import 'package:dio/dio.dart';
import 'package:dio/io.dart'; // <-- Add this for IOHttpClientAdapter
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'retry_interceptor.dart';

Dio getDio() {
  Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  // Add HTTP adapter configuration for better connection handling
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.idleTimeout = const Duration(seconds: 10);
      client.connectionTimeout = const Duration(seconds: 30);
      return client;
    },
  );

  // Bounded exponential-backoff retry for GET requests on transient
  // connection errors/timeouts — see retry_interceptor.dart for why this
  // is GET-only.
  dio.interceptors.add(RetryInterceptor(dio));

  // Request/response logging — debug builds only. Headers and bodies can
  // contain auth tokens and PII, so this must never run in release builds.
  if (kDebugMode) {
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        compact: true,
      ),
    );
  }

  return dio;
}
