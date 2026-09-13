import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ViMai Kids design tokens. All product UI should read from here.
class VimaiColor {
  // Brand commercial palette
  static const primaryPink = Color(0xFFFF2A6D);
  static const accentOrange = Color(0xFFFF7E40);
  static const leafGreen = Color(0xFF22C55E);
  static const textDark = Color(0xFF1E2229);
  static const bgWarmCream = Color(0xFFFDFBF4);

  static const skyTop = Color(0xFFB8DCF5);
  static const skyMid = Color(0xFFE7F4FF);
  static const grass = leafGreen;
  static const grassDeep = Color(0xFF16A34A);
  static const cloud = Color(0xFFFFFFFF);
  static const path = Color(0xFFE8C48A);
  static const cream = bgWarmCream;
  static const creamDeep = Color(0xFFFFE8D2);
  static const surface = Color(0xFFFFFCF8);
  static const ink = textDark;
  static const inkSoft = Color(0xFF5B6470);
  static const line = Color(0x1A1E2229);

  static const coral = primaryPink;
  static const coralSoft = Color(0xFFFFD6E3);
  static const sky = Color(0xFF4C8DDB);
  static const skySoft = Color(0xFFD5E6FF);
  static const mint = leafGreen;
  static const mintSoft = Color(0xFFD4F3E3);
  static const grape = Color(0xFF7B63E0);
  static const grapeSoft = Color(0xFFE4DCFC);
  static const peach = accentOrange;
  static const peachSoft = Color(0xFFFFE1D0);
  static const honey = Color(0xFFE39B1A);
  static const honeySoft = Color(0xFFFFE9C4);
  static const teal = Color(0xFF2A9B94);
  static const tealSoft = Color(0xFFD4F3F0);

  static const correct = leafGreen;
  static const retry = accentOrange;
  static const mascot = Color(0xFFFFB07A);
  static const mascotBelly = Color(0xFFFFF0E4);
  static const mascotBlush = Color(0xFFFF9AA8);

  static const candyGradient = LinearGradient(
    colors: [primaryPink, accentOrange],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class VimaiSize {
  static const iconSm = 22.0;
  static const iconMd = 28.0;
  static const iconLg = 36.0;
  static const iconHero = 56.0;
  static const touchMin = 48.0;
  static const touchKid = 70.0;
  static const glyphTile = 60.0;
  static const mascotHeader = 80.0;
  static const mascotHero = 120.0;
  static const mascotCard = 72.0;
}

class VimaiSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const maxContent = 720.0;
  static const maxWide = 960.0;
  static const maxHome = 1200.0;
  static const maxHero = 1180.0;
}

class VimaiBreakpoints {
  static const phone = 600.0;
  static const tablet = 1024.0;

  static bool isPhone(double width) => width < phone;
  static bool isTablet(double width) => width >= phone && width < tablet;
  static bool isDesktop(double width) => width >= tablet;
}

class VimaiRadius {
  static const sm = 14.0;
  static const md = 20.0;
  static const lg = 24.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

/// Child-friendly type scale — Baloo 2 for body, Poppins for brand titles.
/// Avoid const TextStyle so Vietnamese diacritics render via Google Fonts.
class VimaiType {
  static TextStyle get display => GoogleFonts.baloo2(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: VimaiColor.ink,
        height: 1.15,
      );
  static TextStyle get greeting => GoogleFonts.baloo2(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: VimaiColor.ink,
        height: 1.18,
      );
  static TextStyle get title => GoogleFonts.baloo2(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: VimaiColor.ink,
        height: 1.22,
      );
  static TextStyle get subtitle => GoogleFonts.baloo2(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: VimaiColor.inkSoft,
        height: 1.35,
      );
  static TextStyle get cardTitle => GoogleFonts.baloo2(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: VimaiColor.ink,
      );
  static TextStyle get cardBody => GoogleFonts.baloo2(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: VimaiColor.inkSoft,
        height: 1.3,
      );
  static TextStyle get button => GoogleFonts.baloo2(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        height: 1.15,
      );
  static TextStyle get label => GoogleFonts.baloo2(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: VimaiColor.ink,
        height: 1.25,
      );
  static TextStyle get caption => GoogleFonts.baloo2(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: VimaiColor.inkSoft,
        height: 1.3,
      );
  static TextStyle get brand => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: VimaiColor.ink,
        height: 1.15,
      );
  static TextStyle get lessonTitle => GoogleFonts.baloo2(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: VimaiColor.ink,
        height: 1.25,
      );
}

class VimaiShadow {
  static const card = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6)),
  ];
  static const soft = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4)),
  ];
  static const lift = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 10)),
  ];
  static const island = [
    BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 3)),
  ];
}

class VimaiMotion {
  static const tap = Duration(milliseconds: 90);
  static const hover = Duration(milliseconds: 140);
  static const feedback = Duration(milliseconds: 220);
  static const page = Duration(milliseconds: 280);
  static const enter = Duration(milliseconds: 420);

  static const curve = Curves.easeOutCubic;
  static const bounceOut = Curves.easeOutBack;

  static Duration of(BuildContext context, Duration duration) {
    if (MediaQuery.disableAnimationsOf(context)) return Duration.zero;
    return duration;
  }
}

class SubjectLook {
  final Color color;
  final Color soft;
  final String glyph;
  final String cue;
  final IconData icon;
  const SubjectLook({
    required this.color,
    required this.soft,
    required this.glyph,
    required this.cue,
    required this.icon,
  });
}

class VimaiSubject {
  static const japanese = SubjectLook(
    color: VimaiColor.grape,
    soft: VimaiColor.grapeSoft,
    glyph: 'あ',
    cue: 'あ い う',
    icon: Icons.menu_book_rounded,
  );
  static const vietnamese = SubjectLook(
    color: VimaiColor.sky,
    soft: VimaiColor.skySoft,
    glyph: 'A',
    cue: 'A B C',
    icon: Icons.record_voice_over_rounded,
  );
  static const math = SubjectLook(
    color: VimaiColor.mint,
    soft: VimaiColor.mintSoft,
    glyph: '3',
    cue: '1 2 3',
    icon: Icons.calculate_rounded,
  );
  static const thinking = SubjectLook(
    color: VimaiColor.grape,
    soft: VimaiColor.grapeSoft,
    glyph: '◆',
    cue: '◆ ○ △',
    icon: Icons.psychology_alt_rounded,
  );
  static const creativity = SubjectLook(
    color: VimaiColor.peach,
    soft: VimaiColor.peachSoft,
    glyph: '✎',
    cue: '✎ ✿',
    icon: Icons.palette_rounded,
  );
  static const games = SubjectLook(
    color: VimaiColor.honey,
    soft: VimaiColor.honeySoft,
    glyph: '▶',
    cue: '★ ▶',
    icon: Icons.sports_esports_rounded,
  );
}

/// Branding asset paths (do not rename files).
class VimaiBrandAssets {
  static const companyLogo = 'assets/images/branding/vimai.jpg';
  static const kidsLogo = 'assets/images/branding/vimai_kids_logo.svg';
  static const copyright =
      'Phát triển bởi ViMai • © 2026 ViMai · MaiMai. All rights reserved.';
}
