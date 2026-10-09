import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../models/expense.dart';

class WeeklyBarChart extends StatefulWidget {
  final List<Expense> expenses;
  final DateTime referenceDate;

  const WeeklyBarChart({
    super.key,
    required this.expenses,
    required this.referenceDate,
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.referenceDate != widget.referenceDate) {
      _selectedIndex = null;
    }
  }

  void _handleTap(TapUpDetails details, BoxConstraints constraints) {
    const double leftMargin = 45.0;
    const double rightMargin = 10.0;
    final double width = constraints.maxWidth;
    final double chartWidth = width - leftMargin - rightMargin;

    final double x = details.localPosition.dx - leftMargin;
    if (x >= 0 && x <= chartWidth) {
      final double stepX = chartWidth / 7;
      final int tappedIndex = (x / stepX).floor();
      if (tappedIndex >= 0 && tappedIndex < 7) {
        setState(() {
          _selectedIndex = _selectedIndex == tappedIndex ? null : tappedIndex;
        });
        return;
      }
    }

    setState(() {
      _selectedIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Generate the last 7 days ending on referenceDate
    final List<DateTime> last7Days = List.generate(
      7,
      (index) => widget.referenceDate.subtract(Duration(days: 6 - index)),
    );

    final List<String> xLabels = last7Days.map((d) {
      final today = DateTime.now();
      if (d.year == today.year &&
          d.month == today.month &&
          d.day == today.day) {
        return 'Hôm nay';
      }
      return _getVietnameseWeekday(d.weekday);
    }).toList();

    final List<double> dailyIncomes = List.filled(7, 0.0);
    final List<double> dailyExpenses = List.filled(7, 0.0);

    for (var expense in widget.expenses) {
      for (int i = 0; i < 7; i++) {
        final d = last7Days[i];
        if (expense.date.year == d.year &&
            expense.date.month == d.month &&
            expense.date.day == d.day) {
          if (expense.type == TransactionType.income) {
            dailyIncomes[i] += expense.amount;
          } else {
            dailyExpenses[i] += expense.amount;
          }
          break;
        }
      }
    }

    double maxVal = 0.0;
    for (int i = 0; i < 7; i++) {
      maxVal = max(maxVal, dailyIncomes[i]);
      maxVal = max(maxVal, dailyExpenses[i]);
    }
    if (maxVal == 0) maxVal = 1.0;

    // Add 10% padding
    final double maxAmount = maxVal * 1.1;

    final colorScheme = Theme.of(context).colorScheme;
    final axisColor = colorScheme.outline;
    final textColor = colorScheme.onSurface;

    final currencyFormat = NumberFormat('#,##0', 'vi_VN');

    return Column(
      children: [
        // Selection Info Area
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          height: 65,
          child: _selectedIndex != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${last7Days[_selectedIndex!].day}/${last7Days[_selectedIndex!].month}/${last7Days[_selectedIndex!].year}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '+${currencyFormat.format(dailyIncomes[_selectedIndex!])} đ',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '-${currencyFormat.format(dailyExpenses[_selectedIndex!])} đ',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.error,
                              ),
                        ),
                      ],
                    ),
                  ],
                )
              : Center(
                  child: Text(
                    'Chạm vào cột để xem chi tiết',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
        ),

        // Chart Area
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              onTapUp: (details) => _handleTap(details, constraints),
              child: SizedBox(
                width: double.infinity,
                height: 220,
                child: CustomPaint(
                  painter: _WeeklyBarChartPainter(
                    dailyIncomes: dailyIncomes,
                    dailyExpenses: dailyExpenses,
                    xLabels: xLabels,
                    maxAmount: maxAmount,
                    incomeColor: Colors.green,
                    expenseColor: colorScheme.error,
                    axisColor: axisColor,
                    textColor: textColor,
                    selectedIndex: _selectedIndex,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _getVietnameseWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }
}

class _WeeklyBarChartPainter extends CustomPainter {
  final List<double> dailyIncomes;
  final List<double> dailyExpenses;
  final List<String> xLabels;
  final double maxAmount;
  final Color incomeColor;
  final Color expenseColor;
  final Color axisColor;
  final Color textColor;
  final int? selectedIndex;

  _WeeklyBarChartPainter({
    required this.dailyIncomes,
    required this.dailyExpenses,
    required this.xLabels,
    required this.maxAmount,
    required this.incomeColor,
    required this.expenseColor,
    required this.axisColor,
    required this.textColor,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintAxis = Paint()
      ..color = axisColor.withAlpha(100)
      ..strokeWidth = 1.0;

    const double leftMargin = 45.0;
    const double bottomMargin = 30.0;
    const double topMargin = 20.0;
    const double rightMargin = 10.0;

    final chartWidth = size.width - leftMargin - rightMargin;
    final chartHeight = size.height - topMargin - bottomMargin;

    canvas.drawLine(
      Offset(leftMargin, topMargin),
      Offset(leftMargin, size.height - bottomMargin),
      paintAxis,
    );
    canvas.drawLine(
      Offset(leftMargin, size.height - bottomMargin),
      Offset(size.width - rightMargin, size.height - bottomMargin),
      paintAxis,
    );

    final int yAxisDivisions = 4;
    for (int i = 0; i <= yAxisDivisions; i++) {
      final double value = (maxAmount / yAxisDivisions) * i;
      final double yPos =
          (size.height - bottomMargin) - (chartHeight / yAxisDivisions) * i;

      if (i > 0) {
        canvas.drawLine(
          Offset(leftMargin, yPos),
          Offset(size.width - rightMargin, yPos),
          Paint()
            ..color = axisColor.withAlpha(50)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke,
        );
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: _formatAmount(value),
          style: TextStyle(color: textColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          leftMargin - textPainter.width - 8,
          yPos - textPainter.height / 2,
        ),
      );
    }

    final int numBars = dailyIncomes.length;
    final double stepX = chartWidth / numBars;
    // Each day has two bars side by side
    final double totalBarGroupWidth = stepX * 0.7;
    final double barWidth = totalBarGroupWidth / 2.1;

    for (int i = 0; i < numBars; i++) {
      final isSelected = selectedIndex == i;
      final isAnySelected = selectedIndex != null;

      final double income = dailyIncomes[i];
      final double expense = dailyExpenses[i];

      final double incomeHeight = (income / maxAmount) * chartHeight;
      final double expenseHeight = (expense / maxAmount) * chartHeight;

      final double groupXPos =
          leftMargin + (i * stepX) + (stepX - totalBarGroupWidth) / 2;

      // Draw Income Bar
      if (incomeHeight > 0) {
        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            groupXPos,
            (size.height - bottomMargin) - incomeHeight,
            barWidth,
            incomeHeight,
          ),
          const Radius.circular(4.0),
        );
        final paintBar = Paint()
          ..style = PaintingStyle.fill
          ..color = isSelected
              ? incomeColor
              : (isAnySelected
                    ? incomeColor.withValues(alpha: 0.4)
                    : incomeColor);
        canvas.drawRRect(rrect, paintBar);
      }

      // Draw Expense Bar
      if (expenseHeight > 0) {
        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            groupXPos + barWidth + 2,
            (size.height - bottomMargin) - expenseHeight,
            barWidth,
            expenseHeight,
          ),
          const Radius.circular(4.0),
        );
        final paintBar = Paint()
          ..style = PaintingStyle.fill
          ..color = isSelected
              ? expenseColor
              : (isAnySelected
                    ? expenseColor.withValues(alpha: 0.4)
                    : expenseColor);
        canvas.drawRRect(rrect, paintBar);
      }

      final labelColor = isSelected
          ? textColor
          : textColor.withValues(alpha: 0.6);
      final fontWeight = isSelected ? FontWeight.bold : FontWeight.normal;

      final textPainter = TextPainter(
        text: TextSpan(
          text: xLabels[i],
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: fontWeight,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          groupXPos + (totalBarGroupWidth - textPainter.width) / 2,
          size.height - bottomMargin + 8,
        ),
      );
    }
  }

  String _formatAmount(double value) {
    if (value == 0) return '0';
    if (value >= 1000000) {
      String formatted = (value / 1000000).toStringAsFixed(1);
      if (formatted.endsWith('.0')) {
        formatted = formatted.substring(0, formatted.length - 2);
      }
      return '${formatted}M';
    } else if (value >= 1000) {
      String formatted = (value / 1000).toStringAsFixed(0);
      return '${formatted}K';
    }
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.maxAmount != maxAmount ||
        oldDelegate.incomeColor != incomeColor ||
        oldDelegate.expenseColor != expenseColor ||
        oldDelegate.axisColor != axisColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.selectedIndex != selectedIndex ||
        !_listEquals(oldDelegate.dailyIncomes, dailyIncomes) ||
        !_listEquals(oldDelegate.dailyExpenses, dailyExpenses) ||
        !_listEquals(oldDelegate.xLabels, xLabels);
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
