import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// Global App Color Tokens
// Used across light/dark themes and all features
// ─────────────────────────────────────────────
class AppColors {
  AppColors._();

  // ── Brand / Primary ──────────────────────────────────────
  static const softRose  = Color(0xFFE8A0A7);
  static const deepRose  = Color(0xFFD98A92);
  static const gold      = Color(0xFFD4AF37);

  // ── Light-mode backgrounds & surfaces ────────────────────
  static const pageBg    = Color(0xFFFDF5F6);
  static const cardBg    = Colors.white;
  static const glightBg  = Color(0xFFF9ECED);
  static const gborder   = Color(0xFFF0D4D7);

  // ── Light-mode text ───────────────────────────────────────
  static const textDark  = Color(0xFF3D1C20);
  static const textMid   = Color(0xFF6B3D42);
  static const textLight = Color(0xFFA07A7E);

  // ── Accent border colours used in stat cards ─────────────
  static const borderBlue   = Color(0xFF3B82F6);
  static const borderGreen  = Color(0xFF22C55E);
  static const borderOrange = Color(0xFFF97316);
  static const borderGold   = Color(0xFFD4AF37);

  // ── Activity card background tints ───────────────────────
  static const actGreenBg  = Color(0xFFDCFCE7);
  static const actBlueBg   = Color(0xFFDBEAFE);
  static const actYellowBg = Color(0xFFFEF9C3);

  // ── Dark-mode equivalents ─────────────────────────────────
  static const dNavy    = Color(0xFF8B5CF6);
  static const dNavy2   = Color(0xFF7C3AED);
  static const dWhite   = Color(0xFF1E3050);
  static const dGbg     = Color(0xFF0F1B2D);
  static const dGlight  = Color(0xFF162236);
  static const dGborder = Color(0xFF243553);
  static const dTd      = Color(0xFFF0F4FF);
  static const dTm      = Color(0xFF94A3B8);
  static const dTl      = Color(0xFF5C7292);

  // ── Profile-specific palette ──────────────────────────────
  static const profilePink       = Color(0xFFCB8490);
  static const profilePinkLight  = Color(0xFFDDA0AA);
  static const profilePinkBg     = Color(0xFFF5EAEC);
  static const profilePinkCard   = Color(0xFFFFFFFF);
  static const profilePinkBorder = Color(0xFFF0DCE0);
  static const profilePinkFill   = Color(0xFFF9F0F2);
  static const profileRed        = Color(0xFFCB4B5A);
  static const profileTextDark   = Color(0xFF2D1B20);
  static const profileTextMid    = Color(0xFF7A5560);
  static const profileTextLight  = Color(0xFFAA8890);
  static const profileGreen      = Color(0xFF4CAF50);
  static const profileIconBlue   = Color(0xFF7B9FD4);
  static const profileIconGreen  = Color(0xFF6DC099);
  static const profileIconPurple = Color(0xFF9B7FD4);
  static const profileIconOrange = Color(0xFFE8A87C);

  // ── Auth screens ──────────────────────────────────────────
  static const authPrimaryPink   = Color(0xFFE58B97);
  static const authLightPinkFill = Color(0xFFF9E7E9);

  // ── Semantic helpers (theme-aware) ────────────────────────
  static Color accent(bool dark)  => dark ? dNavy    : softRose;
  static Color accent2(bool dark) => dark ? dNavy2   : deepRose;
  static Color bg(bool dark)      => dark ? dGbg     : pageBg;
  static Color card(bool dark)    => dark ? dWhite   : cardBg;
  static Color border(bool dark)  => dark ? dGborder : gborder;
  static Color input(bool dark)   => dark ? dGlight  : glightBg;
  static Color textD(bool dark)   => dark ? dTd      : textDark;
  static Color textM(bool dark)   => dark ? dTm      : textMid;
  static Color textL(bool dark)   => dark ? dTl      : textLight;
  static Color navBar(bool dark)  => dark ? dGlight  : cardBg;

  static Color profileBg(bool dark)    => dark ? const Color(0xFF0F1B2D) : profilePinkBg;
  static Color profileCard(bool dark)  => dark ? const Color(0xFF162236) : profilePinkCard;
  static Color profileTextD(bool dark) => dark ? const Color(0xFFF0F4FF) : profileTextDark;
  static Color profileTextM(bool dark) => dark ? const Color(0xFF94A3B8) : profileTextMid;
  static Color profileBorder(bool dark)=> dark ? const Color(0xFF243553) : profilePinkBorder;

  static BoxShadow shadow(bool dark) => BoxShadow(
    color: dark ? Colors.black.withOpacity(.55) : softRose.withOpacity(.12),
    blurRadius: dark ? 16 : 12,
    offset: const Offset(0, 2),
  );

  static BoxShadow shadowMd(bool dark) => BoxShadow(
    color: dark ? Colors.black.withOpacity(.7) : softRose.withOpacity(.22),
    blurRadius: dark ? 24 : 20,
    offset: const Offset(0, 4),
  );
}
