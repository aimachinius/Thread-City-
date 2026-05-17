import 'package:flutter/material.dart';
import '../screens/main_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Temporarily bypass auth and go directly to main screen
    return const MainScreen();
  }
}
