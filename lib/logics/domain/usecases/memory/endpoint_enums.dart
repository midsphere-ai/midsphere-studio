import 'package:flutter_client/logics/data/helpers/general_utils.dart';
import 'package:flutter_client/logics/domain/entities/memory/marketplace/base.dart';
import 'package:flutter_client/logics/domain/entities/memory/marketplace/user.dart';
import 'package:flutter_client/logics/domain/entities/memory/misc/file.dart';
import 'package:flutter_client/logics/domain/entities/memory/misc/schemas.dart';

import '../../entities/agents/settings.dart';
import '../../entities/memory/conversation/base.dart';
import '../../entities/memory/conversation/message.dart';
import '../base.dart';

enum MemoryEndpoints implements Endpoint {
  startConversation,
  fetchMessages,
  fetchMessagesByTaskId,
  getAllConversations,
  deleteChat,
  deleteAllChats,
  bulkDeleteConversations,
  //Addons
  registerAddon,
  unregisterAddon,
  getAddonAuthLink,
  checkAndUpdateAuthStatus,
  getConnectionStatus,
  regenerateAuthLink,
  getUserAddons,
  getAllAddons,
  getExpandedAddon,
  //Search
  searchThreads,
  searchUserAddons,
  searchAllAddons,
  //Agent stuff
  getLlmProviders,
  registerLlmProvider,
  unregisterLlmProvider,
  registerMcpConfig,
  unregisterMcpConfig,
  getMcpConfigs,
  getContextConfig,
  updateContextConfig,
  updateTypeLlm,
  //Misc
  uploadFile,
  files,
  getMessage,
  health,
  cancelTask,
  cacheStats,
  stats;

  @override
  String get value => "memory/${Toolkit.camelToSnakeCase(toString().split('.').last)}";

  @override
  String get name => "memory";

