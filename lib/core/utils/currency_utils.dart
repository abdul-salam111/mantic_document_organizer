import 'package:intl/intl.dart';

// ============================================================================
// CURRENCY & PRICE FORMATTING 💰
// ============================================================================

extension CurrencyFormatting on num {
  /// Format with commas: 1000 -> 1,000
  String get withCommas {
    return NumberFormat("#,##0", "en_US").format(this);
  }

  /// Format as USD currency: 1000 -> $1,000.00
  String get asCurrency {
    return NumberFormat.currency(locale: "en_US", symbol: "\$").format(this);
  }

  /// Format with custom currency symbol: formatCurrency(symbol: '₹')
  String formatCurrency({
    String symbol = '\$',
    String locale = 'en_US',
    int decimalDigits = 2,
  }) {
    return NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimalDigits,
    ).format(this);
  }

  /// Format price without decimal if whole number: 10.00 -> 10, 10.50 -> 10.50
  String get asPrice {
    if (this % 1 == 0) {
      return NumberFormat("#,##0", "en_US").format(this);
    }
    return NumberFormat("#,##0.00", "en_US").format(this);
  }

  /// Format with custom symbol: formatPrice(symbol: '₹')
  String formatPrice({String? symbol}) {
    final formatter = NumberFormat('#,###');
    final formatted = formatter.format(this);
    return symbol != null ? '$symbol$formatted' : formatted;
  }

  /// Compact currency: 1000 -> $1K, 1000000 -> $1M
  String get asCompactCurrency {
    return NumberFormat.compactCurrency(
      locale: "en_US",
      symbol: "\$",
    ).format(this);
  }

  /// Format as Pakistani Rupees: 1000 -> ₨1,000
  String get asPKR {
    return NumberFormat.currency(
      locale: "en_US",
      symbol: "₨",
      decimalDigits: 0,
    ).format(this);
  }

  /// Format as Euros: 1000 -> €1,000.00
  String get asEUR {
    return NumberFormat.currency(locale: "de_DE", symbol: "€").format(this);
  }

  /// Format as British Pounds: 1000 -> £1,000.00
  String get asGBP {
    return NumberFormat.currency(locale: "en_GB", symbol: "£").format(this);
  }

  /// Compact format: 1000 -> 1K, 1000000 -> 1M, 1000000000 -> 1B
  String get asCompact {
    return NumberFormat.compact(locale: "en_US").format(this);
  }

  /// Compact with decimals: 1500 -> 1.5K
  String get asCompactWithDecimals {
    return NumberFormat.compact(locale: "en_US").format(this);
  }

  /// Custom compact formatting
  String toCompact({int decimals = 1}) {
    if (this >= 1000000000) {
      return '${(this / 1000000000).toStringAsFixed(decimals)}B';
    } else if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(decimals)}M';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(decimals)}K';
    }
    return toStringAsFixed(0);
  }

  /// Compact for social media: 1000 -> 1k, 1500000 -> 1.5m
  String get asSocialCount {
    if (this >= 1000000) {
      final value = this / 1000000;
      return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}m';
    } else if (this >= 1000) {
      final value = this / 1000;
      return '${value.toStringAsFixed(value >= 10 ? 0 : 1)}k';
    }
    return toString();
  }
}

// ============================================================================
// STRING TO NUMBER EXTENSIONS FOR CURRENY PARSING 🔤
// ============================================================================

extension StringToNumber on String {
  /// Parse to int or return null
  int? get toIntOrNull => int.tryParse(this);

  /// Parse to double or return null
  double? get toDoubleOrNull => double.tryParse(this);

  /// Parse to int or return default
  int toIntOr(int defaultValue) => int.tryParse(this) ?? defaultValue;

  /// Parse to double or return default
  double toDoubleOr(double defaultValue) =>
      double.tryParse(this) ?? defaultValue;

  /// Remove commas and parse: "1,000" -> 1000
  int? get parseNumber {
    final cleaned = replaceAll(',', '');
    return int.tryParse(cleaned);
  }

  /// Remove currency symbols and parse: "$1,000.50" -> 1000.50
  double? get parseCurrency {
    final cleaned = replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned);
  }
}
