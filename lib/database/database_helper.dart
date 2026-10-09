import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/expense.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'expenses.db');

    final db = await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            merchant TEXT NOT NULL,
            date TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            imagePath TEXT,
            thumbnailPath TEXT,
            type TEXT NOT NULL DEFAULT 'expense',
            note TEXT,
            isSample INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await _seedData(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _ensureColumns(db);
      },
    );

    // Controlled one-time seeding:
    // If the database has no sample data or no income data, seed sample data.
    await _ensureSampleData(db);

    return db;
  }

  Future<void> _ensureColumns(Database db) async {
    final tableInfo = await db.rawQuery('PRAGMA table_info(expenses)');
    final columnNames = tableInfo.map((row) => row['name'] as String).toSet();

    if (!columnNames.contains('thumbnailPath')) {
      await db.execute('ALTER TABLE expenses ADD COLUMN thumbnailPath TEXT');
    }
    if (!columnNames.contains('type')) {
      await db.execute(
        "ALTER TABLE expenses ADD COLUMN type TEXT NOT NULL DEFAULT 'expense'",
      );
    }
    if (!columnNames.contains('note')) {
      await db.execute('ALTER TABLE expenses ADD COLUMN note TEXT');
    }
    if (!columnNames.contains('isSample')) {
      await db.execute(
        'ALTER TABLE expenses ADD COLUMN isSample INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  Future<void> _ensureSampleData(Database db) async {
    await _ensureColumns(db);

    final sampleCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM expenses WHERE isSample = 1'),
        ) ??
        0;

    final incomeCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM expenses WHERE type = 'income'",
          ),
        ) ??
        0;

    if (sampleCount == 0) {
      await _seedData(db);
    } else if (incomeCount == 0) {
      await _seedIncomeOnly(db);
    }
  }

  String _formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DateTime _safeDate(int day) {
    final now = DateTime.now();
    try {
      return DateTime(now.year, now.month, day);
    } catch (_) {
      return DateTime(now.year, now.month, 28);
    }
  }

  Future<void> _seedIncomeOnly(Database db) async {
    final incomeSamples = [
      {
        'merchant': 'Lương làm thêm',
        'amount': 2500000.0,
        'date': _formatIsoDate(_safeDate(1)),
        'category': ExpenseCategory.overtime.name,
        'type': 'income',
        'isSample': 1,
      },
      {
        'merchant': 'Gia đình hỗ trợ',
        'amount': 1500000.0,
        'date': _formatIsoDate(_safeDate(3)),
        'category': ExpenseCategory.familySupport.name,
        'type': 'income',
        'isSample': 1,
      },
      {
        'merchant': 'Gia sư',
        'amount': 800000.0,
        'date': _formatIsoDate(_safeDate(8)),
        'category': ExpenseCategory.otherIncome.name,
        'type': 'income',
        'isSample': 1,
      },
      {
        'merchant': 'Làm thêm cuối tuần',
        'amount': 350000.0,
        'date': _formatIsoDate(_safeDate(12)),
        'category': ExpenseCategory.overtime.name,
        'type': 'income',
        'isSample': 1,
      },
      {
        'merchant': 'Tiền thưởng',
        'amount': 200000.0,
        'date': _formatIsoDate(_safeDate(15)),
        'category': ExpenseCategory.bonus.name,
        'type': 'income',
        'isSample': 1,
      },
    ];

    await db.transaction((txn) async {
      for (final item in incomeSamples) {
        await txn.insert('expenses', item);
      }
    });
  }

  Future<void> _seedData(Database db) async {
    final allSamples = [
      // 5 Khoản thu
      {
        'merchant': 'Lương làm thêm',
        'amount': 2500000.0,
        'date': _formatIsoDate(_safeDate(1)),
        'category': ExpenseCategory.overtime.name,
        'type': 'income',
        'isSample': 1,
      },
      {
        'merchant': 'Gia đình hỗ trợ',
        'amount': 1500000.0,
        'date': _formatIsoDate(_safeDate(3)),
        'category': ExpenseCategory.familySupport.name,
        'type': 'income',
        'isSample': 1,
      },
      {
        'merchant': 'Gia sư',
        'amount': 800000.0,
        'date': _formatIsoDate(_safeDate(8)),
        'category': ExpenseCategory.otherIncome.name,
        'type': 'income',
        'isSample': 1,
      },
      {
        'merchant': 'Làm thêm cuối tuần',
        'amount': 350000.0,
        'date': _formatIsoDate(_safeDate(12)),
        'category': ExpenseCategory.overtime.name,
        'type': 'income',
        'isSample': 1,
      },
      {
        'merchant': 'Tiền thưởng',
        'amount': 200000.0,
        'date': _formatIsoDate(_safeDate(15)),
        'category': ExpenseCategory.bonus.name,
        'type': 'income',
        'isSample': 1,
      },

      // 13 Khoản chi
      {
        'merchant': 'Ăn sáng',
        'amount': 25000.0,
        'date': _formatIsoDate(_safeDate(2)),
        'category': ExpenseCategory.food.name,
        'type': 'expense',
        'isSample': 1,
      },
      {
        'merchant': 'Ăn trưa',
        'amount': 40000.0,
        'date': _formatIsoDate(_safeDate(3)),
        'category': ExpenseCategory.food.name,
        'type': 'expense',
        'isSample': 1,
      },
      {
        'merchant': 'Trà sữa',
        'amount': 35000.0,
        'date': _formatIsoDate(_safeDate(4)),
        'category': ExpenseCategory.entertainment.name,
        'type': 'expense',
        'isSample': 1,
      },
      {
        'merchant': 'Tiền xăng',
        'amount': 70000.0,
        'date': _formatIsoDate(_safeDate(5)),
        'category': ExpenseCategory.travel.name,
        'type': 'expense',
        'isSample': 1,
      },
      {
        'merchant': 'In tài liệu học tập',
        'amount': 45000.0,
        'date': _formatIsoDate(_safeDate(6)),
        'category': ExpenseCategory.study.name,
        'type': 'expense',
        'isSample': 1,
      },
      {
        'merchant': 'Mua vở và bút',
        'amount': 65000.0,
        'date': _formatIsoDate(_safeDate(7)),
        'category': ExpenseCategory.gear.name,
        'type': 'expense',
        'isSample': 1,
      },
      {
        'merchant': 'Ăn tối',
        'amount': 50000.0,
        'date': _formatIsoDate(_safeDate(8)),
        'category': ExpenseCategory.food.name,
        'type': 'expense',
        'isSample': 1,
      },
      {
        'merchant': 'Mua sách',
        'amount': 120000.0,
        'date': _formatIsoDate(_safeDate(10)),
        'category': ExpenseCategory.study.name,
        'type': 'expense',
        'isSample': 1,
      },
      {
        'merchant': 'Cà phê',
        'amount': 30000.0,
        'date': _formatIsoDate(_safeDate(11)),
        'category': ExpenseCategory.food.name,
        'type': 'expense',
        'isSample': 1,
      },
      {
        'merchant': 'Ăn trưa',
        'amount': 40000.0,
        'date': _formatIsoDate(_safeDate(12)),
        'category': ExpenseCategory.food.name,
        'type': 'expense',
        'isSample': 1,
      },
      {
        'merchant': 'Vé xe',
        'amount': 35000.0,
        'date': _formatIsoDate(_safeDate(13)),
        'category': ExpenseCategory.travel.name,
        'type': 'expense',
        'isSample': 1,
      },
      {
        'merchant': 'Đồ dùng cá nhân',
        'amount': 85000.0,
        'date': _formatIsoDate(_safeDate(14)),
        'category': ExpenseCategory.gear.name,
        'type': 'expense',
        'isSample': 1,
      },
      {
        'merchant': 'Ăn tối',
        'amount': 55000.0,
        'date': _formatIsoDate(_safeDate(15)),
        'category': ExpenseCategory.food.name,
        'type': 'expense',
        'isSample': 1,
      },
    ];

    await db.transaction((txn) async {
      for (final item in allSamples) {
        await txn.insert('expenses', item);
      }
    });
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  Future<Expense?> getExpenseById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Expense.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getExpenseCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM expenses'),
    );
    return count ?? 0;
  }

  Future<double> getTotalExpense() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM expenses WHERE type = 'expense'",
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  Future<double> getTotalIncome() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM expenses WHERE type = 'income'",
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  Future<double> getBalance() async {
    final income = await getTotalIncome();
    final expense = await getTotalExpense();
    return income - expense;
  }
}
