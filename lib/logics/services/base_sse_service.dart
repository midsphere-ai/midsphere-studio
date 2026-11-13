import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:eventflux/client.dart';
import 'package:eventflux/enum.dart';
import 'package:eventflux/http_client_adapter.dart';
import 'package:eventflux/models/reconnect.dart';
import 'package:eventflux/models/response.dart';
import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;

import '../data/global_logics.dart';

/// HTTP client adapter for long-lived SSE connections.
///
/// The default dart:io HttpClient has a 15-second idle timeout for connection
/// pooling. This adapter sets idleTimeout to zero so long-lived SSE streams
/// are never dropped during quiet periods. The server sends heartbeats every
/// 15 seconds for liveness detection instead.
class _SSEHttpClientAdapter implements HttpClientAdapter {
  late final io.HttpClient _httpClient;
  late final IOClient _ioClient;

  _SSEHttpClientAdapter() {
    _httpClient = io.HttpClient()
      ..idleTimeout = Duration.zero;
    _ioClient = IOClient(_httpClient);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _ioClient.send(request);
  }

  void close() {
    _ioClient.close();
    _httpClient.close();
  }
}

/// Connection state for SSE service.
enum SSEConnectionState {
  /// Initial state, not connected.
  disconnected,

  /// Currently attempting to connect.
  connecting,

  /// Successfully connected and receiving events.
  connected,

  /// Connection failed with an error.
  error,
}

/// Configuration for SSE reconnection behavior.
class SSEReconnectConfig {
  /// Maximum number of reconnection attempts.
  final int maxAttempts;

  /// Base interval between reconnection attempts.
  final Duration interval;

  /// Whether to use exponential backoff.
  final bool exponentialBackoff;

  const SSEReconnectConfig({
    this.maxAttempts = 15,
    this.interval = const Duration(seconds: 5),
    this.exponentialBackoff = false,
  });

  /// Default configuration with linear retry.
  static const SSEReconnectConfig linear = SSEReconnectConfig();

  /// Exponential backoff configuration.
  static const SSEReconnectConfig exponential = SSEReconnectConfig(
    exponentialBackoff: true,
    interval: Duration(seconds: 2),
  );
}

/// Generic base class for SSE streaming services using EventFlux.
///
/// This provides a consistent pattern for SSE connections with:
/// - Automatic reconnection with configurable backoff
/// - Last-Event-ID tracking for resumption after reconnect
/// - Generic event parsing via `fromJson` callback
/// - Connection state management
/// - Proper resource cleanup
///
/// Example usage:
/// ```dart
/// final service = BaseSSEService<MyEvent>(
///   endpoint: 'api/events/stream/',
///   fromJson: MyEvent.fromJson,
///   eventIdExtractor: (event) => event.id,
/// );
/// service.eventStream.listen((event) => print(event));
/// await service.connect();
/// ```
class BaseSSEService<T> {
  /// The endpoint path (relative to base URL).
  final String endpoint;

  EventFlux? _sseThread = EventFlux.spawn();
  /// Function to parse JSON data into event objects.
  final T Function(Map<String, dynamic> json) fromJson;

  /// Optional function to extract event ID for Last-Event-ID tracking.
  /// If provided, enables reconnection resumption.
  final String? Function(T event)? eventIdExtractor;

  /// Optional query parameters to append to the endpoint.
  final Map<String, String>? queryParams;

  /// Reconnection configuration.
  final SSEReconnectConfig reconnectConfig;

  /// Whether to automatically reconnect on connection loss.
  final bool autoReconnect;

  /// Optional logging callback for debugging.
  void Function(String message)? onLog;

  /// Optional callback for parse errors. If provided, called instead of addError.
  /// This allows subclasses to convert parse errors into typed data events.
  void Function(Object error, StackTrace stack)? onParseError;

  // Internal state
  StreamController<T>? _eventController;
  StreamController<SSEConnectionState>? _stateController;
  StreamSubscription<dynamic>? _streamSubscription;
  SSEConnectionState _connectionState = SSEConnectionState.disconnected;
  String? _authToken;
  String? _lastError;
  int _consecutiveFailures = 0;
  _SSEHttpClientAdapter? _httpClientAdapter;

  /// Last received event ID for reconnection resumption.
  /// When reconnecting, this is sent as Last-Event-ID header
  /// so the server skips already-received messages.
  String? _lastEventId;

  /// Timestamp of the most recent reconnection attempt.
  DateTime? _lastReconnectAt;

