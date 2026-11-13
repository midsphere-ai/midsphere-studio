import 'dart:async';

import 'package:flutter_client/logics/domain/entities/memory/conversation/message.dart';

import 'base_sse_service.dart';
import 'conversation_stream_service.dart';
import '../data/global_logics.dart';

/// Event types received from the agent stream.
enum AgentStreamEventType {
  /// A message was received from the agent.
  message,
  /// The agent task completed.
  complete,
  /// An error occurred.
  error,
  /// The conversation's busy status (onGoing) changed.
  statusChanged,
}

/// Completion status from the agent stream.
enum AgentCompletionStatus {
  /// Task finished successfully. All messages have been delivered.
  completed,
  /// Something went wrong during execution (API error, sandbox failure, etc.).
  error,
  /// Agent never started within 2 minutes. Temporal worker failed to pick up task.
  timeout,
  /// Conversation was deleted while stream was active.
  deleted,
  /// Task was cancelled by user or system.
  cancelled,
  /// Unknown status (fallback).
  unknown,
}

/// Represents a completion event from the agent stream.
class AgentStreamComplete {
  final String type;
  final String statusString;
  final AgentCompletionStatus status;
  final String? reason;

  AgentStreamComplete({
    required this.type,
    required this.statusString,
    required this.status,
    this.reason,
  });

  factory AgentStreamComplete.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'completed';
    return AgentStreamComplete(
      type: json['type'] ?? 'complete',
      statusString: statusStr,
      status: _parseStatus(statusStr),
      reason: json['reason'] as String?,
    );
  }

  static AgentCompletionStatus _parseStatus(String status) {
    switch (status) {
      case 'completed':
      case 'done':
        return AgentCompletionStatus.completed;
      case 'error':
        return AgentCompletionStatus.error;
      case 'timeout':
        return AgentCompletionStatus.timeout;
      case 'deleted':
        return AgentCompletionStatus.deleted;
      case 'cancelled':
        return AgentCompletionStatus.cancelled;
      default:
        return AgentCompletionStatus.unknown;
    }
  }

  /// Whether the task completed with an error.
  bool get hasError => status == AgentCompletionStatus.error;

  /// Whether the task completed successfully.
  bool get isCompleted => status == AgentCompletionStatus.completed;

  /// Whether the agent timed out (never started within 2 minutes).
  bool get isTimeout => status == AgentCompletionStatus.timeout;

  /// Whether the conversation was deleted mid-stream.
  bool get isDeleted => status == AgentCompletionStatus.deleted;

  /// Whether the task was cancelled.
  bool get isCancelled => status == AgentCompletionStatus.cancelled;

  /// Whether the user should retry the task.
  bool get shouldRetry => isTimeout;
}

/// Represents an event from the agent stream.
class AgentStreamEvent {
  final AgentStreamEventType eventType;
  final SukunaMessage? message;
  final AgentStreamComplete? complete;
  final String? error;
  /// Whether the conversation is currently busy (onGoing).
  /// Only set for statusChanged events.
  final bool? isOnGoing;

  AgentStreamEvent._({
    required this.eventType,
    this.message,
    this.complete,
    this.error,
    this.isOnGoing,
  });

  factory AgentStreamEvent.message(SukunaMessage message) {
    return AgentStreamEvent._(
      eventType: AgentStreamEventType.message,
      message: message,
    );
  }

  factory AgentStreamEvent.complete(AgentStreamComplete complete) {
    return AgentStreamEvent._(
      eventType: AgentStreamEventType.complete,
      complete: complete,
    );
  }

  factory AgentStreamEvent.error(String error) {
    return AgentStreamEvent._(
      eventType: AgentStreamEventType.error,
      error: error,
    );
  }

  /// Create a status changed event when the conversation's onGoing status changes.
  factory AgentStreamEvent.statusChanged(bool isOnGoing) {
    return AgentStreamEvent._(
      eventType: AgentStreamEventType.statusChanged,
      isOnGoing: isOnGoing,
    );
  }

  factory AgentStreamEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;

