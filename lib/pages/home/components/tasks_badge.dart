import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/data/repositories/authentication.dart';

/// Displays the tasks remaining count from subscription usage limits.
class TasksBadge extends StatelessWidget {
  const TasksBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: AuthenticationProvider(),
      builder: (context, _) {
        final tasksInfo = _getTasksRemaining();
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.secondary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.zap, size: 14, color: scheme.primary),
              SizedBox(width: 6),
              Text(
                tasksInfo,
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.foreground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Get tasks remaining from subscription extras.
  /// Key: tasks_remaining_week -> { limit, used, label }
  String _getTasksRemaining() {
    final subscription = AuthenticationProvider().activeSubscription;
    if (subscription == null) return '0 / 0';

    try {
      final extras = subscription.extras;
      if (extras.isEmpty) return '0 / 0';

      if (extras.containsKey('tasks_remaining_week')) {
        final limits = extras['tasks_remaining_week'];
        if (limits is Map) {
          final tasksLimit = _parseInt(limits['limit']);
          final tasksUsed = _parseInt(limits['used']);
          return '$tasksUsed / $tasksLimit';
        }
      }
      return '∞';
    } catch (e) {
      return '0 / 0';
    }
  }
}
