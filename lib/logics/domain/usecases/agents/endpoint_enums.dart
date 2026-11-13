import 'package:flutter_client/logics/data/helpers/general_utils.dart';
import 'package:flutter_client/logics/domain/entities/agents/agent_execution.dart';
import 'package:flutter_client/logics/domain/entities/agents/scheduled_task.dart';

import '../base.dart';

/// Endpoints for Agent Execution API
///
/// These endpoints handle agent task execution,
/// SSE streaming, and scheduled task management.
enum AgentEndpoints implements Endpoint {
  // Agent Execution Endpoints
  startExecution,
  cancelTask,
  respondToHitl,

  // Scheduled Task Endpoints
  createScheduledTask,
  listScheduledTasks,
  deleteScheduledTask;

  @override
  String get value => "chat/${Toolkit.camelToSnakeCase(toString().split('.').last)}";

  @override
  String get name => "chat";

  @override
  APIReference get requiredParams {
    switch (this) {
      // ==================== AGENT EXECUTION ====================

      case AgentEndpoints.startExecution:
        return APIReference(
          endpoint: '/completions/start',
          method: 'POST',
          parameters: ['message', 'conversation_id'],
          returnType: [Map, AgentExecutionResponse.fromJson],
        );

      case AgentEndpoints.cancelTask:
        return APIReference(
          endpoint: '/completions/cancel/{conversation_id}/',
          method: 'POST',
          parameters: ['conversation_id'],
          returnType: [Map, TaskCancelResponse.fromJson],
        );

      case AgentEndpoints.respondToHitl:
        return APIReference(
          endpoint: '/completions/{conversation_id}/respond',
          method: 'POST',
          parameters: ['conversation_id', 'response'],
          returnType: [bool],
        );

      // ==================== SCHEDULED TASKS ====================

      case AgentEndpoints.createScheduledTask:
        return APIReference(
          endpoint: '/completions/schedule',
          method: 'POST',
          parameters: ['prompt', 'crontab'],
          returnType: [Map, ScheduledTaskResponse.fromJson],
        );

      case AgentEndpoints.listScheduledTasks:
        return APIReference(
          endpoint: '/completions/schedule',
          method: 'GET',
          parameters: [],
          returnType: [List<Map>, ScheduledTaskResponse.fromJson],
        );

      case AgentEndpoints.deleteScheduledTask:
        return APIReference(
          endpoint: '/completions/schedule/{task_id}/',
          method: 'DELETE',
          parameters: ['task_id'],
          returnType: [Map, ScheduledTaskDeleteResponse.fromJson],
        );
    }
  }
}
