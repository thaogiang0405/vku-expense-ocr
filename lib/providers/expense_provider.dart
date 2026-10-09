import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../database/database_helper.dart';

final expenseProvider = AsyncNotifierProvider<ExpenseNotifier, List<Expense>>(
  () {
    return ExpenseNotifier();
  },
);

class ExpenseNotifier extends AsyncNotifier<List<Expense>> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<List<Expense>> build() async {
    return _fetchExpenses();
  }

  Future<List<Expense>> _fetchExpenses() async {
    return await _dbHelper.getExpenses();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchExpenses());
  }

  Future<void> addExpense(Expense expense) async {
    // Optionally we can set state to loading, but it might flicker the UI
    // So we just execute and then refresh the list.
    await _dbHelper.insertExpense(expense);
    await refresh();
  }

  Future<void> deleteExpense(int id) async {
    final expense = await _dbHelper.getExpenseById(id);
    await _dbHelper.deleteExpense(id);

    if (expense != null) {
      if (expense.receiptImagePath != null) {
        // Check if shared
        final allExpenses = await _dbHelper.getExpenses();
        final isShared = allExpenses.any(
          (e) => e.receiptImagePath == expense.receiptImagePath,
        );
        if (!isShared) {
          try {
            final file = File(expense.receiptImagePath!);
            if (await file.exists()) await file.delete();
          } catch (e) {
            // ignore
          }
        }
      }
      if (expense.receiptThumbnailPath != null) {
        final allExpenses = await _dbHelper.getExpenses();
        final isShared = allExpenses.any(
          (e) => e.receiptThumbnailPath == expense.receiptThumbnailPath,
        );
        if (!isShared) {
          try {
            final file = File(expense.receiptThumbnailPath!);
            if (await file.exists()) await file.delete();
          } catch (e) {
            // ignore
          }
        }
      }
    }

    await refresh();
  }

  Future<void> updateExpense(Expense expense) async {
    await _dbHelper.updateExpense(expense);
    await refresh();
  }
}
