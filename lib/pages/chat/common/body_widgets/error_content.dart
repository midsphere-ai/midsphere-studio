import 'package:arcane/arcane.dart';
import 'package:flutter_client/widgets/content_card/content_card.export.dart';

class ErrorContent extends StatelessWidget {
  final String errorMessage;
  final bool animate;
  final Duration animationDelay;

  const ErrorContent({
    super.key,
    required this.errorMessage,
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
            Icon(LucideIcons.triangleAlert, size: 20, color: colors.destructive),
            const SizedBox(height: 8),
            Text(errorMessage, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis).xSmall.muted,
          ],
        ),
      ),
    );
  }
}
