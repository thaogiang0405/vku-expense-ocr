import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;

  const ExpenseCard({super.key, required this.expense, this.onTap});

  String _getCategoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return 'Ăn uống';
      case ExpenseCategory.study:
        return 'Học tập';
      case ExpenseCategory.travel:
        return 'Đi lại';
      case ExpenseCategory.gear:
        return 'Đồ dùng';
      case ExpenseCategory.entertainment:
        return 'Giải trí';
      case ExpenseCategory.salary:
        return 'Lương';
      case ExpenseCategory.overtime:
        return 'Làm thêm';
      case ExpenseCategory.familySupport:
        return 'Gia đình hỗ trợ';
      case ExpenseCategory.bonus:
        return 'Tiền thưởng';
      case ExpenseCategory.otherIncome:
        return 'Thu nhập khác';
      default:
        return 'Khác';
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.study:
        return Icons.school;
      case ExpenseCategory.travel:
        return Icons.directions_car;
      case ExpenseCategory.gear:
        return Icons.devices;
      case ExpenseCategory.entertainment:
        return Icons.sports_esports;
      case ExpenseCategory.salary:
        return Icons.work;
      case ExpenseCategory.overtime:
        return Icons.more_time;
      case ExpenseCategory.familySupport:
        return Icons.family_restroom;
      case ExpenseCategory.bonus:
        return Icons.card_giftcard;
      case ExpenseCategory.otherIncome:
        return Icons.add_circle;
      default:
        return Icons.receipt_long;
    }
  }

  Color _getCategoryColor(ExpenseCategory category) {
    if (expense.type == TransactionType.income) return Colors.green;
    switch (category) {
      case ExpenseCategory.food:
        return Colors.orange;
      case ExpenseCategory.study:
        return Colors.blue;
      case ExpenseCategory.travel:
        return Colors.green;
      case ExpenseCategory.gear:
        return Colors.purple;
      case ExpenseCategory.entertainment:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');
    final isIncome = expense.type == TransactionType.income;
    final amountPrefix = isIncome ? '+' : '-';
    final amountColor = isIncome
        ? Colors.green
        : Theme.of(context).colorScheme.error;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.3),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(expense.category)
              .withValues(alpha: 0.2),
          child: Icon(
            _getCategoryIcon(expense.category),
            color: _getCategoryColor(expense.category),
          ),
        ),
        title: Text(
          expense.merchant,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          expense.note ?? _getCategoryName(expense.category),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '$amountPrefix${currencyFormat.format(expense.amount)} đ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: amountColor,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
