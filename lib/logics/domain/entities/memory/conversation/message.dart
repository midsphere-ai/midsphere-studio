// ignore_for_file: overridden_fields, prefer_typing_uninitialized_variables

import '../../base/base.dart';
import 'base.dart';

class SukunaMessage extends BaseModel {
  @override
  final String id;
  final String message;
  final Conversation conversation;
  final String messageType;
  final Map<String, dynamic>? kwargs;
  final Map<String, dynamic>? metadata;
  /// Whether the message content was truncated (cut at 1000 chars by backend).
  /// When true, the full content should be fetched separately if needed.
  final bool contentTruncated;

  @override
  final DateTime dateCreated;

  SukunaMessage({
    required this.id,
    required this.message,
    required this.conversation,
    required this.messageType,
    required this.kwargs,
    required this.metadata,
    required this.dateCreated,
    this.contentTruncated = false,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'conversation': conversation,
      'messageType': messageType,
      'kwargs': kwargs,
      'metadata': metadata,
      'dateCreated': dateCreated.toIso8601String(),
      'content_truncated': contentTruncated,
    };
  }

  @override
  factory SukunaMessage.fromJson(Map<String, dynamic> json) {
    // Handle conversation field - can be a full object, just an ID string, or null
    Conversation conversation;
    final convData = json['conversation'];
    if (convData is Map<String, dynamic>) {
      conversation = Conversation.fromJson(convData);
    } else {
      // Create a minimal conversation object if only ID is provided or null
      final convId = convData?.toString() ?? json['conversation_id']?.toString() ?? '';
      conversation = Conversation(
        id: convId,
        title: null,
        summary: null,
        user: 0,
        space: null,
        onGoing: false,
        hasCompleted: false,
        hasError: false,
        requiresUserInput: false,
        cancellationRequested: false,
        dateCreated: DateTime.now(),
      );
    }

    // Build kwargs: use existing kwargs, or synthesize from tool_calls if present
    Map<String, dynamic> kwargs;
    if (json['kwargs'] != null) {
      kwargs = Map<String, dynamic>.from(json['kwargs']);
    } else if (json['tool_calls'] != null) {
      kwargs = {'tool_calls': json['tool_calls']};
    } else {
      kwargs = {};
    }

    return SukunaMessage(
      id: json['id']?.toString() ?? '',
      message: json['message']?.toString() ?? json['content']?.toString() ?? '',
      conversation: conversation,
      messageType: json['type']?.toString() ?? 'unknown',
      kwargs: kwargs,
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : {},
      dateCreated: DateTime.tryParse(
        json['date_created']?.toString() ?? json['created_at']?.toString() ?? '',
      ) ?? DateTime.now(),
      contentTruncated: json['content_truncated'] == true,
    );
  }

  /// Parse from SSE stream format (different field names than REST API).
  /// Orbiter wraps payloads as `{type: "...", data: {...}}`.
  /// REST API sends: message, date_created
  factory SukunaMessage.fromSSE(Map<String, dynamic> json) {
    // Orbiter nests payload under 'data' key
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    final type = json['type']?.toString() ?? 'unknown';

    // Extract message text based on event type
    String messageContent;
    if (type == 'message_output') {
      messageContent = data['response']?.toString() ?? json['content']?.toString() ?? '';
    } else if (type == 'reasoning') {
      messageContent = data['text']?.toString() ?? '';
    } else if (type == 'error') {
      messageContent = data['error']?.toString() ?? '';
    } else if (type == 'status') {
      messageContent = data['message']?.toString() ?? '';
    } else {
      messageContent = json['content']?.toString() ?? '';  // fallback for old format
    }

    // Put entire data dict into kwargs for UI renderers
    final kwargs = Map<String, dynamic>.from(data);

    // Build metadata, propagate agent_name
    final metadata = json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : <String, dynamic>{};
    if (data['agent_name'] != null) {
      metadata['agent_name'] = data['agent_name'];
    }

    // Handle conversation field - can be a full object, just an ID string, or null
    Conversation conversation;
    final convData = json['conversation'] ?? data['conversation'];
    if (convData is Map<String, dynamic>) {
      conversation = Conversation.fromJson(convData);
    } else {
      // Create a minimal conversation object if only ID is provided or null
      final convId = convData?.toString() ?? json['conversation_id']?.toString() ?? data['conversation_id']?.toString() ?? '';
      conversation = Conversation(
        id: convId,
        title: null,
        summary: null,
        user: 0,
        space: null,
        onGoing: false,
        hasCompleted: false,
        hasError: false,
        requiresUserInput: false,
        cancellationRequested: false,
        dateCreated: DateTime.now(),
      );
    }

    return SukunaMessage(
      id: json['id']?.toString() ?? '',
      message: messageContent,
      conversation: conversation,
      messageType: type,
      kwargs: kwargs,
      metadata: metadata,
      dateCreated: DateTime.tryParse(
        json['created_at']?.toString() ?? data['created_at']?.toString() ?? '',
      ) ?? DateTime.now(),
      contentTruncated: json['content_truncated'] == true,
    );
  }
}
