import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_client/logics/data/global_logics.dart';
import 'package:flutter_client/logics/domain/entities/agents/agent_execution.dart';
import 'package:flutter_client/logics/domain/entities/base/base.dart';
import 'package:flutter_client/logics/domain/entities/base/repo.dart';
import 'package:flutter_client/logics/services/agent_stream_service.dart';

import '../../logics/domain/usecases/agents/agent_usecase.dart';
import '../../logics/domain/usecases/memory/memory_usecase.dart';

/// User identifiers for chat messages.
class ChatUsers {
  static const user = User(id: 'user', name: 'You');
  static const agent = User(id: 'agent', name: 'Midsphere AI');
}

/// Callback types for chat events.
typedef OnMessageCallback = void Function(AgentStreamEvent event);
typedef OnCompleteCallback = void Function();
typedef OnErrorCallback = void Function(String error);
/// Called when the conversation's busy (onGoing) status changes.
typedef OnStatusChangedCallback = void Function(bool isOnGoing);

/// Clean, SSE-only chat manager for agent conversations.
///
/// Handles:
/// - Conversation creation/management
/// - SSE streaming for real-time updates
/// - Message pagination
/// - Message sending via Agent API
class ChatManager {
  /// Current conversation ID.
  String? conversationId;

  /// Current task ID (from POST /completions/start response).
  String? taskId;

  /// Repository for paginated message fetching.
  BaseRepository messagesRepo = BaseRepository();

  /// Whether pagination has reached the end.
  bool hasReachedEnd = false;

  // SSE service and subscription
  AgentStreamService? _sseService;
  StreamSubscription<AgentStreamEvent>? _sseSubscription;

  // Callbacks
  OnMessageCallback? _onMessage;
  OnCompleteCallback? _onComplete;
  OnErrorCallback? _onError;
  OnStatusChangedCallback? _onStatusChanged;

  /// Whether SSE is currently connected.
  bool get isConnected => _sseService?.isConnected ?? false;

  /// Current conversation ID getter.
  String? get threadId => conversationId;

  // ─────────────────────────────────────────────────────────────────────────
  // Conversation Management
  // ─────────────────────────────────────────────────────────────────────────

