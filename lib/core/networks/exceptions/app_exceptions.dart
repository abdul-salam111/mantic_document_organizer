// FILE: lib/core/networks/exceptions/app_exceptions.dart

class AppException implements Exception {
  final String? _message;
  final String? _prefix;

  AppException([this._message, this._prefix]);

  /// Text intended for the person using the app. Transport/status prefixes
  /// remain useful in [toString] for diagnostics, but the API's `detail`
  /// should reach the user unchanged (for example, “No account found with
  /// this email.”).
  String get message {
    final message = _message;
    if (message != null && message.isNotEmpty) return message;
    final prefix = _prefix?.trim();
    if (prefix == null || prefix.isEmpty) return 'An error occurred';
    return prefix.endsWith(':')
        ? prefix.substring(0, prefix.length - 1)
        : prefix;
  }

  @override
  String toString() {
    if (_message == null || _message.isEmpty) {
      return _prefix ?? "An error occurred";
    }
    return "${_prefix ?? ''}$_message";
  }
}

/// A person dismissed a platform authentication sheet. This is an expected
/// outcome, so presentation code should return quietly instead of showing an
/// error toast.
class AuthenticationCancelledException extends AppException {
  AuthenticationCancelledException() : super('Authentication was cancelled.');
}

// Network Exceptions
class NoInternetException extends AppException {
  NoInternetException([String? message])
    : super(message, "No Internet Connection: ");
}

class RequestTimeoutException extends AppException {
  RequestTimeoutException([String? message])
    : super(message, "Request Timeout: ");
}

class FetchDataException extends AppException {
  FetchDataException([String? message]) : super(message, "Fetch Data Error: ");
}

// Authentication & Authorization Exceptions
class UnauthorizedException extends AppException {
  UnauthorizedException([String? message]) : super(message, "Unauthorized: ");
}

class ForbiddenException extends AppException {
  ForbiddenException([String? message]) : super(message, "Forbidden Access: ");
}

// Client Error Exceptions
class BadRequestException extends AppException {
  BadRequestException([String? message]) : super(message, "Invalid Request: ");
}

class NotFoundException extends AppException {
  NotFoundException([String? message]) : super(message, "Resource Not Found: ");
}

class MethodNotAllowedException extends AppException {
  MethodNotAllowedException([String? message])
    : super(message, "Method Not Allowed: ");
}

class InvalidInputException extends AppException {
  InvalidInputException([String? message]) : super(message, "Invalid Input: ");
}

class TooManyRequestsException extends AppException {
  TooManyRequestsException([String? message])
    : super(message, "Too Many Requests: ");
}

// Server Error Exceptions
class InternalServerErrorException extends AppException {
  InternalServerErrorException([String? message])
    : super(message, "Internal Server Error: ");
}

class ServiceUnavailableException extends AppException {
  ServiceUnavailableException([String? message])
    : super(message, "Service Unavailable: ");
}