  /// Creates a new [BaseSSEService].
  ///
  /// [endpoint] - The API endpoint path (relative to base URL).
  /// [fromJson] - Function to parse JSON into event objects.
  /// [eventIdExtractor] - Optional function to extract event ID for Last-Event-ID tracking.
  /// [queryParams] - Optional query parameters.
  /// [reconnectConfig] - Configuration for automatic reconnection.
  /// [autoReconnect] - Whether to automatically reconnect on failure.
  BaseSSEService({
    required this.endpoint,
    required this.fromJson,
    this.eventIdExtractor,
    this.queryParams,
    this.reconnectConfig = SSEReconnectConfig.linear,
    this.autoReconnect = true,
  });

  /// Get the last event ID (useful for manual reconnection).
  String? get lastEventId => _lastEventId;

  /// Set the last event ID (useful when resuming from a known point).
  set lastEventId(String? id) => _lastEventId = id;

  /// Stream of parsed events.
  ///
  /// This is a broadcast stream, allowing multiple listeners.
  Stream<T> get eventStream {
    _eventController ??= StreamController<T>.broadcast();
    return _eventController!.stream;
  }

  /// Stream of connection state changes.
  Stream<SSEConnectionState> get stateStream {
    _stateController ??= StreamController<SSEConnectionState>.broadcast();
    return _stateController!.stream;
  }

  /// Current connection state.
  SSEConnectionState get connectionState => _connectionState;

  /// Whether the service is currently connected.
  bool get isConnected => _connectionState == SSEConnectionState.connected;

  /// Last error message, if any.
  String? get lastError => _lastError;

  /// Number of consecutive reconnection failures.
  int get reconnectionAttempts => _consecutiveFailures;

  /// Timestamp of the last reconnection attempt.
  DateTime? get lastReconnectAt => _lastReconnectAt;

  void _log(String message) {
    onLog?.call('[SSE:$endpoint] $message');
  }

  void _updateState(SSEConnectionState state) {
    _connectionState = state;
    _stateController?.add(state);
    _log('State changed to: ${state.name}');
  }

  /// Build the full URL with base URL, endpoint, and query parameters.
  String _buildUrl() {
    final baseUrl = DataConstants.url;
    var url = '$baseUrl$endpoint';

    if (queryParams != null && queryParams!.isNotEmpty) {
      final queryString = queryParams!.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      url = '$url?$queryString';
    }

    return url;
  }

  /// Connect to the SSE stream.
  ///
  /// [authToken] - Optional auth token. If not provided, uses DataConstants.getToken().
  Future<void> connect([String? authToken]) async {
    _authToken = authToken ?? DataConstants.getToken();

    if (_authToken == null) {
      _log('Cannot connect: no auth token');
      _lastError = 'No authentication token';
      _updateState(SSEConnectionState.error);
      return;
    }

    _updateState(SSEConnectionState.connecting);
    _lastError = null;

    final url = _buildUrl();

    try {
      final headers = {
        'Authorization': 'Bearer $_authToken',
        'Accept': 'text/event-stream',
      };
      // Include Last-Event-ID on initial connect if available (for resumption)
      if (_lastEventId != null) {
        headers['Last-Event-ID'] = _lastEventId!;
        _log('Connecting with Last-Event-ID: $_lastEventId');
      }

      // Use a custom HTTP client with no idle timeout for long-lived SSE.
      // The server sends heartbeats every 15s for liveness detection.
      _httpClientAdapter ??= _SSEHttpClientAdapter();

      _sseThread?.connect(
        EventFluxConnectionType.get,
        url,
        header: headers,
        httpClient: _httpClientAdapter,
        onSuccessCallback: (EventFluxResponse? response) {
          _consecutiveFailures = 0;
          _updateState(SSEConnectionState.connected);

          _streamSubscription = response?.stream?.listen(
            (data) {
              _onData(data.data);
            },
            onError: (error) {
              _lastError = error.toString();
              _updateState(SSEConnectionState.error);
            },
            onDone: () {
              if (_connectionState == SSEConnectionState.connected) {
                _updateState(SSEConnectionState.disconnected);
              }
            },
          );
        },
        onError: (error) {
          _lastError = error.toString();
          _updateState(SSEConnectionState.error);
        },
        autoReconnect: autoReconnect,
        reconnectConfig: ReconnectConfig(
          mode: reconnectConfig.exponentialBackoff
              ? ReconnectMode.exponential
              : ReconnectMode.linear,
          interval: reconnectConfig.interval,
          maxAttempts: reconnectConfig.maxAttempts,
          reconnectHeader: () async {
            // Refresh token on reconnect
            final newToken = DataConstants.getToken();
            if (newToken == null) {
              _log('Cannot reconnect: no auth token');
              _lastError = 'No authentication token';
              _updateState(SSEConnectionState.error);
              return {'Accept': 'text/event-stream'};
            }
            _authToken = newToken;
            final headers = {
              'Authorization': 'Bearer $newToken',
              'Accept': 'text/event-stream',
            };
            // Include Last-Event-ID for resumption if available
            if (_lastEventId != null) {
              headers['Last-Event-ID'] = _lastEventId!;
              _log('Reconnecting with Last-Event-ID: $_lastEventId');
            }
            return headers;
          },
          onReconnect: () {
            _consecutiveFailures++;
            _lastReconnectAt = DateTime.now();
            _log('Reconnecting... (attempt $_consecutiveFailures/${reconnectConfig.maxAttempts})');
            if (_consecutiveFailures >= reconnectConfig.maxAttempts) {
              _log('Circuit breaker: max reconnection attempts reached, disconnecting');
              _lastError = 'Max reconnection attempts (${ reconnectConfig.maxAttempts}) exceeded';
              disconnect();
              _updateState(SSEConnectionState.error);
              return;
            }
            _updateState(SSEConnectionState.connecting);
          },
        ),
      );
    } catch (e) {
      _lastError = e.toString();
      _updateState(SSEConnectionState.error);
    }
  }

