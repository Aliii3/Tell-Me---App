import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

extension BuildContextX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get textColor =>
      isDark ? AppColors.darkText : AppColors.lightText;

  Color get text2Color =>
      isDark ? AppColors.darkText2 : AppColors.lightText2;

  Color get text3Color =>
      isDark ? AppColors.darkText3 : AppColors.lightText3;

  Color get bgColor =>
      isDark ? AppColors.darkBg : AppColors.lightBg;

  Color get surfaceColor =>
      isDark ? AppColors.darkSurface : AppColors.lightSurface;

  Color get surface2Color =>
      isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;

  Color get borderColor =>
      isDark ? AppColors.darkBorder : AppColors.lightBorder;

  Color get cardBgColor =>
      isDark ? AppColors.darkCardBg : AppColors.lightCardBg;

  Color get cyanColor =>
      isDark ? AppColors.darkCyan : AppColors.lightCyan;

  Color get cyanDimColor =>
      isDark ? AppColors.darkCyanDim : AppColors.lightCyanDim;

  Color get indigoColor =>
      isDark ? AppColors.darkIndigo : AppColors.lightIndigo;

  Color get navBgColor =>
      isDark ? AppColors.darkNavBg : AppColors.lightNavBg;

  LinearGradient get accentGradient =>
      isDark ? AppColors.accentGradientDark : AppColors.accentGradientLight;

  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
}

extension DateTimeX on DateTime {
  String get dayName {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

extension StringX on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
