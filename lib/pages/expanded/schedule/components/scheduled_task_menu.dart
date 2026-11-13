import 'package:arcane/arcane.dart';
import 'package:arcane/generated/arcane_shadcn/src/components/menu/dropdown_menu.dart';
import 'package:arcane/generated/arcane_shadcn/src/components/overlay/toast.dart';
import 'package:flutter_client/logics/domain/entities/agents/scheduled_task.dart';
import 'package:flutter_client/logics/domain/usecases/schedule/schedule_usecase.dart';
import 'package:flutter/foundation.dart';

import '../../../home/home.dart';
import '../main.dart';

enum _ToastType { success, danger }

class ScheduledTaskMenu extends StatelessWidget {
  final Function showToast;
  final ScheduledTaskResponse task;

  const ScheduledTaskMenu({super.key, required this.task, required this.showToast});

  @override
  Widget build(BuildContext context) {
    return IconButton.ghost(
      icon: Icon(LucideIcons.ellipsis),
      density: ButtonDensity.dense,
      onPressed: () => _showOptionsMenu(context),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showDropdown(
      context: context,
      builder: (context) {
        return ScheduledTaskMenuDropdown(showToast: showToast, task: task);
      },
    ).future.then((_) {
      if (kDebugMode) {
      }
    });
  }
}

class ScheduledTaskMenuDropdown extends StatefulWidget {
  final Function showToast;
  final ScheduledTaskResponse task;

  const ScheduledTaskMenuDropdown({super.key, required this.task, required this.showToast});

  @override
  State<ScheduledTaskMenuDropdown> createState() => _ScheduledTaskMenuDropdownState();
}

class _ScheduledTaskMenuDropdownState extends State<ScheduledTaskMenuDropdown> {
  @override
  Widget build(BuildContext context) {
    return DropdownMenu(
      children: [
        MenuButton(
          leading: Icon(LucideIcons.trash2),
          onPressed: () async {
            try {
              await _removeTask(context);
            } catch (e) {
              widget.showToast("Error", "Failed to delete scheduled task");
            }
            closeOverlay(context);
          },
          child: const Text('Remove Task'),
        ),
      ],
    );
  }

  Future<void> _removeTask(BuildContext context) async {
    await Schedule.delete(taskId: widget.task.id);

    if (context.mounted) {
      _showToast(
        context: RootShell.context(ValueKey('main')),
        type: _ToastType.success,
        title: 'Task Removed',
        message: 'Scheduled task has been removed.',
      );
      RootShell.updateAndRefresh(
        const ValueKey('main'),
        ExpandedScheduleView(key: ValueKey(DateTime.now().millisecondsSinceEpoch)),
        'Scheduled Tasks',
        LucideIcons.clock,
      );
    }
  }

  void _showToast({
    required BuildContext context,
    required _ToastType type,
    required String title,
    required String message,
  }) {
    Color indicatorColor = switch (type) {
      _ToastType.success => Colors.green,
      _ToastType.danger => Colors.red,
    };

    showToast(
      context: context,
      location: ToastLocation.topCenter,
      builder: (context, overlay) {
        return SurfaceCard(
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: indicatorColor),
                const Gap(12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Basic(
                      title: Text(title),
                      subtitle: Text(message),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
