import 'package:arcane/arcane.dart';

import '../../../main.dart';

class QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Function callBack;
  const QuickAction({super.key, required this.label, required this.icon, required this.callBack});

  @override
  Widget build(BuildContext context) {

    return Card(
      filled: true,
      fillColor: Theme.of(context).colorScheme.background,
      onPressed: () async {
        await postHogInstance.capture(
          eventName: 'user_clicked_quick_action',
          properties: {'label': label},
        );
        callBack();
      },
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
