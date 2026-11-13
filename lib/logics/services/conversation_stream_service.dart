import 'dart:async';

import 'base_sse_service.dart';
import '../domain/entities/memory/conversation/base.dart';

/// Event types received from the conversation stream SSE endpoint.
enum ConversationEventType {
  /// A conversation was created or updated.
  conversationUpdated,

  /// A conversation was deleted.
  conversationDeleted,

  /// Initial sync of all conversations is complete.
  syncComplete,

  /// Periodic keepalive signal (~5 seconds).
  heartbeat,

  /// An error occurred on the server.
  error,
}

/// Represents a single event from the conversation stream.
class ConversationStreamEvent {
  /// The type of this event.
  final ConversationEventType type;

  /// The event payload data. Contents vary by event type:
  /// - `conversationUpdated`: `{conversation: {...}, is_new: bool}`
  /// - `conversationDeleted`: `{conversation_id: String}`
  /// - `syncComplete`: `{conversations: [...]}`
  /// - `heartbeat`: `{}`
  /// - `error`: `{message: String}`
  final Map<String, dynamic> data;

  const ConversationStreamEvent._({
    required this.type,
    required this.data,
  });

  /// Create a conversation updated event.
  factory ConversationStreamEvent.conversationUpdated(
    Map<String, dynamic> data,
  ) {
    return ConversationStreamEvent._(
      type: ConversationEventType.conversationUpdated,
      data: data,
    );
  }

  /// Create a conversation deleted event.
  factory ConversationStreamEvent.conversationDeleted(
    Map<String, dynamic> data,
  ) {
    return ConversationStreamEvent._(
      type: ConversationEventType.conversationDeleted,
      data: data,
    );
  }

  /// Create a sync complete event.
  factory ConversationStreamEvent.syncComplete(Map<String, dynamic> data) {
    return ConversationStreamEvent._(
      type: ConversationEventType.syncComplete,
      data: data,
    );
  }

  /// Create a heartbeat event.
  factory ConversationStreamEvent.heartbeat() {
    return const ConversationStreamEvent._(
      type: ConversationEventType.heartbeat,
      data: {},
    );
  }

  /// Create an error event.
  factory ConversationStreamEvent.error(String message) {
    return ConversationStreamEvent._(
      type: ConversationEventType.error,
      data: {'message': message},
    );
  }

  /// Parse a raw SSE JSON payload into an event.
  factory ConversationStreamEvent.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? '';

    switch (typeStr) {
      case 'conversation_updated':
        return ConversationStreamEvent.conversationUpdated(json);
      case 'conversation_deleted':
        return ConversationStreamEvent.conversationDeleted(json);
      case 'sync_complete':
        return ConversationStreamEvent.syncComplete(json);
      case 'heartbeat':
        return ConversationStreamEvent.heartbeat();
      case 'error':
        return ConversationStreamEvent.error(
          json['message'] as String? ?? 'Unknown error',
        );
      default:
        // Treat unknown types as info/heartbeat
        return ConversationStreamEvent.heartbeat();
    }
  }

  /// Extract the conversation object from an update event.
  Conversation? get conversation {
    if (type != ConversationEventType.conversationUpdated) return null;
    final convJson = data['conversation'] as Map<String, dynamic>?;
    if (convJson == null) return null;
    return Conversation.fromJson(convJson);
  }

  /// Check if this update represents a new conversation.
  bool get isNew => data['is_new'] == true;

  /// Get the conversation ID from a delete event.
  String? get deletedConversationId {
    if (type != ConversationEventType.conversationDeleted) return null;
    return data['conversation_id'] as String?;
  }

  /// Get the list of conversations from a sync complete event.
  List<Conversation> get syncedConversations {
    if (type != ConversationEventType.syncComplete) return [];
    final list = data['conversations'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Conversation.fromJson)
        .toList();
  }

  /// Get error message from an error event.
  String? get errorMessage {
    if (type != ConversationEventType.error) return null;
    return data['message'] as String?;
  }
}

