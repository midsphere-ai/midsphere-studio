import 'package:arcane/arcane.dart';
import 'package:flutter_client/widgets/animations/animations.dart';
import 'package:flutter_client/logics/domain/entities/agents/scheduled_task.dart';
import 'package:intl/intl.dart';
import 'scheduled_task_menu.dart';

/// A widget that displays a scheduled task in a card format.
class ScheduledTaskCard extends StatelessWidget {
  final ScheduledTaskResponse task;
  final Function showToast;

  const ScheduledTaskCard({super.key, required this.task, required this.showToast});

  @override
  Widget build(BuildContext context) {
    return HoverScaleCard.subtle(
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.prompt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.scheduleDescription,
                        ).small.muted,
                      ],
                    ),
                  ),
                  ScheduledTaskMenu(showToast: showToast, task: task),
                ],
              ),

              const SizedBox(height: 20),

              // Details section
              _buildDetailsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    final details = <Widget>[];
    int index = 0;
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    void addDetail(IconData icon, String label, String value) {
      details.add(
        FadeSlideTransition(
          delay: Duration(milliseconds: 50 * index),
          slideOffset: AnimationConstants.slideFromBottom,
          child: _buildDetailItem(context, icon, label, value),
        ),
      );
      index++;
    }

    addDetail(LucideIcons.clock, 'Schedule', task.crontab);
    addDetail(LucideIcons.calendar, 'Created', dateFormat.format(task.dateCreated));
    addDetail(LucideIcons.refreshCw, 'Last Updated', dateFormat.format(task.dateUpdated));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details.map((detail) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: detail,
      )).toList(),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton.secondary(
          icon: Icon(icon, size: 16),
          onPressed: () {},
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
              ).small,
              const SizedBox(height: 4),
              Text(
                value,
              ).mono.small.muted,
            ],
          ),
        ),
      ],
    );
  }
}
