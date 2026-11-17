import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thread_app/l10n/app_localizations.dart';
import 'package:thread_app/l10n/translations_vi.dart';
import 'package:thread_app/l10n/translations_en.dart';
import 'package:thread_app/l10n/translations_ja.dart';
import 'package:thread_app/providers/locale_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('i18n Regional Resolution Tests', () {
    const supported = [
      Locale('vi', 'VN'),
      Locale('en', 'US'),
      Locale('ja', 'JP'),
    ];

    test('Device locale null defaults to Vietnamese (vi_VN)', () {
      final resolved = AppLocalizations.resolveLocale(null, supported);
      expect(resolved.languageCode, equals('vi'));
      expect(resolved.countryCode, equals('VN'));
    });

    test('Vietnamese languageCode or VN countryCode resolves to vi_VN', () {
      final res1 = AppLocalizations.resolveLocale(const Locale('vi', 'VN'), supported);
      expect(res1.languageCode, equals('vi'));

      final res2 = AppLocalizations.resolveLocale(const Locale('vi'), supported);
      expect(res2.languageCode, equals('vi'));

      final res3 = AppLocalizations.resolveLocale(const Locale('en', 'VN'), supported);
      expect(res3.languageCode, equals('vi'));
    });

    test('Japanese languageCode or JP countryCode resolves to ja_JP', () {
      final res1 = AppLocalizations.resolveLocale(const Locale('ja', 'JP'), supported);
      expect(res1.languageCode, equals('ja'));

      final res2 = AppLocalizations.resolveLocale(const Locale('ja'), supported);
      expect(res2.languageCode, equals('ja'));

      final res3 = AppLocalizations.resolveLocale(const Locale('en', 'JP'), supported);
      expect(res3.languageCode, equals('ja'));
    });

    test('Other languages and regions resolve to English (en_US) international default', () {
      final res1 = AppLocalizations.resolveLocale(const Locale('en', 'US'), supported);
      expect(res1.languageCode, equals('en'));

      final res2 = AppLocalizations.resolveLocale(const Locale('fr', 'FR'), supported);
      expect(res2.languageCode, equals('en'));

      final res3 = AppLocalizations.resolveLocale(const Locale('de', 'DE'), supported);
      expect(res3.languageCode, equals('en'));
    });
  });

  group('i18n Translation Dictionary Parity Tests', () {
    const vi = TranslationsVi();
    const en = TranslationsEn();
    const ja = TranslationsJa();

    test('All languages have non-empty common navigation labels', () {
      for (final dict in [vi, en, ja]) {
        expect(dict.appTitle, isNotEmpty);
        expect(dict.navHome, isNotEmpty);
        expect(dict.navSearch, isNotEmpty);
        expect(dict.navNewThread, isNotEmpty);
        expect(dict.navActivity, isNotEmpty);
        expect(dict.navProfile, isNotEmpty);
      }
    });

    test('All languages have non-empty auth and password labels', () {
      for (final dict in [vi, en, ja]) {
        expect(dict.loginButton, isNotEmpty);
        expect(dict.registerButton, isNotEmpty);
        expect(dict.changePasswordTitle, isNotEmpty);
        expect(dict.changePasswordSubtitle, isNotEmpty);
        expect(dict.changePasswordSuccessSub, isNotEmpty);
        expect(dict.passwordCannotMatchOld, isNotEmpty);
        expect(dict.changePasswordFailure, isNotEmpty);
        expect(dict.forgotPasswordTitle, isNotEmpty);
        expect(dict.ruleLength, isNotEmpty);
        expect(dict.ruleUppercase, isNotEmpty);
        expect(dict.ruleDigit, isNotEmpty);
        expect(dict.ruleSpecial, isNotEmpty);
        expect(dict.ruleMatch, isNotEmpty);
      }
    });

    test('All languages have non-empty chat and messaging keys', () {
      for (final dict in [vi, en, ja]) {
        expect(dict.chatStatusActive, isNotEmpty);
        expect(dict.chatStatusOffline, isNotEmpty);
        expect(dict.chatSingleMessagePendingSender, isNotEmpty);
        expect(dict.chatPendingSenderNotice, isNotEmpty);
        expect(dict.replyToAcceptPrompt, isNotEmpty);
        expect(dict.userFallback, isNotEmpty);
        expect(dict.justNow, isNotEmpty);
        expect(dict.tryAgain, isNotEmpty);
        expect(dict.cannotPlayVideo, isNotEmpty);
        expect(dict.sentPhotoNotification, isNotEmpty);
        expect(dict.sentVideoNotification, isNotEmpty);
        expect(dict.postNoLongerExists, isNotEmpty);
      }
    });

    test('All languages have non-empty detailed auth error keys', () {
      for (final dict in [vi, en, ja]) {
        expect(dict.emailAlreadyInUse, isNotEmpty);
        expect(dict.weakPassword, isNotEmpty);
        expect(dict.invalidCredentials, isNotEmpty);
        expect(dict.accountNotFound, isNotEmpty);
        expect(dict.loginFailure, isNotEmpty);
        expect(dict.googleLoginFailure, isNotEmpty);
        expect(dict.registerSuccess, isNotEmpty);
        expect(dict.registerFailure, isNotEmpty);
        expect(dict.passwordsDoNotMatch, isNotEmpty);
        expect(dict.enterPassword, isNotEmpty);
        expect(dict.enterConfirmPassword, isNotEmpty);
        expect(dict.currentPasswordIncorrect, isNotEmpty);
        expect(dict.sessionExpiredReLogin, isNotEmpty);
      }
    });

    test('All languages have non-empty search and profile labels', () {
      for (final dict in [vi, en, ja]) {
        expect(dict.past7Days, isNotEmpty);
        expect(dict.noTrendingHashtags, isNotEmpty);
        expect(dict.noAccountsFound, isNotEmpty);
        expect(dict.noPostsFound, isNotEmpty);
        expect(dict.noHashtagsFound, isNotEmpty);
        expect(dict.noRepostsYet, isNotEmpty);
        expect(dict.followersLabel, isNotEmpty);
        expect(dict.followingLabel, isNotEmpty);
        expect(dict.noFollowersYet, isNotEmpty);
      }
    });

    test('Parameterized strings format accurately across languages', () {
      expect(vi.timeMinutes(5), equals('5m'));
      expect(en.timeMinutes(5), equals('5m'));
      expect(ja.timeMinutes(5), equals('5分前'));

      expect(vi.sharedCountSuccess(3), contains('3'));
      expect(en.sharedCountSuccess(3), contains('3'));
      expect(ja.sharedCountSuccess(3), contains('3'));
    });
  });

  group('LocaleProvider State & Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Default provider state is auto (null)', () async {
      final provider = LocaleProvider();
      await provider.init();
      expect(provider.locale, isNull);
      expect(provider.isAuto, isTrue);
    });

    test('Switching language persists to SharedPreferences', () async {
      final provider = LocaleProvider();
      await provider.init();

      await provider.setLocale(const Locale('en', 'US'));
      expect(provider.locale?.languageCode, equals('en'));
      expect(provider.isAuto, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_locale_code'), equals('en'));

      await provider.setLocale(const Locale('ja', 'JP'));
      expect(provider.locale?.languageCode, equals('ja'));
      expect(prefs.getString('selected_locale_code'), equals('ja'));

      await provider.clearLocale();
      expect(provider.locale, isNull);
      expect(provider.isAuto, isTrue);
      expect(prefs.containsKey('selected_locale_code'), isFalse);
    });
  });
}
