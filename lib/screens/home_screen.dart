import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_card.dart';
import 'camera_screen.dart';
import 'expense_detail_screen.dart';
import 'income_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.add_card, color: Colors.green),
                title: const Text('Thêm Thu Nhập'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IncomeScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.orange),
                title: const Text('Thêm Chi Tiêu (Chụp Hóa Đơn)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncExpenses = ref.watch(expenseProvider);
    final currencyFormat = NumberFormat('#,##0', 'vi_VN');

    return Scaffold(
      appBar: AppBar(title: const Text('Tổng quan')),
      body: asyncExpenses.when(
        data: (expenses) {
          final now = DateTime.now();
          final currentMonthExpenses = expenses
              .where(
                (e) => e.date.year == now.year && e.date.month == now.month,
              )
              .toList();

          double totalIncome = 0;
          double totalExpense = 0;
          for (var e in currentMonthExpenses) {
            if (e.type == TransactionType.income) {
              totalIncome += e.amount;
            } else {
              totalExpense += e.amount;
            }
          }
          final balance = totalIncome - totalExpense;

          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có giao dịch nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _showAddOptions,
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm giao dịch'),
                  ),
                ],
              ),
            );
          }

          // Group by Date
          final Map<String, List<Expense>> grouped = {};
          final dateFormat = DateFormat('dd/MM/yyyy');

          for (var expense in expenses) {
            final dateStr = dateFormat.format(expense.date);
            grouped.putIfAbsent(dateStr, () => []).add(expense);
          }

          final sortedDates = grouped.keys.toList()
            ..sort(
              (a, b) => dateFormat.parse(b).compareTo(dateFormat.parse(a)),
            );

          return CustomScrollView(
            slivers: [
              // Summary Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Balance Card
                      Card(
                        elevation: 0,
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                'Số dư tháng ${now.month}',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${currencyFormat.format(balance)} đ',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Income/Expense Row
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 0,
                              color: Colors.green.withValues(alpha: 0.1),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.arrow_downward,
                                          color: Colors.green,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Tổng thu',
                                          style: TextStyle(color: Colors.green),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${currencyFormat.format(totalIncome)} đ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Card(
                              elevation: 0,
                              color: Colors.red.withValues(alpha: 0.1),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.arrow_upward,
                                          color: Colors.red,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Tổng chi',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${currencyFormat.format(totalExpense)} đ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${currentMonthExpenses.length} giao dịch trong tháng',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              // Transaction List
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final dateKey = sortedDates[index];
                  final dailyExpenses = grouped[dateKey]!;

                  String displayDate = dateKey;
                  final dateObj = dateFormat.parse(dateKey);
                  final today = DateTime(now.year, now.month, now.day);
                  final yesterday = today.subtract(const Duration(days: 1));

                  if (dateObj == today) {
                    displayDate = 'Hôm nay';
                  } else if (dateObj == yesterday) {
                    displayDate = 'Hôm qua';
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          displayDate,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      ...dailyExpenses.map((expense) {
                        return ExpenseCard(
                          expense: expense,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ExpenseDetailScreen(expenseId: expense.id!),
                              ),
                            );
                          },
                        );
                      }),
                    ],
                  );
                }, childCount: sortedDates.length),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text('Lỗi tải dữ liệu')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOptions,
        icon: const Icon(Icons.add),
        label: const Text('Thêm giao dịch'),
      ),
    );
  }
}
