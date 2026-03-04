import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DesignSystem {
  // Colors (iOS Parity)
  static const Color emerald = Color(0xFF00E08E);
  static const Color background = Color(0xFF05070F);
  static const Color glassWhite = Color(0x0DFFFFFF); // white at 5%
  static const Color glassBorder = Color(0x1AFFFFFF); // white at 10%
  static const Color accentBlue = Color(0xFF00B2FF);

  // Gradients
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF05070F),
      Color(0xFF0A0E1E),
    ],
  );

  // Text Styles
  static TextStyle get titleLarge => GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle get headlineMedium => GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    color: Colors.white.withOpacity(0.9),
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
    color: emerald.withOpacity(0.7),
  );

  // Decoration Utils
  static BoxDecoration glassDecoration({double radius = 24.0}) {
    return BoxDecoration(
      color: glassWhite,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: glassBorder, width: 1.0),
    );
  }
}
