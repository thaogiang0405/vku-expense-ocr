import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;

import '../models/expense.dart';
import '../models/parsed_receipt.dart';
import '../providers/expense_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final ParsedReceipt parsedData;
  final String imagePath;
  final Expense? existingExpense; // If editing

  const ReviewScreen({
    super.key,
    required this.parsedData,
    required this.imagePath,
    this.existingExpense,
  });

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _merchantController;
  late TextEditingController _dateController;
  late TextEditingController _totalController;
  late ExpenseCategory _selectedCategory;
  late DateTime _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(
      text: widget.parsedData.merchant ?? '',
    );
    _selectedDate = widget.parsedData.date ?? DateTime.now();
    _dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(_selectedDate),
    );
    final totalText = widget.parsedData.total != null
        ? NumberFormat('#,##0', 'vi_VN').format(widget.parsedData.total)
        : '';
    _totalController = TextEditingController(text: totalText);

    // Default to food, unless editing
    _selectedCategory =
        widget.existingExpense?.category ?? ExpenseCategory.food;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _dateController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      final numStr = _totalController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final amount = double.tryParse(numStr) ?? 0.0;

      String? finalImagePath = widget.imagePath.isEmpty
          ? null
          : widget.imagePath;
      String? finalThumbPath;

      if (finalImagePath != null && !finalImagePath.contains('receipts')) {
        try {
          final docDir = await getApplicationDocumentsDirectory();
          final receiptsDir = Directory('${docDir.path}/receipts');
          if (!await receiptsDir.exists()) {
            await receiptsDir.create(recursive: true);
          }

          final fileName = p.basename(widget.imagePath);
          final savedImage = await File(widget.imagePath)
              .copy('${receiptsDir.path}/$fileName');
          finalImagePath = savedImage.path;

          // Generate thumbnail
          final thumbFile = File('${receiptsDir.path}/thumb_$fileName');
          final bytes = await savedImage.readAsBytes();
          final image = await compute(img.decodeImage, bytes);
          if (image != null) {
            final thumbnail = img.copyResize(image, width: 200);
            await thumbFile.writeAsBytes(img.encodeJpg(thumbnail, quality: 70));
            finalThumbPath = thumbFile.path;
          }
        } catch (e) {
          debugPrint('Failed to save image/thumbnail: $e');
          finalImagePath = widget.imagePath; // fallback
        }
      } else {
        // We are editing and image is already in receipts folder
        finalImagePath = widget.existingExpense?.receiptImagePath;
        finalThumbPath = widget.existingExpense?.receiptThumbnailPath;
      }

      final expense = Expense(
        id: widget.existingExpense?.id,
        merchant: _merchantController.text.trim(),
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory,
        receiptImagePath: finalImagePath,
        receiptThumbnailPath: finalThumbPath,
      );

      if (widget.existingExpense != null) {
        await ref.read(expenseProvider.notifier).updateExpense(expense);
      } else {
        await ref.read(expenseProvider.notifier).addExpense(expense);
      }

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hủy bỏ giao dịch?'),
          content: const Text(
            'Những thay đổi của bạn sẽ không được lưu. Bạn có chắc chắn muốn thoát?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Thoát'),
            ),
          ],
        );
      },
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.existingExpense != null
                ? 'Sửa giao dịch'
                : 'Chi tiết giao dịch',
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Image Preview Area
              if (widget.imagePath.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.black12,
                  child: kIsWeb
                      ? Image.network(widget.imagePath, fit: BoxFit.contain)
                      : Image.file(File(widget.imagePath), fit: BoxFit.contain),
                ),

              if (widget.imagePath.isNotEmpty) const Divider(height: 1),

              // Form Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Merchant Field
                        TextFormField(
                          controller: _merchantController,
                          decoration: const InputDecoration(
                            labelText: 'Người bán / Cửa hàng',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.store),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập tên cửa hàng';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Date Field
                        TextFormField(
                          controller: _dateController,
                          decoration: const InputDecoration(
                            labelText: 'Ngày giao dịch',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: _pickDate,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng chọn ngày';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Total Field
                        TextFormField(
                          controller: _totalController,
                          decoration: const InputDecoration(
                            labelText: 'Số tiền (đ)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập số tiền';
                            }
                            final numStr = value.replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            );
                            final numVal = double.tryParse(numStr);
                            if (numVal == null || numVal <= 0) {
                              return 'Số tiền phải lớn hơn 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Category Field
                        DropdownButtonFormField<ExpenseCategory>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Danh mục',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: ExpenseCategory.food,
                              child: Text('Ăn uống'),
                            ),
                            DropdownMenuItem(
                              value: ExpenseCategory.study,
                              child: Text('Học tập'),
                            ),
                            DropdownMenuItem(
                              value: ExpenseCategory.travel,
                              child: Text('Di chuyển'),
                            ),
                            DropdownMenuItem(
                              value: ExpenseCategory.gear,
                              child: Text('Thiết bị'),
                            ),
                            DropdownMenuItem(
                              value: ExpenseCategory.entertainment,
                              child: Text('Giải trí'),
                            ),
                            DropdownMenuItem(
                              value: ExpenseCategory.other,
                              child: Text('Khác'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Vui lòng chọn danh mục';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Save Button
                        FilledButton(
                          onPressed: _isSaving ? null : _saveExpense,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Lưu chi tiêu'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
