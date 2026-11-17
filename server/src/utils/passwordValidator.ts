export interface PasswordValidationResult {
  isValid: boolean;
  errors: string[];
  ruleResults: {
    length: boolean;
    uppercase: boolean;
    lowercase: boolean;
    digit: boolean;
    specialChar: boolean;
    noWhitespace: boolean;
    notCommon: boolean;
  };
}

export const MIN_PASSWORD_LENGTH = 8;
export const MAX_PASSWORD_LENGTH = 64;

// Regex patterns
const UPPERCASE_REGEX = /[A-Z]/;
const LOWERCASE_REGEX = /[a-z]/;
const DIGIT_REGEX = /[0-9]/;
// Special characters: ASCII punctuation and symbols matching Dart validator
const SPECIAL_CHAR_REGEX = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?~`]/;
// Any whitespace: space, \t, \n, \r, \f, etc.
const WHITESPACE_REGEX = /\s/;

// Canonical blacklist of weak / common passwords (normalized lowercase)
export const CANONICAL_BLACKLIST = new Set<string>([
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
]);

export const hasValidLength = (password: string): boolean =>
  password.length >= MIN_PASSWORD_LENGTH && password.length <= MAX_PASSWORD_LENGTH;

export const hasUppercase = (password: string): boolean =>
  UPPERCASE_REGEX.test(password);

export const hasLowercase = (password: string): boolean =>
  LOWERCASE_REGEX.test(password);

export const hasDigit = (password: string): boolean =>
  DIGIT_REGEX.test(password);

export const hasSpecialChar = (password: string): boolean =>
  SPECIAL_CHAR_REGEX.test(password);

export const hasNoWhitespace = (password: string): boolean =>
  !WHITESPACE_REGEX.test(password);

export const isNotCommon = (password: string): boolean => {
  const normalized = password.trim().toLowerCase();
  return !CANONICAL_BLACKLIST.has(normalized);
};

export const validatePassword = (password: string | undefined | null): PasswordValidationResult => {
  const pwd = typeof password === 'string' ? password : '';
  const errors: string[] = [];

  const ruleLength = hasValidLength(pwd);
  if (!ruleLength) {
    if (pwd.length < MIN_PASSWORD_LENGTH) {
      errors.push(`Password must be at least ${MIN_PASSWORD_LENGTH} characters.`);
    } else {
      errors.push(`Password must not exceed ${MAX_PASSWORD_LENGTH} characters.`);
    }
  }

  const ruleUppercase = hasUppercase(pwd);
  if (!ruleUppercase) {
    errors.push('Password must contain at least one uppercase letter.');
  }

  const ruleLowercase = hasLowercase(pwd);
  if (!ruleLowercase) {
    errors.push('Password must contain at least one lowercase letter.');
  }

  const ruleDigit = hasDigit(pwd);
  if (!ruleDigit) {
    errors.push('Password must contain at least one number.');
  }

  const ruleSpecialChar = hasSpecialChar(pwd);
  if (!ruleSpecialChar) {
    errors.push('Password must contain at least one special character.');
  }

  const ruleNoWhitespace = hasNoWhitespace(pwd);
  if (!ruleNoWhitespace) {
    errors.push('Password must not contain whitespace.');
  }

  const ruleNotCommon = isNotCommon(pwd);
  if (!ruleNotCommon) {
    errors.push('Password is commonly used or too weak.');
  }

  const ruleResults = {
    length: ruleLength,
    uppercase: ruleUppercase,
    lowercase: ruleLowercase,
    digit: ruleDigit,
    specialChar: ruleSpecialChar,
    noWhitespace: ruleNoWhitespace,
    notCommon: ruleNotCommon,
  };

  const isValid =
    ruleLength &&
    ruleUppercase &&
    ruleLowercase &&
    ruleDigit &&
    ruleSpecialChar &&
    ruleNoWhitespace &&
    ruleNotCommon;

  return {
    isValid,
    errors,
    ruleResults,
  };
};
