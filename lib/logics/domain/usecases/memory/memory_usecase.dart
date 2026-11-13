import 'package:dio/dio.dart';

import '../../../data/global_logics.dart';
import '../../entities/base/repo.dart';
import '../../entities/memory/misc/schemas.dart';
import '../base.dart';
import 'endpoint_enums.dart';

class Memory {
  // ==================== CONVERSATION MANAGEMENT ====================

  static Future<dynamic> startConversation() async {
    return NetworkConnector.callEndpoint(MemoryEndpoints.startConversation, {});
  }

  static Future<dynamic> fetchMessages({
    required BaseRepository repo,
    required String conversationId,
  }) async {
    return NetworkConnector.callPaginatedEndpoints(
      repo,
      MemoryEndpoints.fetchMessages,
      {'conversation_id': conversationId},
    );
  }

  static Future<dynamic> fetchTaskMessages({
    required BaseRepository repo,
    required String taskId,
  }) async {
    return NetworkConnector.callPaginatedEndpoints(
      repo,
      MemoryEndpoints.fetchMessagesByTaskId,
      {'task_id': taskId},
    );
  }

  static Future<dynamic> cancelTask({required String conversationId}) async {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.cancelTask,
      {'conversation_id': conversationId},
    );
  }

  static Future<dynamic> getAllConversations({
    required BaseRepository repo,
  }) async {
    return NetworkConnector.callPaginatedEndpoints(
      repo,
      MemoryEndpoints.getAllConversations,
      {},
    );
  }

  static Future<dynamic> deleteChat({required String conversationId}) async {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.deleteChat,
      {'conversation_id': conversationId},
    );
  }

  static Future<dynamic> deleteAllChats() async {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.deleteAllChats,
      {},
    );
  }

  static Future<dynamic> bulkDeleteConversations({
    required List<String> conversationIds,
  }) async {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.bulkDeleteConversations,
      {'conversation_ids': conversationIds},
    );
  }

  // ==================== ADDON MANAGEMENT ====================

  static Future<dynamic> registerAddon({required String addonId}) async {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.registerAddon,
      {'addon_id': addonId},
    );
  }

  static Future<dynamic> unregisterAddon({required String userAddonId}) async {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.unregisterAddon,
      {'user_addon_id': userAddonId},
    );
  }

  static Future<dynamic> getAddonAuthLink({required String userAddonId}) async {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.getAddonAuthLink,
      {'user_addon_id': userAddonId},
    );
  }

  static Future<dynamic> checkAndUpdateAuthStatus({
    required String userAddonId,
  }) async {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.checkAndUpdateAuthStatus,
      {'user_addon_id': userAddonId},
    );
  }

  static Future<AddonConnectionStatus> getConnectionStatus({
    required String userAddonId,
  }) async {
    return await NetworkConnector.callEndpoint(
      MemoryEndpoints.getConnectionStatus,
      {'user_addon_id': userAddonId},
    ) as AddonConnectionStatus;
  }

  static Future<AddonAuthLink> regenerateAuthLink({
    required String userAddonId,
  }) async {
    return await NetworkConnector.callEndpoint(
      MemoryEndpoints.regenerateAuthLink,
      {'user_addon_id': userAddonId},
    ) as AddonAuthLink;
  }

  static Future<dynamic> getUserAddons({required BaseRepository repo}) async {
    return NetworkConnector.callPaginatedEndpoints(
      repo,
      MemoryEndpoints.getUserAddons,
      {},
    );
  }

  static Future<dynamic> getAllAddons({required BaseRepository repo}) async {
    return NetworkConnector.callPaginatedEndpoints(
      repo,
      MemoryEndpoints.getAllAddons,
      {},
    );
  }

  static Future<dynamic> getExpandedAddon({required String addonId}) async {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.getExpandedAddon,
      {'addon_id': addonId},
    );
  }

  // ==================== SEARCH OPERATIONS ====================

  static Future<dynamic> searchThreads({
    required BaseRepository repo,
    required String query,
  }) async {
    return NetworkConnector.callPaginatedEndpoints(
      repo,
      MemoryEndpoints.searchThreads,
      {'query': query},
    );
  }

  static Future<dynamic> searchUserAddons({
    required BaseRepository repo,
    required String query,
    required bool authComplete,
  }) async {
    return NetworkConnector.callPaginatedEndpoints(
      repo,
      MemoryEndpoints.searchUserAddons,
      {'query': query, 'auth_complete': authComplete},
    );
  }

  static Future<dynamic> searchAllAddons({
    required BaseRepository repo,
    required String query,
  }) async {
    return NetworkConnector.callPaginatedEndpoints(
      repo,
      MemoryEndpoints.searchAllAddons,
      {'query': query},
    );
  }

  // ==================== AGENT STUFF ====================

  static Future<dynamic> getLlmProviders({required BaseRepository repo}) async {
    return NetworkConnector.callPaginatedEndpoints(
      repo,
      MemoryEndpoints.getLlmProviders,
      {},
    );
  }

  static Future<dynamic> registerLlmProvider({
    required String providerName,
    required String llmBaseUrl,
    required String llmApiKey,
    required String llmModelName,
    required String type,
    Map<String, dynamic> extras = const {},
  }) async {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.registerLlmProvider,
      {
        'provider_name': providerName,
        'llm_base_url': llmBaseUrl,
        'llm_api_key': llmApiKey,
        'llm_model_name': llmModelName,
        'type': type,
        'extras': extras,
      },
    );
  }

  static Future<dynamic> unregisterLlmProvider({
    required String providerId,
  }) async {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.unregisterLlmProvider,
      {'provider_id': providerId},
    );
  }

  static Future<dynamic> registerMcpConfig({
    required String serverName,
    required String serverType,
    String? command,
    String? arguments,
    String? env,
    String? description,
    String? url,
    int? timeout,
    int? sseReadTimeout,
    double? clientSessionTimeoutSeconds,
  }) async {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.registerMcpConfig,
      {
        'server_name': serverName,
        'server_type': serverType,
        'command': command ?? "",
        'arguments': arguments ?? "",
        'env': env ?? "",
        'description': description,
        'url': url,
        'timeout': timeout,
        'sse_read_timeout': sseReadTimeout,
        'client_session_timeout_seconds': clientSessionTimeoutSeconds,
      },
    );
  }

  static Future<dynamic> unregisterMcpConfig({required String configId}) async {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.unregisterMcpConfig,
      {'config_id': configId},
    );
  }

  static Future<dynamic> getMcpConfigs({required BaseRepository repo}) async {
    return NetworkConnector.callPaginatedEndpoints(
      repo,
      MemoryEndpoints.getMcpConfigs,
      {},
    );
  }

  static Future<dynamic> getContextConfig() async {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.getContextConfig,
      {},
    );
  }

  static Future<dynamic> updateContextConfig({
    required bool llmBasedCompression,
    required int triggerCompressionLength,
    required bool contextAutoOptimisation,
    required double maxTokenBudgetRatio,
    required String compressionLlmId,
  }) async {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.updateContextConfig,
      {
        'llm_based_compression': llmBasedCompression,
        'trigger_compression_length': triggerCompressionLength,
        'context_auto_optimisation': contextAutoOptimisation,
        'max_token_budget_ratio': maxTokenBudgetRatio,
        'compression_llm_id': compressionLlmId,
      },
    );
  }

  // ==================== FILE AND MISC OPERATIONS ====================

  static Future<dynamic> uploadFile({required MultipartFile file}) async {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.uploadFile,
      {'file': file},
    );
  }

  static Future<dynamic> getFiles({required BaseRepository repo}) async {
    return NetworkConnector.callPaginatedEndpoints(
      repo,
      MemoryEndpoints.files,
      {},
    );
  }

  static Future<dynamic> downloadFile({required String fileId}) async {
    try {
      final response = await NetworkConnector.dio.get(
        'storage/files/$fileId/download',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${DataConstants.getToken()}',
          },
        ),
      );
      if (NetworkConnector.isSuccessful(response.statusCode)) {
        return FileDownloadResponse.fromJson(response.data);
      }
      throw Exception(response.data.toString());
    } catch (e) {
      rethrow;
    }
  }

  static Future<dynamic> getMessage({required String messageId}) async {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.getMessage,
      {'message_id': messageId},
    );
  }

  static Future<dynamic> healthCheck() async {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.health,
      {},
    );
  }

  static Future<dynamic> getCacheStats() async {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.cacheStats,
      {},
    );
  }

  static Future<dynamic> getStats() async {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.stats,
      {},
    );
  }

  static Future<dynamic> updateTypeLlm({
    required String llmType,
    required String providerId,
  }) {
    return NetworkConnector.callEndpoint(
      MemoryEndpoints.updateTypeLlm,
      {'llm_type': llmType, 'provider_id': providerId},
    );
  }
}
