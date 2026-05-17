import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/post_repository.dart';
import 'data/repositories/user_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/home_provider.dart';
import 'providers/user_provider.dart';
import 'providers/post_provider.dart';
import 'utils/app_routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/app_config.dart';
import 'firebase_options.dart';

import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ [FIREBASE] Core ready');

  final authRepository = AuthRepository(AppConfig.authUrl);
  final postRepository = PostRepository();
  final userRepository = UserRepository();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        Provider<IPostRepository>.value(value: postRepository),
        Provider<IUserRepository>.value(value: userRepository),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProxyProvider<AuthProvider, HomeProvider>(
          create: (context) =>
              HomeProvider(postRepository, context.read<AuthProvider>()),
          update: (context, auth, previous) =>
              HomeProvider(postRepository, auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PostProvider>(
          create: (context) =>
              PostProvider(postRepository, context.read<AuthProvider>()),
          update: (context, auth, previous) =>
              PostProvider(postRepository, auth),
        ),
        ChangeNotifierProvider(
          create: (context) => UserProvider(userRepository, postRepository),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Threads Clone',
          theme: AppTheme.lightTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          // Sử dụng home thay vì initialRoute để tự động chuyển màn hình
          home: auth.isAuthenticated 
            ? MainScreen() 
            : LoginScreen(),
        );
      },
    );
  }
}
