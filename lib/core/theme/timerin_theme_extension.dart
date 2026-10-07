import 'package:flutter/material.dart';
import 'package:timerin/core/theme/app_colors.dart';

/// Extension untuk token warna kustom Timerin di luar ColorScheme standar Flutter.
@immutable
class TimerinThemeExtension extends ThemeExtension<TimerinThemeExtension> {
  const TimerinThemeExtension({
    required this.accent,
    required this.warning,
    required this.overlayBg,
    required this.surfaceVariant,
    required this.border,
    required this.textMuted,
    required this.textMutedHeader,
  });

  final Color accent;
  final Color warning;
  final Color overlayBg;
  final Color surfaceVariant;
  final Color border;
  final Color textMuted;
  final Color textMutedHeader;

  /// Nilai default sesuai Design Tokens.
  static const TimerinThemeExtension defaultTheme = TimerinThemeExtension(
    accent: AppColors.accent,
    warning: AppColors.warning,
    overlayBg: AppColors.overlayBg,
    surfaceVariant: AppColors.surfaceVariant,
    border: AppColors.border,
    textMuted: AppColors.textMuted,
    textMutedHeader: AppColors.textMutedHeader,
  );

  @override
  ThemeExtension<TimerinThemeExtension> copyWith({
    Color? accent,
    Color? warning,
    Color? overlayBg,
    Color? surfaceVariant,
    Color? border,
    Color? textMuted,
    Color? textMutedHeader,
  }) {
    return TimerinThemeExtension(
      accent: accent ?? this.accent,
      warning: warning ?? this.warning,
      overlayBg: overlayBg ?? this.overlayBg,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      border: border ?? this.border,
      textMuted: textMuted ?? this.textMuted,
      textMutedHeader: textMutedHeader ?? this.textMutedHeader,
    );
  }

  @override
  ThemeExtension<TimerinThemeExtension> lerp(
    covariant ThemeExtension<TimerinThemeExtension>? other,
    double t,
  ) {
    if (other is! TimerinThemeExtension) {
      return this;
    }
    return TimerinThemeExtension(
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      overlayBg: Color.lerp(overlayBg, other.overlayBg, t) ?? overlayBg,
      surfaceVariant:
          Color.lerp(surfaceVariant, other.surfaceVariant, t) ?? surfaceVariant,
      border: Color.lerp(border, other.border, t) ?? border,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      textMutedHeader:
          Color.lerp(textMutedHeader, other.textMutedHeader, t) ??
          textMutedHeader,
    );
  }
}

/// Extension helper pada [BuildContext] untuk akses mudah tanpa hardcode:
/// `context.timerinTheme.accent`
extension TimerinThemeContextX on BuildContext {
  TimerinThemeExtension get timerinTheme {
    return Theme.of(this).extension<TimerinThemeExtension>() ??
        TimerinThemeExtension.defaultTheme;
  }
}
