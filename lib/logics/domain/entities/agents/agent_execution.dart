import '../base/base.dart';

/// Request body for starting agent execution
class AgentExecutionRequest {
  final String message;
  final List<String> files;
  final List<String> addons;
  final List<String> mcp;
  final String? model;
  final Map<String, dynamic>? customise;

  AgentExecutionRequest({
    required this.message,
    this.files = const [],
    this.addons = const [],
    this.mcp = const [],
    this.model,
    this.customise,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'message': message,
    };
    if (files.isNotEmpty) json['files'] = files;
    if (addons.isNotEmpty) json['addons'] = addons;
    if (mcp.isNotEmpty) json['mcp'] = mcp;
    if (model != null) json['model'] = model;
    if (customise != null) json['customise'] = customise;
    return json;
  }
}

/// Response from starting agent execution (Orbiter returns {task_id, conversation_id})
class AgentExecutionResponse extends BaseModel {
  final String taskId;
  final String conversationId;

  AgentExecutionResponse({
    required this.taskId,
    required this.conversationId,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'conversation_id': conversationId,
    };
  }

  factory AgentExecutionResponse.fromJson(Map<String, dynamic> json) {
    final taskId = json['task_id'];
    if (taskId == null) {
      throw FormatException('Missing required field: task_id');
    }
    return AgentExecutionResponse(
      taskId: taskId.toString(),
      conversationId: json['conversation_id']?.toString() ?? '',
    );
  }
}

/// Response for task cancellation (Orbiter returns {cancelled: true, message: "..."})
class TaskCancelResponse extends BaseModel {
  final bool cancelled;
  final String? message;

  TaskCancelResponse({
    required this.cancelled,
    this.message,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'cancelled': cancelled,
      'message': message,
    };
  }

  factory TaskCancelResponse.fromJson(Map<String, dynamic> json) {
    return TaskCancelResponse(
      cancelled: json['cancelled'] ?? false,
      message: json['message'],
    );
  }
}

/// Error response for capacity exceeded (429)
class CapacityExceededResponse {
  final String error;
  final String status;
  final int retryAfter;

  CapacityExceededResponse({
    required this.error,
    required this.status,
    required this.retryAfter,
  });

  factory CapacityExceededResponse.fromJson(Map<String, dynamic> json) {
    return CapacityExceededResponse(
      error: json['error'],
      status: json['status'],
      retryAfter: json['retry_after'] ?? 30,
    );
  }
}

/// Error response for duplicate task (409)
class DuplicateTaskResponse {
  final String error;
  final String status;

  DuplicateTaskResponse({
    required this.error,
    required this.status,
  });

  factory DuplicateTaskResponse.fromJson(Map<String, dynamic> json) {
    return DuplicateTaskResponse(
      error: json['error'],
      status: json['status'],
    );
  }
}
