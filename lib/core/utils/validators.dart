// ============================================================================
// STRING VALIDATION EXTENSIONS ✅
// ============================================================================

import 'package:flutter/material.dart';

// Only the DateTime-side extension is needed here (for `getAge()`).
// `date_utils.dart` also declares its own `String.isValidDate` getter
// (StringToDateTime) which collides with this file's own
// StringValidationExtensions.isValidDate — hidden to avoid that ambiguity.
import 'date_utils.dart' show DateTimeExtensions;

extension StringValidationExtensions on String {
  // ========================================================================
  // EMAIL & CONTACT VALIDATIONS 📧
  // ========================================================================

  /// Check if valid email
  bool get isValidEmail {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(this);
  }

  /// Check if valid phone (10-15 digits with optional +)
  bool get isValidPhone {
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    return phoneRegex.hasMatch(this);
  }

  /// Check if valid Pakistani phone (11 digits starting with 03)
  bool get isValidPakistaniPhone {
    final phoneRegex = RegExp(r'^03[0-9]{9}$');
    return phoneRegex.hasMatch(this);
  }

  /// Check if valid US phone
  bool get isValidUSPhone {
    final phoneRegex = RegExp(r'^(\+1)?[2-9]\d{2}[2-9]\d{6}$');
    return phoneRegex.hasMatch(this);
  }

  // ========================================================================
  // PASSWORD VALIDATIONS 🔐
  // ========================================================================

  /// Check if valid password (at least 6 characters)
  bool get isValidPassword => length >= 6;

  /// Check if strong password (8+ chars, uppercase, lowercase, number, special)
  bool get isStrongPassword {
    if (length < 8) return false;
    final hasUppercase = contains(RegExp(r'[A-Z]'));
    final hasLowercase = contains(RegExp(r'[a-z]'));
    final hasDigit = contains(RegExp(r'[0-9]'));
    final hasSpecialChar = contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    return hasUppercase && hasLowercase && hasDigit && hasSpecialChar;
  }

  /// Check if medium password (6+ chars, letters and numbers)
  bool get isMediumPassword {
    if (length < 6) return false;
    final hasLetter = contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = contains(RegExp(r'[0-9]'));
    return hasLetter && hasDigit;
  }

  /// Get password strength (0-4)
  int get passwordStrength {
    if (isEmpty) return 0;
    int strength = 0;
    if (length >= 8) strength++;
    if (contains(RegExp(r'[A-Z]'))) strength++;
    if (contains(RegExp(r'[a-z]'))) strength++;
    if (contains(RegExp(r'[0-9]'))) strength++;
    if (contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    return strength > 4 ? 4 : strength;
  }

  // ========================================================================
  // NAME VALIDATIONS 👤
  // ========================================================================

  /// Check if valid name (only letters and spaces)
  bool get isValidName {
    final nameRegex = RegExp(r'^[a-zA-Z ]+$');
    return nameRegex.hasMatch(this);
  }

  /// Check if valid full name (first and last name)
  bool get isValidFullName {
    final parts = trim().split(' ');
    return parts.length >= 2 && parts.every((p) => p.isNotEmpty);
  }

  /// Check if valid username (alphanumeric, underscore, 3-20 chars)
  bool get isValidUsername {
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    return usernameRegex.hasMatch(this);
  }

  // ========================================================================
  // NUMERIC VALIDATIONS 🔢
  // ========================================================================

  /// Check if numeric
  bool get isNumeric {
    return double.tryParse(this) != null;
  }

  /// Check if integer
  bool get isInteger {
    return int.tryParse(this) != null;
  }

  /// Check if alphabetic only
  bool get isAlpha {
    final alphaRegex = RegExp(r'^[a-zA-Z]+$');
    return alphaRegex.hasMatch(this);
  }

  /// Check if alphanumeric
  bool get isAlphanumeric {
    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
    return alphanumericRegex.hasMatch(this);
  }

  // ========================================================================
  // URL & WEB VALIDATIONS 🌐
  // ========================================================================

  /// Check if valid URL
  bool get isValidURL {
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    return urlRegex.hasMatch(this);
  }

  /// Check if valid domain
  bool get isValidDomain {
    final domainRegex = RegExp(
      r'^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$',
    );
    return domainRegex.hasMatch(toLowerCase());
  }

  /// Check if valid IP address
  bool get isValidIP {
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(this)) return false;
    final parts = split('.');
    return parts.every((part) {
      final num = int.tryParse(part);
      return num != null && num >= 0 && num <= 255;
    });
  }

  // ========================================================================
  // DOCUMENT VALIDATIONS 📄
  // ========================================================================

  /// Check if valid CNIC (Pakistani ID: 13 digits with optional dashes)
  bool get isValidCNIC {
    final cnicRegex = RegExp(r'^[0-9]{5}-?[0-9]{7}-?[0-9]$');
    return cnicRegex.hasMatch(this);
  }

