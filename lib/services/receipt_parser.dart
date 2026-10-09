import 'package:flutter/foundation.dart';

import '../models/parsed_receipt.dart';

enum SemanticCategory {
  finalPayment(1000),
  subtotal(500),
  other(0),
  itemPrice(-600),
  serviceCharge(-800),
  discount(-800),
  vat(-1000);

  final int baseScore;
  const SemanticCategory(this.baseScore);
}

class Candidate {
  final double amount;
  final int lineIndex;
  final String sourceLine;
  SemanticCategory category = SemanticCategory.other;
  String matchedLabel = "";
  double score = 0.0;

  Candidate(this.amount, this.lineIndex, this.sourceLine);
}

class ReceiptParser {
  ParsedReceipt parse(String rawText) {
    debugPrint('========== RAW OCR TEXT ==========');
    debugPrint(rawText);
    debugPrint('===================================');

    final lines = rawText
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    debugPrint('========== OCR LINES ==========');
    for (int i = 0; i < lines.length; i++) {
      debugPrint('[$i] "${lines[i]}"');
    }
    debugPrint('================================');

    final merchant = _parseMerchant(lines);
    final date = _parseDate(rawText);
    final total = _parseTotal(lines);

    debugPrint('========== FINAL PARSER RESULT ==========');
    debugPrint('detectedTotal = $total');
    debugPrint('detectedDate = $date');
    debugPrint('detectedMerchant = $merchant');
    debugPrint('=========================================');

    return ParsedReceipt(
      merchant: merchant,
      date: date,
      total: total,
      rawText: rawText,
    );
  }

  String? _parseMerchant(List<String> lines) {
    final ignoreExact = [
      'receipt',
      'hóa đơn',
      'hoa don',
      'invoice',
      'bill',
      'phiếu thanh toán',
      'phieu thanh toan',
      'hóa đơn bán hàng',
      'hoa don ban hang',
      'cửa hàng',
      'cua hang',
      'siêu thị',
      'sieu thi',
      'hóa đơn thanh toán',
      'hoa don thanh toan',
    ];

    for (String line in lines) {
      final lowerLine = line.toLowerCase();
      if (ignoreExact.contains(lowerLine)) continue;

      final digitCount = RegExp(r'\d').allMatches(line).length;
      if (digitCount > line.length * 0.5) continue;

      if (_extractAmountCandidates(line).isNotEmpty) continue;

      if (RegExp(r'\b(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})\b').hasMatch(line)) {
        continue;
      }

      if (RegExp(r'[a-zA-Z]').hasMatch(line) && line.length >= 3) {
        return line;
      }
    }
    return null;
  }

  DateTime? _parseDate(String rawText) {
    final dateRegex = RegExp(r'\b(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})\b');
    final matches = dateRegex.allMatches(rawText);

    for (var match in matches) {
      int? day = int.tryParse(match.group(1)!);
      int? month = int.tryParse(match.group(2)!);
      int? year = int.tryParse(match.group(3)!);

      if (day != null && month != null && year != null) {
        if (day >= 1 &&
            day <= 31 &&
            month >= 1 &&
            month <= 12 &&
            year > 2000 &&
            year <= DateTime.now().year + 1) {
          return DateTime(year, month, day);
        }
      }
    }
    return null;
  }

  double? _parseTotal(List<String> rawLines) {
    List<String> lines = [];
    for (String l in rawLines) {
      String fixed = l.replaceAllMapped(
        RegExp(r'(?<=\d)\s*([.,])\s*(?=\d)'),
        (m) => m.group(1)!,
      );
      lines.add(fixed);
    }

    List<Candidate> allCandidates = [];
    for (int i = 0; i < lines.length; i++) {
      List<double> lineAmts = _extractAmountCandidates(lines[i]);
      for (double a in lineAmts) {
        allCandidates.add(Candidate(a, i, lines[i]));
      }
    }

    if (allCandidates.isEmpty) return null;

    // 1. Semantic Classification
    for (var cand in allCandidates) {
      String normLine = _normalizeText(cand.sourceLine);
      String normPrev = cand.lineIndex > 0
          ? _normalizeText(lines[cand.lineIndex - 1])
          : '';

      SemanticCategory? cat = _findCategory(normLine);
      if (cat != null) {
        cand.category = cat;
        cand.matchedLabel = cand.sourceLine;
      } else {
        cat = _findCategory(normPrev);
        if (cat != null) {
          cand.category = cat;
          cand.matchedLabel = lines[cand.lineIndex - 1];
        }
      }
    }

    // 2. Frequency counting
    Map<double, int> freqs = {};
    for (var c in allCandidates) {
      freqs[c.amount] = (freqs[c.amount] ?? 0) + 1;
    }

    // 3. Scoring
    for (var cand in allCandidates) {
      cand.score = cand.category.baseScore.toDouble();
      cand.score +=
          freqs[cand.amount]! * 20.0; // Duplicate amounts get priority
      cand.score += (cand.lineIndex * 0.1); // Lower line items get tie-breaker

      String lowerLine = cand.sourceLine.toLowerCase();
      if (lowerLine.contains('vnd') ||
          lowerLine.contains('đ') ||
          lowerLine.contains('vnđ')) {
        cand.score += 10.0;
      }
    }

    // 4. Debug Logging
    debugPrint('========== TOTAL SEMANTIC CANDIDATES ==========');
    for (var cand in allCandidates) {
      debugPrint('amount = ${cand.amount.toInt()}');
      debugPrint('category = ${cand.category.name}');
      debugPrint('label = "${cand.matchedLabel}"');
      debugPrint('score = ${cand.score}');
      debugPrint('---');
    }
    debugPrint('==============================================');

    // 5. Select Best
    allCandidates.sort((a, b) => a.score.compareTo(b.score));
    Candidate best = allCandidates.last;

    debugPrint('========== FINAL TOTAL ==========');
    debugPrint('${best.amount.toInt()}');
    debugPrint('=================================');

    return best.amount;
  }

