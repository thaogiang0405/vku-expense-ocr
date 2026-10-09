import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/widgets/weekly_bar_chart.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN', null);
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('WeeklyBarChart renders empty data correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        WeeklyBarChart(
          expenses: const [],
          referenceDate: DateTime(2026, 10, 9),
        ),
      ),
    );

    // Initial state: no column selected
    expect(find.text('Chạm vào cột để xem chi tiết'), findsOneWidget);
  });

  testWidgets('WeeklyBarChart handles column selection', (
    WidgetTester tester,
  ) async {
    final referenceDate = DateTime(2026, 10, 9);
    final expense = Expense(
      id: 1,
      merchant: 'Test',
      amount: 150000,
      date: referenceDate, // Today
      category: ExpenseCategory.food,
    );

    await tester.pumpWidget(
      buildTestableWidget(
        WeeklyBarChart(expenses: [expense], referenceDate: referenceDate),
      ),
    );

    expect(find.text('Chạm vào cột để xem chi tiết'), findsOneWidget);

    // Find the GestureDetector directly
    final gestureDetectorFinder = find.byType(GestureDetector);
    expect(gestureDetectorFinder, findsOneWidget);

    final rect = tester.getRect(gestureDetectorFinder);

    // Tap on the right-most area (which corresponds to today, index 6)
    // leftMargin = 45, rightMargin = 10
    final dx = rect.right - 20;
    final dy = rect.center.dy;

    await tester.tapAt(Offset(dx, dy));
    await tester.pumpAndSettle();

    // Now it should show the date and amount instead of the placeholder
    expect(find.text('Chạm vào cột để xem chi tiết'), findsNothing);

    // We expect the amount to be formatted as '150.000 đ' (based on vi_VN NumberFormat)
    expect(find.textContaining('150.000'), findsOneWidget);

    // The date for index 6 should be 9/10/2026
    expect(find.textContaining('9/10/2026'), findsOneWidget);

    // Tap again to unselect
    await tester.tapAt(Offset(dx, dy));
    await tester.pumpAndSettle();

    expect(find.text('Chạm vào cột để xem chi tiết'), findsOneWidget);
  });
}
