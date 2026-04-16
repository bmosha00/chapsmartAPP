import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ChapSmart Design System
class C {
  // ─── Warm cream palette ──────────
  static const Color bg = Color(0xFFFDF6EC);
  static const Color bgWarm = Color(0xFFFAF0E2);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0x1FB48C5A);
  static const Color borderHover = Color(0x4DF7931A);

  // Brand
  static const Color btc = Color(0xFFF7931A);
  static const Color btcDark = Color(0xFFD97C10);

  // Semantic
  static const Color green = Color(0xFF16A34A);
  static const Color red = Color(0xFFDC2626);
  static const Color blue = Color(0xFF2563EB);
  static const Color purple = Color(0xFF8B5CF6);

  // Text
  static const Color t1 = Color(0xFF1A1207);
  static const Color t2 = Color(0xFF6B5A42);
  static const Color t3 = Color(0xFF9C8B74);

  // Service accent colors
  static const Color send = btc;
  static const Color airtime = blue;
  static const Color buySats = green;
  static const Color merchant = purple;

  // Tier
  static const Color bronze = Color(0xFFCD7F32);
  static const Color silver = Color(0xFFA8A9AD);
  static const Color gold = Color(0xFFFFD700);

  // Nostr
  static const Color nostr = purple;

  // Shadows
  static final shadow = BoxShadow(
    color: const Color(0xFF785014).withOpacity(0.04),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );
  static final shadowMd = BoxShadow(
    color: const Color(0xFF785014).withOpacity(0.06),
    blurRadius: 32,
    offset: const Offset(0, 8),
  );
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: C.bg,
      fontFamily: 'DM Sans',
      colorScheme: const ColorScheme.light(
        primary: C.btc,
        secondary: C.btcDark,
        surface: C.card,
        error: C.red,
        onPrimary: Colors.white,
        onSurface: C.t1,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: C.t1, letterSpacing: -0.5, height: 1.15),
        displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: C.t1, letterSpacing: -0.5),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: C.t1, letterSpacing: -0.3),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: C.t1),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: C.t1, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: C.t2, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: C.t3),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
        labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.t2),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.t3, letterSpacing: 0.5),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.t1, fontFamily: 'DM Sans'),
        iconTheme: IconThemeData(color: C.t1),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: C.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.border, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.border, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.btc, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.red, width: 1.5)),
        hintStyle: const TextStyle(color: C.t3, fontSize: 15),
        labelStyle: const TextStyle(color: C.t2, fontSize: 13, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: C.t1,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'DM Sans'),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: C.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: C.border)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: C.border, thickness: 1),
    );
  }
}
