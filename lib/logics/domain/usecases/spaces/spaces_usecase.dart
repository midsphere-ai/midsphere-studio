import 'package:flutter_client/logics/domain/entities/base/repo.dart';
import '../base.dart';
import 'endpoint_enums.dart';

class Spaces {
  // ==================== SPACE MANAGEMENT ====================

  static Future<dynamic> createSpace({
    required String name,
    required String description,
  }) async {
    return NetworkConnector.callEndpoint(
        SpacesEndpoints.createSpace,
        {
          'name': name,
          'description': description,
        });
  }

  static Future<dynamic> modifySpace({
    required String spaceId,
    required String name,
    required String description,
  }) async {
    return NetworkConnector.callEndpoint(
        SpacesEndpoints.modifySpace,
        {
          'space_id': spaceId,
          'name': name,
          'description': description,
        });
  }

  static Future<dynamic> deleteSpace({required String spaceId}) async {
    return NetworkConnector.callEndpoint(
        SpacesEndpoints.deleteSpace,
        {
          'space_id': spaceId,
        });
  }

  static Future<dynamic> getSpaceInfo({required String spaceId}) async {
    return NetworkConnector.callEndpoint(
        SpacesEndpoints.getSpaceInfo,
        {
          'space_id': spaceId,
        });
  }

  static Future<dynamic> getAllUserSpaces({required BaseRepository repo}) async {
    return NetworkConnector.callPaginatedEndpoints(
        repo, SpacesEndpoints.getAllUserSpaces, {});
  }
}
