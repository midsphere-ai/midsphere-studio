import 'package:arcane/arcane.dart';
import 'package:dio/dio.dart';
import 'package:flutter_client/logics/data/helpers/general_utils.dart';

import '../../data/global_logics.dart';
import '../entities/base/base.dart';
import '../entities/base/repo.dart';

import 'package:sentry/sentry.dart';

class APIReference {
  final String endpoint;
  final String method;
  final List parameters;
  final List returnType;

  APIReference({
    required this.endpoint,
    required this.method,
    required this.parameters,
    required this.returnType,
  });
}

abstract class Endpoint {
  APIReference get requiredParams;
  String get value => "";
  String get name => "";
}

class NetworkConnector {
  static const successMessage = "Success";
  static Dio dio = Dio(
    BaseOptions(
      baseUrl: DataConstants.url,
      headers: _defaultHeaders,
      followRedirects: false,
      connectTimeout: 25000.ms,
      receiveTimeout: 15000.ms,
      validateStatus: (status) {
        return status! < 500;
      },
    ),
  );

  static Map<String, String> get _defaultHeaders => {
    "Authorization": "Bearer ${DataConstants.getToken()}",
  };

  static Future<dynamic> performPost(
    String endpoint, {
    dynamic data,
  }) async {
    try {
      return await dio.post(endpoint, data: data);
    } catch (exception, stackTrace) {
      await Sentry.captureException(exception, stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<dynamic> performGet(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.get(endpoint, queryParameters: queryParameters);
    } catch (exception, stackTrace) {
      await Sentry.captureException(exception, stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<dynamic> performPut(
    String endpoint, {
    dynamic data,
  }) async {
    try {
      return await dio.put(endpoint, data: data);
    } catch (exception, stackTrace) {
      await Sentry.captureException(exception, stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<dynamic> performPatch(
    String endpoint, {
    dynamic data,
  }) async {
    try {
      return await dio.patch(endpoint, data: data);
    } catch (exception, stackTrace) {
      await Sentry.captureException(exception, stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<dynamic> performDelete(
    String endpoint, {
    dynamic data,
  }) async {
    try {
      return await dio.delete(endpoint, data: data);
    } catch (exception, stackTrace) {
      await Sentry.captureException(exception, stackTrace: stackTrace);
      rethrow;
    }
  }

  static String getErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad Request: The server could not understand the request. Please check your input.';
      case 401:
        return 'Unauthorized: Access is denied due to invalid credentials.';
      case 403:
        return 'Forbidden: You do not have permission to access this resource.';
      case 404:
        return 'Not Found: The requested resource could not be found on the server.';
      case 408:
        return 'Request Timeout: The server timed out waiting for the request.';
      case 500:
        return 'Internal Server Error: Something went wrong on the server.';
      case 502:
        return 'Bad Gateway: The server received an invalid response from an upstream server.';
      case 503:
        return 'Service Unavailable: The server is currently unavailable. Please try again later.';
      case 504:
        return 'Gateway Timeout: The server took too long to respond.';
      default:
        return 'An error occurred. Please try again later.';
    }
  }

  /// Calls an API endpoint and returns the parsed response.
  ///
  /// Return types depend on the endpoint's `returnType` configuration:
  /// - When `returnType[0]` is [Map]: returns the result of `returnType[1](response.data)` (a parsed model instance)
  /// - Otherwise: returns `response.data` directly (typically for [List] or primitive responses)
  ///
  /// Throws [Exception] on non-2xx HTTP status codes or validation failures.
  static Future<dynamic> callEndpoint(
    Endpoint endpoint,
    Map<String, dynamic> parameters, {
    String? method,
  }) async {
    try {
      String apiEndpoint = endpoint.name;
      if (parameters.containsKey('page_size')) {
        apiEndpoint +=
            '${endpoint.requiredParams.endpoint}?page=${parameters['page_number']}&page_size=${parameters['page_size']}';
      } else {
        apiEndpoint += endpoint.requiredParams.endpoint;
      }

      method ??= endpoint.requiredParams.method;
      validateParameters(endpoint, parameters);
      for (String param in endpoint.requiredParams.parameters) {
        final queryParam = "{$param}";
        if (apiEndpoint.contains(queryParam)) {
          apiEndpoint = apiEndpoint.replaceAll(queryParam, parameters[param]);
        }
      }

      // Build filtered query params that exclude path-substituted params
      Map<String, dynamic> queryParams = Map.from(parameters);
      for (String param in endpoint.requiredParams.parameters) {
        if (endpoint.requiredParams.endpoint.contains('{$param}')) {
          queryParams.remove(param);
        }
      }
      queryParams.remove('page_size');
      queryParams.remove('page_number');

      dynamic data = parameters;
      bool containsFile = parameters.values.any((element) =>
          element is MultipartFile ||
          (element is List && element.any((e) => e is MultipartFile)));
      if (containsFile) {
        data = FormData.fromMap(parameters);
      }

      Response response;
      switch (method.toUpperCase()) {
        case "POST":
          response = await performPost(apiEndpoint, data: data);
          break;
        case "PUT":
          response = await performPut(apiEndpoint, data: data);
          break;
        case "PATCH":
          response = await performPatch(apiEndpoint, data: data);
          break;
        case "DELETE":
          response = await performDelete(apiEndpoint, data: data);
          break;
        case "GET":
          response = await performGet(apiEndpoint, queryParameters: queryParams);
          break;
        default:
          throw Exception("Unsupported HTTP method: $method");
      }

      if (isSuccessful(response.statusCode)) {
        final typeList = endpoint.requiredParams.returnType;
        if (typeList.isEmpty) {
          throw Exception(
            "Return type not specified for endpoint $apiEndpoint",
          );
        }

        final returnType = typeList.first;
        if (returnType == Map && typeList.length >= 2) {
          return typeList.last(response.data);
        }
        return response.data;
      }

      throw Exception(
        "${response.data}",
      );
    } catch (exception, stackTrace) {
      await Sentry.captureException(exception, stackTrace: stackTrace);
      rethrow;
    }
  }

  static dynamic buildRepository(
    String endpoint,
    BaseRepository repo,
    Map data,
    Function returnInstance, {
    bool justItems = false,
  }) async {
    try {
      if (data.isEmpty) {
        throw Exception("Empty data");
      }

      final rawItems = data['items'];
      if (rawItems == null || rawItems is! List) {
        throw FormatException(
          'Expected data["items"] to be a List, but got ${rawItems.runtimeType}: $rawItems',
        );
      }

      final newItems = rawItems
          .map((e) => returnInstance(e))
          .cast<BaseModel>()
          .toList();

      if (repo.accumulateItems) {
        // Infinite scroll mode: append items
        repo.appendItems(newItems);
      } else if (repo.maxCount == -1) {
        // First fetch: replace items
        repo.items = newItems;
      } else {
        // Legacy pagination behavior: add items
        repo.items.addAll(newItems);
      }

      repo.maxCount = data['count'];
      repo.totalPages = Toolkit.calculateTotalPages(
        repo.maxCount,
        repo.pageSize,
      );
      repo.removeDuplicates();
      repo.updateHasReachedMax();
      return repo;
    } catch (exception, stackTrace) {
      await Sentry.captureException(exception, stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<dynamic> callPaginatedEndpoints(
    BaseRepository repo,
    Endpoint endpoint,
    Map<String, dynamic> parameters, {
    bool justItems = false,
  }) async {
    try {
      if (repo.currentPage > repo.totalPages) {
        return repo;
      }
      parameters['page_size'] = repo.pageSize;
      parameters['page_number'] = repo.currentPage;

      final response = await callEndpoint(
        endpoint,
        parameters,
        method: endpoint.requiredParams.method,
      );

      if (response is String || response is bool) {
        return response;
      }

      if (response is Map) {
        repo.currentPage += 1;
        return buildRepository(
          endpoint.value,
          repo,
          response,
          endpoint.requiredParams.returnType.last,
        );
      }

      throw Exception(
        response.toString(),
      );
    } catch (exception, stackTrace) {
      await Sentry.captureException(exception, stackTrace: stackTrace);
      rethrow;
    }
  }

  static void validateParameters(
    Endpoint endpoint,
    Map<String, dynamic> parameters,
  ) {
    final requiredParams = endpoint.requiredParams;

    final missingParams = requiredParams.parameters
        .where(
          (param) =>
              !parameters.containsKey(param) || parameters[param] == null,
        )
        .toList();

    if (missingParams.isNotEmpty) {
      throw ArgumentError(
        'Missing required parameters for $endpoint: ${missingParams.join(", ")}',
      );
    }
  }

  static bool isSuccessful(int? statusCode) =>
      statusCode == 200 || statusCode == 201;
}
