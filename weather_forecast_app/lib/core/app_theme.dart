import 'package:flutter/material.dart';

class AppTheme {
  // App Colors
  static const Color kPrimaryColor = Color(0xFF0A3D62);
  static const Color kSurfaceLight = Color(0xFFF4F8FF);
  static const Color kWhite = Colors.white;
  static const Color kBlack = Colors.black;

  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: kPrimaryColor,
      scaffoldBackgroundColor: kSurfaceLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: kPrimaryColor,
        foregroundColor: kWhite,
        titleTextStyle: TextStyle(color: kWhite),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        prefixIconColor: kPrimaryColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: kWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: kPrimaryColor),
      ),
      cardTheme: CardThemeData(
        color: kWhite,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: kPrimaryColor,
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: const AppBarTheme(
        backgroundColor: kPrimaryColor,
        foregroundColor: kWhite,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: kWhite),
        bodyMedium: TextStyle(color: kWhite),
      ),
    );
  }
}