  /// Parse and emit incoming data.
  void _onData(String? data) {
    if (data == null || data.isEmpty) return;

    // Skip SSE comments (heartbeats) - lines starting with ':'
    if (data.trim().startsWith(':')) {
      _log('Heartbeat received, ignoring');
      return;
    }

    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final event = fromJson(json);

      // Track the event ID for reconnection resumption
      if (eventIdExtractor != null) {
        final eventId = eventIdExtractor!(event);
        if (eventId != null && eventId.isNotEmpty) {
          _lastEventId = eventId;
        }
      }

      _eventController?.add(event);
      _log('Event received: ${event.runtimeType}');
    } catch (e, stack) {
      _log('Failed to parse event: $e (data: $data)');
      if (onParseError != null) {
        onParseError!(e, stack);
      }
    }
  }

  /// Disconnect from the SSE stream.
  void disconnect() {
    _log('Disconnecting...');
    _streamSubscription?.cancel();
    _streamSubscription = null;

    try {
      _sseThread?.disconnect();
    } catch (e) {
      _log('Error during disconnect: $e');
    }

    _updateState(SSEConnectionState.disconnected);
  }

  /// Dispose of all resources.
  ///
  /// After calling this, the service cannot be reused.
  void dispose() {
    disconnect();
    _httpClientAdapter?.close();
    _httpClientAdapter = null;
    _eventController?.close();
    _eventController = null;
    _stateController?.close();
    _stateController = null;
    _sseThread = null;
    _log('Service disposed');
  }
}

/// Factory for creating scoped SSE service instances.
///
/// Use this when you need multiple independent SSE connections
/// (e.g., per-conversation streams).
class SSEServiceFactory<T> {
  final String Function(String id) endpointBuilder;
  final T Function(Map<String, dynamic> json) fromJson;
  final String? Function(T event)? eventIdExtractor;
  final SSEReconnectConfig reconnectConfig;
  final bool autoReconnect;

  final Map<String, BaseSSEService<T>> _instances = {};

  SSEServiceFactory({
    required this.endpointBuilder,
    required this.fromJson,
    this.eventIdExtractor,
    this.reconnectConfig = SSEReconnectConfig.linear,
    this.autoReconnect = true,
  });

  /// Get or create a service instance for the given ID.
  BaseSSEService<T> getInstance(String id) {
    return _instances.putIfAbsent(
      id,
      () => BaseSSEService<T>(
        endpoint: endpointBuilder(id),
        fromJson: fromJson,
        eventIdExtractor: eventIdExtractor,
        reconnectConfig: reconnectConfig,
        autoReconnect: autoReconnect,
      ),
    );
  }

  /// Dispose a specific instance.
  void disposeInstance(String id) {
    _instances[id]?.dispose();
    _instances.remove(id);
  }

  /// Dispose all instances.
  void disposeAll() {
    for (final service in _instances.values) {
      service.dispose();
    }
    _instances.clear();
  }
}
