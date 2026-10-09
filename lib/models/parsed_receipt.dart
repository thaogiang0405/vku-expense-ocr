class ParsedReceipt {
  final String? merchant;
  final DateTime? date;
  final double? total;
  final String rawText;

  const ParsedReceipt({
    this.merchant,
    this.date,
    this.total,
    required this.rawText,
  });
}
