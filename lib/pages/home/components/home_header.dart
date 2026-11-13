import 'dart:math' as math;

import 'package:arcane/arcane.dart';
import 'package:flutter_client/logics/data/providers/incognito_provider.dart';
import 'package:flutter_client/logics/data/repositories/authentication.dart';
import 'package:flutter_client/widgets/window/platform_window.dart'
    if (dart.library.io) 'package:flutter_client/widgets/window/platform_window_io.dart'
    if (dart.library.html) 'package:flutter_client/widgets/window/platform_window_web.dart';
import 'package:flutter_client/pages/expanded/notifications/main.dart';
import 'package:flutter_client/pages/home/components/plan_badge.dart';
import 'package:flutter_client/pages/home/components/tasks_badge.dart';
import 'package:flutter_client/pages/home/home.dart';
import 'package:flutter_client/widgets/window/window_buttons.dart';

part 'home_header_actions.dart';

/// The header bar displayed at the top of the home page.
class HomeHeader extends StatefulWidget {
  final String title;
  final IconData icon;

  const HomeHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDesktop = isDesktopPlatform;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: scheme.background,
        ),
        child: Row(
          children: [
            Expanded(
              child: WindowDragArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _HeaderContent(
                    title: widget.title,
                    icon: widget.icon,
                  ),
                ),
              ),
            ),
            if (isDesktop) const WindowButtons(),
          ],
        ),
      ),
    );
  }
}

class _HeaderContent extends StatelessWidget {
  final String title;
  final IconData icon;

  const _HeaderContent({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isOnSection = title != "New chat" && title != "New task";
    final showPlanBadge = title == "New chat" || title == "New task";

    return Stack(
      alignment: Alignment.center,
      children: [
        // Left side - Section title with animated crossfade
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-0.1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: isOnSection
                  ? _SectionTitle(key: ValueKey(title), title: title, icon: icon)
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ),
        ),
        // Center - Plan badge with animated visibility
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: showPlanBadge
                ? const _AnimatedPlanBadge(key: ValueKey('plan'))
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ),
        // Right side actions
        const Align(
          alignment: Alignment.centerRight,
          child: _HeaderActions(),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatefulWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({super.key, required this.title, required this.icon});

  @override
  State<_SectionTitle> createState() => _SectionTitleState();
}

class _SectionTitleState extends State<_SectionTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        final progress = Curves.easeOutCubic.transform(_entryController.value);
        return Transform.translate(
          offset: Offset(-8 * (1 - progress), 0),
          child: Opacity(
            opacity: progress,
            child: child,
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 16, color: scheme.mutedForeground),
          const SizedBox(width: 8),
          Text(widget.title),
        ],
      ),
    );
  }
}
