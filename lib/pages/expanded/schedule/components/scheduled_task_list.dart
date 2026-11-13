import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/domain/entities/agents/scheduled_task.dart';
import 'package:flutter_client/pages/expanded/schedule/components/scheduled_task_card.dart';

import '../../../../logics/domain/usecases/schedule/schedule_usecase.dart';
import '../../../../widgets/builders/item_builder_list.dart';

class ScheduledTaskList extends StatelessWidget {
  final ScrollController controller;
  final Function showToast;
  const ScheduledTaskList({super.key, required this.controller, required this.showToast});

  @override
  Widget build(BuildContext context) {
    return ItemBuilderBloc(
      blocKey: 'scheduledTaskList',
      paginated: true,
      dataSource: (repo) => Schedule.list(repo: repo),
      onDataEmpty: "No scheduled tasks found",
      onError: "Error fetching scheduled tasks",
      placeHolderItems: [
        ScheduledTaskResponse(
          id: '1',
          prompt: 'Generate a daily summary report',
          crontab: '0 9 * * *',
          dateCreated: DateTime.now(),
          dateUpdated: DateTime.now(),
        ).toJson(),
        ScheduledTaskResponse(
          id: '2',
          prompt: 'Check system health status',
          crontab: '0 * * * *',
          dateCreated: DateTime.now(),
          dateUpdated: DateTime.now(),
        ).toJson(),
      ],
      item: (data) {
        if (data is ScheduledTaskResponse) {
          return ScheduledTaskCard(showToast: showToast, task: data);
        }
        return ScheduledTaskCard(
          showToast: showToast,
          task: ScheduledTaskResponse.fromJson(data),
        );
      },
    );
  }
}
