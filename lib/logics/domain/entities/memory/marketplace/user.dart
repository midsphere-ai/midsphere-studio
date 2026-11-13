import '../../base/base.dart';
import 'base.dart';

class UserMarketplaceAddons extends BaseModel {
  @override
  final String id;
  final MarketplaceAddon enabledAddon; // MarketplaceAddon ID
  final int owner; // User ID
  final bool authComplete;
  final String? authLink;
  final String? configId;
  @override
  final DateTime dateCreated;

  UserMarketplaceAddons({
    required this.id,
    required this.enabledAddon,
    required this.owner,
    required this.authComplete,
    this.authLink,
    this.configId,
    required this.dateCreated,
  });

  @override
  Map<String, dynamic> toJson() => {
    "id": id,
    "enabled_addon": enabledAddon,
    "owner": owner,
    "auth_complete": authComplete,
    "auth_link": authLink,
    "config_id": configId,
    "date_created": dateCreated.toIso8601String(),
  };

  @override
  factory UserMarketplaceAddons.fromJson(Map<String, dynamic> json) {
    json['enabled_addon'].forEach((key, value) {
    });
    return UserMarketplaceAddons(
      id: json["id"],
      enabledAddon: MarketplaceAddon.fromJson(json['enabled_addon']),
      owner: json["owner"],
      authComplete: json["auth_complete"],
      authLink: json["auth_link"],
      configId: json["config_id"],
      dateCreated: DateTime.parse(json["date_created"]),
    );
  }
}
