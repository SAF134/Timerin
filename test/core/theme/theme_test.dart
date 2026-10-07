import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_theme.dart';
import 'package:timerin/core/theme/app_typography.dart';
import 'package:timerin/core/theme/timerin_theme_extension.dart';

void main() {
  group('Theme Tokens & ThemeData Tests (T-003)', () {
    test('AppColors matches 02-DESIGN.md values exactly', () {
      expect(AppColors.primary, const Color(0xFF111625));
      expect(AppColors.bg, const Color(0xFFF8F9FD));
      expect(AppColors.surface, const Color(0xFFFFFFFF));
      expect(AppColors.surfaceVariant, const Color(0xFFF1F4F9));
      expect(AppColors.border, const Color(0xFFE2E8F0));
      expect(AppColors.text, const Color(0xFF111827));
      expect(AppColors.textOnPrimary, const Color(0xFFFFFFFF));
      expect(AppColors.textMuted, const Color(0xFF64748B));
      expect(AppColors.textMutedHeader, const Color(0xFF94A3B8));
      expect(AppColors.accent, const Color(0xFF00D1B2));
      expect(AppColors.warning, const Color(0xFFF59E0B));
      expect(AppColors.error, const Color(0xFFEF4444));
      expect(AppColors.overlayBg, const Color(0xD9111625));
    });

    test('AppSpacing contains expected scale values', () {
      expect(AppSpacing.s4, 4.0);
      expect(AppSpacing.s8, 8.0);
      expect(AppSpacing.s12, 12.0);
      expect(AppSpacing.s16, 16.0);
      expect(AppSpacing.s24, 24.0);
      expect(AppSpacing.s32, 32.0);
    });

    test('AppRadius matches design tokens', () {
      expect(AppRadius.card, 16.0);
      expect(AppRadius.button, 14.0);
      expect(AppRadius.sheet, 28.0);
      expect(AppRadius.pill, 999.0);
    });

    test('AppTypography scales are 12, 14, 16, 20, 28', () {
      expect(AppTypography.caption12.fontSize, 12.0);
      expect(AppTypography.body14.fontSize, 14.0);
      expect(AppTypography.body16.fontSize, 16.0);
      expect(AppTypography.title20.fontSize, 20.0);
      expect(AppTypography.display28.fontSize, 28.0);
    });

    test('AppTheme configures ThemeData with tokens and extension', () {
      final theme = AppTheme.theme;

      expect(theme.scaffoldBackgroundColor, AppColors.bg);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.surface, AppColors.surface);
      expect(theme.colorScheme.error, AppColors.error);

      final extension = theme.extension<TimerinThemeExtension>();
      expect(extension, isNotNull);
      expect(extension!.accent, AppColors.accent);
      expect(extension.warning, AppColors.warning);
      expect(extension.overlayBg, AppColors.overlayBg);
      expect(extension.surfaceVariant, AppColors.surfaceVariant);
      expect(extension.border, AppColors.border);
    });

    testWidgets(
      'TimerinThemeContextX resolves extension correctly in widget tree',
      (WidgetTester tester) async {
        late TimerinThemeExtension resolvedExtension;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.theme,
            home: Builder(
              builder: (context) {
                resolvedExtension = context.timerinTheme;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(resolvedExtension.accent, AppColors.accent);
        expect(resolvedExtension.warning, AppColors.warning);
        expect(resolvedExtension.overlayBg, AppColors.overlayBg);
      },
    );
  });
}
