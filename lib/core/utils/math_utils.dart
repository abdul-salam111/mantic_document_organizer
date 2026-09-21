// ============================================================================
// PERCENTAGE FORMATTING 📊
// ============================================================================

import 'package:intl/intl.dart';

import 'currency_utils.dart';

extension PercentageFormatting on num {
  /// Format as percentage: 0.5 -> 50%
  String get asPercentage {
    return NumberFormat.percentPattern().format(this);
  }

  /// Format with custom decimal places: toPercentage(decimals: 1) -> 50.5%
  String toPercentage({int decimals = 0}) {
    final value = this * 100;
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Format with +/- sign: 0.05 -> +5%, -0.03 -> -3%
  String get asPercentageWithSign {
    final value = this * 100;
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)}%';
  }
}

// ============================================================================
// DECIMAL & ROUNDING 🔢
// ============================================================================

extension DecimalFormatting on num {
  /// Format with specific decimal places: toDecimal(2) -> 10.50
  String toDecimal(int places) {
    return toStringAsFixed(places);
  }

  /// Round to nearest: 10.6 -> 11
  int get rounded => round();

  /// Round up: 10.1 -> 11
  int get roundedUp => ceil();

  /// Round down: 10.9 -> 10
  int get roundedDown => floor();

  /// Format with 2 decimal places: 10.5 -> 10.50
  String get to2Decimals => toStringAsFixed(2);

  /// Format with no decimals: 10.99 -> 11
  String get to0Decimals => toStringAsFixed(0);

  /// Remove trailing zeros: 10.50 -> 10.5, 10.00 -> 10
  String get withoutTrailingZeros {
    final str = toString();
    if (!str.contains('.')) return str;
    return str.replaceAll(RegExp(r'\.?0+$'), '');
  }
}

// ============================================================================
// FILE SIZE FORMATTING 💾
// ============================================================================

extension FileSizeFormatting on num {
  /// Format bytes: 1024 -> 1 KB, 1048576 -> 1 MB
  String get asFileSize {
    if (this >= 1073741824) {
      return '${(this / 1073741824).toStringAsFixed(2)} GB';
    } else if (this >= 1048576) {
      return '${(this / 1048576).toStringAsFixed(2)} MB';
    } else if (this >= 1024) {
      return '${(this / 1024).toStringAsFixed(2)} KB';
    }
    return '$this B';
  }

  /// Format bytes with custom decimals
  String toFileSize({int decimals = 2}) {
    if (this >= 1073741824) {
      return '${(this / 1073741824).toStringAsFixed(decimals)} GB';
    } else if (this >= 1048576) {
      return '${(this / 1048576).toStringAsFixed(decimals)} MB';
    } else if (this >= 1024) {
      return '${(this / 1024).toStringAsFixed(decimals)} KB';
    }
    return '$this B';
  }
}

// ============================================================================
// ORDINAL NUMBERS 🔢
// ============================================================================

extension OrdinalFormatting on int {
  /// Convert to ordinal: 1 -> 1st, 2 -> 2nd, 3 -> 3rd, 4 -> 4th
  String get asPosition {
    if (this >= 11 && this <= 13) {
      return '${this}th';
    }
    switch (this % 10) {
      case 1:
        return '${this}st';
      case 2:
        return '${this}nd';
      case 3:
        return '${this}rd';
      default:
        return '${this}th';
    }
  }
}

// ============================================================================
// RANGE & VALIDATION CHECKS ✅
// ============================================================================

extension NumberValidation on num {
  /// Check if number is between range (inclusive)
  bool isBetween(num min, num max) => this >= min && this <= max;

  /// Check if positive
  bool get isPositive => this > 0;

  /// Check if negative
  bool get isNegative => this < 0;

  /// Check if zero
  bool get isZero => this == 0;

  /// Check if even
  bool get isEven => this % 2 == 0;

  /// Check if odd
  bool get isOdd => this % 2 != 0;

  /// Clamp value between min and max
  num clampValue(num min, num max) => clamp(min, max);
}

// ============================================================================
// NULLABLE NUMBER EXTENSIONS 🔄
// ============================================================================

extension NullableNumberExtensions on num? {
  /// Get value or default: null -> 0
  num get orZero => this ?? 0;

  /// Get value or custom default
  num orDefault(num defaultValue) => this ?? defaultValue;

  /// Format as currency with null safety
  String get asCurrencyOrEmpty {
    return this?.asCurrency ?? '';
  }

  /// Format with commas or return empty
  String get withCommasOrEmpty {
    return this?.withCommas ?? '';
  }

  /// Check if null or zero
  bool get isNullOrZero => this == null || this == 0;
}
