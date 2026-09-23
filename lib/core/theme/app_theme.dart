import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
    ),

    scaffoldBackgroundColor: Colors.white,

    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),

    cardTheme: const CardThemeData(
      elevation: 2,
      margin: EdgeInsets.zero,
    ),

    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(
          double.infinity,
          50,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
  );
}