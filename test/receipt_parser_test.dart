import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/services/receipt_parser.dart';

void main() {
  late ReceiptParser parser;

  setUp(() {
    parser = ReceiptParser();
  });

  group('ReceiptParser - Amount & Total Extraction', () {
    test('A. TONG CONG standard', () {
      final result = parser.parse('TỔNG CỘNG: 317.900 đ');
      expect(result.total, 317900.0);
    });

    test('B. Dot formatting', () {
      final result = parser.parse('Tổng tiền: 3.178.500');
      expect(result.total, 3178500.0);
    });

    test('C. Comma formatting with currency', () {
      final result = parser.parse('Total: 3,178,500 VND');
      expect(result.total, 3178500.0);
    });

    test('D. OCR space injection', () {
      final result = parser.parse('Tổng tiền: 947. 100');
      expect(result.total, 947100.0);
    });

    test('E. Vietnamese VAT Invoice priority', () {
      final rawText = '''
Cộng tiền hàng: 2.943.056
Tiền thuế GTGT: 235.444
Tổng cộng tiền thanh toán: 3.178.500
      ''';
      expect(parser.parse(rawText).total, 3178500.0);
    });

    test('F. Grand Total precedence over Subtotal/VAT/Service', () {
      final rawText = '''
Subtotal: 820.000
Service Charge: 41.000
VAT: 86.100
Grand Total: 947.100
      ''';
      expect(parser.parse(rawText).total, 947100.0);
    });

    test('J. No total returns null without crash', () {
      final result = parser.parse('Hello World\nWelcome to my shop');
      expect(result.total, isNull);
    });
  });

  group('ReceiptParser - Amount Normalization Edge Cases', () {
    test('Normalizes various formats correctly', () {
      expect(parser.parse('Total: 150.000').total, 150000.0);
      expect(parser.parse('Total: 150,000').total, 150000.0);
      expect(parser.parse('Total: 150000').total, 150000.0);
      expect(parser.parse('Total: 947. 100').total, 947100.0);
      expect(parser.parse('Total: 3.178.500 VND').total, 3178500.0);
      expect(parser.parse('Total: 3,178,500 VND').total, 3178500.0);
    });
  });

  group('ReceiptParser - Date Parsing', () {
    test('G. extracts DD/MM/YYYY', () {
      final result = parser.parse('Ngày: 22/05/2024');
      expect(result.date, DateTime(2024, 5, 22));
    });

    test('H. extracts DD-MM-YYYY', () {
      final result = parser.parse('Date: 22-05-2024');
      expect(result.date, DateTime(2024, 5, 22));
    });

    test('Invalid date returns null without crash', () {
      final result = parser.parse('Date: 99/99/9999');
      expect(result.date, isNull);
    });
  });

  group('ReceiptParser - Merchant Parsing', () {
    test('I. extracts first meaningful line as merchant', () {
      final rawText = '''CỬA HÀNG THỰC PHẨM MINH AN
Địa chỉ: 123 Lê Lợi''';
      final result = parser.parse(rawText);
      expect(result.merchant, 'CỬA HÀNG THỰC PHẨM MINH AN');
    });
  });
}
