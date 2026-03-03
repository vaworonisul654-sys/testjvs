import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = "J.A.R.V.I.S.";
  
  // Premium Color Palette (iOS Parity)
  static const Color emerald = Color(0xFF00E08E);
  static const Color obsidian = Color(0xFF02070F);
  static const Color sapphireGlow = Color(0xFF0D4033);
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color errorRed = Color(0xFFEF4444);
  
  // Keys (Placeholders, should be in secrets.dart)
  static const String geminiKey = "YOUR_GEMINI_API_KEY";
  
  // Default Settings
  static const String defaultNativeLang = "Russian";
  static const String defaultTargetLang = "English";
}