  /// Check if valid Pakistani passport
  bool get isValidPakistaniPassport {
    final passportRegex = RegExp(r'^[A-Z]{2}[0-9]{7}$');
    return passportRegex.hasMatch(this);
  }

  /// Check if valid credit card number (Luhn algorithm)
  bool get isValidCreditCard {
    if (isEmpty || !isNumeric) return false;
    final digits = replaceAll(RegExp(r'\s+'), '');
    if (digits.length < 13 || digits.length > 19) return false;

    int sum = 0;
    bool alternate = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int digit = int.parse(digits[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  // ========================================================================
  // DATE & TIME VALIDATIONS 📅
  // ========================================================================

  /// Check if valid date (YYYY-MM-DD)
  bool get isValidDate {
    try {
      DateTime.parse(this);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if valid time (HH:MM or HH:MM:SS)
  bool get isValidTime {
    final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$');
    return timeRegex.hasMatch(this);
  }

  // ========================================================================
  // SPECIAL FORMATS 🎯
  // ========================================================================

  /// Check if valid hex color
  bool get isValidHexColor {
    final hexRegex = RegExp(r'^#?([0-9A-Fa-f]{6}|[0-9A-Fa-f]{3})$');
    return hexRegex.hasMatch(this);
  }

  /// Check if valid postal code (5 or 5+4 digits)
  bool get isValidPostalCode {
    final postalRegex = RegExp(r'^\d{5}(-\d{4})?$');
    return postalRegex.hasMatch(this);
  }

  /// Check if valid ISBN (10 or 13 digits)
  bool get isValidISBN {
    final isbn = replaceAll(RegExp(r'[-\s]'), '');
    return isbn.length == 10 || isbn.length == 13;
  }

  // ========================================================================
  // CHECKS 🔍
  // ========================================================================

  /// Check if empty or whitespace
  bool get isBlank => trim().isEmpty;

  /// Check if not blank
  bool get isNotBlank => !isBlank;

  /// Check if contains only whitespace
  bool get isWhitespace => isNotEmpty && trim().isEmpty;

  /// Check if lowercase
  bool get isLowerCase => this == toLowerCase();

  /// Check if uppercase
  bool get isUpperCase => this == toUpperCase();

  /// Check if contains emoji
  bool get containsEmoji {
    final emojiRegex = RegExp(
      r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
    );
    return emojiRegex.hasMatch(this);
  }

  /// Check if palindrome
  bool get isPalindrome {
    final reversed = split('').reversed.join('');
    return toLowerCase() == reversed.toLowerCase();
  }
}

// ============================================================================
// COMPLETE VALIDATOR CLASS 🎯
// ============================================================================

class Validator {
  // ========================================================================
  // BASIC VALIDATIONS ✅
  // ========================================================================

  /// Validate required field
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName == null
          ? 'This field is required'
          : '$fieldName is required';
    }
    return null;
  }

  // ========================================================================
  // EMAIL & CONTACT VALIDATIONS 📧
  // ========================================================================

  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!value.isValidEmail) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validate phone
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (!value.isValidPhone) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validate Pakistani phone
  static String? validatePakistaniPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (!value.isValidPakistaniPhone) {
      return 'Please enter a valid Pakistani phone (03xxxxxxxxx)';
    }
    return null;
  }

  // ========================================================================
  // PASSWORD VALIDATIONS 🔐
  // ========================================================================

  /// Validate password (basic)
  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (!value.isValidPassword) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate strong password
  static String? validateStrongPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  /// Validate password confirmation
  static String? validatePasswordMatch(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ========================================================================
  // NAME VALIDATIONS 👤
  // ========================================================================

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (!value.isValidName) {
      return 'Name should contain only letters and spaces';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validate full name
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (!value.isValidFullName) {
      return 'Please enter your full name (first and last name)';
    }
    return null;
  }

  /// Validate username
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (!value.isValidUsername) {
      return 'Username must be 3-20 characters (letters, numbers, underscore)';
    }
    return null;
  }

  // ========================================================================
  // LENGTH VALIDATIONS 📏
  // ========================================================================

  /// Validate minimum length
  static String? validateMinLength(
    String? value,
    int minLength, {
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field'} is required';
    }
    if (value.length < minLength) {
      return '${fieldName ?? 'Field'} must be at least $minLength characters';
    }
    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(
    String? value,
    int maxLength, {
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field'} is required';
    }
    if (value.length > maxLength) {
      return '${fieldName ?? 'Field'} must not exceed $maxLength characters';
    }
    return null;
  }

  /// Validate length range
  static String? validateLengthRange(
    String? value,
    int minLength,
    int maxLength, {
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field'} is required';
    }
    if (value.length < minLength || value.length > maxLength) {
      return '${fieldName ?? 'Field'} must be between $minLength and $maxLength characters';
    }
    return null;
  }

  /// Validate exact length
  static String? validateExactLength(
    String? value,
    int length, {
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field'} is required';
    }
    if (value.length != length) {
      return '${fieldName ?? 'Field'} must be exactly $length characters';
    }
    return null;
  }

  // ========================================================================
  // NUMERIC VALIDATIONS 🔢
  // ========================================================================

  /// Validate numeric
  static String? validateNumeric(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field'} is required';
    }
    if (!value.isNumeric) {
      return '${fieldName ?? 'Field'} must be a number';
    }
    return null;
  }

  /// Validate integer
  static String? validateInteger(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field'} is required';
    }
    if (!value.isInteger) {
      return '${fieldName ?? 'Field'} must be a whole number';
    }
    return null;
  }

