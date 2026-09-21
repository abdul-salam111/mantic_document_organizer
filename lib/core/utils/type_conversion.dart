// Helper method to safely convert to int
import 'dart:convert';

import 'package:flutter/material.dart';

int safeToInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

// Helper method to safely convert to double
double safeToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

// Helper method to safely convert to String
String safeToString(dynamic value, {String defaultValue = ''}) {
  if (value == null) return defaultValue;
  if (value is String) return value;
  return value.toString();
}

// Helper method to safely convert to bool
bool safeToBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase().trim();
    if (lower == 'true' || lower == '1' || lower == 'yes') return true;
    if (lower == 'false' || lower == '0' || lower == 'no') return false;
  }
  return defaultValue;
}

// Helper method to safely convert to List
List<T> safeToList<T>(dynamic value, {List<T> defaultValue = const []}) {
  if (value == null) return defaultValue;
  if (value is List<T>) return value;
  if (value is List) {
    try {
      return value.cast<T>();
    } catch (e) {
      return defaultValue;
    }
  }
  return defaultValue;
}

// Helper method to safely convert to Map
Map<K, V> safeToMap<K, V>(dynamic value, {Map<K, V> defaultValue = const {}}) {
  if (value == null) return defaultValue;
  if (value is Map<K, V>) return value;
  if (value is Map) {
    try {
      return value.cast<K, V>();
    } catch (e) {
      return defaultValue;
    }
  }
  return defaultValue;
}

// Helper method to safely convert to DateTime
DateTime? safeToDateTime(dynamic value, {DateTime? defaultValue}) {
  if (value == null) return defaultValue;
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      return defaultValue;
    }
  }
  if (value is int) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } catch (e) {
      return defaultValue;
    }
  }
  return defaultValue;
}

// Helper method to safely convert to num
num safeToNum(dynamic value, {num defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? defaultValue;
  return defaultValue;
}

// Helper method to safely get value with type checking
T? safeAs<T>(dynamic value) {
  if (value == null) return null;
  if (value is T) return value;
  return null;
}

// Helper method to safely convert to Duration
Duration? safeToDuration(dynamic value, {Duration? defaultValue}) {
  if (value == null) return defaultValue;
  if (value is Duration) return value;
  if (value is int) return Duration(milliseconds: value);
  if (value is String) {
    try {
      // Try to parse as milliseconds
      final ms = int.tryParse(value);
      if (ms != null) return Duration(milliseconds: ms);
    } catch (e) {
      return defaultValue;
    }
  }
  return defaultValue;
}

// Helper method to safely convert to Color
Color? safeToColor(dynamic value, {Color? defaultValue}) {
  if (value == null) return defaultValue;
  if (value is Color) return value;
  if (value is int) {
    try {
      return Color(value);
    } catch (e) {
      return defaultValue;
    }
  }
  if (value is String) {
    try {
      // Remove # if present
      String hexColor = value.replaceAll('#', '');
      // Add FF for alpha if not present
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return defaultValue;
    }
  }
  return defaultValue;
}

// Helper method to safely convert to Enum
T? safeToEnum<T>(dynamic value, List<T> enumValues, {T? defaultValue}) {
  if (value == null) return defaultValue;
  if (value is T) return value;
  if (value is String) {
    try {
      return enumValues.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() == value.toLowerCase(),
        orElse: () => defaultValue ?? enumValues.first,
      );
    } catch (e) {
      return defaultValue;
    }
  }
  if (value is int && value >= 0 && value < enumValues.length) {
    return enumValues[value];
  }
  return defaultValue;
}

// Helper method to safely parse JSON string
dynamic safeJsonDecode(dynamic value, {dynamic defaultValue}) {
  if (value == null) return defaultValue;
  if (value is! String) return defaultValue;
  try {
    return jsonDecode(value);
  } catch (e) {
    return defaultValue;
  }
}

// Helper method to safely encode to JSON string
String? safeJsonEncode(dynamic value, {String? defaultValue}) {
  if (value == null) return defaultValue;
  try {
    return jsonEncode(value);
  } catch (e) {
    return defaultValue;
  }
}

// Helper method to safely get nested value from Map
T? safeGetNested<T>(
  Map<dynamic, dynamic>? map,
  List<String> keys, {
  T? defaultValue,
}) {
  if (map == null || keys.isEmpty) return defaultValue;

  dynamic current = map;
  for (var key in keys) {
    if (current is Map && current.containsKey(key)) {
      current = current[key];
    } else {
      return defaultValue;
    }
  }

  return current is T ? current : defaultValue;
}

// Helper method to safely convert to Uri
Uri? safeToUri(dynamic value, {Uri? defaultValue}) {
  if (value == null) return defaultValue;
  if (value is Uri) return value;
  if (value is String) {
    try {
      return Uri.parse(value);
    } catch (e) {
      return defaultValue;
    }
  }
  return defaultValue;
}
