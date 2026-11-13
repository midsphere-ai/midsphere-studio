import 'package:arcane/arcane.dart';
import 'package:image_network/image_network.dart';
import 'package:flutter_client/widgets/content_card/content_card.export.dart';

class VideoPreviewContent extends StatelessWidget {
  final String rawData;
  final Widget Function() fallbackBuilder;
  final bool animate;
  final Duration animationDelay;

  const VideoPreviewContent({
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
      final data = JsonDecodeUtils.decodeNested(rawData);
      String? thumbnail;

      if (data is Map) {
        thumbnail = data['thumbnail']?.toString();
      }

      return ContentCard(
        animate: animate,
        delay: animationDelay,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (thumbnail != null)
                ClipRRect(
                  borderRadius: Theme.of(context).borderRadiusSm,
                  child: ImageNetwork(
                    image: thumbnail,
                    height: double.infinity,
                    width: double.infinity,
                    fitWeb: BoxFitWeb.cover,
                  ),
                ),
              Icon(LucideIcons.play, size: 20, color: colors.foreground.withOpacity(0.6)),
            ],
          ),
        ),
      );
    } catch (e) {
      return fallbackBuilder();
    }
  }
}
