import 'package:arcane/arcane.dart';

/// Minimal header - just text, no decoration.
class ContentCardHeader extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? metadata;
  final Widget? trailing;
  final bool monoTitle;
  final Color? iconColor;

  const ContentCardHeader({
    super.key,
    this.icon,
    required this.title,
    this.metadata,
    this.trailing,
    this.monoTitle = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 6, right: 6, top: 4, bottom: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: iconColor ?? colors.mutedForeground.withOpacity(0.5)),
            const SizedBox(width: 4),
          ],
          monoTitle ? Text(title).mono.xSmall.muted : Text(title).xSmall.muted,
          const Spacer(),
          if (metadata != null) Text(metadata!).xSmall.muted,
          if (trailing != null) ...[
            if (metadata != null) const SizedBox(width: 4),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Accent variant - subtle primary tint on icon.
class ContentCardHeaderAccent extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? metadata;
  final Widget? trailing;
  final bool monoTitle;

  const ContentCardHeaderAccent({
    super.key,
    this.icon,
    required this.title,
    this.metadata,
    this.trailing,
    this.monoTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ContentCardHeader(
      icon: icon,
      title: title,
      metadata: metadata,
      trailing: trailing,
      monoTitle: monoTitle,
      iconColor: colors.primary.withOpacity(0.6),
    );
  }
}
