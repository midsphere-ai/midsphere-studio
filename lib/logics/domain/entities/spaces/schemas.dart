// Result classes (equivalent to Python dataclasses)
class CreateSpaceResult {
  final String spaceId;

  const CreateSpaceResult({required this.spaceId});

  factory CreateSpaceResult.fromJson(Map<String, dynamic> json) {
    return CreateSpaceResult(
      spaceId: json['space_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'space_id': spaceId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CreateSpaceResult &&
              runtimeType == other.runtimeType &&
              spaceId == other.spaceId;

  @override
  int get hashCode => spaceId.hashCode;

  @override
  String toString() => 'CreateSpaceResult(spaceId: $spaceId)';
}

class SpaceUpdationResult {
  final String spaceId;
  final bool modified;

  const SpaceUpdationResult({
    required this.spaceId,
    required this.modified,
  });

  factory SpaceUpdationResult.fromJson(Map<String, dynamic> json) {
    return SpaceUpdationResult(
      spaceId: json['space_id'] as String,
      modified: json['modified'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'space_id': spaceId,
      'modified': modified,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SpaceUpdationResult &&
              runtimeType == other.runtimeType &&
              spaceId == other.spaceId &&
              modified == other.modified;

  @override
  int get hashCode => Object.hash(spaceId, modified);

  @override
  String toString() => 'SpaceUpdationResult(spaceId: $spaceId, modified: $modified)';
}

class SpaceRemoveResult {
  final String spaceId;
  final bool deleted;

  const SpaceRemoveResult({
    required this.spaceId,
    required this.deleted,
  });

  factory SpaceRemoveResult.fromJson(Map<String, dynamic> json) {
    return SpaceRemoveResult(
      spaceId: json['space_id'] as String,
      deleted: json['deleted'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'space_id': spaceId,
      'deleted': deleted,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SpaceRemoveResult &&
              runtimeType == other.runtimeType &&
              spaceId == other.spaceId &&
              deleted == other.deleted;

  @override
  int get hashCode => Object.hash(spaceId, deleted);

  @override
  String toString() => 'SpaceRemoveResult(spaceId: $spaceId, deleted: $deleted)';
}

// Schema classes for data transfer
class SpaceDataSchema {
  final String name;
  final String description;

  const SpaceDataSchema({
    required this.name,
    required this.description,
  });

  factory SpaceDataSchema.fromJson(Map<String, dynamic> json) {
    return SpaceDataSchema(
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SpaceDataSchema &&
              runtimeType == other.runtimeType &&
              name == other.name &&
              description == other.description;

  @override
  int get hashCode => Object.hash(name, description);

  @override
  String toString() => 'SpaceDataSchema(name: $name, description: $description)';
}

class SpaceUpdateSchema extends SpaceDataSchema {
  final String spaceId;

  const SpaceUpdateSchema({
    required this.spaceId,
    required super.name,
    required super.description,
  });

  factory SpaceUpdateSchema.fromJson(Map<String, dynamic> json) {
    return SpaceUpdateSchema(
      spaceId: json['space_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'space_id': spaceId,
      ...super.toJson(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SpaceUpdateSchema &&
              runtimeType == other.runtimeType &&
              spaceId == other.spaceId &&
              name == other.name &&
              description == other.description;

  @override
  int get hashCode => Object.hash(spaceId, name, description);

  @override
  String toString() => 'SpaceUpdateSchema(spaceId: $spaceId, name: $name, description: $description)';
}

class SpaceIdSchema {
  final String spaceId;

  const SpaceIdSchema({required this.spaceId});

  factory SpaceIdSchema.fromJson(Map<String, dynamic> json) {
    return SpaceIdSchema(
      spaceId: json['space_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'space_id': spaceId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SpaceIdSchema &&
              runtimeType == other.runtimeType &&
              spaceId == other.spaceId;

  @override
  int get hashCode => spaceId.hashCode;

  @override
  String toString() => 'SpaceIdSchema(spaceId: $spaceId)';
}
