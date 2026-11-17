import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thread_app/core/config/app_config.dart';
import 'package:thread_app/utils/app_routes.dart';
import 'package:thread_app/screens/post_detail_screen.dart';
import 'package:thread_app/screens/profile_screen.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  group('Share Feature Unit Tests', () {
    test('AppConfig.publicAppUrl returns valid non-empty public web origin', () {
      final publicUrl = AppConfig.publicAppUrl;
      expect(publicUrl, isNotEmpty);
      expect(publicUrl.startsWith('http://') || publicUrl.startsWith('https://'), isTrue);
      // Ensure it does not contain API route
      expect(publicUrl.contains('/api'), isFalse);
    });

    test('AppConfig.getPostShareUrl formats clean public URL without /api/', () {
      const postId = 123;
      final shareUrl = AppConfig.getPostShareUrl(postId);

      expect(shareUrl, endsWith('/post/123'));
      expect(shareUrl.contains('/api/'), isFalse);
      expect(shareUrl.contains('/api/post'), isFalse);
      expect(shareUrl, equals('${AppConfig.publicAppUrl}/post/123'));
    });

    test('AppRoutes.onGenerateRoute parses /post/123 into PostDetailScreen with postId = 123', () {
      const settings = RouteSettings(name: '/post/123');
      final route = AppRoutes.onGenerateRoute(settings);

      expect(route, isA<MaterialPageRoute>());
      final materialRoute = route as MaterialPageRoute;

      // Build widget tree for the route
      final widget = materialRoute.builder(MockBuildContext());
      expect(widget, isA<PostDetailScreen>());
      final postDetailScreen = widget as PostDetailScreen;
      expect(postDetailScreen.postId, equals(123));
      expect(postDetailScreen.post, isNull);
    });

    test('AppRoutes.onGenerateRoute handles invalid post id safely without crashing', () {
      const invalidSettings = RouteSettings(name: '/post/abc');
      final route = AppRoutes.onGenerateRoute(invalidSettings);

      expect(route, isA<MaterialPageRoute>());
      final materialRoute = route as MaterialPageRoute;

      // Must build safely and show error screen instead of throwing exception
      final widget = materialRoute.builder(MockBuildContext());
      expect(widget, isA<Scaffold>());
    });

    test('AppRoutes.onGenerateRoute handles negative post id safely without crashing', () {
      const negativeSettings = RouteSettings(name: '/post/-5');
      final route = AppRoutes.onGenerateRoute(negativeSettings);

      expect(route, isA<MaterialPageRoute>());
      final materialRoute = route as MaterialPageRoute;

      final widget = materialRoute.builder(MockBuildContext());
      expect(widget, isA<Scaffold>());
    });

    test('ShareParams initializes with correct subject, text, and sharePositionOrigin', () {
      const originRect = Rect.fromLTWH(10, 20, 100, 50);
      final params = ShareParams(
        text: 'Check out: ${AppConfig.getPostShareUrl(99)}',
        subject: 'Thread-City',
        sharePositionOrigin: originRect,
      );

      expect(params.text, contains('/post/99'));
      expect(params.text, isNot(contains('/api/')));
      expect(params.subject, equals('Thread-City'));
      expect(params.sharePositionOrigin, equals(originRect));
      expect(SharePlus.instance, isNotNull);
    });

    test('AppConfig.getProfileShareUrl formats clean public URL without /api/', () {
      const username = 'thanhhau';
      final shareUrl = AppConfig.getProfileShareUrl(username);

      expect(shareUrl, endsWith('/user/thanhhau'));
      expect(shareUrl.contains('/api/'), isFalse);
      expect(shareUrl, equals('${AppConfig.publicAppUrl}/user/thanhhau'));
    });

    test('AppRoutes.onGenerateRoute parses /user/:username into ProfileScreen', () {
      const settings = RouteSettings(name: '/user/thanhhau');
      final route = AppRoutes.onGenerateRoute(settings);

      expect(route, isA<MaterialPageRoute>());
      final materialRoute = route as MaterialPageRoute;

      final widget = materialRoute.builder(MockBuildContext());
      expect(widget, isA<ProfileScreen>());
      final profileScreen = widget as ProfileScreen;
      expect(profileScreen.currentUsername, equals('thanhhau'));
    });

    test('AppRoutes.onGenerateRoute parses /profile/:username into ProfileScreen', () {
      const settings = RouteSettings(name: '/profile/alice');
      final route = AppRoutes.onGenerateRoute(settings);

      expect(route, isA<MaterialPageRoute>());
      final materialRoute = route as MaterialPageRoute;

      final widget = materialRoute.builder(MockBuildContext());
      expect(widget, isA<ProfileScreen>());
      final profileScreen = widget as ProfileScreen;
      expect(profileScreen.currentUsername, equals('alice'));
    });
  });
}

class MockBuildContext extends Fake implements BuildContext {}
