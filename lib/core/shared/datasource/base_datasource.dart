import '../../networks/networks_exports.dart';

/* -------------------------------------------------------------------------- */
/*                         Base Remote Datasource                              */
/* -------------------------------------------------------------------------- */

abstract class BaseRemoteDatasource {
  final DioHelper dioHelper;

  const BaseRemoteDatasource({required this.dioHelper});

  /// POST request with single object response
  Future<T> post<T>({
    required String url,
    required Map<String, dynamic> body,
    required T Function(dynamic response) parser,
    String? authToken,
  }) async {
    try {
      final response = await dioHelper.postApi(
        url: url,
        requestBody: body,
        authToken: authToken,
        isAuthRequired: authToken != null,
      );
      return parser(response);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// POST request with list response
  Future<List<T>> postList<T>({
    required String url,
    required Map<String, dynamic> body,
    required T Function(dynamic json) parser,
    String? authToken,
  }) async {
    try {
      final response = await dioHelper.postApi(
        url: url,
        requestBody: body,
        authToken: authToken,
        isAuthRequired: authToken != null,
      );
      return List<T>.from(response.map((json) => parser(json)));
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// GET request with single object response
  Future<T> get<T>({
    required String url,
    required T Function(dynamic response) parser,
    Map<String, dynamic>? queryParams,
    String? authToken,
  }) async {
    try {
      final response = await dioHelper.getApi(
        url: url,
        authToken: authToken,
        isAuthRequired: authToken != null,
        queryParameters: queryParams,
      );
      return parser(response);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// GET request with list response
  Future<List<T>> getList<T>({
    required String url,
    required T Function(dynamic json) parser,
    Map<String, dynamic>? queryParams,
    String? authToken,
  }) async {
    try {
      final response = await dioHelper.getApi(
        url: url,
        authToken: authToken,
        isAuthRequired: authToken != null,
        queryParameters: queryParams,
      );
      return List<T>.from(response.map((json) => parser(json)));
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// PUT request with single object response
  Future<T> put<T>({
    required String url,
    required Map<String, dynamic> body,
    required T Function(dynamic response) parser,
    String? authToken,
  }) async {
    try {
      final response = await dioHelper.putApi(
        url: url,
        requestBody: body,
        authToken: authToken,
        isAuthRequired: authToken != null,
      );
      return parser(response);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// PUT request with list response
  Future<List<T>> putList<T>({
    required String url,
    required Map<String, dynamic> body,
    required T Function(dynamic json) parser,
    String? authToken,
  }) async {
    try {
      final response = await dioHelper.putApi(
        url: url,
        requestBody: body,
        authToken: authToken,
        isAuthRequired: authToken != null,
      );
      return List<T>.from(response.map((json) => parser(json)));
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// DELETE request with single object response
  Future<T> delete<T>({
    required String url,
    required T Function(dynamic response) parser,
    Map<String, dynamic>? queryParams,
    String? authToken,
  }) async {
    try {
      final response = await dioHelper.deleteApi(
        url: url,
        authToken: authToken,
        isAuthRequired: authToken != null,
        queryParameters: queryParams,
      );
      return parser(response);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// DELETE request with list response
  Future<List<T>> deleteList<T>({
    required String url,
    required T Function(dynamic json) parser,
    Map<String, dynamic>? queryParams,
    String? authToken,
  }) async {
    try {
      final response = await dioHelper.deleteApi(
        url: url,
        authToken: authToken,
        isAuthRequired: authToken != null,
        queryParameters: queryParams,
      );
      return List<T>.from(response.map((json) => parser(json)));
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  /// PATCH request with single object response
  Future<T> patch<T>({
    required String url,
    required Map<String, dynamic> body,
    required T Function(dynamic response) parser,
    String? authToken,
  }) async {
    try {
      final response = await dioHelper.patchApi(
        url: url,
        requestBody: body,
        authToken: authToken,
        isAuthRequired: authToken != null,
      );
      return parser(response);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(e.toString());
    }
  }
}
