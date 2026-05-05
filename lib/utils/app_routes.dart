import 'package:flutter/material.dart';
import '../screens/main_screen.dart';

class AppRoutes {
  static const String home = '/';
  // Sau này thêm các route khác như: login, post_detail, profile...

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(
            currentUsername: 'thanh_hau',
            currentNickname: 'Thanh Hau',
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
