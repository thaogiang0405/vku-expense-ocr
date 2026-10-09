import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/widgets/expense_card.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN', null);
  });

  testWidgets('ExpenseCard displays correct info', (WidgetTester tester) async {
    final date = DateTime(2026, 10, 9);
    final expense = Expense(
      id: 1,
      merchant: 'TEST MERCHANT 123',
      amount: 150000.0,
      date: date,
      category: ExpenseCategory.food,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ExpenseCard(expense: expense)),
      ),
    );

    // Verify Merchant
    expect(find.text('TEST MERCHANT 123'), findsOneWidget);

    // Verify Amount (formatted)
    expect(find.textContaining('150.000'), findsOneWidget);

    // Verify Category Name
    expect(find.text('Ăn uống'), findsOneWidget);

    // Verify Category Icon
    expect(
      find.byIcon(Icons.restaurant),
      findsOneWidget,
    ); // Food category uses Icons.restaurant
  });
}
