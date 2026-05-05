import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/post_repository.dart';
import 'providers/auth_provider.dart';
import 'utils/app_routes.dart';

void main() {
  // Khởi tạo các dependencies (Repo)
  final authRepository = AuthRepository();
  final postRepository = PostRepository();

  runApp(
    MultiProvider(
      providers: [
        Provider<IAuthRepository>.value(value: authRepository),
        Provider<IPostRepository>.value(value: postRepository),
        
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Threads Clone',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      // App - Provider - Material App - Route
      onGenerateRoute: AppRoutes.onGenerateRoute,
      initialRoute: AppRoutes.home,
    );
  }
}
