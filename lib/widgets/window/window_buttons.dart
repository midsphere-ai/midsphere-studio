import 'package:arcane/arcane.dart';
import 'package:flutter_client/widgets/window/platform_window.dart'
    if (dart.library.io) 'package:flutter_client/widgets/window/platform_window_io.dart'
    if (dart.library.html) 'package:flutter_client/widgets/window/platform_window_web.dart';

/// Platform-aware window control buttons (minimize, maximize, close).
/// Only displays on desktop platforms (Windows, macOS, Linux).
class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    // Only show on desktop platforms
    if (!isDesktopPlatform) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        _WindowButton(
          icon: LucideIcons.minus,
          onPressed: () => minimizeWindow(),
          hoverColor: scheme.muted,
        ),
        _WindowButton(
          icon: isWindowMaximized
              ? LucideIcons.minimize2
              : LucideIcons.maximize2,
          onPressed: () => maximizeOrRestoreWindow(),
          hoverColor: scheme.muted,
        ),
        _WindowButton(
          icon: LucideIcons.x,
          onPressed: () => closeWindow(),
          hoverColor: isDark ? Colors.red.shade400 : Colors.red.shade500,
          isClose: true,
        ),
      ],
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color hoverColor;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    required this.hoverColor,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 32,
          decoration: BoxDecoration(
            color: _isHovered ? widget.hoverColor : Colors.transparent,
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: 16,
              color: _isHovered && widget.isClose
                  ? Colors.white
                  : scheme.foreground,
            ),
          ),
        ),
      ),
    );
  }
}

/// A draggable area that allows window movement when dragged.
/// Wrap your title bar content with this widget.
class WindowDragArea extends StatelessWidget {
  final Widget child;

  const WindowDragArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Only enable drag on desktop platforms
    if (!isDesktopPlatform) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => startDragging(),
      onDoubleTap: () => maximizeOrRestoreWindow(),
      child: child,
    );
  }
}
