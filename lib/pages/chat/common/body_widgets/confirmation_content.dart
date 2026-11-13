import 'package:arcane/arcane.dart';
import 'package:flutter_client/widgets/content_card/content_card.export.dart';

typedef ToolConfig = Map<String, dynamic>;

class ConfirmationContent extends StatelessWidget {
  final String message;
  final bool animate;
  final Duration animationDelay;

  const ConfirmationContent({
    super.key,
    required this.message,
    this.animate = true,
    this.animationDelay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ContentCard(
      animate: animate,
      delay: animationDelay,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.check, size: 20, color: colors.primary),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center).xSmall.muted,
          ],
        ),
      ),
    );
  }
}
