import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'vimai_tokens.dart';

class AppTheme {
  static const Color primaryColor = VimaiColor.primaryPink;
  static const Color backgroundColor = VimaiColor.bgWarmCream;
  static const Color textDark = VimaiColor.textDark;
  static const Color textLight = VimaiColor.inkSoft;

  static const Color hiraganaColor = VimaiColor.primaryPink;
  static const Color katakanaColor = VimaiColor.sky;
  static const Color mathColor = VimaiColor.leafGreen;
  static const Color gamesColor = VimaiColor.honey;

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: VimaiColor.primaryPink,
        primary: VimaiColor.primaryPink,
        secondary: VimaiColor.accentOrange,
        surface: VimaiColor.surface,
        brightness: Brightness.light,
      ),
    );

    final baloo = GoogleFonts.baloo2TextTheme(base.textTheme).apply(
      bodyColor: VimaiColor.textDark,
      displayColor: VimaiColor.textDark,
    );
    final brandTitle = GoogleFonts.poppins(
      color: VimaiColor.textDark,
      fontSize: 22,
      fontWeight: FontWeight.w800,
    );

    return base.copyWith(
      textTheme: baloo,
      primaryTextTheme: baloo,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textDark, size: 22),
        titleTextStyle: brandTitle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(VimaiSize.touchKid, VimaiSize.touchKid),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VimaiRadius.lg),
          ),
          textStyle: GoogleFonts.baloo2(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: VimaiColor.coralSoft,
        backgroundColor: VimaiColor.surface,
        labelStyle: GoogleFonts.baloo2(fontWeight: FontWeight.w700, color: VimaiColor.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VimaiRadius.pill)),
      ),
    );
  }
}