/// SSE streaming service for real-time conversation updates using EventFlux.
///
/// Connects to the `/api/memory/conversations/stream` endpoint and provides
/// a stream of [ConversationStreamEvent] objects for real-time UI updates.
///
/// This is a wrapper around [BaseSSEService] with conversation-specific
/// configuration and filtering (e.g., heartbeat filtering).
///
/// Example usage:
/// ```dart
/// final service = ConversationStreamService();
/// service.eventStream.listen((event) {
///   if (event.type == ConversationEventType.conversationUpdated) {
///     print('Updated: ${event.conversation?.title}');
///   }
/// });
/// await service.connect();
/// ```
class ConversationStreamService {
  /// The underlying SSE service.
  final BaseSSEService<ConversationStreamEvent> _service;

  /// Stream controller for filtered events (excludes heartbeats).
  StreamController<ConversationStreamEvent>? _filteredController;
  StreamSubscription<ConversationStreamEvent>? _subscription;
  bool _disposed = false;

  /// Optional logging callback for debugging.
  void Function(String message)? onLog;

  /// Creates a new [ConversationStreamService].
  ///
  /// [baseUrl] - Optional base URL (defaults to DataConstants.url).
  /// [pollInterval] - Unused, kept for API compatibility.
  ConversationStreamService({
    String? baseUrl,
    int? pollInterval,
  }) : _service = BaseSSEService<ConversationStreamEvent>(
          endpoint: 'memory/conversations/stream/',
          fromJson: ConversationStreamEvent.fromJson,
          reconnectConfig: SSEReconnectConfig.linear,
          autoReconnect: true,
        ) {
    _service.onLog = (msg) => onLog?.call(msg);
    _service.onParseError = (error, stack) {
      _filteredController?.add(ConversationStreamEvent.error(error.toString()));
    };
  }

  /// Stream of conversation events (heartbeats are filtered out).
  ///
  /// This is a broadcast stream, allowing multiple listeners.
  Stream<ConversationStreamEvent> get eventStream {
    if (_disposed) {
      throw StateError('ConversationStreamService has been disposed');
    }
    _filteredController ??= StreamController<ConversationStreamEvent>.broadcast();
    return _filteredController!.stream;
  }

  /// Stream of connection state changes.
  Stream<SSEConnectionState> get stateStream => _service.stateStream;

  /// Whether the service is currently connected.
  bool get isConnected => _service.isConnected;

  /// Current connection state.
  SSEConnectionState get connectionState => _service.connectionState;

  /// Connect to the SSE stream.
  ///
  /// [authToken] - Bearer authentication token.
  Future<void> connect(String authToken) async {
    if (_disposed) {
      throw StateError('Cannot connect: ConversationStreamService has been disposed');
    }
    _filteredController ??= StreamController<ConversationStreamEvent>.broadcast();
    _subscription ??= _service.eventStream.listen(
      (event) {
        if (event.type != ConversationEventType.heartbeat) {
          _filteredController?.add(event);
        }
      },
      onError: (error) {
        _filteredController?.add(ConversationStreamEvent.error(error.toString()));
      },
    );
    await _service.connect(authToken);
  }

  /// Disconnect from the SSE stream.
  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _service.disconnect();
  }

  /// Dispose of all resources.
  ///
  /// After calling this, the service cannot be reused.
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _subscription = null;
    _filteredController?.close();
    _filteredController = null;
    _service.dispose();
  }
}

/// Global singleton instance for app-wide access.
ConversationStreamService? _globalConversationStreamService;

/// Get or create the global conversation stream service.
///
/// This ensures a single SSE connection is shared across the app.
ConversationStreamService getConversationStreamService({int? pollInterval}) {
  _globalConversationStreamService ??= ConversationStreamService(
    pollInterval: pollInterval,
  );
  return _globalConversationStreamService!;
}

/// Dispose of the global conversation stream service.
///
/// Call this when the app is closing or the user logs out.
void disposeConversationStreamService() {
  _globalConversationStreamService?.dispose();
  _globalConversationStreamService = null;
}
