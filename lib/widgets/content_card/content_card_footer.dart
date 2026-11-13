import 'package:arcane/arcane.dart';

/// Minimal footer - just subtle text.
class ContentCardFooter extends StatelessWidget {
  final IconData? icon;
  final String text;
  final bool ellipsis;

  const ContentCardFooter({
    super.key,
    this.icon,
    required this.text,
    this.ellipsis = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 6, right: 6, top: 2, bottom: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 8, color: colors.mutedForeground.withOpacity(0.4)),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              text,
              overflow: ellipsis ? TextOverflow.ellipsis : null,
            ).xSmall.muted,
          ),
        ],
      ),
    );
  }
}
