import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../widgets/donut_chart.dart';
import '../widgets/weekly_bar_chart.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  Color _getCategoryColor(ExpenseCategory category) {
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
      case ExpenseCategory.salary:
        return Colors.blueAccent;
      case ExpenseCategory.overtime:
        return Colors.greenAccent;
      case ExpenseCategory.familySupport:
        return Colors.pinkAccent;
      case ExpenseCategory.bonus:
        return Colors.amber;
      case ExpenseCategory.otherIncome:
        return Colors.teal;
      default:
        return Colors.grey;
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

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseProvider);
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê'), centerTitle: true),
      body: expensesAsync.when(
        data: (allExpenses) {
          final expenses = allExpenses
              .where(
                (e) =>
                    e.date.year == _selectedMonth.year &&
                    e.date.month == _selectedMonth.month,
              )
              .toList();

          double totalIncome = 0;
          double totalExpense = 0;
          final Map<ExpenseCategory, double> expenseCategoryMap = {};

          for (final e in expenses) {
            if (e.type == TransactionType.income) {
              totalIncome += e.amount;
            } else {
              totalExpense += e.amount;
              expenseCategoryMap[e.category] =
                  (expenseCategoryMap[e.category] ?? 0) + e.amount;
            }
          }
          final balance = totalIncome - totalExpense;

          return Column(
            children: [
              // Month Switcher
              Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _previousMonth,
                    ),
                    Text(
                      'Tháng ${_selectedMonth.month}/${_selectedMonth.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
              ),

              // Totals
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Thu nhập',
                            style: TextStyle(color: Colors.green),
                          ),
                          Text(
                            '+${currencyFormat.format(totalIncome)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Chi tiêu',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          Text(
                            '-${currencyFormat.format(totalExpense)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Chênh lệch'),
                          Text(
                            currencyFormat.format(balance),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: expenses.isEmpty
                    ? _buildEmptyState()
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        children: [
                          // Weekly Bar Chart
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Thu & Chi 7 ngày qua',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    WeeklyBarChart(
                                      expenses: allExpenses, // Pass all for rolling 7 days
                                      referenceDate:
                                          DateTime.now(), // Fixed to now
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Pie Chart (Expenses Only)
                          if (totalExpense > 0) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'Phân bổ chi tiêu',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                final sortedEntries =
                                    expenseCategoryMap.entries.toList()..sort(
                                      (a, b) => b.value.compareTo(a.value),
                                    );
                                final Map<String, double> chartData = {};
                                final Map<String, Color> chartColors = {};
                                for (final entry in sortedEntries) {
                                  final name = _getCategoryName(entry.key);
                                  chartData[name] = entry.value;
                                  chartColors[name] = _getCategoryColor(
                                    entry.key,
                                  );
                                }

                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxHeight: 250,
                                        ),
                                        child: DonutChart(
                                          categoryTotals: chartData,
                                          categoryColors: chartColors,
                                          total: totalExpense,
                                        ),
                                      ),
                                    ),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: sortedEntries.length,
                                      itemBuilder: (context, index) {
                                        final entry = sortedEntries[index];
                                        final category = entry.key;
                                        final amount = entry.value;
                                        final percentage =
                                            (amount / totalExpense * 100)
                                                .round();

                                        return ListTile(
                                          leading: Icon(
                                            Icons.circle,
                                            color: _getCategoryColor(category),
                                          ),
                                          title: Text(
                                            _getCategoryName(category),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          trailing: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${currencyFormat.format(amount)} đ',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                '$percentage%',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            const Center(child: Text('Không thể tải dữ liệu thống kê.')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Chưa có dữ liệu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Hãy thêm các khoản thu/chi để xem thống kê.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
