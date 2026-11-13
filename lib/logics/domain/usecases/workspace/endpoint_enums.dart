import '../../../data/helpers/general_utils.dart';
import '../../entities/workspace/users/user.dart';
import '../base.dart';

enum WorkspaceEndpoints implements Endpoint {
  createUser,
  removeUser,
  getLoggedInUser,
  updateUser;

  @override
  String get value => "workspace/${Toolkit.camelToSnakeCase(toString().split('.').last)}";

  @override
  String get name => "workspace";

  @override
  APIReference get requiredParams {
    switch (this) {
      case WorkspaceEndpoints.createUser:
        return APIReference(
          endpoint: "/users",
          method: "POST",
          parameters: ['user_name', 'user_email', 'password'],
          returnType: [bool]
        );

      case WorkspaceEndpoints.removeUser:
        return APIReference(
            endpoint: "/users",
            method: "DELETE",
            parameters: ['user_id'],
            returnType: [bool]
        );
      case WorkspaceEndpoints.getLoggedInUser:
        return APIReference(
            endpoint: "/users/me/",
            method: "GET",
            parameters: [],
            returnType: [Map, User.fromJson]
        );
      case WorkspaceEndpoints.updateUser:
        return APIReference(
            endpoint: "/users",
            method: "PATCH",
            parameters: ['user_name', 'user_email', 'user_id'],
            returnType: [bool]
        );
    }
  }
}
