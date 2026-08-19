import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PharmacyApp());
}

class PharmacyApp extends StatelessWidget {
  const PharmacyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0E6B57);
    return MaterialApp(
      title: 'ABC Pharmacy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary),
        scaffoldBackgroundColor: const Color(0xFFEEF3F1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF16241F),
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
