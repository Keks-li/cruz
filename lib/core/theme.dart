import 'package:flutter/material.dart';

class AppTheme {
  // Admin Navy Design System
  static const adminPrimaryColor = Color(0xFF0F172A); // Deep Navy
  static const adminBackgroundColor = Color(0xFFF8FAFC); // Very Light Grey-Blue
  static const adminSurfaceColor = Colors.white;
  static const adminTextColor = Color(0xFF1E293B); // Dark Slate
  static const adminAccentRevenue = Color(0xFF10B981); // Emerald Green
  static const adminAccentAlert = Color(0xFFEF4444); // Soft Red
  static const adminInputFill = Color(0xFFF1F5F9);
  
  // Agent Green Design System
  static const agentPrimaryColor = Color(0xFF00A86B); // Jungle Green
  static const agentBackgroundColor = Color(0xFFF8FAFC); // Very Light Grey-Blue
  static const agentSurfaceColor = Colors.white;
  static const agentTextColor = Color(0xFF1E293B); // Dark Slate
  static const agentAccentRegister = Color(0xFF7C3AED); // Deep Purple
  static const agentAccentSync = Color(0xFFF59E0B); // Golden Orange
  static const agentInputFill = Color(0xFFF1F5F9);
  
  static const primaryColor = adminPrimaryColor; // Default
  static const secondaryColor = Color(0xFF10B981);
  static const backgroundColor = Color(0xFFF8F9FE);
  static const dangerColor = Color(0xFFEF4444);

  // Premium Shadow
  static const cardShadow = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    )
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: agentPrimaryColor,
        primary: agentPrimaryColor,
        secondary: secondaryColor,
        surface: Colors.white,
        background: agentBackgroundColor,
      ),
      scaffoldBackgroundColor: agentBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: agentTextColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: agentTextColor),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
    );
  }
}
