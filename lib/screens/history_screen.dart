import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_card.dart';
import 'expense_detail_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';
  ExpenseCategory? _selectedCategory;
  String _selectedDateRange =
      'Tất cả'; // 'Tất cả', 'Hôm nay', '7 ngày qua', 'Tháng này', 'Tùy chỉnh'
  String _selectedType = 'Tất cả'; // 'Tất cả', 'Thu nhập', 'Chi tiêu'
  DateTime? _startDate;
  DateTime? _endDate;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedDateRange = 'Tùy chỉnh';
      });
    }
  }

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

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = null;
      _selectedDateRange = 'Tất cả';
      _selectedType = 'Tất cả';
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncExpenses = ref.watch(expenseProvider);
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            onPressed: _clearFilters,
            tooltip: 'Xóa bộ lọc',
          ),
        ],
      ),
      body: asyncExpenses.when(
        data: (expenses) {
          final filtered = expenses.where((e) {
            // Type filter
            if (_selectedType == 'Thu nhập' && e.type != TransactionType.income)
              return false;
            if (_selectedType == 'Chi tiêu' &&
                e.type != TransactionType.expense)
              return false;

            // Text search
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              final textMatch =
                  e.merchant.toLowerCase().contains(query) ||
                  (e.note?.toLowerCase().contains(query) ?? false);
              if (!textMatch) return false;
            }

            // Category filter
            if (_selectedCategory != null && e.category != _selectedCategory) {
              return false;
            }

            // Date filter
            final today = DateTime.now();
            final date = e.date;
            final justDate = DateTime(date.year, date.month, date.day);
            final justToday = DateTime(today.year, today.month, today.day);

            switch (_selectedDateRange) {
              case 'Hôm nay':
                if (justDate != justToday) return false;
                break;
              case '7 ngày qua':
                if (justDate.isBefore(
                  justToday.subtract(const Duration(days: 7)),
                )) {
                  return false;
                }
                break;
              case 'Tháng này':
                if (date.year != today.year || date.month != today.month) {
                  return false;
                }
                break;
              case 'Tùy chỉnh':
                if (_startDate != null && _endDate != null) {
                  final start = DateTime(
                    _startDate!.year,
                    _startDate!.month,
                    _startDate!.day,
                  );
                  final end = DateTime(
                    _endDate!.year,
                    _endDate!.month,
                    _endDate!.day,
                  );
                  if (justDate.isBefore(start) || justDate.isAfter(end)) {
                    return false;
                  }
                }
                break;
            }

            return true;
          }).toList();

          final totalIncome = filtered
              .where((e) => e.type == TransactionType.income)
              .fold(0.0, (sum, item) => sum + item.amount);
          final totalExpense = filtered
              .where((e) => e.type == TransactionType.expense)
              .fold(0.0, (sum, item) => sum + item.amount);

          return Column(
            children: [
              // Filters Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Tìm kiếm tên hoặc ghi chú...',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedType,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Loại GD',
                              border: OutlineInputBorder(),
                            ),
                            items: ['Tất cả', 'Thu nhập', 'Chi tiêu'].map((
                              String value,
                            ) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedType = newValue;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedDateRange,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Thời gian',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                [
                                  'Tất cả',
                                  'Hôm nay',
                                  '7 ngày qua',
                                  'Tháng này',
                                  'Tùy chỉnh',
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                if (newValue == 'Tùy chỉnh') {
                                  _pickCustomDateRange();
                                } else {
                                  setState(() {
                                    _selectedDateRange = newValue;
                                    _startDate = null;
                                    _endDate = null;
                                  });
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ExpenseCategory?>(
                      value: _selectedCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<ExpenseCategory?>(
                          value: null,
                          child: Text('Tất cả danh mục'),
                        ),
                        ...ExpenseCategory.values.map((cat) {
                          return DropdownMenuItem<ExpenseCategory?>(
                            value: cat,
                            child: Text(_getCategoryName(cat)),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Summary
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tìm thấy (${filtered.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (totalIncome > 0)
                          Text(
                            '+${currencyFormat.format(totalIncome)} đ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        if (totalExpense > 0)
                          Text(
                            '-${currencyFormat.format(totalExpense)} đ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        if (totalIncome == 0 && totalExpense == 0)
                          const Text(
                            '0 đ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Không có giao dịch nào phù hợp.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final expense = filtered[index];
                          return ExpenseCard(
                            expense: expense,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ExpenseDetailScreen(
                                    expenseId: expense.id!,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text('Lỗi tải dữ liệu')),
      ),
    );
  }
}
