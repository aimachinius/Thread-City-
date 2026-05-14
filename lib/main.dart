import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/post_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/home_provider.dart';
import 'providers/profile_provider.dart';
import 'utils/app_routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
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

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        Provider<IPostRepository>.value(value: postRepository),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProxyProvider<AuthProvider, HomeProvider>(
          create: (context) =>
              HomeProvider(postRepository, context.read<AuthProvider>()),
          update: (context, auth, previous) =>
              HomeProvider(postRepository, auth),
        ),
        ChangeNotifierProvider(create: (_) => ProfileProvider(postRepository)),
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
