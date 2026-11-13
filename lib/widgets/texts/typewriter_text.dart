import 'package:arcane/arcane.dart';
import 'package:flutter_client/widgets/animations/animation_constants.dart';

/// A widget that reveals text character by character with a typewriter effect.
///
/// Features:
/// - Configurable typing speed
/// - Optional blinking cursor
/// - onComplete callback
class TypewriterText extends StatefulWidget {
  /// The text to reveal.
  final String text;

  /// Text style to apply.
  final TextStyle? style;

  /// Duration between each character.
  final Duration characterDelay;

  /// Whether to show a blinking cursor.
  final bool showCursor;

  /// Cursor character.
  final String cursor;

  /// Callback when typing is complete.
  final VoidCallback? onComplete;

  /// Whether to start typing immediately.
  final bool autoStart;

  /// Initial delay before typing starts.
  final Duration startDelay;

  /// Text alignment.
  final TextAlign textAlign;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.characterDelay = AnimationConstants.typewriterSpeed,
    this.showCursor = true,
    this.cursor = '|',
    this.onComplete,
    this.autoStart = true,
    this.startDelay = Duration.zero,
    this.textAlign = TextAlign.start,
  });

  @override
  State<TypewriterText> createState() => TypewriterTextState();
}

class TypewriterTextState extends State<TypewriterText>
    with TickerProviderStateMixin {
  late AnimationController _typingController;
  late AnimationController _cursorController;
  int _currentCharIndex = 0;
  bool _isTyping = false;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();

    _typingController = AnimationController(
      vsync: this,
      duration: widget.characterDelay,
    );

    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    if (widget.showCursor) {
      _cursorController.repeat(reverse: true);
    }

    if (widget.autoStart) {
      _startTyping();
    }
  }

  @override
  void dispose() {
    _typingController.dispose();
    _cursorController.dispose();
    super.dispose();
  }

  /// Start the typewriter effect.
  void start() {
    if (!_isTyping && !_isComplete) {
      _startTyping();
    }
  }

  /// Reset and restart the typewriter effect.
  void restart() {
    setState(() {
      _currentCharIndex = 0;
      _isComplete = false;
    });
    _startTyping();
  }

  /// Skip to the end.
  void skipToEnd() {
    setState(() {
      _currentCharIndex = widget.text.length;
      _isComplete = true;
    });
    widget.onComplete?.call();
  }

  void _startTyping() async {
    if (widget.startDelay > Duration.zero) {
      await Future.delayed(widget.startDelay);
    }

    if (!mounted) return;

    _isTyping = true;
    _typeNextCharacter();
  }

  void _typeNextCharacter() async {
    if (!mounted || _currentCharIndex >= widget.text.length) {
      _isTyping = false;
      _isComplete = true;
      widget.onComplete?.call();
      return;
    }

    await Future.delayed(widget.characterDelay);

    if (!mounted) return;

    setState(() {
      _currentCharIndex++;
    });

    _typeNextCharacter();
  }

  @override
  Widget build(BuildContext context) {
    final displayText = widget.text.substring(0, _currentCharIndex);
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle = widget.style ?? defaultStyle;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            displayText,
            style: effectiveStyle,
            textAlign: widget.textAlign,
          ),
        ),
        if (widget.showCursor && !_isComplete)
          AnimatedBuilder(
            animation: _cursorController,
            builder: (context, child) {
              return Opacity(
                opacity: _cursorController.value,
                child: Text(
                  widget.cursor,
                  style: effectiveStyle.copyWith(
                    color: effectiveStyle.color?.withValues(alpha: 0.7),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// A text widget that types out multiple lines with delays between them.
class MultilineTypewriter extends StatefulWidget {
  /// Lines of text to type.
  final List<String> lines;

  /// Style for the text.
  final TextStyle? style;

  /// Delay between characters.
  final Duration characterDelay;

  /// Delay between lines.
  final Duration lineDelay;

  /// Whether to show cursor.
  final bool showCursor;

  /// Callback when all lines are complete.
  final VoidCallback? onComplete;

  const MultilineTypewriter({
    super.key,
    required this.lines,
    this.style,
    this.characterDelay = AnimationConstants.typewriterSpeed,
    this.lineDelay = const Duration(milliseconds: 500),
    this.showCursor = true,
    this.onComplete,
  });

  @override
  State<MultilineTypewriter> createState() => _MultilineTypewriterState();
}

class _MultilineTypewriterState extends State<MultilineTypewriter> {
  int _currentLineIndex = 0;
  final List<String> _completedLines = [];
  String _currentLine = '';
  int _currentCharIndex = 0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() async {
    while (_currentLineIndex < widget.lines.length && mounted) {
      final line = widget.lines[_currentLineIndex];

      while (_currentCharIndex < line.length && mounted) {
        await Future.delayed(widget.characterDelay);
        if (!mounted) return;

        setState(() {
          _currentCharIndex++;
          _currentLine = line.substring(0, _currentCharIndex);
        });
      }

      if (!mounted) return;

      // Line complete
      _completedLines.add(line);
      _currentLineIndex++;
      _currentCharIndex = 0;
      _currentLine = '';

      if (_currentLineIndex < widget.lines.length) {
        await Future.delayed(widget.lineDelay);
      }
    }

    if (mounted) {
      setState(() {
        _isComplete = true;
      });
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle = widget.style ?? defaultStyle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._completedLines.map((line) => Text(line, style: effectiveStyle)),
        if (!_isComplete)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_currentLine, style: effectiveStyle),
              if (widget.showCursor)
                _BlinkingCursor(
                  cursor: '|',
                  style: effectiveStyle,
                ),
            ],
          ),
      ],
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  final String cursor;
  final TextStyle style;

  const _BlinkingCursor({
    required this.cursor,
    required this.style,
  });

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: Text(
            widget.cursor,
            style: widget.style.copyWith(
              color: widget.style.color?.withValues(alpha: 0.7),
            ),
          ),
        );
      },
    );
  }
}
