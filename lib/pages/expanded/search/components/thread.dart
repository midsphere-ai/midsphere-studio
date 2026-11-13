import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/domain/entities/memory/conversation/base.dart';
import 'package:flutter_client/widgets/animations/animations.dart';

import '../../../chat/base.dart';
import '../../../home/home.dart';

class ThreadCard extends StatelessWidget {
  final String? conversationId;
  final String title;
  final String description;
  final String timeAgoString;
  final Conversation conversation;
  const ThreadCard({
    super.key,
    this.conversationId,
    required this.title,
    required this.description,
    required this.timeAgoString,
    required this.conversation,
  });

  @override
  Widget build(BuildContext context) {
    return HoverScaleCard.subtle(
      child: GhostButton(
        density: ButtonDensity.dense,
        onPressed: () => RootShell.updateAndRefresh(
          ValueKey('main'),
          ChatUI(conversationId: conversationId, isBusy: conversation.onGoing,),
          "Chat",
          LucideIcons.messagesSquare,
          shouldShowBorder: true,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            _buildHeader(context),
            SizedBox(height: 6),
            Row(
              spacing: 12,
              children: [
                if (conversation.onGoing)
                  _OnGoingBadge(),
                Row(
                  spacing: 4,
                  children: [
                    Icon(LucideIcons.clock, size: 14),
                    Text(timeAgoString).small,
                  ],
                ).small.muted.iconSmall().iconMutedForeground(),
              ],
            ),
            SizedBox(height: 2),
            Divider(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, overflow: TextOverflow.ellipsis),
            Text(description.isNotEmpty ? description : "Summary not updated", overflow: TextOverflow.ellipsis, maxLines: 2,).muted.small,
          ],
        )),
        GhostButton(
          density: ButtonDensity.compact,
          child: Icon(LucideIcons.ellipsis),
        ),
      ],
    );
  }
}

/// A badge showing "On going" status with pulse animation and rotating loader.
class _OnGoingBadge extends StatefulWidget {
  const _OnGoingBadge();

  @override
  State<_OnGoingBadge> createState() => _OnGoingBadgeState();
}

class _OnGoingBadgeState extends State<_OnGoingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _pulseAnimation,
      child: Row(
        spacing: 4,
        children: [
          _RotatingLoader(),
          Text("On going").small,
        ],
      ),
    );
  }
}

/// A continuously rotating loader icon.
class _RotatingLoader extends StatefulWidget {
  const _RotatingLoader();

  @override
  State<_RotatingLoader> createState() => _RotatingLoaderState();
}

class _RotatingLoaderState extends State<_RotatingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        LucideIcons.loader,
        size: 14,
      ),
    );
  }
}
