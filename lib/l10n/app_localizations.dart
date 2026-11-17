import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_strings.dart';
import 'translations_vi.dart';
import 'translations_en.dart';
import 'translations_ja.dart';

export 'app_strings.dart';

class AppLocalizations {
  final Locale locale;
  final AppStrings strings;

  static AppStrings _current = const TranslationsVi();
  static AppStrings get current => _current;

  static void updateCurrent(Locale locale) {
    _current = getStringsForLocale(locale);
  }

  AppLocalizations(this.locale, this.strings) {
    _current = strings;
  }

  static const List<Locale> supportedLocales = [
    Locale('vi', 'VN'),
    Locale('en', 'US'),
    Locale('ja', 'JP'),
    Locale('vi'),
    Locale('en'),
    Locale('ja'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppStrings of(BuildContext context) {
    try {
      final instance = Localizations.of<AppLocalizations>(context, AppLocalizations);
      return instance?.strings ?? _current;
    } catch (_) {
      return _current;
    }
  }

  static AppStrings getStringsForLocale(Locale locale) {
    switch (locale.languageCode.toLowerCase()) {
      case 'vi':
        return const TranslationsVi();
      case 'ja':
        return const TranslationsJa();
      case 'en':
      default:
        return const TranslationsEn();
    }
  }

  /// Tự động phân giải ngôn ngữ theo vùng (Region / System Locale)
  static Locale resolveLocale(Locale? deviceLocale, Iterable<Locale> supportedLocales) {
    if (deviceLocale == null) {
      return const Locale('vi', 'VN');
    }

    final lang = deviceLocale.languageCode.toLowerCase();
    final country = deviceLocale.countryCode?.toUpperCase();

    // 1. Vùng Việt Nam
    if (lang == 'vi' || country == 'VN') {
      return const Locale('vi', 'VN');
    }

    // 2. Vùng Nhật Bản
    if (lang == 'ja' || country == 'JP') {
      return const Locale('ja', 'JP');
    }

    // 3. Mặc định quốc tế: Tiếng Anh
    return const Locale('en', 'US');
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['vi', 'en', 'ja'].contains(locale.languageCode.toLowerCase());
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    final strings = AppLocalizations.getStringsForLocale(locale);
    AppLocalizations._current = strings;
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale, strings));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsHelper on AppLocalizations {
  static AppStrings getStringForLocaleExact(Locale locale) {
    return AppLocalizations.getStringsForLocale(locale);
  }
}

extension BuildContextLocalizations on BuildContext {
  AppStrings get l10n => AppLocalizations.of(this);
}
