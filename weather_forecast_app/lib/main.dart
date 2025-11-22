import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'package:weather_forecast_app/controllers/setting_controller.dart';
import 'package:weather_forecast_app/views/auth/signup_screen.dart';
import 'core/app_theme.dart';
import 'views/auth/signin_screen.dart';
import 'views/forecast/daily_forecast_screen.dart';
import 'firebase_options.dart'; // Ensure this file exists and contains DefaultFirebaseOptions
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Load persisted settings before showing UI so initial state is correct.
  final settings = SettingsController();
  await settings.load();

  // Initialize notifications (FCM) after Firebase and settings are loaded
  final notifService = NotificationService();
  // kick off token retrieval and subscribe if user previously enabled
  // Fire-and-forget token init and subscription
  () async {
    try {
      await notifService.initAndGetToken(settings);
      // Access settings in a runtime-safe way. If anything unexpected is
      // present (older compiled code or a different runtime shape), catch
      // the error so the app doesn't crash on startup.
      try {
        if (settings.weatherNotificationsEnabled) {
          await notifService.subscribeToTopic('weather_alerts');
        }
      } catch (e) {
        // log and continue
        if (kDebugMode) print('Could not read weatherNotificationsEnabled: $e');
      }
    } catch (e) {
      if (kDebugMode) print('Notification init failed: $e');
    }
  }();

  runApp(
    ChangeNotifierProvider<SettingsController>.value(
      value: settings,
      child: const WeatherForecastApp(),
    ),
  );
}

class WeatherForecastApp extends StatelessWidget {
  const WeatherForecastApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Weather Forecast App",
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.theme == 'light'
          ? ThemeMode.light
          : settings.theme == 'dark'
          ? ThemeMode.dark
          : ThemeMode.system,
      home: const SigninScreen(),
      routes: {
        '/signup': (context) => const SignupScreen(),
        '/dailyForecast': (context) => DailyForecastScreen(),
        //'/forgotPassword': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}
