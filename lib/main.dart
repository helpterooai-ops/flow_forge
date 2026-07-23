import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const FlowForgeApp());
}

class FlowForgeApp extends StatelessWidget {
  const FlowForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowForge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'IBMPlexSansArabic',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAFC),
          foregroundColor: Color(0xFF1E293B),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Color(0xFF1E293B),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 14, color: Color(0xFF64748B)),
          bodySmall: TextStyle(fontFamily: 'IBMPlexSansArabic', fontSize: 12, color: Color(0xFF94A3B8)),
          titleLarge: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w700, fontSize: 20, color: Color(0xFF1E293B)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
