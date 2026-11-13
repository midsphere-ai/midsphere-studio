import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../entities/agents/agent_execution.dart';
import '../../entities/base/base.dart';
import '../../entities/base/repo.dart';
import '../../entities/memory/conversation/message.dart';
import '../base.dart';
import 'endpoint_enums.dart';

/// Agent Usecase
///
/// Provides methods for agent execution, task management,
/// and scheduled task operations.
class Agent {
  // ==================== AGENT EXECUTION ====================

  /// Start a new agent execution task
  ///
  /// Triggers a new agent task via Orbiter with the provided
  /// message and optional configuration.
  ///
  /// Returns [AgentExecutionResponse] with task_id and conversation_id.
  ///
  /// Throws:
  /// - 429: Server capacity exceeded
  /// - 409: Task already running for this conversation
  static Future<dynamic> startExecution({
    required String conversationId,
    required String message,
    List files = const [],
    List<String> addons = const [],
    List<String> mcp = const [],
    String? model,
    Map<String, dynamic>? customise,
  }) async {
    final dio = NetworkConnector.dio;

    // Build form data - each field as individual form field
    // Lists and dicts are JSON-encoded strings (parsed by Pydantic validators)
    final formMap = <String, dynamic>{
      'conversation_id': conversationId,
      'message': message,
    };

    // File IDs (strings) as JSON array
    final fileIds = files.whereType<String>().toList();
    formMap['files'] = jsonEncode(fileIds);
    formMap['addons'] = jsonEncode(addons);
    formMap['mcp'] = jsonEncode(mcp);

    if (model != null) {
      formMap['model'] = model;
    }
    if (customise != null) {
      formMap['customise'] = jsonEncode(customise);
    }

    // Actual file uploads (MultipartFile objects) go under 'files' key
    final fileUploads = files.whereType<MultipartFile>().toList();

    final formData = FormData.fromMap(formMap);

    // Add file uploads separately to FormData
    if (fileUploads.isNotEmpty) {
      for (var file in fileUploads) {
        formData.files.add(MapEntry('files', file));
      }
    }

    try {

      final response = await dio.post(
        'chat/completions/start',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AgentExecutionResponse.fromJson(response.data);
      }

      // Handle structured error responses
      final statusCode = response.statusCode ?? 500;
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        // 400: Validation error
        // 403: Permission denied for addon/MCP/model
        // 404: Resource not found
        // 409: Task already running for this conversation
        // 429: Rate limit exceeded / no workers available
        if (statusCode == 400 || statusCode == 403 || statusCode == 404 ||
            statusCode == 409 || statusCode == 429) {
          throw ApiException.fromResponse(statusCode, data);
        }
      }

      throw Exception(response.data.toString());
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('[Agent.startExecution] Error: $e');
      rethrow;
    }
  }

  /// Cancel a currently running task
  ///
  /// Returns [TaskCancelResponse] with status and task_id.
  static Future<dynamic> cancelTask({
    required String conversationId,
  }) async {
    return NetworkConnector.callEndpoint(
      AgentEndpoints.cancelTask,
      {'conversation_id': conversationId},
    );
  }

  // ==================== HITL (Human-in-the-Loop) ====================

  /// Respond to a human-in-the-loop prompt
  ///
  /// Sends the user's response to an active HITL request for the given conversation.
  static Future<dynamic> respondToHitl({
    required String conversationId,
    required String response,
  }) async {
    return NetworkConnector.callEndpoint(
      AgentEndpoints.respondToHitl,
      {
        'conversation_id': conversationId,
        'response': response,
      },
    );
  }

  // ==================== MESSAGE PAGINATION ====================

  /// Fetch messages for a conversation from Orbiter.
  ///
  /// Uses the `/chat/completions/conversations/{id}/messages` endpoint
  /// with response format `{messages, total_count, page, page_size}`.
  static Future<BaseRepository> fetchConversationMessages({
    required String conversationId,
    required BaseRepository repo,
  }) async {
    final response = await NetworkConnector.performGet(
      'chat/completions/conversations/$conversationId/messages',
      queryParameters: {
        'page': repo.currentPage.toString(),
        'page_size': repo.pageSize.toString(),
      },
    );

    final data = response.data as Map<String, dynamic>;
    final messages = (data['messages'] as List)
        .map((e) => SukunaMessage.fromJson(e as Map<String, dynamic>))
        .toList();

    repo.items = messages;
    repo.maxCount = data['total_count'] ?? 0;
    repo.totalPages = (repo.maxCount / repo.pageSize).ceil();
    return repo;
  }

  // ==================== SCHEDULED TASKS ====================

  /// Create a new scheduled task
  ///
  /// Schedule an agent prompt to run periodically using cron expression.
  ///
  /// Example crontab values:
  /// - "0 9 * * *" - Daily at 9 AM
  /// - "0 9 * * 1" - Every Monday at 9 AM
  /// - "0 0 1 * *" - First day of every month at midnight
  static Future<dynamic> createScheduledTask({
    required String prompt,
    required String crontab,
  }) async {
    return NetworkConnector.callEndpoint(
      AgentEndpoints.createScheduledTask,
      {
        'prompt': prompt,
        'crontab': crontab,
      },
    );
  }

  /// List all scheduled tasks for the authenticated user
  ///
  /// Supports pagination via [repo] parameter.
  static Future<dynamic> listScheduledTasks({
    required BaseRepository repo,
  }) async {
    return NetworkConnector.callPaginatedEndpoints(
      repo,
      AgentEndpoints.listScheduledTasks,
      {},
    );
  }

  /// Delete a scheduled task
  ///
  /// Returns [ScheduledTaskDeleteResponse] with deletion confirmation.
  static Future<dynamic> deleteScheduledTask({
    required String taskId,
  }) async {
    return NetworkConnector.callEndpoint(
      AgentEndpoints.deleteScheduledTask,
      {'task_id': taskId},
    );
  }
}
