import 'package:intl/intl.dart';

// ============================================================================
// COMPLETE DATETIME EXTENSIONS 📅
// ============================================================================

extension DateTimeExtensions on DateTime {
  // ========================================================================
  // DATE CHECKS ✅
  // ========================================================================

  /// Check if the date is today
  bool isToday() {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if the date is yesterday
  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if the date is tomorrow
  bool isTomorrow() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Check if the date is in the past
  bool isPast() => isBefore(DateTime.now());

  /// Check if the date is in the future
  bool isFuture() => isAfter(DateTime.now());

  /// Check if same day as another date
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Check if same month as another date
  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }

  /// Check if same year as another date
  bool isSameYear(DateTime other) {
    return year == other.year;
  }

  /// Check if this week
  bool isThisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.startOfDay()) && isBefore(endOfWeek.endOfDay());
  }

  /// Check if this month
  bool isThisMonth() {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// Check if this year
  bool isThisYear() {
    return year == DateTime.now().year;
  }

  // ========================================================================
  // WEEKEND & WEEKDAY ⏰
  // ========================================================================

  /// Check if the date is a weekend
  bool isWeekend() {
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }

  /// Check if the date is a weekday
  bool isWeekday() {
    return !isWeekend();
  }

  /// Get the name of the day (e.g., Monday, Tuesday)
  String get dayName {
    return DateFormat('EEEE').format(this);
  }

  /// Get short day name (e.g., Mon, Tue)
  String get shortDayName {
    return DateFormat('EEE').format(this);
  }

  /// Get the name of the month (e.g., January, February)
  String get monthName {
    return DateFormat('MMMM').format(this);
  }

  /// Get short month name (e.g., Jan, Feb)
  String get shortMonthName {
    return DateFormat('MMM').format(this);
  }

  // ========================================================================
  // DATE FORMATTING 📝
  // ========================================================================

  /// Format as "dd-MM-yyyy"
  String formatDate() {
    return DateFormat('dd-MM-yyyy').format(this);
  }

  /// Format as "yyyy-MM-dd" (ISO format)
  String formatISODate() {
    return DateFormat('yyyy-MM-dd').format(this);
  }

  /// Format as "dd-MM-yyyy HH:mm"
  String formatDateTime() {
    return DateFormat('dd-MM-yyyy HH:mm').format(this);
  }

  /// Format as "MMM dd, yyyy" (e.g., Jan 15, 2024)
  String get formatted {
    return DateFormat('MMM dd, yyyy').format(this);
  }

  /// Format as "MMMM dd, yyyy" (e.g., January 15, 2024)
  String get formattedLong {
    return DateFormat('MMMM dd, yyyy').format(this);
  }

  /// Format time as "HH:mm" (24-hour)
  String get timeOnly {
    return DateFormat('HH:mm').format(this);
  }

  /// Format time as "hh:mm a" (12-hour with AM/PM)
  String get time12Hour {
    return DateFormat('hh:mm a').format(this);
  }

  /// Format as "dd MMM yyyy, hh:mm a"
  String get fullFormat {
    return DateFormat('dd MMM yyyy, hh:mm a').format(this);
  }

  /// Custom format
  String format(String pattern) {
    return DateFormat(pattern).format(this);
  }

  // ========================================================================
  // RELATIVE TIME (Time Ago) 🕐
  // ========================================================================

  /// Get relative time string (e.g., "2 hours ago", "just now")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 5) {
      return 'just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Get short relative time (e.g., "2h ago", "3d ago")
  String get timeAgoShort {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }

  /// Get time until (for future dates)
  String get timeUntil {
    final difference = this.difference(DateTime.now());

    if (difference.inSeconds < 0) {
      return 'passed';
    } else if (difference.inSeconds < 60) {
      return 'in ${difference.inSeconds} seconds';
    } else if (difference.inMinutes < 60) {
      return 'in ${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return 'in ${difference.inHours} hours';
    } else if (difference.inDays < 7) {
      return 'in ${difference.inDays} days';
    } else if (difference.inDays < 30) {
      return 'in ${(difference.inDays / 7).floor()} weeks';
    } else if (difference.inDays < 365) {
      return 'in ${(difference.inDays / 30).floor()} months';
    } else {
      return 'in ${(difference.inDays / 365).floor()} years';
    }
  }

  // ========================================================================
  // AGE & DIFFERENCES 📊
  // ========================================================================

  /// Get the age based on the date
  int getAge() {
    final now = DateTime.now();
    int age = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) {
      age--;
    }
    return age;
  }

  /// Get difference in days
  int differenceInDays(DateTime other) {
    return DateTime(
      year,
      month,
      day,
    ).difference(DateTime(other.year, other.month, other.day)).inDays;
  }

  /// Get difference in months
  int differenceInMonths(DateTime other) {
    return (year - other.year) * 12 + (month - other.month);
  }

  /// Get difference in years
  int differenceInYears(DateTime other) {
    return year - other.year;
  }

  /// Get difference in hours
  int differenceInHours(DateTime other) {
    return difference(other).inHours;
  }

  /// Get difference in minutes
  int differenceInMinutes(DateTime other) {
    return difference(other).inMinutes;
  }

  // ========================================================================
  // DATE ARITHMETIC ➕➖
  // ========================================================================

  /// Add days
  DateTime addDays(int days) {
    return add(Duration(days: days));
  }

  /// Subtract days
  DateTime subtractDays(int days) {
    return subtract(Duration(days: days));
  }

  /// Add months
  DateTime addMonths(int months) {
    return DateTime(year, month + months, day, hour, minute, second);
  }

  /// Subtract months
  DateTime subtractMonths(int months) {
    return DateTime(year, month - months, day, hour, minute, second);
  }

  /// Add years
  DateTime addYears(int years) {
    return DateTime(year + years, month, day, hour, minute, second);
  }

  /// Subtract years
  DateTime subtractYears(int years) {
    return DateTime(year - years, month, day, hour, minute, second);
  }

  /// Add hours
  DateTime addHours(int hours) {
    return add(Duration(hours: hours));
  }

  /// Add minutes
  DateTime addMinutes(int minutes) {
    return add(Duration(minutes: minutes));
  }

  // ========================================================================
  // START/END OF PERIODS 🔚
  // ========================================================================

  /// Get start of day (00:00:00)
  DateTime startOfDay() {
    return DateTime(year, month, day);
  }

  /// Get end of day (23:59:59)
  DateTime endOfDay() {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  /// Get start of week (Monday)
  DateTime startOfWeek() {
    return subtract(Duration(days: weekday - 1)).startOfDay();
  }

  /// Get end of week (Sunday)
  DateTime endOfWeek() {
    return add(Duration(days: DateTime.daysPerWeek - weekday)).endOfDay();
  }

  /// Get start of month
  DateTime startOfMonth() {
    return DateTime(year, month, 1);
  }

  /// Get end of month
  DateTime endOfMonth() {
    return DateTime(year, month + 1, 0, 23, 59, 59, 999);
  }

  /// Get start of year
  DateTime startOfYear() {
    return DateTime(year, 1, 1);
  }

  /// Get end of year
  DateTime endOfYear() {
    return DateTime(year, 12, 31, 23, 59, 59, 999);
  }

  // ========================================================================
  // WEEK UTILITIES 📆
  // ========================================================================

  /// Get week number of year (1-52)
  int get weekOfYear {
    final firstDayOfYear = DateTime(year, 1, 1);
    final daysSinceFirstDay = differenceInDays(firstDayOfYear);
    return ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
  }

  /// Get first day of week (Monday)
  DateTime get firstDayOfWeek {
    return startOfWeek();
  }

  /// Get last day of week (Sunday)
  DateTime get lastDayOfWeek {
    return endOfWeek();
  }

  // ========================================================================
  // MONTH UTILITIES 📅
  // ========================================================================

  /// Get number of days in month
  int get daysInMonth {
    return DateTime(year, month + 1, 0).day;
  }

  /// Get first day of month
  DateTime get firstDayOfMonth {
    return startOfMonth();
  }

  /// Get last day of month
  DateTime get lastDayOfMonth {
    return endOfMonth();
  }

  /// Check if leap year
  bool get isLeapYear {
    return (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
  }

  // ========================================================================
  // BUSINESS DAY CALCULATIONS 💼
  // ========================================================================

  /// Get next business day (skips weekends)
  DateTime get nextBusinessDay {
    DateTime next = addDays(1);
    while (next.isWeekend()) {
      next = next.addDays(1);
    }
    return next;
  }

  /// Get previous business day (skips weekends)
  DateTime get previousBusinessDay {
    DateTime prev = subtractDays(1);
    while (prev.isWeekend()) {
      prev = prev.subtractDays(1);
    }
    return prev;
  }

  /// Add business days (skips weekends)
  DateTime addBusinessDays(int days) {
    DateTime result = this;
    int addedDays = 0;

    while (addedDays < days) {
      result = result.addDays(1);
      if (!result.isWeekend()) {
        addedDays++;
      }
    }
    return result;
  }

  /// Count business days between dates
  int businessDaysBetween(DateTime other) {
    int count = 0;
    DateTime current = this;
    final end = other;

    while (current.isBefore(end)) {
      if (!current.isWeekend()) {
        count++;
      }
      current = current.addDays(1);
    }
    return count;
  }

  // ========================================================================
  // COPY WITH 📋
  // ========================================================================

  /// Copy with new values
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
  }) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
    );
  }

  // ========================================================================
  // QUARTER UTILITIES 📊
  // ========================================================================

  /// Get quarter of year (1-4)
  int get quarter {
    return ((month - 1) / 3).floor() + 1;
  }

  /// Get start of quarter
  DateTime get startOfQuarter {
    final quarterMonth = ((quarter - 1) * 3) + 1;
    return DateTime(year, quarterMonth, 1);
  }

  /// Get end of quarter
  DateTime get endOfQuarter {
    final quarterMonth = quarter * 3;
    return DateTime(year, quarterMonth + 1, 0, 23, 59, 59, 999);
  }
}