  @override
  APIReference get requiredParams {
    switch (this) {
      // Conversation Management
      case MemoryEndpoints.startConversation:
        return APIReference(
          endpoint: '/conversations',
          method: 'POST',
          parameters: [],
          returnType: [Map, ConversationCreateResponse.fromJson],
        );

      case MemoryEndpoints.fetchMessages:
        return APIReference(
          endpoint: '/conversations/{conversation_id}/messages',
          method: 'GET',
          parameters: ['conversation_id'],
          returnType: [List<Map>, SukunaMessage.fromJson],
        );

      case MemoryEndpoints.fetchMessagesByTaskId:
        return APIReference(
          endpoint: '/tasks/{task_id}/messages',
          method: 'GET',
          parameters: ['task_id'],
          returnType: [List<Map>, SukunaMessage.fromJson],
        );

      case MemoryEndpoints.getAllConversations:
        return APIReference(
          endpoint: '/conversations',
          method: 'GET',
          parameters: [],
          returnType: [List<Map>, Conversation.fromJson],
        );

      case MemoryEndpoints.deleteChat:
        return APIReference(
          endpoint: '/conversations/{conversation_id}',
          method: 'DELETE',
          parameters: ['conversation_id'],
          returnType: [Map, DeleteResponse.fromJson],
        );

      case MemoryEndpoints.deleteAllChats:
        return APIReference(
          endpoint: '/conversations',
          method: 'DELETE',
          parameters: [],
          returnType: [Map, DeleteResponse.fromJson],
        );

      case MemoryEndpoints.bulkDeleteConversations:
        return APIReference(
          endpoint: '/conversations/bulk-delete',
          method: 'POST',
          parameters: ['conversation_ids'],
          returnType: [Map, DeleteResponse.fromJson],
        );

      // Addon Management
      case MemoryEndpoints.registerAddon:
        return APIReference(
          endpoint: '/addons/register',
          method: 'POST',
          parameters: ['addon_id'],
          returnType: [Map, RegisterAddonResult.fromJson],
        );

      case MemoryEndpoints.unregisterAddon:
        return APIReference(
          endpoint: '/user-addons/{user_addon_id}',
          method: 'DELETE',
          parameters: ['user_addon_id'],
          returnType: [Map, UnRegisterAddonResult.fromJson],
        );

      case MemoryEndpoints.getAddonAuthLink:
        return APIReference(
          endpoint: '/user-addons/{user_addon_id}/auth-link',
          method: 'GET',
          parameters: ['user_addon_id'],
          returnType: [Map, AddonAuthLink.fromJson],
        );

      case MemoryEndpoints.checkAndUpdateAuthStatus:
        return APIReference(
          endpoint: '/user-addons/{user_addon_id}/refresh-auth',
          method: 'POST',
          parameters: ['user_addon_id'],
          returnType: [Map, AddonAuthenticationStatus.fromJson],
        );

      case MemoryEndpoints.getConnectionStatus:
        return APIReference(
          endpoint: '/user-addons/{user_addon_id}/connection-status',
          method: 'GET',
          parameters: ['user_addon_id'],
          returnType: [Map, AddonConnectionStatus.fromJson],
        );

      case MemoryEndpoints.regenerateAuthLink:
        return APIReference(
          endpoint: '/user-addons/{user_addon_id}/regenerate-auth-link',
          method: 'POST',
          parameters: ['user_addon_id'],
          returnType: [Map, AddonAuthLink.fromJson],
        );

      case MemoryEndpoints.getUserAddons:
        return APIReference(
          endpoint: '/user-addons',
          method: 'GET',
          parameters: [],
          returnType: [List<Map>, UserMarketplaceAddons.fromJson],
        );

      case MemoryEndpoints.getAllAddons:
        return APIReference(
          endpoint: '/addons',
          method: 'GET',
          parameters: [],
          returnType: [List<Map>, MarketplaceAddon.fromJson],
        );

      case MemoryEndpoints.getExpandedAddon:
        return APIReference(
          endpoint: '/addons/{addon_id}',
          method: 'GET',
          parameters: ['addon_id'],
          returnType: [Map, ExpandedAddon.fromJson],
        );

      // Search Operations
      case MemoryEndpoints.searchThreads:
        return APIReference(
          endpoint: '/conversations/search',
          method: 'GET',
          parameters: ['query'],
          returnType: [List<Map>, Conversation.fromJson],
        );

      case MemoryEndpoints.searchUserAddons:
        return APIReference(
          endpoint: '/user-addons/search',
          method: 'GET',
          parameters: ['query', 'auth_complete'],
          returnType: [List<Map>, UserMarketplaceAddons.fromJson],
        );

      case MemoryEndpoints.searchAllAddons:
        return APIReference(
          endpoint: '/addons/search',
          method: 'GET',
          parameters: ['query'],
          returnType: [List<Map>, MarketplaceAddon.fromJson],
        );

      // Agent stuff
      case MemoryEndpoints.getLlmProviders:
        return APIReference(
          endpoint: '/llm-providers',
          method: 'GET',
          parameters: [],
          returnType: [List<Map>, UserModelProvider.fromJson],
        );

      case MemoryEndpoints.registerLlmProvider:
        return APIReference(
          endpoint: '/llm-providers',
          method: 'POST',
          parameters: [
            'provider_name',
            'llm_base_url',
            'llm_api_key',
            'llm_model_name',
            'type',
            'extras',
          ],
          returnType: [Map, (Map<String, dynamic> json) => json],
        );

      case MemoryEndpoints.unregisterLlmProvider:
        return APIReference(
          endpoint: '/llm-providers/{provider_id}',
          method: 'DELETE',
          parameters: ['provider_id'],
          returnType: [Map, (Map<String, dynamic> json) => json],
        );

      case MemoryEndpoints.registerMcpConfig:
        return APIReference(
          endpoint: '/mcp-configs',
          method: 'POST',
          parameters: [
            'server_name',
            'command',
            'arguments',
            'env',
            'description',
          ],
          returnType: [Map, (Map<String, dynamic> json) => json],
        );

      case MemoryEndpoints.unregisterMcpConfig:
        return APIReference(
          endpoint: '/mcp-configs/{config_id}',
          method: 'DELETE',
          parameters: ['config_id'],
          returnType: [Map, (Map<String, dynamic> json) => json],
        );

      case MemoryEndpoints.getMcpConfigs:
        return APIReference(
          endpoint: '/mcp-configs',
          method: 'GET',
          parameters: [],
          returnType: [List<Map>, UserCustomMCPConfig.fromJson],
        );

      case MemoryEndpoints.getContextConfig:
        return APIReference(
          endpoint: '/context-config',
          method: 'GET',
          parameters: [],
          returnType: [Map, UserContextConfig.fromJson],
        );

      case MemoryEndpoints.updateContextConfig:
        return APIReference(
          endpoint: '/context-config',
          method: 'PUT',
          parameters: [
            'llm_based_compression',
            'trigger_compression_length',
            'context_auto_optimisation',
            'max_token_budget_ratio',
            'compression_llm_id',
          ],
          returnType: [Map, (Map<String, dynamic> json) => json],
        );

      case MemoryEndpoints.updateTypeLlm:
        return APIReference(
          endpoint: '/llm-type',
          method: 'PUT',
          parameters: ['llm_type', 'provider_id'],
          returnType: [Map, (Map<String, dynamic> json) => json],
        );

      // File and Misc Operations
      case MemoryEndpoints.uploadFile:
        return APIReference(
          endpoint: '/files',
          method: 'POST',
          parameters: ['file'],
          returnType: [Map, FileUploadResponse.fromJson],
        );

      case MemoryEndpoints.files:
        return APIReference(
          endpoint: '/files',
          method: 'GET',
          parameters: [],
          returnType: [List<Map>, StoredFile.fromJson],
        );

      case MemoryEndpoints.getMessage:
        return APIReference(
          endpoint: '/messages/{message_id}',
          method: 'GET',
          parameters: ['message_id'],
          returnType: [Map, SukunaMessage.fromJson],
        );

      case MemoryEndpoints.cancelTask:
        return APIReference(
          endpoint: '/conversations/{conversation_id}/cancel',
          method: 'POST',
          parameters: ['conversation_id'],
          returnType: [Map, Conversation.fromJson],
        );

      case MemoryEndpoints.health:
        return APIReference(
          endpoint: '/health',
          method: 'GET',
          parameters: [],
          returnType: [Map, HealthResponse.fromJson],
        );

      case MemoryEndpoints.cacheStats:
        return APIReference(
          endpoint: '/stats/cache',
          method: 'GET',
          parameters: [],
          returnType: [Map, (Map<String, dynamic> json) => json],
        );

      case MemoryEndpoints.stats:
        return APIReference(
          endpoint: '/stats/user',
          method: 'GET',
          parameters: [],
          returnType: [Map, (Map<String, dynamic> json) => json],
        );

    }
  }
}
