import 'dart:developer' as dev;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/post_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/message_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'providers/home_provider.dart';
import 'providers/user_provider.dart';
import 'providers/post_provider.dart';
import 'providers/message_provider.dart';
import 'providers/notification_provider.dart';
import 'utils/app_routes.dart';
import 'core/config/app_config.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'auth/login_screen.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  dev.log('✅ [FIREBASE] Core ready', name: 'main');

  final authRepository = AuthRepository(AppConfig.authUrl);
  final postRepository = PostRepository();
  final userRepository = UserRepository();
  final messageRepository = MessageRepository();
  final notificationRepository = NotificationRepository();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        Provider<IPostRepository>.value(value: postRepository),
        Provider<IUserRepository>.value(value: userRepository),
        Provider<IMessageRepository>.value(value: messageRepository),
        Provider<INotificationRepository>.value(value: notificationRepository),
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider(authRepository)),
        ChangeNotifierProxyProvider<app_auth.AuthProvider, HomeProvider>(
          create: (context) =>
              HomeProvider(postRepository, context.read<app_auth.AuthProvider>()),
          update: (context, auth, previous) =>
              previous ?? HomeProvider(postRepository, auth),
        ),
        ChangeNotifierProxyProvider<app_auth.AuthProvider, PostProvider>(
          create: (context) =>
              PostProvider(postRepository, context.read<app_auth.AuthProvider>()),
          update: (context, auth, previous) =>
              previous ?? PostProvider(postRepository, auth),
        ),
        ChangeNotifierProxyProvider<app_auth.AuthProvider, MessageProvider>(
          create: (context) =>
              MessageProvider(messageRepository, context.read<app_auth.AuthProvider>()),
          update: (context, auth, previous) {
            if (previous != null) {
              previous.updateAuth(auth);
              return previous;
            }
            return MessageProvider(messageRepository, auth);
          },
        ),
        ChangeNotifierProvider(
          create: (context) => UserProvider(userRepository, postRepository),
        ),
        ChangeNotifierProxyProvider<app_auth.AuthProvider, NotificationProvider>(
          create: (context) => NotificationProvider(notificationRepository, context.read<app_auth.AuthProvider>()),
          update: (context, auth, previous) =>
              previous ?? NotificationProvider(notificationRepository, auth),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<app_auth.AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: scaffoldMessengerKey,
          scrollBehavior: const AppScrollBehavior(),
          debugShowCheckedModeBanner: false,
          title: 'Threads Clone',
          theme: AppTheme.lightTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          // Sử dụng home thay vì initialRoute để tự động chuyển màn hình
          home: auth.isAuthenticated 
            ? const MainScreen() 
            : const LoginScreen(),
        );
      },
    );
  }
}
