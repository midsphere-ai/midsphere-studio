import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/domain/usecases/schedule/schedule_usecase.dart';
import 'package:flutter_client/widgets/texts/settings_text_field.dart';

import '../main.dart';
import '../../../home/home.dart';

/// Crontab presets for common scheduling patterns.
enum CrontabPreset {
  custom("Custom", ""),
  everyHour("Every hour", "0 * * * *"),
  dailyAt9am("Daily at 9:00 AM", "0 9 * * *"),
  dailyAtNoon("Daily at noon", "0 12 * * *"),
  dailyAtMidnight("Daily at midnight", "0 0 * * *"),
  weekdaysAt9am("Weekdays at 9:00 AM", "0 9 * * 1-5"),
  weeklyMonday("Weekly on Monday", "0 0 * * 1"),
  monthlyFirst("Monthly on the 1st", "0 0 1 * *");

  final String label;
  final String crontab;
  const CrontabPreset(this.label, this.crontab);
}

/// A form for adding a new scheduled task.
class AddScheduledTaskForm extends StatefulWidget {
  final VoidCallback? onSuccess;
  final Function(String, String) showToast;

  const AddScheduledTaskForm({super.key, this.onSuccess, required this.showToast});

  @override
  State<AddScheduledTaskForm> createState() => _AddScheduledTaskFormState();
}

class _AddScheduledTaskFormState extends State<AddScheduledTaskForm> {
  CrontabPreset _selectedPreset = CrontabPreset.dailyAt9am;

  late final TextEditingController _promptController;
  late final TextEditingController _crontabController;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController();
    _crontabController = TextEditingController(text: _selectedPreset.crontab);
  }

  @override
  void dispose() {
    _promptController.dispose();
    _crontabController.dispose();
    super.dispose();
  }

  void _onPresetChanged(CrontabPreset? preset) {
    if (preset != null) {
      setState(() {
        _selectedPreset = preset;
        if (preset != CrontabPreset.custom) {
          _crontabController.text = preset.crontab;
        }
      });
    }
  }

  void _handleSave() async {
    if (_promptController.text.trim().isEmpty) {
      widget.showToast('Error', 'Prompt is required.');
      return;
    }

    if (_crontabController.text.trim().isEmpty) {
      widget.showToast('Error', 'Crontab expression is required.');
      return;
    }

    // Crontab validation (5 parts with range checks)
    final parts = _crontabController.text.trim().split(' ');
    if (parts.length != 5) {
      widget.showToast('Error', 'Invalid crontab format. Expected 5 parts (e.g., "0 9 * * *").');
      return;
    }

    final rangeNames = ['Minute', 'Hour', 'Day of month', 'Month', 'Day of week'];
    final rangeMins = [0, 0, 1, 1, 0];
    final rangeMaxs = [59, 23, 31, 12, 7];
    for (var i = 0; i < 5; i++) {
      final part = parts[i];
      if (part == '*') continue;
      final value = int.tryParse(part);
      if (value == null || value < rangeMins[i] || value > rangeMaxs[i]) {
        widget.showToast('Error', '${rangeNames[i]} must be ${rangeMins[i]}-${rangeMaxs[i]} or *, got "$part".');
        return;
      }
    }

    try {
      await Schedule.create(
        prompt: _promptController.text.trim(),
        crontab: _crontabController.text.trim(),
      );
      widget.showToast('Success', 'Scheduled task created successfully.');
      _clearControllers();
      widget.onSuccess?.call();
      RootShell.updateAndRefresh(
        const ValueKey('main'),
        ExpandedScheduleView(key: ValueKey(DateTime.now().millisecondsSinceEpoch)),
        'Scheduled Tasks',
        LucideIcons.clock,
      );
    } catch (e) {
      widget.showToast('Error', 'Failed to create scheduled task. $e');
    }
    closeOverlay(context);
  }

  void _clearControllers() {
    _promptController.clear();
    _crontabController.clear();
    setState(() {
      _selectedPreset = CrontabPreset.dailyAt9am;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        SettingsTextField(
          controller: _promptController,
          icon: LucideIcons.messageSquare,
          label: 'Prompt',
          isTextArea: true,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Schedule Preset',
          ).small,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Select<CrontabPreset>(
            value: _selectedPreset,
            constraints: BoxConstraints(minWidth: 600),
            onChanged: _onPresetChanged,
            itemBuilder: (context, item) => Text(item.label),
            popup: SelectPopup(
              items: SelectItemList(
                children: CrontabPreset.values
                    .map(
                      (e) => SelectItemButton(value: e, child: Text(e.label)),
                    )
                    .toList(),
              ),
            ).call,
            placeholder: const Text("Select Schedule"),
          ),
        ),
        SettingsTextField(
          controller: _crontabController,
          icon: LucideIcons.clock,
          label: 'Crontab Expression',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Format: minute hour day month weekday (e.g., "0 9 * * *" for daily at 9am)',
          ).xSmall.muted,
        ),
        const SizedBox(height: 24),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: PrimaryButton(
            onPressed: _handleSave,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [const Text('Create Scheduled Task').bold],
            ),
          ),
        ),
      ],
    );
  }
}
