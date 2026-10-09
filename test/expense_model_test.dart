import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/expense.dart';

void main() {
  group('Expense Model Tests', () {
    test('toMap() converts correctly', () {
      final date = DateTime(2026, 10, 8);
      final expense = Expense(
        id: 1,
        merchant: 'Test Shop',
        amount: 50000,
        date: date,
        category: ExpenseCategory.food,
        receiptImagePath: '/path/to/image.jpg',
      );

      final map = expense.toMap();

      expect(map['id'], 1);
      expect(map['merchant'], 'Test Shop');
      expect(map['amount'], 50000.0);
      expect(map['date'], date.toIso8601String());
      expect(map['category'], 'food');
      expect(map['imagePath'], '/path/to/image.jpg');
    });

    test('fromMap() converts correctly with all fields', () {
      final date = DateTime(2026, 10, 8);
      final map = {
        'id': 2,
        'merchant': 'Tech Store',
        'amount': 1500000.0,
        'date': date.toIso8601String(),
        'category': 'gear',
        'imagePath': '/assets/receipt.png',
      };

      final expense = Expense.fromMap(map);

      expect(expense.id, 2);
      expect(expense.merchant, 'Tech Store');
      expect(expense.amount, 1500000.0);
      expect(expense.date, date);
      expect(expense.category, ExpenseCategory.gear);
      expect(expense.receiptImagePath, '/assets/receipt.png');
    });

    test('fromMap() handles missing imagePath and id', () {
      final date = DateTime(2026, 10, 9);
      final map = {
        'merchant': 'Coffee Shop',
        'amount': 30000.0,
        'date': date.toIso8601String(),
        'category': 'food',
      };

      final expense = Expense.fromMap(map);

      expect(expense.id, isNull);
      expect(expense.merchant, 'Coffee Shop');
      expect(expense.amount, 30000.0);
      expect(expense.receiptImagePath, isNull);
    });

    test('fromMap() does not crash on invalid date and provides fallback', () {
      final map = {
        'merchant': 'Buggy Shop',
        'amount': 100.0,
        'date': 'INVALID_DATE',
        'category': 'other',
      };

      final expense = Expense.fromMap(map);

      expect(expense.merchant, 'Buggy Shop');
      // Should fallback to DateTime.now() - roughly check it's within recent time
      expect(DateTime.now().difference(expense.date).inMinutes, lessThan(1));
    });

    test('fromMap() falls back to other if category is invalid', () {
      final map = {
        'merchant': 'Unknown Cat',
        'amount': 100.0,
        'date': DateTime.now().toIso8601String(),
        'category': 'unknown_weird_category',
      };

      final expense = Expense.fromMap(map);
      expect(expense.category, ExpenseCategory.other);
    });
  });
}
