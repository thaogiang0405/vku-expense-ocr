import 'package:flutter/material.dart';

class CameraOverlay extends StatelessWidget {
  const CameraOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    // Ignore pointer để gesture detector phía dưới (tap to focus) có thể nhận được sự kiện
    return IgnorePointer(
      child: CustomPaint(
        painter: OverlayPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Vẽ màn chắn đen mờ nhưng chừa khoảng trống ở giữa
    final backgroundPaint = Paint()..color = Colors.black54;

    final double boxWidth = size.width * 0.8;
    final double boxHeight = size.height * 0.65;
    final double left = (size.width - boxWidth) / 2;
    final double top = (size.height - boxHeight) / 2;
    final rect = Rect.fromLTWH(left, top, boxWidth, boxHeight);

    // Sử dụng Path.combine hoặc fillType evenOdd để đục lỗ trong suốt
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, backgroundPaint);

    // 2. Vẽ 4 góc định vị (brackets) màu xanh (teal)
    final cornerPaint = Paint()
      ..color = Colors.tealAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 30.0;

    // Top-left
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + cornerLength),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(left + boxWidth, top),
      Offset(left + boxWidth - cornerLength, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + boxWidth, top),
      Offset(left + boxWidth, top + cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(left, top + boxHeight),
      Offset(left + cornerLength, top + boxHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + boxHeight),
      Offset(left, top + boxHeight - cornerLength),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(left + boxWidth, top + boxHeight),
      Offset(left + boxWidth - cornerLength, top + boxHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + boxWidth, top + boxHeight),
      Offset(left + boxWidth, top + boxHeight - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