    // Handle completion event
    if (type == 'complete') {
      return AgentStreamEvent.complete(AgentStreamComplete.fromJson(json));
    }

    // Ignore heartbeat/ping events - return a no-op status event
    if (type == 'heartbeat' || type == 'ping') {
      return AgentStreamEvent._(eventType: AgentStreamEventType.statusChanged, isOnGoing: null);
    }

    // Handle error events (non-fatal, stream continues)
    // Orbiter sends structured errors: {data: {error: "..."}} or {message: "..."}
    if (type == 'error') {
      final data = json['data'] is Map ? json['data'] as Map : null;
      final errorMsg = data?['error']?.toString() ?? json['message']?.toString() ?? 'Unknown error';
      // Recoverable errors → show inline as message so they render in chat
      if (data != null && data['recoverable'] == true) {
        return AgentStreamEvent.message(SukunaMessage.fromSSE(json));
      }
      return AgentStreamEvent.error(errorMsg);
    }

    // All other types are message events:
    // - message_output: Text response from the AI model
    // - tool_call: Agent is invoking a tool
    // - tool_result_output: Result returned from a tool
    // - step_output: Progress/step indicator
    try {
      // Use fromSSE() which handles SSE field names (content, created_at)
      // instead of REST API field names (message, date_created)
      return AgentStreamEvent.message(SukunaMessage.fromSSE(json));
    } catch (e) {
      rethrow;
    }
  }

  /// Get the event ID for Last-Event-ID tracking.
  /// Returns null for non-message events or events without ID.
  String? get eventId {
    if (eventType == AgentStreamEventType.message && message != null) {
      return message!.id;
    }
    return null;
  }
}

/// Service for streaming real-time agent execution updates via SSE using EventFlux.
///
/// Connects to the `/chat/completions/{task_id}/events` endpoint
/// and provides a stream of [AgentStreamEvent] objects.
///
/// This is a wrapper around [BaseSSEService] with agent-specific
/// configuration and automatic completion handling.
///
/// Features:
/// - Automatic reconnection with exponential backoff
/// - Last-Event-ID tracking for seamless reconnection resumption
/// - Handles all completion statuses (completed, error, timeout, deleted)
/// - Integrates with conversation stream for onGoing status changes
///
/// Example usage:
/// ```dart
/// final service = AgentStreamService();
/// service.eventStream.listen((event) {
///   switch (event.eventType) {
///     case AgentStreamEventType.message:
///       print('Message: ${event.message?.content}');
///       break;
///     case AgentStreamEventType.complete:
///       if (event.complete?.shouldRetry ?? false) {
///         print('Agent timed out, please retry');
///       }
///       break;
///     case AgentStreamEventType.error:
///       print('Error: ${event.error}');
///       break;
///   }
/// });
/// await service.connect(authToken: 'token', taskId: 'task-id', conversationId: 'conv-id');
/// ```
class AgentStreamService {
  /// The underlying SSE service (created per conversation).
  BaseSSEService<AgentStreamEvent>? _service;

  final String baseUrl;
  String? _taskId;
  String? _conversationId;

  /// Optional logging callback.
  void Function(String message)? onLog;

  /// Stream controller for events.
  StreamController<AgentStreamEvent>? _eventController;
  StreamSubscription<AgentStreamEvent>? _subscription;

  /// Flag to prevent concurrent connect() calls (race condition prevention).
  bool _isConnecting = false;

  /// Subscription to the conversation stream for onGoing status updates.
  StreamSubscription<ConversationStreamEvent>? _conversationSubscription;
  /// Track the last known onGoing status to detect changes.
  bool? _lastOnGoingStatus;

  /// Last received event ID for reconnection resumption.
  String? _lastEventId;

  /// Creates a new [AgentStreamService].
  AgentStreamService({required this.baseUrl});

  /// Get the last event ID (useful for debugging or manual reconnection).
  String? get lastEventId => _lastEventId;

  /// Stream of agent events.
  Stream<AgentStreamEvent> get eventStream {
    _eventController ??= StreamController<AgentStreamEvent>.broadcast();
    return _eventController!.stream;
  }

