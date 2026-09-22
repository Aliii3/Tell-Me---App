import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle manrope({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        decoration: decoration,
      );

  static TextStyle sora({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  // Dot-matrix / pixel display font for bento card titles
  static TextStyle dotMatrix({
    double fontSize = 32,
    Color? color,
    double letterSpacing = 2,
  }) =>
      GoogleFonts.spaceMono(
        fontSize: fontSize,
        color: color,
        letterSpacing: letterSpacing,
        height: 1.1,
      );

  // ── Named styles ──────────────────────────────────────────────────────────

  static TextStyle displayXl({Color? color}) => sora(
        fontSize: 46,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.1,
      );

  static TextStyle displayLg({Color? color}) => sora(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.2,
      );

  static TextStyle displayMd({Color? color}) => sora(
        fontSize: 27,
        fontWeight: FontWeight.w800,
        color: color,
      );

  static TextStyle headingLg({Color? color}) => manrope(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: color,
      );

  static TextStyle headingMd({Color? color}) => manrope(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle headingSm({Color? color}) => manrope(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle bodyLg({Color? color, FontWeight? weight}) => manrope(
        fontSize: 15,
        fontWeight: weight ?? FontWeight.w500,
        color: color,
      );

  static TextStyle bodyMd({Color? color, FontWeight? weight}) => manrope(
        fontSize: 14,
        fontWeight: weight ?? FontWeight.w500,
        color: color,
      );

  static TextStyle bodySm({Color? color, FontWeight? weight}) => manrope(
        fontSize: 13,
        fontWeight: weight ?? FontWeight.w500,
        color: color,
      );

  static TextStyle caption({Color? color}) => manrope(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle micro({Color? color}) => manrope(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle label({Color? color}) => manrope(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.3,
      );
}
