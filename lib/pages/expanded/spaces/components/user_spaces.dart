import 'package:arcane/arcane.dart' hide Avatar;
import 'package:dice_bear/dice_bear.dart';
import 'package:flutter_client/pages/expanded/spaces/main.dart';
import 'package:flutter_client/widgets/animations/animations.dart';

import '../../../../logics/domain/usecases/spaces/spaces_usecase.dart';
import '../../../home/home.dart';
import '../../../../widgets/builders/item_builder_list_card.dart';

class UserSpaces extends StatefulWidget {
  const UserSpaces({super.key});

  @override
  State<UserSpaces> createState() => _UserSpacesState();
}

class _UserSpacesState extends State<UserSpaces> {
  @override
  Widget build(BuildContext context) {
    return ItemBuilderBlocCard(
      blocKey: 'userSpaces',
      paginated: true,
      customHeight: 125,
      customWidth: 300,
      dataSource: Spaces.getAllUserSpaces,
      dataSourceArgs: const {},
      onDataEmpty: "No Spaces found",
      onError: "Error fetching Spaces",
      placeHolderItems: _placeholderAddons,
      item: (data) => _buildSpacesCard(context, data),
    );
  }

  Widget _buildSpacesCard(BuildContext context, dynamic data) {
    final String name;
    final String description;
    final String spacesId;

    if (data is Map) {
      name = data['name'] ?? '';
      description = data['description'] ?? '';
      spacesId = '';
    } else {
      name = data.name ?? '';
      description = data.description ?? '';
      spacesId = data.id;
    }

    Avatar avatar = DiceBearBuilder(
      seed: name,
      radius: 49,
      size: 16,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      sprite: DiceBearSprite.icons,
    ).build();
    return HoverScaleCard(
      hoverScale: AnimationConstants.hoverScaleDefault,
      child: Card(
        padding: EdgeInsets.all(12),
        onPressed: () {
          RootShell.updateAndRefresh(
            ValueKey('main'),
            ExpandedSpaces(spaceId: spacesId),
            'Spaces',
            LucideIcons.layers
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              _AnimatedAvatar(avatar: avatar),
            ]),
            SizedBox(height: 8),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis).h4,
            Text(
              description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ).muted.normal,
          ],
        ),
      ),
    );
  }

  static const List<Map<String, String>> _placeholderAddons = [
    {
      "name": "Slack",
      "description":
          "Slack is a cloud-based team communication platform with channels, direct messages, file sharing, and thousands of integrations.",
      "logo":
          "https://upload.wikimedia.org/wikipedia/commons/7/76/Slack_Icon.png",
    },
    {
      "name": "Zoom",
      "description":
          "Zoom is a video conferencing platform offering HD video, audio, webinars, chat, and screen sharing for meetings and webinars.",
      "logo":
          "https://upload.wikimedia.org/wikipedia/commons/7/75/Zoom_Communications_Logo.svg",
    },
    {
      "name": "Microsoft Teams",
      "description":
          "Microsoft Teams is a collaboration platform that integrates chat, meetings, calling, and Office apps for teams.",
      "logo":
          "https://upload.wikimedia.org/wikipedia/commons/4/4f/Microsoft_Office_Teams_%282018%E2%80%93present%29.svg",
    },
    {
      "name": "Google Meet",
      "description":
          "Google Meet is Google's video-conferencing product providing secure meetings, screen sharing and integration with Google Workspace.",
      "logo":
          "https://upload.wikimedia.org/wikipedia/commons/2/2d/Google_Meet_icon_%282020%29.svg",
    },
  ];
}

/// An avatar widget with elasticOut scale entrance animation.
class _AnimatedAvatar extends StatefulWidget {
  final Avatar avatar;

  const _AnimatedAvatar({required this.avatar});

  @override
  State<_AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<_AnimatedAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConstants.scaleElastic,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationConstants.elasticCurve,
    ));

    // Start animation after a small delay for stagger effect
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.avatar.toImage(height: 32, width: 32),
    );
  }
}
