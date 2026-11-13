import 'package:arcane/arcane.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_client/widgets/animations/animations.dart';

/// A thumbnail widget for displaying blog images with fallback.
class BlogThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const BlogThumbnail({
    super.key,
    required this.imageUrl,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(scheme);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheHeight: (size * 2).toInt(),
        memCacheWidth: (size * 2).toInt(),
        fadeInDuration: AnimationConstants.imageFadeIn,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: scheme.secondary,
        ).asSkeleton(),
        errorWidget: (context, url, error) => _buildPlaceholder(scheme),
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme scheme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.secondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        LucideIcons.fileText,
        color: scheme.mutedForeground,
      ),
    );
  }
}

/// A larger image widget for blog detail view.
class BlogDetailImage extends StatelessWidget {
  final String? imageUrl;
  final double height;

  const BlogDetailImage({
    super.key,
    required this.imageUrl,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            width: double.infinity,
            height: height,
            fit: BoxFit.cover,
            fadeInDuration: AnimationConstants.imageFadeIn,
            placeholder: (context, url) => Container(
              width: double.infinity,
              height: height,
              color: scheme.secondary,
            ).asSkeleton(),
            errorWidget: (context, url, error) => const SizedBox.shrink(),
          ),
        ),
        const Gap(24),
      ],
    );
  }
}
