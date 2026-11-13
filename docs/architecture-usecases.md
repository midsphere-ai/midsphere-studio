# Architecture Design: Domain Usecases & Networking

## Overview

The `lib/logics/domain/usecases/` directory serves as the centralized API interaction layer for the application. It decouples the application's business logic from the underlying HTTP networking implementation (Dio).

This layer is responsible for:
1.  Defining API Endpoints and their configurations.
2.  Executing HTTP requests (GET, POST, PUT, PATCH, DELETE).
3.  Validating request parameters.
4.  Handling Authentication (Bearer tokens).
5.  Global Error Handling (Sentry integration).
6.  Response Parsing and Type Conversion.
7.  Pagination management.

## Core Components

### 1. `NetworkConnector` (`base.dart`)
This is the core static class that wraps the `Dio` HTTP client. It configures the base URL, default headers (Authorization), and timeouts.

**Key Methods:**
*   **`performPost`, `performGet`, `performPut`, `performPatch`, `performDelete`**: Low-level wrappers around Dio methods. They handle exception catching, Sentry logging, and throwing formatted exceptions based on HTTP status codes.
*   **`callEndpoint`**: The primary entry point for executing an API call.
    *   Accepts an `Endpoint` object and a map of `parameters`.
    *   Validates parameters against the Endpoint's definition.
    *   Executes the request using the specified method (default: POST).
    *   Parses the response based on the `return_type` defined in the Endpoint.
*   **`callPaginatedEndpoints`**: Specialized method for fetching lists of data.
    *   Accepts a `BaseRepository` object to track state (current page, total pages).
    *   Automatically injects `page_size` and `page_number` into parameters.
    *   Updates the Repository with fetched items, counts, and pagination metadata.
*   **`validateParameters`**: Ensures all parameters required by the `Endpoint` are present.

### 2. `Endpoint` Interface (`base.dart`)
An abstract contract that all API endpoint collections must implement.

```dart
abstract class Endpoint {
  Map<String, List<dynamic>> get requiredParams; // Defines params and return types
  String get value; // Defines the API path (URL)
}
```

## Domain Specific Implementations

The architecture organizes endpoints by domain (e.g., `cms`, `memory`, `spaces`, `workspace`). Each domain typically consists of two files:

### 1. Endpoint Enums (`endpoint_enums.dart`)
Endpoints are defined as `enum`s implementing the `Endpoint` interface. This centralizes URL paths and configuration.

**Structure of `requiredParams`:**
*   `params`: List of string keys that *must* be present in the request map.
*   `return_type`: A list defining how to parse the response.
    *   Index 0: The expected Type (e.g., `Map`, `List<Map>`, or specific primitives).
    *   Index 1 (Optional): A factory function (e.g., `User.fromJson`) to convert the raw JSON into a strongly typed entity.

**Example:**
```dart
enum MyDomainEndpoints implements Endpoint {
  getData;

  @override
  String get value => "my-domain/get-data";

  @override
  Map<String, List<dynamic>> get requiredParams {
    switch (this) {
      case MyDomainEndpoints.getData:
        return {
          'params': ['id'],                 // 'id' is required
          'return_type': [Map, MyData.fromJson] // Response is a Map, convert using MyData.fromJson
        };
    }
  }
}
```

### 2. Usecase Classes (`<domain>_usecase.dart`)
These classes contain static methods that act as the public API for the rest of the application. They abstract the `NetworkConnector` calls, providing a strongly-typed function signature.

**Example:**
```dart
class MyDomain {
  static Future<dynamic> getData({required String id}) async {
    return NetworkConnector.callEndpoint(
      MyDomainEndpoints.getData,
      method: 'GET',
      {'id': id},
    );
  }
}
```

## Data Flow

1.  **Invocation**: UI or Logic layer calls a static method, e.g., `Memory.fetchMessages(repo: myRepo, conversationId: '123')`.
2.  **Configuration**: The Usecase method calls `NetworkConnector`, passing the specific `Endpoint` enum (e.g., `MemoryEndpoints.fetchMessages`) and parameters.
3.  **Validation**: `NetworkConnector` checks `Endpoint.requiredParams['params']` to ensure `conversation_id` is present.
4.  **Pagination (if applicable)**: If calling `callPaginatedEndpoints`, `page` and `page_size` are added to the request parameters from the `BaseRepository`.
5.  **Execution**: The HTTP request is sent via Dio.
6.  **Response Handling**:
    *   **Success (200/201)**: The response data is parsed. If a factory function is provided in `return_type`, the JSON is converted into Entity objects (e.g., `SukunaMessage`).
    *   **Failure**: Exceptions are caught, logged to Sentry, and rethrown with user-friendly messages.

## How to Add a New API Method

1.  **Define the Entity**: Ensure a model exists in `lib/logics/domain/entities/` with a `.fromJson` factory.
2.  **Add Endpoint Enum**:
    *   Go to `lib/logics/domain/usecases/<domain>/endpoint_enums.dart`.
    *   Add a new enum case.
    *   Update `value` (URL path) and `requiredParams` (params list and return type factory).
3.  **Add Usecase Method**:
    *   Go to `lib/logics/domain/usecases/<domain>/<domain>_usecase.dart`.
    *   Add a static method that accepts necessary arguments.
    *   Call `NetworkConnector.callEndpoint` (or `callPaginatedEndpoints`) with the new enum.
