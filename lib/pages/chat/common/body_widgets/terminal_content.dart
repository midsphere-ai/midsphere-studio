import 'package:arcane/arcane.dart';
import 'package:flutter_client/pages/chat/common/terminal.dart';
import 'package:flutter_client/widgets/content_card/content_card.export.dart';

class TerminalContent extends StatelessWidget {
  final String rawData;
  final Map<String, dynamic> arguments;
  final bool animate;
  final Duration animationDelay;

  const TerminalContent({
    super.key,
    required this.rawData,
    required this.arguments,
    this.animate = true,
    this.animationDelay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    try {
      final data = JsonDecodeUtils.decodeNested(rawData);
      final command = arguments['command']?.toString() ?? '';
      final output = data is List && data.isNotEmpty ? data[0].toString() : data.toString();

      return ContentCard(
        animate: animate,
        delay: animationDelay,
        contentPadding: const EdgeInsets.all(4),
        child: TerminalView(
          prompt: '\$ ',
          inputCommand: command,
          promptColor: colors.mutedForeground,
          cursorColor: colors.mutedForeground,
          output: output,
          backgroundColor: colors.background,
        ),
      );
    } catch (e) {
      return const Center(child: Text('Failed'));
    }
  }
}
