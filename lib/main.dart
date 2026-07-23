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
        
        // إعدادات العناوين (تستخدم الوزن العريض Bold)
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAFC),
          foregroundColor: Color(0xFF1E293B),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontWeight: FontWeight.w700, // Bold
            fontSize: 22,
            color: Color(0xFF1E293B),
          ),
        ),
        
        // إعدادات النصوص العامة
        textTheme: const TextTheme(
          // العناوين
          titleLarge: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontWeight: FontWeight.w700, // Bold
            fontSize: 20,
            color: Color(0xFF1E293B),
          ),
          // النصوص العادية
          bodyMedium: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontWeight: FontWeight.w400, // Regular
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
          bodySmall: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontWeight: FontWeight.w400, // Regular
            fontSize: 12,
            color: Color(0xFF94A3B8),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
