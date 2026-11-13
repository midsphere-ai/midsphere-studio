import '../../base/base.dart';

class Conversation extends BaseModel {
  @override
  final String id;
  final String? title;
  final String? summary;
  final int user;
  final String? space;

  final bool onGoing;
  final bool hasCompleted;
  final bool hasError;
  final bool requiresUserInput;
  final bool cancellationRequested;

  @override
  final DateTime dateCreated;
  final DateTime? dateUpdated;

  Conversation({
    required this.id,
    required this.title,
    required this.summary,
    required this.dateCreated,
    required this.user,
    required this.space,
    required this.onGoing,
    required this.hasCompleted,
    required this.hasError,
    required this.requiresUserInput,
    required this.cancellationRequested,
    this.dateUpdated,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'user': user,
      'space': space,
      'on_going': onGoing,
      'has_completed': hasCompleted,
      'has_error': hasError,
      'requires_user_input': requiresUserInput,
      'cancellation_requested': cancellationRequested,
      'date_created': dateCreated.toIso8601String(),
      'date_updated': dateUpdated?.toIso8601String(),
    };
  }

  @override
  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'],
    title: json['title'],
    summary: json['summary'],
    user: json['user'] ?? 0,
    space: json['space'],
    onGoing: json['on_going'] ?? false,
    hasCompleted: json['has_completed'] ?? false,
    hasError: json['has_error'] ?? false,
    requiresUserInput: json['requires_user_input'] ?? false,
    cancellationRequested: json['cancellation_requested'] ?? false,
    dateCreated: DateTime.tryParse(json['date_created']?.toString() ?? '') ?? DateTime.now(),
    dateUpdated: DateTime.tryParse(json['date_updated']?.toString() ?? ''),
  );
}
