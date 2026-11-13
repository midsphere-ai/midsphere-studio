import '../../entities/agents/scheduled_task.dart';
import '../base.dart';

enum ScheduleEndpoints implements Endpoint {
  createScheduledTask,
  listScheduledTasks,
  deleteScheduledTask;

  @override
  String get value => "schedule";

  @override
  String get name => "chat";

  @override
  APIReference get requiredParams {
    switch (this) {
      case ScheduleEndpoints.createScheduledTask:
        return APIReference(
          endpoint: '/completions/schedule',
          method: 'POST',
          parameters: ['prompt', 'crontab'],
          returnType: [Map, ScheduledTaskResponse.fromJson],
        );

      case ScheduleEndpoints.listScheduledTasks:
        return APIReference(
          endpoint: '/completions/schedule',
          method: 'GET',
          parameters: [],
          returnType: [List<Map>, ScheduledTaskResponse.fromJson],
        );

      case ScheduleEndpoints.deleteScheduledTask:
        return APIReference(
          endpoint: '/completions/schedule/{task_id}/',
          method: 'DELETE',
          parameters: ['task_id'],
          returnType: [Map, ScheduledTaskDeleteResponse.fromJson],
        );
    }
  }
}
