import 'package:flutter/material.dart';
import 'package:weather_forecast_app/views/auth/signup_screen.dart';
import 'core/app_theme.dart';
import 'views/auth/signin_screen.dart';
import 'views/forecast/daily_forecast_screen.dart';

void main() {
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
