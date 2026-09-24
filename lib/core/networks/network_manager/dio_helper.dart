import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../exceptions/app_exceptions.dart';

class DioHelper {
  final Dio dio;
  final InternetConnectionChecker _connectionChecker;
  final Duration _connectivityCheckInterval;
  Timer? _connectivityPollTimer;

  // Optimistic default: assume connected until the first check resolves
  // (see _ensureConnected doc below for what happens if that guess is
  // wrong).
  bool _hasConnection = true;

  // Constructor injection.
  //
  // Deliberately polls [_connectionChecker.hasConnection] on our own
  // [Timer] instead of subscribing to its `onStatusChange` stream: that
  // stream starts/stops the package's internal monitoring based on
  // listener count (async, fire-and-forget internally), which is built
  // for one subscriber living for the whole app's lifetime — it doesn't
  // reliably tear down its own polling Timer in time when a listener
  // added right before subscribes and cancels quickly (as this
  // template's tests do on every run, via `sl.reset()` between them),
  // which shows up as "a Timer is still pending" test failures. Owning
  // the Timer here instead makes disposal fully synchronous and
  // deterministic — no dependency on a shared singleton's internal
  // bookkeeping.
  DioHelper(
    this.dio, {
    InternetConnectionChecker? connectionChecker,
    Duration connectivityCheckInterval = const Duration(seconds: 10),
  }) : _connectionChecker =
           connectionChecker ?? InternetConnectionChecker.instance,
       _connectivityCheckInterval = connectivityCheckInterval {
    _refreshConnectivity();
    _connectivityPollTimer = Timer.periodic(
      _connectivityCheckInterval,
      (_) => _refreshConnectivity(),
    );
  }

  Future<void> _refreshConnectivity() async {
    _hasConnection = await _connectionChecker.hasConnection;
  }

  /// Checks connectivity before firing a request, so "no internet" is
  /// reported immediately via [NoInternetException] instead of only
  /// reactively after a request already times out.
  ///
  /// Reads a cached status kept up to date by the periodic check above,
  /// instead of awaiting a fresh HTTP HEAD probe before every request —
  /// that used to add a real per-request latency tax. Trade-off: between
  /// checks (and right after construction, before the first one
  /// resolves), this can be stale — if it's wrong, the request just fails
  /// normally and `_handleDioError` maps `DioExceptionType.connectionError`
  /// to `NoInternetException` reactively, same as before this change
  /// existed.
  void _ensureConnected() {
    if (!_hasConnection) {
      throw NoInternetException(
        'Please check your network settings and try again.',
      );
    }
  }

  /// Stops the periodic connectivity poll. [DioHelper] is registered as
  /// an app-lifetime singleton with this wired up as its GetIt `dispose`
  /// callback (see core/di/injection_container.dart) specifically so
  /// tests that call `sl.reset()` between runs don't leak this timer —
  /// `flutter_test` asserts no pending timers survive a test.
  Future<void> dispose() async {
    _connectivityPollTimer?.cancel();
    _connectivityPollTimer = null;
  }

  Options get options => Options(
    receiveDataWhenStatusError: true,
    contentType: "application/json",
    responseType: ResponseType.json,
  );

