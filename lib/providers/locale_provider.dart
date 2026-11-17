import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

class LocaleProvider with ChangeNotifier {
  static const String _prefKey = 'selected_locale_code';

  Locale? _locale;
  String _currentLanguageCode = 'auto'; // 'auto', 'vi', 'en', 'ja'
  bool _isInitialized = false;
  Future<void>? _initFuture;

  Locale? get locale => _locale;
  String get currentLanguageCode => _currentLanguageCode;
  bool get isInitialized => _isInitialized;
  bool get isAuto => _currentLanguageCode == 'auto';

  LocaleProvider() {
    _initFuture = _loadPreference();
  }

  Future<void> init() async {
    await (_initFuture ??= _loadPreference());
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefKey) ?? 'auto';
      _applyLanguageCode(code, notify: false);
    } catch (_) {
      _locale = null;
      _currentLanguageCode = 'auto';
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _applyLanguageCode(String code, {bool notify = true}) {
    _currentLanguageCode = code;
    switch (code) {
      case 'vi':
        _locale = const Locale('vi', 'VN');
        break;
      case 'en':
        _locale = const Locale('en', 'US');
        break;
      case 'ja':
        _locale = const Locale('ja', 'JP');
        break;
      case 'auto':
      default:
        _locale = null; // null kích hoạt localeResolutionCallback tự động nhận diện theo vùng
        _currentLanguageCode = 'auto';
        break;
    }
    if (_locale != null) {
      AppLocalizations.updateCurrent(_locale!);
    }
    if (notify) {
      notifyListeners();
    }
  }

  /// Đặt ngôn ngữ bằng mã ('auto', 'vi', 'en', 'ja') và lưu vào SharedPreferences
  Future<void> setLanguage(String code) async {
    _applyLanguageCode(code);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (code == 'auto') {
        await prefs.remove(_prefKey);
      } else {
        await prefs.setString(_prefKey, code);
      }
    } catch (e) {
      debugPrint('[LocaleProvider] Error saving locale preference: $e');
    }
  }

  /// Đặt Locale cụ thể (hoặc null để về tự động)
  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      await setLanguage('auto');
    } else {
      await setLanguage(locale.languageCode.toLowerCase());
    }
  }

  /// Xóa thiết lập thủ công và quay về tự động
  Future<void> clearLocale() async {
    await setLanguage('auto');
  }
}
