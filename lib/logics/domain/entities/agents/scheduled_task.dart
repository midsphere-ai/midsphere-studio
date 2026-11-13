import '../base/base.dart';

/// Request body for creating a scheduled task
class ScheduledTaskRequest {
  final String prompt;
  final String crontab;

  ScheduledTaskRequest({
    required this.prompt,
    required this.crontab,
  });

  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      'crontab': crontab,
    };
  }
}

/// Response for scheduled task operations
class ScheduledTaskResponse extends BaseModel {
  @override
  final String id;
  final String prompt;
  final String crontab;
  @override
  final DateTime dateCreated;
  final DateTime dateUpdated;

  ScheduledTaskResponse({
    required this.id,
    required this.prompt,
    required this.crontab,
    required this.dateCreated,
    required this.dateUpdated,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'crontab': crontab,
      'created_at': dateCreated.toIso8601String(),
      'updated_at': dateUpdated.toIso8601String(),
    };
  }

  factory ScheduledTaskResponse.fromJson(Map<String, dynamic> json) {
    return ScheduledTaskResponse(
      id: json['id'],
      prompt: json['prompt'],
      crontab: json['crontab'],
      dateCreated: DateTime.parse(json['created_at']),
      dateUpdated: DateTime.parse(json['updated_at']),
    );
  }

  /// Returns a human-readable description of the cron schedule
  String get scheduleDescription {
    // Parse common cron patterns
    final parts = crontab.split(' ');
    if (parts.length != 5) return crontab;

    final minute = parts[0];
    final hour = parts[1];
    final dayOfMonth = parts[2];
    final month = parts[3];
    final dayOfWeek = parts[4];

    // Daily at specific time
    if (dayOfMonth == '*' && month == '*' && dayOfWeek == '*') {
      return 'Daily at $hour:${minute.padLeft(2, '0')}';
    }

    // Weekly
    if (dayOfMonth == '*' && month == '*' && dayOfWeek != '*') {
      final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      final dayIndex = int.tryParse(dayOfWeek);
      final dayName = dayIndex != null && dayIndex < 7 ? days[dayIndex] : dayOfWeek;
      return 'Every $dayName at $hour:${minute.padLeft(2, '0')}';
    }

    // Monthly
    if (dayOfMonth != '*' && month == '*' && dayOfWeek == '*') {
      return 'Monthly on day $dayOfMonth at $hour:${minute.padLeft(2, '0')}';
    }

    return crontab;
  }
}

/// Response for scheduled task deletion
class ScheduledTaskDeleteResponse {
  final bool deleted;
  final String id;

  ScheduledTaskDeleteResponse({
    required this.deleted,
    required this.id,
  });

  Map<String, dynamic> toJson() {
    return {
      'deleted': deleted,
      'id': id,
    };
  }

  factory ScheduledTaskDeleteResponse.fromJson(Map<String, dynamic> json) {
    return ScheduledTaskDeleteResponse(
      deleted: json['deleted'] ?? false,
      id: json['id'],
    );
  }
}