  Future<dynamic> getApi({
    required String url,
    bool isAuthRequired = false,
    String? authToken,
    Object? requestBody,
    Map<String, dynamic>? queryParameters,
  }) async {
    _ensureConnected();

    Options requestOptions = isAuthRequired
        ? options.copyWith(
            headers: {
              ...?options.headers,
              "Authorization": "Bearer $authToken",
            },
          )
        : options;

    try {
      Response response = await dio.get(
        url,
        options: requestOptions,
        data: requestBody,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (error) {
      _handleDioError(error);
      rethrow;
    } catch (error) {
      throw FetchDataException(error.toString());
    }
  }

  Future<dynamic> postApi({
    required String url,
    bool isAuthRequired = false,
    String? authToken,
    Object? requestBody,
  }) async {
    _ensureConnected();

    Options requestOptions = isAuthRequired
        ? options.copyWith(
            headers: {
              ...?options.headers,
              "Authorization": "Bearer $authToken",
            },
          )
        : options;

    try {
      Response response = await dio.post(
        url,
        data: requestBody,
        options: requestOptions,
      );
      return response.data;
    } on DioException catch (error) {
      _handleDioError(error);
      rethrow;
    } catch (error) {
      throw FetchDataException(error.toString());
    }
  }

  Future<dynamic> putApi({
    required String url,
    bool isAuthRequired = false,
    Object? requestBody,
    String? authToken,
  }) async {
    _ensureConnected();

    Options requestOptions = isAuthRequired
        ? options.copyWith(
            headers: {
              ...?options.headers,
              "Authorization": "Bearer $authToken",
            },
          )
        : options;

    try {
      Response response = await dio.put(
        url,
        options: requestOptions,
        data: requestBody,
      );
      return response.data;
    } on DioException catch (error) {
      _handleDioError(error);
      rethrow;
    } catch (error) {
      throw FetchDataException(error.toString());
    }
  }

  Future<dynamic> patchApi({
    required String url,
    bool isAuthRequired = false,
    Object? requestBody,
    String? authToken,
  }) async {
    _ensureConnected();

    Options requestOptions = isAuthRequired
        ? options.copyWith(
            headers: {
              ...?options.headers,
              "Authorization": "Bearer $authToken",
            },
          )
        : options;

    try {
      Response response = await dio.patch(
        url,
        options: requestOptions,
        data: requestBody,
      );
      return response.data;
    } on DioException catch (error) {
      _handleDioError(error);
      rethrow;
    } catch (error) {
      throw FetchDataException(error.toString());
    }
  }

  Future<dynamic> deleteApi({
    required String url,
    bool isAuthRequired = false,
    Object? requestBody,
    String? authToken,
    Map<String, dynamic>? queryParameters,
  }) async {
    _ensureConnected();

    Options requestOptions = isAuthRequired
        ? options.copyWith(
            headers: {
              ...?options.headers,
              "Authorization": "Bearer $authToken",
            },
          )
        : options;

    try {
      Response response = await dio.delete(
        url,
        options: requestOptions,
        data: requestBody,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (error) {
      _handleDioError(error);
      rethrow;
    } catch (error) {
      throw FetchDataException(error.toString());
    }
  }

  void _handleDioError(DioException error) {
    // Handle HTTP status codes first
    final statusCode = error.response?.statusCode;

    if (statusCode != null) {
      final errorMessage = _extractErrorMessage(error.response);

      switch (statusCode) {
        case 400:
          throw BadRequestException(errorMessage ?? 'Bad request');
        case 401:
          throw UnauthorizedException(errorMessage ?? 'Unauthorized access');
        case 403:
          throw ForbiddenException(errorMessage ?? 'Access forbidden');
        case 404:
          throw NotFoundException(errorMessage ?? 'Resource not found');
        case 405:
          throw MethodNotAllowedException(errorMessage ?? 'Method not allowed');
        case 408:
          throw RequestTimeoutException(errorMessage ?? 'Request timeout');
        case 422:
          throw InvalidInputException(errorMessage ?? 'Invalid input data');
        case 429:
          throw TooManyRequestsException(errorMessage ?? 'Too many requests');
        case 500:
          throw InternalServerErrorException(
            errorMessage ?? 'Internal server error',
          );
        case 502:
          throw BadRequestException(errorMessage ?? 'Bad gateway');
        case 503:
          throw ServiceUnavailableException(
            errorMessage ?? 'Service unavailable',
          );
        case 504:
          throw RequestTimeoutException(errorMessage ?? 'Gateway timeout');
        default:
          // Handle other 4xx errors
          if (statusCode >= 400 && statusCode < 500) {
            throw BadRequestException(
              errorMessage ?? 'Client error: $statusCode',
            );
          }
          // Handle other 5xx errors
          if (statusCode >= 500) {
            throw InternalServerErrorException(
              errorMessage ?? 'Server error: $statusCode',
            );
          }
      }
    }

    // Handle DioException types (connection issues, timeouts, etc.)
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw RequestTimeoutException(error.message ?? 'Request timeout');
      case DioExceptionType.badResponse:
        throw FetchDataException(error.message ?? 'Bad response from server');
      case DioExceptionType.cancel:
        throw FetchDataException('Request cancelled');
      case DioExceptionType.connectionError:
        throw NoInternetException(error.message ?? 'No internet connection');
      case DioExceptionType.badCertificate:
        throw BadRequestException(error.message ?? 'SSL certificate error');
      case DioExceptionType.unknown:
        throw FetchDataException(error.message ?? 'Unknown error occurred');
    }
  }

  /// Extract error message from response
  String? _extractErrorMessage(Response? response) {
    if (response?.data == null) return null;

    try {
      final data = response!.data;

      // Handle different response formats
      if (data is Map) {
        // Try common error message keys
        return data['message'] as String? ??
            data['error'] as String? ??
            data['msg'] as String? ??
            data['detail'] as String? ??
            data['errorMessage'] as String?;
      } else if (data is String) {
        return data;
      }
    } catch (e) {
      // If parsing fails, return null
      return null;
    }

    return null;
  }

  /// Send multipart request with files
  Future<dynamic> sendMultipartRequest({
    required String url,
    Map<String, dynamic>? fields,
    List<FileUploadModel>? files,
    bool isAuthRequired = false,
    String? authToken,
    ProgressCallback? onSendProgress,
  }) async {
    _ensureConnected();

    try {
      // Create FormData
      FormData formData = FormData();

      // Add text fields
      if (fields != null) {
        fields.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      // Add files
      if (files != null && files.isNotEmpty) {
        for (var fileModel in files) {
          File file = File(fileModel.filePath);

          // Check if file exists
          if (!await file.exists()) {
            throw Exception('File not found: ${fileModel.filePath}');
          }

          String fileName = fileModel.fileName ?? file.path.split('/').last;

          formData.files.add(
            MapEntry(
              fileModel.fieldName,
              await MultipartFile.fromFile(
                file.path,
                filename: fileName,
                contentType: fileModel.contentType,
              ),
            ),
          );
        }
      }

      // Set up options - DON'T set Content-Type manually, let Dio handle it
      Options requestOptions = Options(
        headers: {
          if (isAuthRequired && authToken != null)
            "Authorization": "Bearer $authToken",
        },
      );

      // Make the request
      Response response = await dio.post(
        url,
        data: formData,
        options: requestOptions,
        onSendProgress: onSendProgress,
      );

      return response.data;
    } on DioException catch (error) {
      _handleDioError(error);
      rethrow;
    } catch (error) {
      throw FetchDataException(error.toString());
    }
  }

  /// Alternative method for single file upload
  Future<dynamic> uploadSingleFile({
    required String url,
    required String fieldName,
    required String filePath,
    Map<String, dynamic>? additionalFields,
    bool isAuthRequired = false,
    String? authToken,
    ProgressCallback? onSendProgress,
  }) async {
    return sendMultipartRequest(
      url: url,
      fields: additionalFields,
      files: [FileUploadModel(fieldName: fieldName, filePath: filePath)],
      isAuthRequired: isAuthRequired,
      authToken: authToken,
      onSendProgress: onSendProgress,
    );
  }

  /// Upload multiple files under the same field name
  Future<dynamic> uploadMultipleFiles({
    required String url,
    required String fieldName,
    required List<String> filePaths,
    Map<String, dynamic>? additionalFields,
    bool isAuthRequired = false,
    String? authToken,
    ProgressCallback? onSendProgress,
  }) async {
    return sendMultipartRequest(
      url: url,
      fields: additionalFields,
      files: filePaths
          .map((path) => FileUploadModel(fieldName: fieldName, filePath: path))
          .toList(),
      isAuthRequired: isAuthRequired,
      authToken: authToken,
      onSendProgress: onSendProgress,
    );
  }

  /// DEPRECATED - Use sendMultipartRequest instead
  @Deprecated(
    'Use sendMultipartRequest, uploadSingleFile, or uploadMultipleFiles instead',
  )
  Future<dynamic> multiPartRequest({
    required String url,
    required Object requestBody,
    bool isAuthRequired = false,
    String? authToken,
  }) async {
    _ensureConnected();

    Options requestOptions = Options(
      headers: {
        if (isAuthRequired && authToken != null)
          "Authorization": "Bearer $authToken",
      },
    );

    try {
      Response response = await dio.post(
        url,
        data: requestBody,
        options: requestOptions,
      );
      return response.data;
    } on DioException catch (error) {
      _handleDioError(error);
      rethrow;
    } catch (error) {
      throw FetchDataException(error.toString());
    }
  }
}

class FileUploadModel {
  final String fieldName;
  final String filePath;
  final String? fileName;
  final MediaType? contentType;

  FileUploadModel({
    required this.fieldName,
    required this.filePath,
    this.fileName,
    this.contentType,
  });
}
