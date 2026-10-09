import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/ocr_service.dart';
import '../services/receipt_parser.dart';
import '../models/ocr_result.dart';
import '../models/parsed_receipt.dart';
import 'review_screen.dart';

class OcrResultScreen extends StatefulWidget {
  final String imagePath;

  const OcrResultScreen({super.key, required this.imagePath});

  @override
  State<OcrResultScreen> createState() => _OcrResultScreenState();
}

class _OcrResultScreenState extends State<OcrResultScreen> {
  final OcrService _ocrService = OcrService();
  final ReceiptParser _receiptParser = ReceiptParser();

  bool _isProcessing = true;
  OcrResult? _ocrResult;
  ParsedReceipt? _parsedReceipt;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _runOcr();
  }

  Future<void> _runOcr() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await _ocrService.processImage(widget.imagePath);

      final parsed = _receiptParser.parse(result.rawText);

      if (!mounted) return;
      setState(() {
        _ocrResult = result;
        _parsedReceipt = parsed;
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint('OCR Error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể phân tích hóa đơn này.';
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  void _retry() {
    Navigator.pop(context);
  }

  void _continue() async {
    if (_parsedReceipt == null) return;

    final expense = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          parsedData: _parsedReceipt!,
          imagePath: widget.imagePath,
        ),
      ),
    );

    if (expense != null && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả quét'), centerTitle: true),
      body: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.black12,
            child: kIsWeb
                ? Image.network(widget.imagePath, fit: BoxFit.contain)
                : Image.file(File(widget.imagePath), fit: BoxFit.contain),
          ),

          const Divider(height: 1),

          Expanded(child: _buildOcrContent()),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: _isProcessing ? null : _retry,
                  child: const Text('Thử lại'),
                ),
                ElevatedButton(
                  onPressed:
                      (_isProcessing || (_ocrResult?.rawText.isEmpty ?? true))
                      ? null
                      : _continue,
                  child: const Text('Tiếp tục'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrContent() {
    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang nhận diện văn bản...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final text = _ocrResult?.rawText.trim() ?? '';

    if (text.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Không tìm thấy chữ nào. Vui lòng chụp lại hóa đơn.',
            style: TextStyle(fontSize: 16, color: Colors.orange),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Thông tin trích xuất',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer
                  .withAlpha(76),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildParsedField('Cửa hàng', _parsedReceipt?.merchant),
                const SizedBox(height: 4),
                _buildParsedField(
                  'Ngày',
                  _parsedReceipt?.date != null
                      ? '${_parsedReceipt!.date!.day}/${_parsedReceipt!.date!.month}/${_parsedReceipt!.date!.year}'
                      : null,
                ),
                const SizedBox(height: 4),
                _buildParsedField(
                  'Tổng tiền',
                  _parsedReceipt?.total != null
                      ? '${_parsedReceipt!.total!.toInt()} đ'
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Văn bản gốc (OCR)',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParsedField(String label, String? value) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: value ?? 'Chưa nhận diện được',
            style: TextStyle(color: value == null ? Colors.orange : null),
          ),
        ],
      ),
    );
  }
}
