import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers/app_providers.dart';
import 'core/notifications/notification_navigation.dart';
import 'core/theme/app_theme.dart';
import 'features/customer/screens/customer_shell.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/splash/splash_screen.dart';
import 'firebase/firebase_options.dart';

class FestivoScrollBehavior extends ScrollBehavior {
  const FestivoScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  NotificationService.instance.registerBackgroundHandler();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService.instance.initialize();
    NotificationService.log('Firebase initialized');
  } catch (error, stackTrace) {
    NotificationService.log('Firebase init failed: $error\n$stackTrace');
  }

  runApp(const ProviderScope(child: FestivoApp()));
}

class FestivoApp extends ConsumerStatefulWidget {
  const FestivoApp({super.key});

  @override
  ConsumerState<FestivoApp> createState() => _FestivoAppState();
}

class _FestivoAppState extends ConsumerState<FestivoApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.processPendingActions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkProvider);
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => ScrollConfiguration(
        behavior: const FestivoScrollBehavior(),
        child: child!,
      ),
      home: const SplashScreenV2(),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomerShell();
  }
}
