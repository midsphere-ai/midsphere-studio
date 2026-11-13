import 'package:arcane/arcane.dart';
import 'package:flutter_client/widgets/content_card/content_card.export.dart';

class PlanViewerContent extends StatelessWidget {
  final String rawData;
  final Widget Function() fallbackBuilder;
  final bool animate;
  final Duration animationDelay;

  const PlanViewerContent({
    super.key,
    required this.rawData,
    required this.fallbackBuilder,
    this.animate = true,
    this.animationDelay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    try {
      String markdown = '';
      final data = JsonDecodeUtils.decodeNested(rawData);

      if (data is Map) {
        markdown = data['message']?.toString() ?? '';
      } else if (data is String) {
        markdown = data;
      }

      if (markdown.isEmpty) return fallbackBuilder();

      return ContentCard(
        animate: animate,
        delay: animationDelay,
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: markdown.split('\n').map((line) {
            if (line.trim().isEmpty) return const SizedBox(height: 4);
            if (line.startsWith('# ')) return Text(line.substring(2)).small.bold;
            if (line.startsWith('## ')) return Padding(padding: const EdgeInsets.only(top: 6), child: Text(line.substring(3)).xSmall.bold);

            if (line.contains('⭕') || line.contains('✅') || line.contains('🔄')) {
              final done = line.contains('✅');
              final current = line.contains('🔄') || line.contains('← CURRENT');
              final text = line.replaceAll(RegExp(r'[⭕✅🔄]|← CURRENT|\*\*'), '').trim();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    Icon(done ? LucideIcons.check : (current ? LucideIcons.play : LucideIcons.circle), size: 8, color: done ? Colors.green : (current ? colors.primary : colors.mutedForeground)),
                    const SizedBox(width: 4),
                    Expanded(child: Text(text, style: TextStyle(fontWeight: current ? FontWeight.w500 : null, color: current ? colors.foreground : colors.mutedForeground)).mono.xSmall),
                  ],
                ),
              );
            }

            if (line.trim().startsWith('- ')) return Padding(padding: const EdgeInsets.only(left: 12), child: Text(line.trim().substring(2)).xSmall.muted);
            if (line.trim() == '---') return Divider(height: 8, color: colors.border.withOpacity(0.2));

            return Text(line).xSmall;
          }).toList(),
        ),
      );
    } catch (e) {
      return fallbackBuilder();
    }
  }
}
