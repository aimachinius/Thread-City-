import 'package:flutter/material.dart';
import '../screens/main_screen.dart';
import '../auth/register_screen.dart';
import '../auth/login_screen.dart';
import '../screens/post_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../l10n/app_localizations.dart';

class AppRoutes {
  static const String home = '/';
  static const String register = '/register';
  static const String login = '/login';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Xử lý deep route /post/:id trên Web và trong App
    final uri = Uri.tryParse(settings.name ?? '');
    if (uri != null && uri.pathSegments.length == 2 && uri.pathSegments[0] == 'post') {
      final postId = int.tryParse(uri.pathSegments[1]);
      if (postId != null && postId > 0) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PostDetailScreen(postId: postId),
        );
      } else {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Scaffold(
            appBar: AppBar(leading: const BackButton()),
            body: Center(
              child: Text(
                context.l10n.postNotFoundOrDeleted,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        );
      }
    }

    // Xử lý deep route /user/:username hoặc /profile/:username
    if (uri != null && uri.pathSegments.length == 2 && (uri.pathSegments[0] == 'user' || uri.pathSegments[0] == 'profile')) {
      final username = uri.pathSegments[1];
      if (username.isNotEmpty) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ProfileScreen(
            currentUsername: username,
            currentNickname: username,
            viewingUserId: username,
          ),
        );
      }
    }

    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MainScreen(),
        );
      case register:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RegisterScreen(),
        );
      case login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}

