import 'package:flutter/material.dart';
import 'package:timerin/core/theme/app_colors.dart';

/// Skala tipografi Timerin berdasarkan `docs/02-DESIGN.md`: 12 / 14 / 16 / 20 / 28.
abstract final class AppTypography {
  static const String fontFamily = 'Inter';

  static const TextStyle display28 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    letterSpacing: -0.5,
  );

  static const TextStyle title20 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    letterSpacing: -0.3,
  );

  static const TextStyle body16 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  static const TextStyle body16Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const TextStyle body14 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  static const TextStyle body14Muted = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static const TextStyle caption12 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static const TextStyle button16 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static const TextTheme textTheme = TextTheme(
    headlineLarge: display28,
    titleLarge: title20,
    bodyLarge: body16,
    bodyMedium: body14,
    bodySmall: caption12,
    labelLarge: button16,
  );
}