  /// Whether the service is currently connected.
  bool get isConnected => _service?.isConnected ?? false;

  /// Current connection state.
  SSEConnectionState get connectionState =>
      _service?.connectionState ?? SSEConnectionState.disconnected;

  /// Stream of connection state changes.
  /// Useful for showing connection status in the UI.
  Stream<SSEConnectionState>? get connectionStateStream => _service?.stateStream;

  /// The conversation ID currently connected to, if any.
  String? get conversationId => _conversationId;

  void _log(String message) {
    final prefix = _conversationId != null
        ? '[AgentStream:$_conversationId]'
        : '[AgentStream]';
    onLog?.call('$prefix $message');
  }

  /// The task ID currently connected to, if any.
  String? get taskId => _taskId;

  /// Connect to the SSE stream for a task.
  ///
  /// [authToken] - Bearer token for authentication.
  /// [taskId] - The task ID to stream events from (from POST /completions/start).
  /// [conversationId] - Optional conversation ID for conversation stream subscription.
  /// [resumeFromEventId] - Optional event ID to resume from (for manual reconnection).
  Future<void> connect({
    required String authToken,
    required String taskId,
    String? conversationId,
    String? resumeFromEventId,
  }) async {
    // Prevent concurrent connect() calls (race condition)
    if (_isConnecting) {
      _log('Connect already in progress, ignoring duplicate call');
      return;
    }
    _isConnecting = true;

    try {
      _taskId = taskId;
      _conversationId = conversationId;

      // Clean up any existing connection, wrapped so a failed cleanup
      // doesn't prevent creating a new connection
      try {
        await _cleanup();
      } catch (e) {
        _log('Cleanup of previous connection failed: $e');
        _subscription = null;
        _conversationSubscription = null;
        _service = null;
      }

      // Set initial last event ID if resuming
      if (resumeFromEventId != null) {
        _lastEventId = resumeFromEventId;
        _log('Resuming from event ID: $resumeFromEventId');
      }

      // Create new service for this task with event ID tracking
      _service = BaseSSEService<AgentStreamEvent>(
        endpoint: 'chat/completions/$taskId/events',
        fromJson: AgentStreamEvent.fromJson,
        // Extract event ID from message events for Last-Event-ID tracking
        eventIdExtractor: (event) => event.eventId,
        // Backend sends retry: 1000 (1 second), use exponential backoff starting at 1s
        reconnectConfig: const SSEReconnectConfig(
          maxAttempts: 15,
          interval: Duration(seconds: 1), // Match backend's retry directive
          exponentialBackoff: true,
        ),
        autoReconnect: true,
      );
      _service!.onLog = (msg) => _log(msg);
      _service!.onParseError = (error, stack) {
        _eventController?.add(AgentStreamEvent.error(error.toString()));
      };

      // Set the initial last event ID on the underlying service
      if (_lastEventId != null) {
        _service!.lastEventId = _lastEventId;
      }

      // Ensure controller exists
      _eventController ??= StreamController<AgentStreamEvent>.broadcast();

      // Subscribe to message stream events
      // Note: We do NOT auto-disconnect on completion events.
      // The SSE connection should stay active until the widget is disposed,
      // as agent tasks can have long gaps (30+ seconds or minutes) between messages.
      _subscription = _service!.eventStream.listen(
        (event) {
          // Track last event ID for reconnection resumption
          final eventId = event.eventId;
          if (eventId != null && eventId.isNotEmpty) {
            _lastEventId = eventId;
          }

          _eventController?.add(event);

          if (event.eventType == AgentStreamEventType.complete) {
            _log('Agent task completed: ${event.complete?.status} (${event.complete?.statusString})');
            // Log additional details for debugging
            if (event.complete?.shouldRetry ?? false) {
              _log('Task timed out - agent never started. User should retry.');
            }
            if (event.complete?.isDeleted ?? false) {
              _log('Conversation was deleted mid-stream.');
            }
            // Connection stays active - widget will dispose when appropriate
          }
        },
        onError: (error) {
          _log('Stream error: $error');
          _eventController?.add(AgentStreamEvent.error(error.toString()));
        },
      );

      // Subscribe to the global conversation stream for onGoing status changes.
      // This allows the widget to toggle isAgentBusy based on conversation state.
      if (_conversationId != null) {
        final conversationService = getConversationStreamService();
        _conversationSubscription = conversationService.eventStream
            .where((e) => e.type == ConversationEventType.conversationUpdated)
            .listen(
          (event) {
            final conv = event.conversation;
            if (conv != null && conv.id == _conversationId) {
              final newOnGoing = conv.onGoing;
              if (_lastOnGoingStatus != newOnGoing) {
                _lastOnGoingStatus = newOnGoing;
                _log('Conversation onGoing changed to: $newOnGoing');
                _eventController?.add(AgentStreamEvent.statusChanged(newOnGoing));
              }
            }
          },
          onError: (error) {
            _log('Conversation stream error: $error');
          },
        );
      }

      // Connect to message stream
      await _service!.connect(authToken);
      _log('Connected to stream for task $taskId');
    } catch (e) {
      _log('Connection failed: $e');
      await _cleanup();
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _cleanup({bool preserveLastEventId = true}) async {
    await _subscription?.cancel();
    _subscription = null;
    await _conversationSubscription?.cancel();
    _conversationSubscription = null;
    _lastOnGoingStatus = null;
    _service?.dispose();
    _service = null;
    // Preserve lastEventId for reconnection unless explicitly reset
    if (!preserveLastEventId) {
      _lastEventId = null;
    }
  }

  /// Disconnect from the SSE stream.
  ///
  /// [resetEventId] - If true, resets the last event ID.
  /// Set to false if you plan to reconnect and resume from the same point.
  void disconnect({bool resetEventId = true}) {
    _log('Disconnecting (resetEventId: $resetEventId)');
    _service?.disconnect();
    _subscription?.cancel();
    _subscription = null;
    _conversationSubscription?.cancel();
    _conversationSubscription = null;
    _lastOnGoingStatus = null;
    _taskId = null;
    _conversationId = null;
    if (resetEventId) {
      _lastEventId = null;
    }
    _log('Disconnected');
  }

  /// Dispose of resources.
  void dispose() {
    _log('Disposing');
    _subscription?.cancel();
    _subscription = null;
    _conversationSubscription?.cancel();
    _conversationSubscription = null;
    _lastOnGoingStatus = null;
    _taskId = null;
    _conversationId = null;
    _lastEventId = null;
    _service?.dispose();
    _service = null;
    _eventController?.close();
    _eventController = null;
    _log('Disposed');
  }

  /// Reset the service for a new conversation.
  /// Call this before connecting to a different conversation.
  void reset() {
    disconnect(resetEventId: true);
    _log('Service reset');
  }
}

/// Singleton instance for global access.
AgentStreamService? _globalAgentStreamService;

/// Get the global agent stream service instance.
AgentStreamService getAgentStreamService() {
  _globalAgentStreamService ??= AgentStreamService(baseUrl: DataConstants.url);
  return _globalAgentStreamService!;
}

/// Dispose the global agent stream service.
void disposeAgentStreamService() {
  _globalAgentStreamService?.dispose();
  _globalAgentStreamService = null;
}

/// Factory for creating per-conversation agent stream services.
///
/// Use this when you need independent streams for multiple conversations.
class AgentStreamServiceFactory {
  final Map<String, AgentStreamService> _instances = {};

  /// Get or create a service for the given conversation ID.
  AgentStreamService getInstance(String conversationId) {
    return _instances.putIfAbsent(
      conversationId,
      () => AgentStreamService(baseUrl: DataConstants.url),
    );
  }

  /// Dispose a specific instance.
  void disposeInstance(String conversationId) {
    _instances[conversationId]?.dispose();
    _instances.remove(conversationId);
  }

  /// Dispose all instances.
  void disposeAll() {
    for (final service in _instances.values) {
      service.dispose();
    }
    _instances.clear();
  }
}
