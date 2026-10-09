enum TransactionType { income, expense }

enum ExpenseCategory {
  // Expense categories
  food,
  study,
  travel,
  gear,
  entertainment,
  other,

  // Income categories
  salary,
  overtime,
  familySupport,
  bonus,
  otherIncome,
}

class Expense {
  final int? id;
  final String merchant;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String? receiptImagePath;
  final String? receiptThumbnailPath;
  final TransactionType type;
  final String? note;
  final int isSample; // 0 or 1

  Expense({
    this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.receiptImagePath,
    this.receiptThumbnailPath,
    this.type = TransactionType.expense,
    this.note,
    this.isSample = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'merchant': merchant,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.name,
      'imagePath': receiptImagePath,
      'thumbnailPath': receiptThumbnailPath,
      'type': type.name,
      'note': note,
      'isSample': isSample,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      merchant: map['merchant'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      receiptImagePath: map['imagePath'] as String?,
      receiptThumbnailPath: map['thumbnailPath'] as String?,
      type: (map['type'] as String?) == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      note: map['note'] as String?,
      isSample: map['isSample'] as int? ?? 0,
    );
  }
}
