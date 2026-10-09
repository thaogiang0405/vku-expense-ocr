import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';

class IncomeScreen extends ConsumerStatefulWidget {
  final Expense? existingIncome;

  const IncomeScreen({super.key, this.existingIncome});

  @override
  ConsumerState<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends ConsumerState<IncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  ExpenseCategory _selectedCategory = ExpenseCategory.salary;
  bool _isSaving = false;

  final currencyFormat = NumberFormat('#,##0', 'vi_VN');

  @override
  void initState() {
    super.initState();
    if (widget.existingIncome != null) {
      _amountController.text = widget.existingIncome!.amount.toInt().toString();
      _merchantController.text = widget.existingIncome!.merchant;
      _noteController.text = widget.existingIncome!.note ?? '';
      _selectedDate = widget.existingIncome!.date;
      _selectedCategory = widget.existingIncome!.category;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _getCategoryName(ExpenseCategory category) {
    switch (category) {
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

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountStr) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Số tiền phải lớn hơn 0')));
      setState(() {
        _isSaving = false;
      });
      return;
    }

    final income = Expense(
      id: widget.existingIncome?.id,
      merchant: _merchantController.text.trim(),
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
      type: TransactionType.income,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      isSample: widget.existingIncome?.isSample ?? 0,
    );

    if (widget.existingIncome == null) {
      await ref.read(expenseProvider.notifier).addExpense(income);
    } else {
      await ref.read(expenseProvider.notifier).updateExpense(income);
    }

    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final incomeCategories = [
      ExpenseCategory.salary,
      ExpenseCategory.overtime,
      ExpenseCategory.familySupport,
      ExpenseCategory.bonus,
      ExpenseCategory.otherIncome,
    ];

    final isEdit = widget.existingIncome != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Sửa khoản thu' : 'Thêm khoản thu')),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số tiền (VNĐ)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty)
                          return 'Vui lòng nhập số tiền';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _merchantController,
                      decoration: const InputDecoration(
                        labelText: 'Tên khoản thu',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty)
                          return 'Vui lòng nhập tên khoản thu';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày nhận tiền',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ExpenseCategory>(
                      value: incomeCategories.contains(_selectedCategory)
                          ? _selectedCategory
                          : incomeCategories.first,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: incomeCategories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(_getCategoryName(cat)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú (không bắt buộc)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'LƯU KHOẢN THU',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
