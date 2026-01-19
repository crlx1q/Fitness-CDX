import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitness_coach/core/theme/app_theme.dart';
import 'package:fitness_coach/presentation/providers/app_provider.dart';
import 'package:fitness_coach/presentation/screens/home_screen.dart';
import 'package:fitness_coach/presentation/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI style immediately (non-blocking)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Lock to portrait mode (non-blocking, fire and forget)
  unawaited(SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]));

  // Start app immediately, init heavy stuff in background
  runApp(const FitLockApp());
  
  // Initialize locale after first frame (non-blocking)
  // Timezone init moved to NotificationService (lazy)
  WidgetsBinding.instance.addPostFrameCallback((_) {
    initializeDateFormatting('ru_RU', null);
  });
}

class FitLockApp extends StatelessWidget {
  const FitLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: MaterialApp(
        title: 'FitLock',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _AppLoader(),
      ),
    );
  }
}

class _AppLoader extends StatelessWidget {
  const _AppLoader();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const _SplashScreen();
        }

        if (!provider.settings.hasCompletedOnboarding) {
          return const OnboardingScreen();
        }

        return const HomeScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logotype.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 24),
            Text(
              'FitLock',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Тренируйся — получай время',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
