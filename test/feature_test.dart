import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/database/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Migration & Advanced CRUD Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      await db.execute('DELETE FROM expenses');
    });

    test('Add expense with thumbnail and fetch by ID', () async {
      final expense = Expense(
        merchant: 'Test Store',
        amount: 50000,
        date: DateTime.now(),
        category: ExpenseCategory.food,
        receiptImagePath: '/test/image.jpg',
        receiptThumbnailPath: '/test/thumb.jpg',
      );

      final id = await dbHelper.insertExpense(expense);
      expect(id, isNotNull);

      final fetched = await dbHelper.getExpenseById(id);
      expect(fetched, isNotNull);
      expect(fetched!.merchant, 'Test Store');
      expect(fetched.receiptImagePath, '/test/image.jpg');
      expect(fetched.receiptThumbnailPath, '/test/thumb.jpg');
    });

    test('Update and Delete Expense', () async {
      final expense = Expense(
        merchant: 'To Be Updated',
        amount: 10000,
        date: DateTime.now(),
        category: ExpenseCategory.other,
      );
      final id = await dbHelper.insertExpense(expense);

      final updatedExpense = Expense(
        id: id,
        merchant: 'Updated Store',
        amount: 20000,
        date: DateTime.now(),
        category: ExpenseCategory.food,
      );
      await dbHelper.updateExpense(updatedExpense);

      final fetched = await dbHelper.getExpenseById(id);
      expect(fetched!.merchant, 'Updated Store');
      expect(fetched.amount, 20000);

      await dbHelper.deleteExpense(id);
      final deleted = await dbHelper.getExpenseById(id);
      expect(deleted, isNull);
    });

    test('Missing image path should be handled gracefully', () async {
      final expense = Expense(
        merchant: 'No Image Store',
        amount: 15000,
        date: DateTime.now(),
        category: ExpenseCategory.food,
        receiptImagePath: null,
      );
      final id = await dbHelper.insertExpense(expense);
      final fetched = await dbHelper.getExpenseById(id);
      expect(fetched!.receiptImagePath, isNull);
    });
  });
}