// ============================================================================
// NULLABLE DATETIME EXTENSIONS 🔄
// ============================================================================

extension NullableDateTimeExtensions on DateTime? {
  /// Get value or return current date
  DateTime get orNow => this ?? DateTime.now();

  /// Get value or return specific date
  DateTime orDefault(DateTime defaultDate) => this ?? defaultDate;

  /// Format or return empty string
  String formatOrEmpty([String pattern = 'dd-MM-yyyy']) {
    return this?.format(pattern) ?? '';
  }

  /// Time ago or return empty
  String get timeAgoOrEmpty => this?.timeAgo ?? '';

  /// Check if null or past
  bool get isNullOrPast => this == null || this!.isPast();

  /// Check if null or future
  bool get isNullOrFuture => this == null || this!.isFuture();
}

// ============================================================================
// STRING TO DATETIME PARSING 🔤
// ============================================================================

extension StringToDateTime on String {
  /// Parse ISO date string: "2024-01-15" or "2024-01-15T10:30:00"
  DateTime? get toDateTime => DateTime.tryParse(this);

  /// Parse date with custom format
  DateTime? parseDate(String format) {
    try {
      return DateFormat(format).parse(this);
    } catch (e) {
      return null;
    }
  }

  /// Parse common formats
  DateTime? get parseCommonDate {
    final formats = [
      'yyyy-MM-dd',
      'dd-MM-yyyy',
      'MM/dd/yyyy',
      'dd/MM/yyyy',
      'yyyy-MM-dd HH:mm:ss',
      'dd-MM-yyyy HH:mm:ss',
    ];

    for (final format in formats) {
      try {
        return DateFormat(format).parse(this);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  /// Check if valid date string
  bool get isValidDate => toDateTime != null;
}

// ============================================================================
// DURATION EXTENSIONS ⏱️
// ============================================================================

extension DurationExtensions on Duration {
  /// Format as "HH:mm:ss"
  String get formatted {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);
    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  /// Format as "2h 30m"
  String get formattedShort {
    if (inHours > 0) {
      return '${inHours}h ${inMinutes.remainder(60)}m';
    } else if (inMinutes > 0) {
      return '${inMinutes}m';
    } else {
      return '${inSeconds}s';
    }
  }

  /// Get readable duration
  String get readable {
    if (inDays > 0) {
      return '$inDays ${inDays == 1 ? 'day' : 'days'}';
    } else if (inHours > 0) {
      return '$inHours ${inHours == 1 ? 'hour' : 'hours'}';
    } else if (inMinutes > 0) {
      return '$inMinutes ${inMinutes == 1 ? 'minute' : 'minutes'}';
    } else {
      return '$inSeconds ${inSeconds == 1 ? 'second' : 'seconds'}';
    }
  }
}

// ============================================================================
// INTEGER TO DURATION HELPERS 🔢
// ============================================================================

extension IntToDuration on int {
  /// Convert to Duration days
  Duration get days => Duration(days: this);

  /// Convert to Duration hours
  Duration get hours => Duration(hours: this);

  /// Convert to Duration minutes
  Duration get minutes => Duration(minutes: this);

  /// Convert to Duration seconds
  Duration get seconds => Duration(seconds: this);

  /// Convert to Duration milliseconds
  Duration get milliseconds => Duration(milliseconds: this);
}

// ============================================================================
// TIME DURATION FORMATTING (from your code) ⏱️
// ============================================================================

extension DurationFormatting on num {
  /// Convert seconds to duration: 90 -> "1:30"
  String get asMinutesSeconds {
    final minutes = (this ~/ 60).toString().padLeft(2, '0');
    final seconds = (this % 60).toInt().toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Convert seconds to readable format: 3661 -> "1h 1m 1s"
  String get asDuration {
    final hours = this ~/ 3600;
    final minutes = (this % 3600) ~/ 60;
    final seconds = (this % 60).toInt();

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  /// Convert milliseconds to readable: 1500 -> "1.5s"
  String get asMilliseconds {
    if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}s';
    }
    return '${this}ms';
  }
}
