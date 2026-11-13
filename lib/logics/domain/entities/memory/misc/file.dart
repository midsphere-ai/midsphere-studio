import '../../base/base.dart';

class StoredFile extends BaseModel {
  @override
  final String id;
  final int? owner; // User ID
  final String file;
  final String name;
  final int size;
  final String mimeType;
  final DateTime uploadedAt;
  final DateTime updatedAt;

  StoredFile({
    required this.id,
    this.owner,
    required this.file,
    required this.name,
    required this.size,
    required this.mimeType,
    required this.uploadedAt,
    required this.updatedAt,
  }) : super();

  @override
  DateTime get dateCreated => uploadedAt;

  @override
  Map<String, dynamic> toJson() => {
    "id": id,
    "owner": owner,
    "file": file,
    "name": name,
    "size": size,
    "mime_type": mimeType,
    "uploaded_at": uploadedAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
  };

  @override
  factory StoredFile.fromJson(Map<String, dynamic> json) {
    return StoredFile(
      id: json["id"],
      owner: json["owner"],
      file: json["file"],
      name: json["name"],
      size: json["size"],
      mimeType: json["mime_type"],
      uploadedAt: DateTime.parse(json["uploaded_at"]),
      updatedAt: DateTime.parse(json["updated_at"]),
    );
  }
}
