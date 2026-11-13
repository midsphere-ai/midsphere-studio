import 'dart:convert';

import 'package:arcane/arcane.dart';

class StepMessage extends StatefulWidget {
  final bool isFirst;
  final bool isLast;
  final Map<String, dynamic> message;
  final bool isActive;
  final int animationIndex;

  const StepMessage({
    super.key,
    required this.message,
    this.isFirst = false,
    this.isLast = false,
    this.isActive = false,
    this.animationIndex = 0,
  });

  @override
  State<StepMessage> createState() => _StepMessageState();
}

class _StepMessageState extends State<StepMessage>
    with TickerProviderStateMixin {
  final double _dotSize = 6.0;
  final double _lineWidth = 0.5;
  final double _topPadding = 15.0;

  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final Animation<double> _dotScaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Entrance animation controller
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Pulse animation for active step
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _dotScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Staggered entrance
    Future.delayed(Duration(milliseconds: widget.animationIndex * 80), () {
      if (mounted) _entranceController.forward();
    });

    // Start pulse animation if active
    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant StepMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _textMap {
    return widget.message;
  }

  Color _getMessageColor(BuildContext context) {
    if (_textMap.containsKey('origin_tool_call')) {
      return Theme.of(context).colorScheme.secondary;
    }
    if (_textMap.containsKey('response')) {
      return Theme.of(context).colorScheme.primary;
    }
    return Colors.white; // Fallback
  }

  Widget? _handleEmpty() {
    if (_textMap.isEmpty ||
        (_textMap.containsKey('metadata') && _textMap['metadata'].isEmpty) ||
        _textMap.containsKey('status')) {
      return Container();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_handleEmpty() != null) {
      return _handleEmpty()!;
    }

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: child,
        );
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLineAndDot(),
            SizedBox(width: 16.0),
            Expanded(child: _buildText()),
          ],
        ),
      ),
    );
  }

  Widget _buildLineAndDot() {
    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _pulseController]),
      builder: (context, _) {
        return CustomPaint(
          size: Size(_dotSize * 2, double.infinity),
          painter: _TimelinePainter(
            context: context,
            isFirst: widget.isFirst,
            isLast: widget.isLast,
            dotColor: _getMessageColor(context),
            dotSize: _dotSize,
            lineWidth: _lineWidth,
            topPadding: _topPadding,
            dotScale: _dotScaleAnimation.value,
            pulseScale: widget.isActive ? _pulseAnimation.value : 1.0,
            isActive: widget.isActive,
          ),
        );
      },
    );
  }

  Widget _buildText() {
    if (_textMap.containsKey('response')) {
      return _baseText(_textMap['response'] ?? "");
    }
    if (_textMap.containsKey('origin_tool_call')) {
      return _buildToolCall();
    }
    return _baseText(_textMap.toString());
  }

  Widget _buildToolCall() {
    final toolCall = _textMap['origin_tool_call'];
    String message = "";
    try {
      final function = toolCall['function'];
      if (function != null && function['arguments'] != null) {
        final args = jsonDecode(function['arguments']);
        if (args is Map && args.containsKey('brief')) {
          message = args["brief"]?.toString() ?? "";
        }
      }
      if (message.isEmpty) {
        message = "Calling tool ${toolCall['function']?['name'] ?? 'unknown'}";
      }
    } catch (e) {
      debugPrint('[StepMessage] Error parsing tool call arguments: $e');
      message = "Calling tool ${toolCall['function']?['name'] ?? 'unknown'}";
    }
    return Card(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Text(message).small,
    );
  }

  Widget _baseText(String text) {
    return Container(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Align(alignment: Alignment.centerLeft, child: Markdown(text)),
    ).muted.small;
  }
}

class _TimelinePainter extends CustomPainter {
  final BuildContext context;
  final bool isFirst;
  final bool isLast;
  final Color dotColor;
  final double dotSize;
  final double lineWidth;
  final double topPadding;
  final double dotScale;
  final double pulseScale;
  final bool isActive;

  _TimelinePainter({
    required this.context,
    required this.isFirst,
    required this.isLast,
    required this.dotColor,
    required this.dotSize,
    required this.lineWidth,
    required this.topPadding,
    this.dotScale = 1.0,
    this.pulseScale = 1.0,
    this.isActive = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Theme.of(context).colorScheme.secondary
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, topPadding);

    double startY = 0;
    double endY = size.height;

    if (isFirst) {
      startY = center.dy;
    }
    if (isLast) {
      endY = center.dy;
    }

    // Draw the line segment for this cell
    if (startY < endY) {
      canvas.drawLine(
        Offset(center.dx, startY),
        Offset(center.dx, endY),
        linePaint,
      );
    }

    // Draw pulse ring for active step
    if (isActive && pulseScale > 1.0) {
      final pulsePaint = Paint()
        ..color = dotColor.withOpacity(0.3 * (1.0 - (pulseScale - 1.0) / 0.4))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, (dotSize / 2) * pulseScale * dotScale, pulsePaint);
    }

    // Draw dot on top with scale animation
    final dotPaint = Paint()..color = dotColor;
    canvas.drawCircle(center, (dotSize / 2) * dotScale, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return oldDelegate.dotScale != dotScale ||
        oldDelegate.pulseScale != pulseScale ||
        oldDelegate.isActive != isActive ||
        oldDelegate.dotColor != dotColor;
  }
}
