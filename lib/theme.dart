import 'package:flutter/material.dart';

class ThemeNotifier with ChangeNotifier {
  ThemeData _themeData;

  ThemeNotifier([ThemeData? themeData]) : _themeData = themeData ?? darkTheme;

  ThemeData get theme => _themeData;

  void updateTheme(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }
}

final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Colors.black,
    secondary: Colors.blueAccent,
    surface: Colors.black,
    onSurface: Colors.white,
    outline: Colors.white24,
  ),
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white, fontFamily: 'SF-Pro-Text'),
    bodyMedium: TextStyle(color: Colors.white70, fontFamily: 'SF-Pro-Text'),
    labelLarge: TextStyle(
      color: Colors.white,
      fontFamily: 'SF-Pro-Text',
      fontWeight: FontWeight.w700,
    ),
  ),
  iconTheme: const IconThemeData(color: Colors.white),
);

final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Colors.white,
    secondary: Colors.blue,
    surface: Colors.white,
    onSurface: Colors.black,
    outline: Colors.black26,
  ),
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black, fontFamily: 'SF-Pro-Text'),
    bodyMedium: TextStyle(color: Colors.black87, fontFamily: 'SF-Pro-Text'),
    labelLarge: TextStyle(
      color: Colors.black,
      fontFamily: 'SF-Pro-Text',
      fontWeight: FontWeight.w700,
    ),
  ),
  iconTheme: const IconThemeData(color: Colors.black),
);