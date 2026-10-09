import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:vku_expense_ocr/database/database_helper.dart';
import 'package:vku_expense_ocr/models/expense.dart';

void main() {
  late DatabaseHelper dbHelper;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    databaseFactory.setDatabasesPath('test_db_helper');
  });

  setUp(() async {
    dbHelper = DatabaseHelper();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expenses.db');
    if (await File(path).exists()) {
      // await databaseFactory.deleteDatabase(path);
    }
    // Need to reset singleton _database reference.
    // However since we can't reset the static variable easily from outside,
    // the cleanest way without changing the app code is to just truncate the table.
    final db = await dbHelper.database;
    await db.execute('DELETE FROM expenses');
  });

  test('Database CRUD Operations', () async {
    // 1. Insert
    final expense = Expense(
      merchant: "Test Store",
      amount: 150000,
      date: DateTime(2026, 10, 8),
      category: ExpenseCategory.food,
    );

    final id = await dbHelper.insertExpense(expense);
    expect(id, isNotNull);
    expect(id, greaterThan(0));

    // 2. Count
    final count = await dbHelper.getExpenseCount();
    expect(count, 1);

    // 3. Read
    final expenses = await dbHelper.getExpenses();
    expect(expenses.length, 1);
    expect(expenses.first.merchant, "Test Store");
    expect(expenses.first.amount, 150000);
    expect(expenses.first.category, ExpenseCategory.food);

    // 4. Read by ID
    final fetched = await dbHelper.getExpenseById(id);
    expect(fetched, isNotNull);
    expect(fetched!.merchant, "Test Store");

    // 5. Update
    final updatedExpense = Expense(
      id: id,
      merchant: "Updated Store",
      amount: 200000,
      date: DateTime(2026, 10, 8),
      category: ExpenseCategory.study,
    );
    await dbHelper.updateExpense(updatedExpense);

    final fetchedUpdated = await dbHelper.getExpenseById(id);
    expect(fetchedUpdated!.merchant, "Updated Store");
    expect(fetchedUpdated.amount, 200000);
    expect(fetchedUpdated.category, ExpenseCategory.study);

    // 6. Delete
    await dbHelper.deleteExpense(id);
    final countAfterDelete = await dbHelper.getExpenseCount();
    expect(countAfterDelete, 0);

    // 7. Total
    final db = await dbHelper.database;
    await db.execute('DELETE FROM expenses');
    await dbHelper.insertExpense(
      Expense(
        merchant: 'A',
        amount: 100000,
        date: DateTime.now(),
        category: ExpenseCategory.food,
      ),
    );
    await dbHelper.insertExpense(
      Expense(
        merchant: 'B',
        amount: 200000,
        date: DateTime.now(),
        category: ExpenseCategory.food,
      ),
    );
    await dbHelper.insertExpense(
      Expense(
        merchant: 'C',
        amount: 300000,
        date: DateTime.now(),
        category: ExpenseCategory.food,
      ),
    );
    final total = await dbHelper.getTotalExpense();
    expect(total, 600000.0);
  });
}
