import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:vku_expense_ocr/database/database_helper.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/providers/expense_provider.dart';

void main() {
  late ProviderContainer container;
  late DatabaseHelper dbHelper;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    databaseFactory.setDatabasesPath('test_expense_provider');
  });

  setUp(() async {
    dbHelper = DatabaseHelper();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expenses.db');
    if (await File(path).exists()) {
      // await databaseFactory.deleteDatabase(path);
    }
    final db = await dbHelper.database;
    await db.execute('DELETE FROM expenses');

    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('ExpenseProvider initial load is empty', () async {
    // Wait for the provider to complete initial load
    final asyncValue = await container.read(expenseProvider.future);
    expect(asyncValue, isEmpty);
  });

  test('ExpenseProvider insert updates state', () async {
    // Read the notifier
    final notifier = container.read(expenseProvider.notifier);

    // Insert
    final expense = Expense(
      merchant: "Test Provider Store",
      amount: 50000,
      date: DateTime(2026, 10, 8),
      category: ExpenseCategory.food,
    );
    await notifier.addExpense(expense);

    // Wait for state refresh
    final list = await container.read(expenseProvider.future);
    expect(list.length, 1);
    expect(list.first.merchant, "Test Provider Store");
  });

  test('ExpenseProvider delete updates state', () async {
    final notifier = container.read(expenseProvider.notifier);

    final expense = Expense(
      merchant: "Store to Delete",
      amount: 100000,
      date: DateTime(2026, 10, 8),
      category: ExpenseCategory.other,
    );
    await notifier.addExpense(expense);

    var list = await container.read(expenseProvider.future);
    expect(list.length, 1);
    final id = list.first.id!;

    await notifier.deleteExpense(id);

    list = await container.read(expenseProvider.future);
    expect(list, isEmpty);
  });
}