  SemanticCategory? _findCategory(String normText) {
    if (_matches(normText, [
      'vat',
      'vatamount',
      'thuesuatgtgt',
      'tienthuegtgt',
      'thue',
      'tax',
      'taxamount',
      'gtgt',
    ])) {
      return SemanticCategory.vat;
    }
    if (_matches(normText, [
      'congtienhang',
      'totalamount',
      'thanhtien',
      'subtotal',
      'amountbeforevat',
      'tienhang',
    ])) {
      return SemanticCategory.subtotal;
    }
    if (_matches(normText, [
      'servicecharge',
      'service',
      'phuphi',
      'phiphucvu',
    ])) {
      return SemanticCategory.serviceCharge;
    }
    if (_matches(normText, ['discount', 'giamgia', 'khuyenmai'])) {
      return SemanticCategory.discount;
    }
    if (_matches(normText, ['dongia', 'unitprice', 'gia'])) {
      return SemanticCategory.itemPrice;
    }
    if (_matches(normText, [
      'tongcongtienthanhtoan',
      'tongcongtienphaithanhtoan',
      'tongtienthanhtoan',
      'tongthanhtoan',
      'tongcong',
      'tienthanhtoan',
      'tongtien',
      'tngtien',
      'totalpayment',
      'totalpayable',
      'amountpayable',
      'amountdue',
      'grandtotal',
      'totaldue',
      'finaltotal',
      'netpayable',
      'total',
      't0tal',
      'tong',
      'tng',
    ])) {
      return SemanticCategory.finalPayment;
    }
    return null;
  }

  bool _matches(String text, List<String> kws) {
    return kws.any((kw) => text.contains(kw));
  }

  String _normalizeText(String text) {
    String t = text.toLowerCase();
    const vietnamese =
        'áàảãạâấầẩẫậăắằẳẵặđéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵ';
    const english =
        'aaaaaaaaaaaaaaaaadeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyy';
    for (int i = 0; i < vietnamese.length; i++) {
      t = t.replaceAll(vietnamese[i], english[i]);
    }
    return t.replaceAll(RegExp(r'[\s:()]'), '');
  }

  List<double> _extractAmountCandidates(String fixed) {
    List<double> amounts = [];

    final separatorRegex = RegExp(r'\b\d{1,3}(?:[.,]\d{3})+\b');
    for (var m in separatorRegex.allMatches(fixed)) {
      String numStr = m.group(0)!.replaceAll('.', '').replaceAll(',', '');
      double? val = double.tryParse(numStr);
      if (val != null) amounts.add(val);
    }

    final plainNumberRegex = RegExp(r'\b\d{4,}\b');
    for (var m in plainNumberRegex.allMatches(fixed)) {
      String numStr = m.group(0)!;
      if (numStr.startsWith('0') && numStr.length >= 9) continue;
      double? val = double.tryParse(numStr);
      if (val != null && val > 3000 && val < 1000000000) {
        amounts.add(val);
      }
    }

    final spaceRegex = RegExp(
      r'\b\d{1,3}(?:\s\d{3})+\s?(?:vnd|vnđ|đ|d)\b',
      caseSensitive: false,
    );
    for (var m in spaceRegex.allMatches(fixed)) {
      String numStr = m
          .group(0)!
          .toLowerCase()
          .replaceAll('vnd', '')
          .replaceAll('vnđ', '')
          .replaceAll('đ', '')
          .replaceAll('d', '')
          .replaceAll(' ', '');
      double? val = double.tryParse(numStr);
      if (val != null) amounts.add(val);
    }

    return amounts.toSet().toList();
  }
}
