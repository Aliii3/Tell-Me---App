import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand palette ─────────────────────────────────────────────────────────
  static const heritageSage = Color(0xFF667A68);   // Legacy (kept for compat)
  static const darkSage     = Color(0xFF4F5D52);   // Legacy
  static const midnightNavy = Color(0xFF0D1B34);   // Primary Background
  static const deepNavy     = Color(0xFF0A1628);   // Secondary Background
  static const softWhite    = Color(0xFFF8FAFC);   // Primary Text
  static const warmStone    = Color(0xFFD6D3D1);   // Supporting Neutral
  static const charcoal     = Color(0xFF1F2937);   // Supporting Neutral

  // ── Purple / Aurora accent ────────────────────────────────────────────────
  static const violet      = Color(0xFF7C3AED);
  static const violetMid   = Color(0xFF8B5CF6);   // medium purple
  static const violetLight = Color(0xFFA78BFA);   // lavender
  static const violetBlush = Color(0xFFF9A8D4);   // soft pink aurora tip
  static const violetDim   = Color(0x267C3AED);   // 15%
  static const violetGlow  = Color(0x407C3AED);   // 25%
  static const violetDeep  = Color(0xFF5B21B6);   // darker violet

  // ── Premium base backgrounds ──────────────────────────────────────────────
  static const premiumBg   = Color(0xFF0B1220);   // deepest dark
  static const premiumBg2  = Color(0xFF111827);
  static const premiumBg3  = Color(0xFF161B26);

  // ── Dark mode tokens ──────────────────────────────────────────────────────
  static const darkBg           = midnightNavy;
  static const darkBg2          = deepNavy;
  static const darkSurface      = Color(0x0AFFFFFF);  // 4%
  static const darkSurface2     = Color(0x12FFFFFF);  // 7%
  static const darkSurface3     = Color(0x1AFFFFFF);  // 10%
  static const darkBorder       = Color(0x14FFFFFF);  // 8%
  static const darkBorder2      = Color(0x24FFFFFF);  // 14%
  static const darkText         = softWhite;
  static const darkText2        = Color(0x99F8FAFC);  // 60%
  static const darkText3        = Color(0x52F8FAFC);  // 32%
  static const darkCyan         = violet;
  static const darkCyanDim      = violetDim;
  static const darkCyanGlow     = violetGlow;
  static const darkIndigo       = violetDeep;
  static const darkIndigoDim    = Color(0x335B21B6);  // 20%
  static const darkCardBg       = Color(0xB80B1220);  // 72%
  static const darkNavBg        = Color(0xB80B1220);  // 72%
  static const darkInputBg      = Color(0x0FFFFFFF);  // 6%
  static const darkToggleTrack  = charcoal;
  static const darkDarkCard     = Color(0xFF080E18);

  // ── Light mode tokens ─────────────────────────────────────────────────────
  static const lightBg           = Color(0xFFF5F6FA);
  static const lightBg2          = Color(0xFFECEEF5);
  static const lightSurface      = Color(0xBFFFFFFF);  // 75%
  static const lightSurface2     = Color(0xEBFFFFFF);  // 92%
  static const lightSurface3     = Color(0xFFFFFFFF);
  static const lightBorder       = Color(0x120D0D1A);  // 7%
  static const lightBorder2      = Color(0x1C0D0D1A);  // 11%
  static const lightText         = Color(0xFF0D0D1A);
  static const lightText2        = Color(0x8C0D0D1A);  // 55%
  static const lightText3        = Color(0x4D0D0D1A);  // 30%
  static const lightCyan         = violet;
  static const lightCyanDim      = violetDim;
  static const lightIndigo       = violetDeep;
  static const lightIndigoDim    = Color(0x1E5B21B6);  // 12%
  static const lightCardBg       = Color(0xE6FFFFFF);  // 90%
  static const lightNavBg        = Color(0xE6F5F6FA);  // 90%
  static const lightInputBg      = Color(0x0A000000);  // 4%
  static const lightToggleTrack  = warmStone;

  // ── Semantic / utility ────────────────────────────────────────────────────
  static const red          = Color(0xFFEF4444);
  static const white        = Color(0xFFFFFFFF);
  static const black        = Color(0xFF111111);
  static const darkOnboard  = Color(0xFF1C1C1E);
  static const lightOnboard = Color(0xFFE9E9EB);

  // ── Gradient helpers ──────────────────────────────────────────────────────
  static const accentGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violetDeep, violet],
  );

  static const accentGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violetDeep, violet],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4C1D95), violet],
  );

  // ── Calendar event colors ─────────────────────────────────────────────────
  static const calendarGray   = Color(0xFFEEEEEE);
  static const calendarSage    = Color(0xFFDDE5DE);
  static const calendarNeutral = Color(0xFFE8EBE8);

  // ── Lumina (premium light theme) ──────────────────────────────────────────
  static const lumBg          = Color(0xFF9AA89A);  // muted sage (screen bg)
  static const lumBgTop       = Color(0xFF8E9C8A);  // darker sage gradient top
  static const lumBgBottom    = Color(0xFFA8A49C);  // warm muted gray bottom
  static const lumSurface     = Color(0xFFFFFFFF);
  static const lumSurface2    = Color(0xFFF3F4F5);
  static const lumSurfaceHigh = Color(0xFFEDEEEF);

  // Mint / Teal – primary
  static const lumPrimary     = Color(0xFF006B57);
  static const lumPrimaryMid  = Color(0xFF62DBBC);
  static const lumPrimaryLight= Color(0xFF7CF3D3);
  static const lumPrimaryDim  = Color(0x1A006B57);

  // Peach – secondary gradient
  static const lumPeach       = Color(0xFFFEB194);
  static const lumPeachDark   = Color(0xFF8A4F38);

  // Lavender – tertiary gradient
  static const lumLavender    = Color(0xFFE6D8FE);
  static const lumLavDark     = Color(0xFF635979);

  // Text
  static const lumText        = Color(0xFF191C1D);
  static const lumText2       = Color(0xFF1E2B28);
  static const lumText3       = Color(0xFF3A4D48);

  // Borders
  static const lumBorder      = Color(0xFFBCCAC3);
  static const lumBorder2     = Color(0xFFE1E3E4);

  // Dark bento card
  static const lumDark        = Color(0xFF3A4540);
  static const lumDark2       = Color(0xFF2D3330);
  static const lumDarkText    = Color(0xFFE0F2EE);
}
