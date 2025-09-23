import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:weather_forecast_app/views/auth/signup_screen.dart';
import 'core/app_theme.dart';
import 'views/auth/signin_screen.dart';
import 'views/forecast/daily_forecast_screen.dart';
import 'firebase_options.dart'; // Ensure this file exists and contains DefaultFirebaseOptions

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // for web/ios/android configs
  );
  runApp(const WeatherForecastApp());
}

class WeatherForecastApp extends StatelessWidget {
  const WeatherForecastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Weather Forecast App",
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const SigninScreen(),
      routes: {
        '/signup': (context) => const SignupScreen(),
        '/dailyForecast': (context) => const DailyForecastScreen(),
        //'/forgotPassword': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}
