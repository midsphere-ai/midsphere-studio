import 'package:uuid/uuid.dart';
import '../base/base.dart';

class UserModelProvider extends BaseModel {
  final int userId;
  final String providerName;
  final String? llmBaseUrl;
  final String? llmApiKey;
  final String? llmModelName;
  final DateTime dateUpdated;

  UserModelProvider({
    String? id,
    required this.userId,
    required this.providerName,
    this.llmBaseUrl,
    this.llmApiKey,
    this.llmModelName,
    DateTime? dateCreated,
    required this.dateUpdated,
  }) {
    if (id != null) this.id = id;
    if (dateCreated != null) this.dateCreated = dateCreated;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'provider_name': providerName,
      'llm_base_url': llmBaseUrl,
      'llm_api_key': llmApiKey,
      'llm_model_name': llmModelName,
      'date_created': dateTimeToJson(dateCreated),
      'date_updated': dateTimeToJson(dateUpdated),
    };
  }

  static UserModelProvider fromJson(Map<String, dynamic> json) {
    return UserModelProvider(
      id: json['id']?.toString(),
      userId: json['user'] ?? 1,
      providerName: json['provider_name'],
      llmBaseUrl: json['llm_base_url'],
      llmApiKey: json['llm_api_key'],
      llmModelName: json['llm_model_name'],
      dateCreated: json['date_created'] != null
          ? DateTime.parse(json['date_created'])
          : null,
      dateUpdated: DateTime.parse(json['date_updated']),
    );
  }

  String getProviderDisplayName() => "$userId's $providerName Provider";
}

class ProviderChoices {
  static const String gemini = 'gemini';
  static const String anthropic = 'anthropic';
  static const String openai = 'openai';
  static const String openrouter = 'openrouter';
}

class UserCustomMCPConfig extends BaseModel {
  final int userId;
  final String serverName;
  final String type; // stdio, sse, streamable-http
  final String? command;
  final String? arguments;
  final String? env;
  final String? description;
  final String? url;
  final int? timeout;
  final int? sseReadTimeout;
  final double? clientSessionTimeoutSeconds;
  final DateTime dateUpdated;

  UserCustomMCPConfig({
    String? id,
    required this.userId,
    required this.serverName,
    this.type = 'stdio',
    this.command,
    this.arguments,
    this.env,
    this.description,
    this.url,
    this.timeout,
    this.sseReadTimeout,
    this.clientSessionTimeoutSeconds,
    DateTime? dateCreated,
    required this.dateUpdated,
  }) {
    this.id = id ?? const Uuid().v4();
    if (dateCreated != null) this.dateCreated = dateCreated;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'server_name': serverName,
      'server_type': type,
      'command': command,
      'arguments': arguments,
      'env': env,
      'description': description,
      'url': url,
      'timeout': timeout,
      'sse_read_timeout': sseReadTimeout,
      'client_session_timeout_seconds': clientSessionTimeoutSeconds,
      'date_created': dateTimeToJson(dateCreated),
      'date_updated': dateTimeToJson(dateUpdated),
    };
  }

  static UserCustomMCPConfig fromJson(Map<String, dynamic> json) {
    return UserCustomMCPConfig(
      id: json['id'],
      userId: json['user'],
      serverName: json['server_name'],
      type: json['server_type'] ?? 'stdio',
      command: json['command'],
      arguments: json['arguments'],
      env: json['env'],
      description: json['description'],
      url: json['url'],
      timeout: json['timeout'],
      sseReadTimeout: json['sse_read_timeout'],
      clientSessionTimeoutSeconds:
          (json['client_session_timeout_seconds'] as num?)?.toDouble(),
      dateCreated: json['date_created'] != null
          ? DateTime.parse(json['date_created'])
          : null,
      dateUpdated: DateTime.parse(json['date_updated']),
    );
  }

  String getDisplayName() => "$userId's $serverName MCP Config";
}

class UserContextConfig extends BaseModel {
  final int userId;
  final bool llmBasedCompression;
  final int triggerCompressionLength;
  final bool contextAutoOptimisation;
  final double maxTokenBudgetRatio;
  final int? compressionLlmId;
  final DateTime dateUpdated;

  UserContextConfig({
    String? id,
    required this.userId,
    this.llmBasedCompression = true,
    this.triggerCompressionLength = 156000,
    this.contextAutoOptimisation = true,
    this.maxTokenBudgetRatio = 0.9,
    this.compressionLlmId,
    DateTime? dateCreated,
    required this.dateUpdated,
  }) {
    this.id = id ?? const Uuid().v4();
    if (dateCreated != null) this.dateCreated = dateCreated;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'llm_based_compression': llmBasedCompression,
      'trigger_compression_length': triggerCompressionLength,
      'context_auto_optimisation': contextAutoOptimisation,
      'max_token_budget_ratio': maxTokenBudgetRatio,
      'compression_llm': compressionLlmId,
      'date_created': dateTimeToJson(dateCreated),
      'date_updated': dateTimeToJson(dateUpdated),
    };
  }

  static UserContextConfig fromJson(Map<String, dynamic> json) {
    return UserContextConfig(
      id: json['id'],
      userId: json['user'],
      llmBasedCompression: json['llm_based_compression'] ?? true,
      triggerCompressionLength: json['trigger_compression_length'] ?? 156000,
      contextAutoOptimisation: json['context_auto_optimisation'] ?? true,
      maxTokenBudgetRatio: (json['max_token_budget_ratio'] ?? 0.9).toDouble(),
      compressionLlmId: json['compression_llm'],
      dateCreated: json['date_created'] != null
          ? DateTime.parse(json['date_created'])
          : null,
      dateUpdated: DateTime.parse(json['date_updated']),
    );
  }

  String getDisplayName() => "$userId's Context Configuration";
}
