/// API error status codes returned from the backend.
enum ApiErrorStatus {
  /// User doesn't have permission to access the resource.
  unauthorized,
  /// Resource was not found.
  notFound,
  /// Service is temporarily unavailable (e.g., sandbox creation failed).
  serviceUnavailable,
  /// Rate limit exceeded (e.g., task limit for the week).
  limitExceeded,
  /// Task already running for this conversation.
  conflict,
  /// No workers available to handle the request (Orbiter 429).
  noWorkers,
  /// Unknown error status.
  unknown,
}

/// Structured API exception with detailed error information.
///
/// Used for handling specific error responses from the backend:
/// - 403: Resource authorization errors (addon, MCP config, model permissions)
/// - 404: Resource not found errors
/// - 503: Service unavailable (sandbox creation failure)
class ApiException implements Exception {
  /// Human-readable error message from the backend.
  final String message;

  /// HTTP status code.
  final int statusCode;

  /// Backend status string (e.g., 'unauthorized', 'service_unavailable').
  final ApiErrorStatus status;

  /// Suggested retry delay in seconds (for 503 errors).
  final int? retryAfter;

  ApiException({
    required this.message,
    required this.statusCode,
    this.status = ApiErrorStatus.unknown,
    this.retryAfter,
  });

  /// Parse from a backend error response.
  factory ApiException.fromResponse(int statusCode, Map<String, dynamic> data) {
    final errorMessage = data['error'] as String? ?? 'An error occurred';
    final statusStr = data['status'] as String? ?? '';
    final retryAfter = data['retry_after'] as int?;

    ApiErrorStatus status;
    switch (statusStr) {
      case 'unauthorized':
        status = ApiErrorStatus.unauthorized;
        break;
      case 'not_found':
        status = ApiErrorStatus.notFound;
        break;
      case 'service_unavailable':
        status = ApiErrorStatus.serviceUnavailable;
        break;
      case 'limit_exceeded':
        status = ApiErrorStatus.limitExceeded;
        break;
      case 'conflict':
        status = ApiErrorStatus.conflict;
        break;
      case 'no_workers':
        status = ApiErrorStatus.noWorkers;
        break;
      default:
        status = ApiErrorStatus.unknown;
    }

    return ApiException(
      message: errorMessage,
      statusCode: statusCode,
      status: status,
      retryAfter: retryAfter,
    );
  }

  /// Whether this is a permission/authorization error.
  bool get isPermissionError => status == ApiErrorStatus.unauthorized || statusCode == 403;

  /// Whether this is a not found error.
  bool get isNotFoundError => status == ApiErrorStatus.notFound || statusCode == 404;

  /// Whether this is a service unavailable error (should retry).
  bool get isServiceUnavailable => status == ApiErrorStatus.serviceUnavailable || statusCode == 503;

  /// Whether this is a rate limit error (429).
  bool get isLimitExceeded => status == ApiErrorStatus.limitExceeded || statusCode == 429;

  /// Whether this is a conflict error (409) - e.g., task already running.
  bool get isConflict => status == ApiErrorStatus.conflict || statusCode == 409;

  /// Whether no workers are available (Orbiter 429 with status: "no_workers").
  bool get isNoWorkers => status == ApiErrorStatus.noWorkers;

  /// Whether the user should retry the operation.
  bool get shouldRetry => (isServiceUnavailable || isNoWorkers) && retryAfter != null;

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

abstract class BaseModel {
  static int _idCounter = 0;
  String id = '${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';
  DateTime dateCreated = DateTime(2000, 12, 13);

  Map<String, dynamic> toJson();

  static T fromJson<T extends BaseModel>(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson() has not been implemented.');
  }

  String dateTimeToJson(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  DateTime dateTimeFromJson(String dateStr) {
    return DateTime.parse(dateStr);
  }

  @override
  String toString() {
    return toJson().toString();
  }
}
