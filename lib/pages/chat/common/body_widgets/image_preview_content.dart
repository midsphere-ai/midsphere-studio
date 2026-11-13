import 'package:arcane/arcane.dart';
import 'package:image_network/image_network.dart';
import 'package:flutter_client/widgets/content_card/content_card.export.dart';

class ImagePreviewContent extends StatelessWidget {
  final String rawData;
  final Widget Function() fallbackBuilder;
  final bool animate;
  final Duration animationDelay;

  const ImagePreviewContent({
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
      String? imageUrl;

      if (data is Map) {
        imageUrl = JsonDecodeUtils.extractUrl(data);
      } else if (data is String && data.startsWith('http')) {
        imageUrl = data;
      }

      return ContentCard(
        animate: animate,
        delay: animationDelay,
        child: Center(
          child: imageUrl != null
              ? ClipRRect(
                  borderRadius: Theme.of(context).borderRadiusSm,
                  child: ImageNetwork(
                    image: imageUrl,
                    height: double.infinity,
                    width: double.infinity,
                    fitWeb: BoxFitWeb.contain,
                    onLoading: Icon(LucideIcons.image, size: 16, color: colors.mutedForeground),
                    onError: Icon(LucideIcons.image, size: 24, color: colors.mutedForeground),
                  ),
                )
              : Icon(LucideIcons.image, size: 24, color: colors.mutedForeground),
        ),
      );
    } catch (e) {
      return fallbackBuilder();
    }
  }
}
