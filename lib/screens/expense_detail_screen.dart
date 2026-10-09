import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../models/parsed_receipt.dart';
import '../providers/expense_provider.dart';
import 'review_screen.dart';
import 'income_screen.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final int expenseId;

  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  Expense? _expense;

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
        return 'Tiền gia đình hỗ trợ';
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

  void _editExpense() async {
    if (_expense == null) return;

    if (_expense!.type == TransactionType.income) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IncomeScreen(existingIncome: _expense),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewScreen(
            parsedData: ParsedReceipt(
              merchant: _expense!.merchant,
              total: _expense!.amount,
              date: _expense!.date,
              rawText: '',
            ),
            imagePath: _expense!.receiptImagePath ?? '',
            existingExpense: _expense,
          ),
        ),
      );
    }
  }

  void _deleteExpense() async {
    if (_expense == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa giao dịch này?'),
        content: const Text('Bạn có chắc chắn muốn xóa khoản chi này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(expenseProvider.notifier).deleteExpense(_expense!.id!);
      if (mounted) {
        Navigator.pop(context); // Go back after delete
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncExpenses = ref.watch(expenseProvider);

    return asyncExpenses.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Chi tiết')),
        body: const Center(child: Text('Lỗi tải dữ liệu')),
      ),
      data: (expenses) {
        Expense? expense;
        try {
          expense = expenses.firstWhere((e) => e.id == widget.expenseId);
        } catch (_) {
          expense = null;
        }

        if (expense == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chi tiết')),
            body: const Center(
              child: Text('Không tìm thấy giao dịch hoặc đã bị xóa.'),
            ),
          );
        }

        // We update the local variable for Edit/Delete functions to use
        _expense = expense;

        final currencyFormat = NumberFormat('#,##0', 'vi_VN');
        final dateFormat = DateFormat('dd/MM/yyyy - HH:mm');

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chi tiết giao dịch'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _editExpense,
                tooltip: 'Sửa',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteExpense,
                tooltip: 'Xóa',
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Area
                if (_expense!.type == TransactionType.expense &&
                    _expense!.receiptImagePath != null)
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.black12,
                    child: FutureBuilder<bool>(
                      future: File(_expense!.receiptImagePath!).exists(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.data == true) {
                          return InteractiveViewer(
                            child: Image.file(
                              File(_expense!.receiptImagePath!),
                              fit: BoxFit.contain,
                            ),
                          );
                        } else {
                          return const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Ảnh hóa đơn không còn tồn tại.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  )
                else if (_expense!.type == TransactionType.expense)
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Không có ảnh hóa đơn',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Details Area
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_expense!.note != null) ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.notes),
                          title: const Text('Ghi chú'),
                          subtitle: Text(
                            _expense!.note!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Divider(height: 16),
                      ],
                      Text(
                        'Số tiền',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currencyFormat.format(_expense!.amount)} đ',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const Divider(height: 32),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.store),
                        title: const Text('Người bán / Cửa hàng'),
                        subtitle: Text(
                          _expense!.merchant,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Divider(height: 16),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Ngày giao dịch'),
                        subtitle: Text(
                          dateFormat.format(_expense!.date),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Divider(height: 16),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(_getCategoryIcon(_expense!.category)),
                        title: const Text('Danh mục'),
                        subtitle: Text(
                          _getCategoryName(_expense!.category),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
