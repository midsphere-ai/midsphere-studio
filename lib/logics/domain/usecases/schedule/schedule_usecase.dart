import '../../entities/base/repo.dart';
import '../base.dart';
import 'endpoint_enums.dart';

class Schedule {
  /// Creates a new scheduled task.
  ///
  /// [prompt] - The AI prompt to execute on schedule.
  /// [crontab] - The crontab expression (e.g., "0 9 * * *" for daily at 9am).
  static Future<dynamic> create({
    required String prompt,
    required String crontab,
  }) async {
    return NetworkConnector.callEndpoint(
      ScheduleEndpoints.createScheduledTask,
      {
        'prompt': prompt,
        'crontab': crontab,
      },
    );
  }

  /// Lists all scheduled tasks with pagination.
  static Future<dynamic> list({required BaseRepository repo}) async {
    return NetworkConnector.callPaginatedEndpoints(
      repo,
      ScheduleEndpoints.listScheduledTasks,
      {},
    );
  }

  /// Deletes a scheduled task by ID.
  static Future<dynamic> delete({required String taskId}) async {
    return NetworkConnector.callEndpoint(
      ScheduleEndpoints.deleteScheduledTask,
      {'task_id': taskId},
    );
  }
}