  /// Validate number range
  static String? validateNumberRange(
    String? value,
    num min,
    num max, {
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field'} is required';
    }
    final number = num.tryParse(value);
    if (number == null) {
      return '${fieldName ?? 'Field'} must be a number';
    }
    if (number < min || number > max) {
      return '${fieldName ?? 'Field'} must be between $min and $max';
    }
    return null;
  }

  /// Validate minimum value
  static String? validateMinValue(String? value, num min, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field'} is required';
    }
    final number = num.tryParse(value);
    if (number == null) {
      return '${fieldName ?? 'Field'} must be a number';
    }
    if (number < min) {
      return '${fieldName ?? 'Field'} must be at least $min';
    }
    return null;
  }

  /// Validate maximum value
  static String? validateMaxValue(String? value, num max, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Field'} is required';
    }
    final number = num.tryParse(value);
    if (number == null) {
      return '${fieldName ?? 'Field'} must be a number';
    }
    if (number > max) {
      return '${fieldName ?? 'Field'} must not exceed $max';
    }
    return null;
  }

  // ========================================================================
  // URL & WEB VALIDATIONS 🌐
  // ========================================================================

  /// Validate URL
  static String? validateURL(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'URL is required';
    }
    if (!value.isValidURL) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  /// Validate domain
  static String? validateDomain(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Domain is required';
    }
    if (!value.isValidDomain) {
      return 'Please enter a valid domain';
    }
    return null;
  }

  /// Validate IP address
  static String? validateIP(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'IP address is required';
    }
    if (!value.isValidIP) {
      return 'Please enter a valid IP address';
    }
    return null;
  }

  // ========================================================================
  // DOCUMENT VALIDATIONS 📄
  // ========================================================================

  /// Validate CNIC
  static String? validateCNIC(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CNIC is required';
    }
    if (!value.isValidCNIC) {
      return 'Please enter a valid CNIC (xxxxx-xxxxxxx-x)';
    }
    return null;
  }

  /// Validate credit card
  static String? validateCreditCard(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Card number is required';
    }
    if (!value.isValidCreditCard) {
      return 'Please enter a valid card number';
    }
    return null;
  }

  // ========================================================================
  // DATE & TIME VALIDATIONS 📅
  // ========================================================================

  /// Validate date
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }
    if (!value.isValidDate) {
      return 'Please enter a valid date';
    }
    return null;
  }

  /// Validate age (minimum)
  static String? validateAge(String? value, int minAge) {
    if (value == null || value.isEmpty) {
      return 'Date of birth is required';
    }
    try {
      final birthDate = DateTime.parse(value);
      final age = birthDate.getAge();
      if (age < minAge) {
        return 'You must be at least $minAge years old';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  /// Validate future date
  static String? validateFutureDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }
    try {
      final date = DateTime.parse(value);
      if (date.isBefore(DateTime.now())) {
        return 'Date must be in the future';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  /// Validate past date
  static String? validatePastDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }
    try {
      final date = DateTime.parse(value);
      if (date.isAfter(DateTime.now())) {
        return 'Date must be in the past';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  // ========================================================================
  // CUSTOM REGEX VALIDATION 🎯
  // ========================================================================

  /// Validate with custom regex
  static String? validateRegex(
    String? value,
    String pattern,
    String errorMessage,
  ) {
    if (value == null || value.isEmpty) {
      return 'Field is required';
    }
    final regex = RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return errorMessage;
    }
    return null;
  }

  // ========================================================================
  // COMPOSITE VALIDATORS 🔗
  // ========================================================================

  /// Validate multiple conditions (returns first error)
  static String? validateMultiple(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }

  /// Combine validators with AND logic
  static String? Function(String?) combineAnd(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}

// ============================================================================
// PASSWORD STRENGTH INDICATOR 💪
// ============================================================================

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = password.passwordStrength;
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.lightGreen,
      Colors.green,
    ];
    final labels = ['Very Weak', 'Weak', 'Fair', 'Good', 'Strong'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: strength / 4,
          backgroundColor: Colors.grey.shade300,
          color: colors[strength],
        ),
        const SizedBox(height: 4),
        Text(
          strength > 0 ? labels[strength - 1] : 'Enter password',
          style: TextStyle(
            fontSize: 12,
            color: strength > 0 ? colors[strength] : Colors.grey,
          ),
        ),
      ],
    );
  }
}
