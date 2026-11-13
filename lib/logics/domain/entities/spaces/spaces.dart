import '../base/base.dart';

class Space extends BaseModel {
  @override
  final String id;
  final String name;
  final String description;
  final int user;
  @override
  final DateTime dateCreated;

  Space({
    required this.id,
    required this.name,
    required this.description,
    required this.user,
    required this.dateCreated,
  });

  @override
  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "description": description,
    "user": user,
    "date_created": dateCreated.toIso8601String(),
  };

  @override
  factory Space.fromJson(Map<String, dynamic> json) {
    return Space(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      user: json["user"],
      dateCreated: DateTime.parse(json["date_created"]),
    );
  }
}