  /// Create a new conversation if needed.
  Future<String> ensureConversation() async {
    if (conversationId != null) return conversationId!;

    const maxRetries = 5;
    for (var i = 0; i < maxRetries; i++) {
      try {
        final response = await Memory.startConversation();
        if (response.conversationId != null) {
          conversationId = response.conversationId;
          return conversationId!;
        }
      } catch (e) {
        debugPrint('[ChatManager] ensureConversation: Error on attempt ${i + 1}: $e');
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    throw Exception('Failed to create conversation after $maxRetries attempts');
  }

  /// Set conversation ID for an existing conversation.
  void setConversation(String id) {
    conversationId = id;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SSE Connection
  // ─────────────────────────────────────────────────────────────────────────

  /// Connect to SSE stream for real-time agent updates.
  ///
  /// [onMessage] - Called when a message event is received.
  /// [onComplete] - Called when the agent completes.
  /// [onError] - Called when an error occurs.
  /// [onStatusChanged] - Called when the conversation's onGoing status changes.
  Future<void> connectSSE({
    required OnMessageCallback onMessage,
    required OnCompleteCallback onComplete,
    required OnErrorCallback onError,
    OnStatusChangedCallback? onStatusChanged,
  }) async {
    if (taskId == null) {
      onError('No task ID available for SSE connection');
      return;
    }

    final token = DataConstants.getToken();
    if (token == null) {
      onError('Not authenticated');
      return;
    }

    // Store callbacks
    _onMessage = onMessage;
    _onComplete = onComplete;
    _onError = onError;
    _onStatusChanged = onStatusChanged;

    // Clean up existing connection
    await _disconnect();

    // Create and connect new service
    _sseService = AgentStreamService(baseUrl: DataConstants.url);

    _sseSubscription = _sseService!.eventStream.listen(
      _handleEvent,
      onError: (e) => _onError?.call(e.toString()),
    );

    await _sseService!.connect(
      authToken: token,
      taskId: taskId!,
      conversationId: conversationId,
    );
  }

  void _handleEvent(AgentStreamEvent event) {
    switch (event.eventType) {
      case AgentStreamEventType.message:
        _onMessage?.call(event);
        break;
      case AgentStreamEventType.complete:
        _onComplete?.call();
        break;
      case AgentStreamEventType.error:
        _onError?.call(event.error ?? 'Unknown error');
        break;
      case AgentStreamEventType.statusChanged:
        if (event.isOnGoing != null) {
          _onStatusChanged?.call(event.isOnGoing!);
        }
        break;
    }
  }

  Future<void> _disconnect() async {
    await _sseSubscription?.cancel();
    _sseSubscription = null;
    _sseService?.dispose();
    _sseService = null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Message Sending
  // ─────────────────────────────────────────────────────────────────────────

  /// Send a message to the agent.
  ///
  /// Creates a conversation if needed, connects SSE, and sends the message.
  Future<void> sendMessage({
    required String message,
    required OnMessageCallback onMessage,
    required OnCompleteCallback onComplete,
    required OnErrorCallback onError,
    List<String> files = const [],
    List<String> addons = const [],
    List<String> mcp = const [],
    String? model,
    Map<String, dynamic>? customise,
  }) async {
    try {
      // Ensure we have a conversation
      await ensureConversation();
      // Send message via Agent API
      final result = await Agent.startExecution(
        conversationId: conversationId!,
        message: message,
        files: files,
        addons: addons,
        mcp: mcp,
        model: model,
        customise: customise,
      );

      // Extract taskId from Orbiter response
      if (result is AgentExecutionResponse) {
        taskId = result.taskId;
      }

      // Connect SSE for streaming responses
      await connectSSE(
        onMessage: onMessage,
        onComplete: onComplete,
        onError: onError,
      );
    } on ApiException catch (e, s) {
      debugPrint('[ChatManager] sendMessage: API ERROR: $e');
      debugPrint('$s');
      // Provide user-friendly error message based on error type
      if (e.isLimitExceeded) {
        onError(e.message); // e.g., "Task limit exceeded for this week"
      } else if (e.isConflict) {
        onError(e.message); // e.g., "Task already running for this conversation"
      } else if (e.isPermissionError) {
        onError(e.message); // e.g., "You do not have permission to use addon abc123"
      } else if (e.isNotFoundError) {
        onError(e.message); // e.g., "Addon abc123 not found"
      } else if (e.isServiceUnavailable || e.isNoWorkers) {
        final retryMsg = e.retryAfter != null
            ? ' Please try again in ${e.retryAfter} seconds.'
            : ' Please try again later.';
        final prefix = e.isNoWorkers ? 'No workers available.' : e.message;
        onError('$prefix$retryMsg');
      } else {
        onError(e.message);
      }
    } catch (e, s) {
      debugPrint('[ChatManager] sendMessage: ERROR: $e');
      debugPrint('$s');
      onError(e.toString());
    }
  }

  /// Respond to a human-in-the-loop prompt.
  Future<bool> respondToHitl(String response) async {
    if (conversationId == null) return false;

    try {
      await Agent.respondToHitl(
        conversationId: conversationId!,
        response: response,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Cancel the current task.
  Future<bool> cancelTask() async {
    if (conversationId == null) return false;

    try {
      final cancellationConversation = await Memory.cancelTask(
        conversationId: conversationId!,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Message Loading & Pagination
  // ─────────────────────────────────────────────────────────────────────────

  /// Load initial messages for the conversation.
  Future<BaseRepository> loadMessages({int pageSize = 200}) async {
    if (conversationId == null) throw Exception('No conversation ID');

    messagesRepo = BaseRepository();
    messagesRepo.pageSize = pageSize;

    return await Agent.fetchConversationMessages(
      conversationId: conversationId!,
      repo: messagesRepo,
    );
  }

  /// Load more (older) messages for pagination.
  ///
  /// Returns null if no more pages available.
  Future<BaseRepository?> loadMoreMessages() async {
    if (conversationId == null || hasReachedEnd) return null;

    if (messagesRepo.currentPage >= messagesRepo.totalPages) {
      hasReachedEnd = true;
      return null;
    }

    messagesRepo.currentPage += 1;

    return await Agent.fetchConversationMessages(
      conversationId: conversationId!,
      repo: messagesRepo,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cleanup
  // ─────────────────────────────────────────────────────────────────────────

  /// Reset the manager for a new conversation.
  Future<void> reset() async {
    await _disconnect();
    conversationId = null;
    taskId = null;
    messagesRepo = BaseRepository();
    hasReachedEnd = false;
  }

  /// Dispose all resources.
  Future<void> dispose() async {
    await _disconnect();
  }
}
