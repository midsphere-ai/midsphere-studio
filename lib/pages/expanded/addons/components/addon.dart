import 'package:arcane/arcane.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_client/pages/expanded/addons/main.dart';
import 'package:flutter_client/widgets/animations/animations.dart';

import '../../../../main.dart';
import '../../../home/home.dart';

class AddonCard extends StatelessWidget {
  final String addonId;
  final String name;
  final String description;
  final String logo;
  const AddonCard({
    super.key,
    required this.addonId,
    required this.name,
    required this.description,
    required this.logo,
  });

  @override
  Widget build(BuildContext context) {
    final innerChild = [
      _logo(context),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(name, overflow: TextOverflow.ellipsis, maxLines: 1).bold,
            SizedBox(height: 4),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ).muted.small,
          ],
        ),
      ),
    ];
    return HoverScaleCard.subtle(
      child: Column(
        children: [
          Flexible(
            child: GhostButton(
              onPressed: _navigateToAddonPage,
              child: Row(
                spacing: 8,
                mainAxisSize: MainAxisSize.max,
                children: innerChild,
              ),
            ),
          ),
          Divider(),
        ],
      ),
    );
  }

  Widget _logo(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4),
      color: Colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: logo,
          height: 64,
          width: 64,
          fit: BoxFit.cover,
          memCacheHeight: 128, // Cache at 2x for retina displays
          memCacheWidth: 128,
          maxHeightDiskCache: 128,
          maxWidthDiskCache: 128,
          fadeInDuration: AnimationConstants.imageFadeIn,
          placeholder: (context, url) => Container(
            height: 64,
            width: 64,
            color: Theme.of(context).colorScheme.card,
          ).asSkeleton(),
          errorWidget: (context, url, error) => imageError(context),
        ),
      ),
    );
  }

  void _navigateToAddonPage() async {
    await postHogInstance.capture(
      eventName: 'user_navigated_to_addon_page',
      properties: {'addon_id': addonId},
    );
    RootShell.updateAndRefresh(
      const ValueKey('main'),
      ExpandedAddonPage(addonId: addonId),
      'Addon',
      LucideIcons.grid2x2Plus,
    );
  }

  Widget imageError(context) {
    return Container(
      height: 64,
      width: 64,
      color: Theme.of(context).colorScheme.card,
    ).asSkeleton();
  }
}
