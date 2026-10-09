import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DonutChart extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final Map<String, Color> categoryColors;
  final double total;

  const DonutChart({
    super.key,
    required this.categoryTotals,
    required this.categoryColors,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _DonutChartPainter(
                  categoryTotals: categoryTotals,
                  categoryColors: categoryColors,
                  total: total,
                ),
              ),
              // Center Text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${currencyFormat.format(total)} đ',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<String, double> categoryTotals;
  final Map<String, Color> categoryColors;
  final double total;

  _DonutChartPainter({
    required this.categoryTotals,
    required this.categoryColors,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final strokeWidth = radius * 0.3; // 30% of radius is stroke

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    double startAngle = -pi / 2; // Start from top
    final hasMultipleCategories = categoryTotals.length > 1;
    // Tiny gap in radians (only if multiple categories exist)
    final gapAngle = hasMultipleCategories ? 0.05 : 0.0;

    for (final entry in categoryTotals.entries) {
      final category = entry.key;
      final amount = entry.value;

      if (amount <= 0) continue;

      final percentage = amount / total;
      final sweepAngle = (percentage * 2 * pi);
      final drawSweepAngle = hasMultipleCategories
          ? max(0.0, sweepAngle - gapAngle)
          : sweepAngle;

      final paint = Paint()
        ..color = categoryColors[category] ?? Colors.grey
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt; // Flat ends make gaps look better

      canvas.drawArc(rect, startAngle, drawSweepAngle, false, paint);

      // Move start angle forward by the full sweep amount (including gap space)
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.total != total ||
        oldDelegate.categoryTotals != categoryTotals;
  }
}
