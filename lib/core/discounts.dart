class DiscountSuggestion {
  const DiscountSuggestion._({
    required this.daysToExpiry,
    this.fixedPercent,
    this.minPercent,
    this.maxPercent,
  });

  factory DiscountSuggestion.fixed({
    required int daysToExpiry,
    required double percent,
  }) {
    return DiscountSuggestion._(daysToExpiry: daysToExpiry, fixedPercent: percent);
  }

  factory DiscountSuggestion.range({
    required int daysToExpiry,
    required double min,
    required double max,
  }) {
    return DiscountSuggestion._(
      daysToExpiry: daysToExpiry,
      minPercent: min,
      maxPercent: max,
    );
  }

  final int daysToExpiry;
  final double? fixedPercent;
  final double? minPercent;
  final double? maxPercent;

  bool get isRange => minPercent != null && maxPercent != null;

  String get percentLabel {
    if (fixedPercent != null) {
      return '${fixedPercent!.toStringAsFixed(0)}%';
    }
    if (isRange) {
      return '${minPercent!.toStringAsFixed(0)}–${maxPercent!.toStringAsFixed(0)}%';
    }
    return '-';
  }
}

DiscountSuggestion? suggestDiscount({
  required DateTime expiryDate,
  required DateTime now,
}) {
  final daysToExpiry = expiryDate.difference(now).inDays;
  if (daysToExpiry <= 0) {
    return null;
  }

  // FoodHub rules:
  // - 3 weeks prior: 5%
  // - 2 weeks prior: 15%
  // - 1 week prior: 20%
  // - last 3 days: 30–40%
  if (daysToExpiry <= 3) {
    return DiscountSuggestion.range(daysToExpiry: daysToExpiry, min: 30, max: 40);
  }
  if (daysToExpiry <= 7) {
    return DiscountSuggestion.fixed(daysToExpiry: daysToExpiry, percent: 20);
  }
  if (daysToExpiry <= 14) {
    return DiscountSuggestion.fixed(daysToExpiry: daysToExpiry, percent: 15);
  }
  if (daysToExpiry <= 21) {
    return DiscountSuggestion.fixed(daysToExpiry: daysToExpiry, percent: 5);
  }
  return null;
}

double commissionRateForDiscount({
  required double baseCommissionRate,
  required double discountPercent,
}) {
  final discount = discountPercent.clamp(0, 100).toDouble();
  final reduced = baseCommissionRate * (1 - (discount / 100));
  return reduced.clamp(0, baseCommissionRate).toDouble();
}

({double minRate, double maxRate}) commissionRateRangeForSuggestion({
  required double baseCommissionRate,
  required DiscountSuggestion suggestion,
}) {
  if (suggestion.fixedPercent != null) {
    final rate = commissionRateForDiscount(
      baseCommissionRate: baseCommissionRate,
      discountPercent: suggestion.fixedPercent!,
    );
    return (minRate: rate, maxRate: rate);
  }

  final minDiscount = (suggestion.minPercent ?? 0).toDouble();
  final maxDiscount = (suggestion.maxPercent ?? 0).toDouble();

  // Higher discount -> lower commission.
  final maxRate = commissionRateForDiscount(
    baseCommissionRate: baseCommissionRate,
    discountPercent: minDiscount,
  );
  final minRate = commissionRateForDiscount(
    baseCommissionRate: baseCommissionRate,
    discountPercent: maxDiscount,
  );

  return (minRate: minRate, maxRate: maxRate);
}
