import 'package:arcane/arcane.dart';

class DottedDivider extends StatelessWidget {
  final Color color;
  final double height;
  final double dashLength;
  final double gapLength;
  final double indent;
  final double endIndent;

  const DottedDivider({
    Key? key,
    this.color = const Color(0xFF000000),
    this.height = 1,
    this.dashLength = 5,
    this.gapLength = 3,
    this.indent = 0,
    this.endIndent = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent, right: endIndent),
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: DottedLinePainter(
          color: color,
          strokeWidth: height,
          dashLength: dashLength,
          gapLength: gapLength,
          isHorizontal: true,
        ),
      ),
    );
  }
}

class DottedVerticalDivider extends StatelessWidget {
  final Color color;
  final double width;
  final double dashLength;
  final double gapLength;
  final double indent;
  final double endIndent;

  const DottedVerticalDivider({
    Key? key,
    this.color = const Color(0xFF000000),
    this.width = 1,
    this.dashLength = 5,
    this.gapLength = 3,
    this.indent = 0,
    this.endIndent = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: indent, bottom: endIndent),
      child: CustomPaint(
        size: Size(width, double.infinity),
        painter: DottedLinePainter(
          color: color,
          strokeWidth: width,
          dashLength: dashLength,
          gapLength: gapLength,
          isHorizontal: false,
        ),
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final bool isHorizontal;

  DottedLinePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
    required this.isHorizontal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isHorizontal) {
      _drawHorizontalDottedLine(canvas, size, paint);
    } else {
      _drawVerticalDottedLine(canvas, size, paint);
    }
  }

  void _drawHorizontalDottedLine(Canvas canvas, Size size, Paint paint) {
    double startX = 0;
    final y = size.height / 2;

    while (startX < size.width) {
      final endX = (startX + dashLength).clamp(0.0, size.width);
      canvas.drawLine(
        Offset(startX, y),
        Offset(endX, y),
        paint,
      );
      startX += dashLength + gapLength;
    }
  }

  void _drawVerticalDottedLine(Canvas canvas, Size size, Paint paint) {
    double startY = 0;
    final x = size.width / 2;

    while (startY < size.height) {
      final endY = (startY + dashLength).clamp(0.0, size.height);
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, endY),
        paint,
      );
      startY += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(DottedLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength ||
        oldDelegate.isHorizontal != isHorizontal;
  }
}
