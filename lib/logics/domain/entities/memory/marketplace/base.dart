import '../../base/base.dart';

class MarketplaceAddon extends BaseModel {
  @override
  final String id;
  final String name;
  final String description;
  final String link;
  final String logo;
  final String enumValue;
  @override
  final DateTime dateCreated;

  MarketplaceAddon({
    required this.id,
    required this.name,
    required this.description,
    required this.link,
    required this.logo,
    required this.enumValue,
    required this.dateCreated,
  });

  @override
  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "description": description,
    "link": link,
    "logo": logo,
    "enum": enumValue,
    "date_created": dateCreated.toIso8601String(),
  };

  @override
  factory MarketplaceAddon.fromJson(Map<String, dynamic> json) {
    return MarketplaceAddon(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      link: json["link"],
      logo: json["logo"],
      enumValue: json["enum"],
      dateCreated: DateTime.parse(json["date_created"]),
    );
  }
}
