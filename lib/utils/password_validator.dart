class PasswordValidationResult {
  final bool isValid;
  final List<String> errors;
  final Map<String, bool> ruleResults;

  const PasswordValidationResult({
    required this.isValid,
    required this.errors,
    required this.ruleResults,
  });

  bool get hasLength => ruleResults['length'] ?? false;
  bool get hasUppercase => ruleResults['uppercase'] ?? false;
  bool get hasLowercase => ruleResults['lowercase'] ?? false;
  bool get hasDigit => ruleResults['digit'] ?? false;
  bool get hasSpecialChar => ruleResults['specialChar'] ?? false;
  bool get hasNoWhitespace => ruleResults['noWhitespace'] ?? false;
  bool get isNotCommon => ruleResults['notCommon'] ?? false;
}

class PasswordValidator {
  static const int minLength = 8;
  static const int maxLength = 64;

  // Regex patterns
  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp _lowercaseRegex = RegExp(r'[a-z]');
  static final RegExp _digitRegex = RegExp(r'[0-9]');
  // Special characters: ASCII punctuation and symbols
  static final RegExp _specialCharRegex =
      RegExp(r'''[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?~`]''');
  // Any whitespace: space, \t, \n, \r, \f, etc.
  static final RegExp _whitespaceRegex = RegExp(r'\s');

  // Canonical blacklist of weak / common passwords (normalized lowercase)
  static const Set<String> canonicalBlacklist = {
    '12345678',
    '123456789',
    '1234567890',
    'password',
    'password123',
    'password123!',
    'pass1234',
    'passw0rd',
    'admin123',
    'admin1234',
    'administrator',
    'root1234',
    'qwerty123',
    'abcdefgh',
    'abc12345',
    'welcome1',
    'letmein1',
    'iloveyou',
    'threadcity',
    'threadcity123',
    'threadcity123!',
  };

  static bool hasValidLength(String password) =>
      password.length >= minLength && password.length <= maxLength;

  static bool hasUppercase(String password) =>
      _uppercaseRegex.hasMatch(password);

  static bool hasLowercase(String password) =>
      _lowercaseRegex.hasMatch(password);

  static bool hasDigit(String password) => _digitRegex.hasMatch(password);

  static bool hasSpecialChar(String password) =>
      _specialCharRegex.hasMatch(password);

  static bool hasNoWhitespace(String password) =>
      !_whitespaceRegex.hasMatch(password);

  static bool isNotCommon(String password) {
    final normalized = password.trim().toLowerCase();
    return !canonicalBlacklist.contains(normalized);
  }

  static PasswordValidationResult validate(String? password) {
    final pwd = password ?? '';
    final errors = <String>[];

    final ruleLength = hasValidLength(pwd);
    if (!ruleLength) {
      if (pwd.length < minLength) {
        errors.add('Password must be at least $minLength characters.');
      } else {
        errors.add('Password must not exceed $maxLength characters.');
      }
    }

    final ruleUppercase = hasUppercase(pwd);
    if (!ruleUppercase) {
      errors.add('Password must contain at least one uppercase letter.');
    }

    final ruleLowercase = hasLowercase(pwd);
    if (!ruleLowercase) {
      errors.add('Password must contain at least one lowercase letter.');
    }

    final ruleDigit = hasDigit(pwd);
    if (!ruleDigit) {
      errors.add('Password must contain at least one number.');
    }

    final ruleSpecialChar = hasSpecialChar(pwd);
    if (!ruleSpecialChar) {
      errors.add('Password must contain at least one special character.');
    }

    final ruleNoWhitespace = hasNoWhitespace(pwd);
    if (!ruleNoWhitespace) {
      errors.add('Password must not contain whitespace.');
    }

    final ruleNotCommon = isNotCommon(pwd);
    if (!ruleNotCommon) {
      errors.add('Password is commonly used or too weak.');
    }

    final ruleResults = {
      'length': ruleLength,
      'uppercase': ruleUppercase,
      'lowercase': ruleLowercase,
      'digit': ruleDigit,
      'specialChar': ruleSpecialChar,
      'noWhitespace': ruleNoWhitespace,
      'notCommon': ruleNotCommon,
    };

    final isValid = ruleLength &&
        ruleUppercase &&
        ruleLowercase &&
        ruleDigit &&
        ruleSpecialChar &&
        ruleNoWhitespace &&
        ruleNotCommon;

    return PasswordValidationResult(
      isValid: isValid,
      errors: errors,
      ruleResults: ruleResults,
    );
  }
}
