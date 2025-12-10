import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const LifeLensApp());
}

class LifeLensApp extends StatelessWidget {
  const LifeLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.dark(useMaterial3: true);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LifeLens Studio',
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFF050814),
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: const Color(0xFF66D9FF),
          secondary: const Color(0xFF9B8CFF),
        ),
        textTheme: baseTheme.textTheme.apply(
          fontFamily: 'Roboto',
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B84FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}