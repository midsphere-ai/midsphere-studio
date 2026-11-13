import '../../../data/helpers/general_utils.dart';
import '../../entities/spaces/schemas.dart';
import '../../entities/spaces/spaces.dart';
import '../base.dart';

enum SpacesEndpoints implements Endpoint {
  createSpace,
  modifySpace,
  deleteSpace,
  getSpaceInfo,
  getAllUserSpaces;

  @override
  String get value => "spaces/${Toolkit.camelToSnakeCase(toString().split('.').last)}";

  @override
  String get name => "spaces/";

  @override
  APIReference get requiredParams {
    switch (this) {
      case SpacesEndpoints.createSpace:
        return APIReference(
          endpoint: '/spaces',
          method: 'POST',
          parameters: ['name', 'description'],
          returnType: [Map, CreateSpaceResult.fromJson],
        );

      case SpacesEndpoints.modifySpace:
        return APIReference(
          endpoint: '/spaces/{space_id}',
          method: 'PUT',
          parameters:  ['space_id', 'name', 'description'],
          returnType: [Map, SpaceUpdationResult.fromJson],
        );

      case SpacesEndpoints.deleteSpace:
        return APIReference(
          endpoint: '/spaces/{space_id}',
          method: 'DELETE',
          parameters:  ['space_id'],
          returnType: [Map, SpaceRemoveResult.fromJson],
        );

      case SpacesEndpoints.getSpaceInfo:
        return APIReference(
          endpoint: '/spaces/{space_id}',
          method: 'GET',
          parameters:  ['space_id'],
          returnType: [Map, Space.fromJson],
        );

      case SpacesEndpoints.getAllUserSpaces:
        return APIReference(
          endpoint: '/spaces',
          method: 'GET',
          parameters:  [],
          returnType: [List<Map>, Space.fromJson],
        );
    }
  }
}
