import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';
import 'package:timerin/data/models/timer_settings_model.dart';
import 'package:timerin/data/repositories/timer_settings_repository.dart';
import 'package:timerin/features/overlay/presentation/overlay_container.dart';

/// Kartu pengaturan konfigurasi timer overlay beserta pratinjau langsung (SCR-004, FR-005..FR-009, FR-018).
class TimerSettingsCard extends ConsumerWidget {
  const TimerSettingsCard({super.key, this.isLocked = false});

  /// Status apakah pengaturan dikunci karena overlay sedang aktif.
  final bool isLocked;

  void _showCustomDurationDialog(
    BuildContext context,
    WidgetRef ref,
    int timerIndex,
    int currentDuration,
  ) {
    int selectedValue = currentDuration.clamp(
      TimerDurationPresets.minCustomSeconds,
      TimerDurationPresets.maxCustomSeconds,
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.cardRadius,
              ),
              title: Text(
                'Durasi Timer ${timerIndex + 1}',
                style: AppTypography.title20,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '$selectedValue detik',
                    style: AppTypography.display28.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  AppSpacing.gapH8,
                  const Text(
                    'Atur durasi antara 5 hingga 600 detik (10 menit)',
                    style: AppTypography.caption12,
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapH16,
                  Slider(
                    value: selectedValue.toDouble(),
                    min: TimerDurationPresets.minCustomSeconds.toDouble(),
                    max: TimerDurationPresets.maxCustomSeconds.toDouble(),
                    divisions: 119,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceVariant,
                    onChanged: (val) {
                      setState(() {
                        selectedValue = val.round();
                      });
                    },
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
              actions: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44.0),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.buttonRadius,
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    AppSpacing.gapW12,
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ref
                              .read(timerSettingsProvider.notifier)
                              .setTimerDuration(timerIndex, selectedValue);
                          Navigator.of(dialogContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44.0),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.buttonRadius,
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(timerSettingsProvider);
    final notifier = ref.read(timerSettingsProvider.notifier);

    final sectionTitleStyle = AppTypography.body14.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: AppSpacing.p24,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.primary, width: 1.0),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Judul Panel
          const Row(
            children: <Widget>[
              Icon(Icons.tune_rounded, color: AppColors.primary, size: 24.0),
              AppSpacing.gapW12,
              Text('Pengaturan Overlay', style: AppTypography.title20),
            ],
          ),
          AppSpacing.gapH24,

          if (isLocked) ...<Widget>[
            Container(
              key: const Key('overlay_settings_locked_banner'),
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: AppRadius.buttonRadius,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.lock_rounded,
                    size: 18.0,
                    color: AppColors.warning,
                  ),
                  AppSpacing.gapW8,
                  Expanded(
                    child: Text(
                      'Pengaturan dikunci saat overlay aktif. Matikan overlay untuk mengubah pengaturan.',
                      style: AppTypography.caption12.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapH16,
          ],

          IgnorePointer(
            ignoring: isLocked,
            child: Opacity(
              opacity: isLocked ? 0.55 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 1. Jumlah Timer (FR-005)
                  Text('Jumlah Timer', style: sectionTitleStyle),
                  AppSpacing.gapH8,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      final count = index + 1;
                      final isSelected = settings.timerCount == count;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: index == 0 ? 0 : 4.0,
                            right: index == 4 ? 0 : 4.0,
                          ),
                          child: InkWell(
                            key: Key('timer_count_chip_$count'),
                            onTap: () => notifier.setTimerCount(count),
                            borderRadius: AppRadius.buttonRadius,
                            child: Container(
                              height: 44.0,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.surfaceVariant,
                                borderRadius: AppRadius.buttonRadius,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$count',
                                style: AppTypography.body16Medium.copyWith(
                                  color: isSelected
                                      ? AppColors.textOnPrimary
                                      : AppColors.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  AppSpacing.gapH24,

                  // 2. Durasi Tiap Timer (FR-007)
                  Text('Durasi Tiap Timer', style: sectionTitleStyle),
                  AppSpacing.gapH12,
                  Column(
                    children: List.generate(settings.timerCount, (index) {
                      final duration = settings.getDurationFor(index);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: AppRadius.buttonRadius,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                'Timer ${index + 1}',
                                style: AppTypography.body14.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              PopupMenuButton<int>(
                                key: Key('timer_duration_dropdown_$index'),
                                initialValue: duration,
                                onSelected: (selectedSec) {
                                  if (selectedSec == -1) {
                                    _showCustomDurationDialog(
                                      context,
                                      ref,
                                      index,
                                      duration,
                                    );
                                  } else {
                                    notifier.setTimerDuration(
                                      index,
                                      selectedSec,
                                    );
                                  }
                                },
                                itemBuilder: (context) => <PopupMenuEntry<int>>[
                                  const PopupMenuItem<int>(
                                    value: 30,
                                    child: Text('30 detik'),
                                  ),
                                  const PopupMenuItem<int>(
                                    value: 60,
                                    child: Text('1 menit (60 dtk)'),
                                  ),
                                  const PopupMenuItem<int>(
                                    value: 120,
                                    child: Text('2 menit (120 dtk)'),
                                  ),
                                  const PopupMenuItem<int>(
                                    value: 180,
                                    child: Text('3 menit (180 dtk)'),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem<int>(
                                    value: -1,
                                    child: Text('Kustom'),
                                  ),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 6.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: AppRadius.buttonRadius,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text(
                                        TimerDurationPresets.formatDurationLabel(
                                          duration,
                                        ),
                                        style: AppTypography.body14.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      AppSpacing.gapW4,
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        size: 20.0,
                                        color: AppColors.textMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  AppSpacing.gapH24,

                  // 3. Format Tampilan Waktu (FR-006)
                  Text('Format Waktu', style: sectionTitleStyle),
                  AppSpacing.gapH8,
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ChoiceChip(
                          key: const Key('format_seconds_chip'),
                          label: const Text('Detik'),
                          selected:
                              settings.timeFormat == TimeDisplayFormat.seconds,
                          onSelected: (selected) {
                            if (selected) {
                              notifier.setTimeFormat(TimeDisplayFormat.seconds);
                            }
                          },
                        ),
                      ),
                      AppSpacing.gapW8,
                      Expanded(
                        child: ChoiceChip(
                          key: const Key('format_mm_ss_chip'),
                          label: const Text('Menit'),
                          selected:
                              settings.timeFormat ==
                              TimeDisplayFormat.minutesSeconds,
                          onSelected: (selected) {
                            if (selected) {
                              notifier.setTimeFormat(
                                TimeDisplayFormat.minutesSeconds,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapH24,

                  // 4. Susunan / Orientasi (FR-009)
                  Text('Susunan Timer', style: sectionTitleStyle),
                  AppSpacing.gapH8,
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ChoiceChip(
                          key: const Key('orientation_vertical_chip'),
                          avatar: const Icon(
                            Icons.table_rows_rounded,
                            size: 18.0,
                          ),
                          label: const Text('Vertikal'),
                          selected:
                              settings.orientation == TimerOrientation.vertical,
                          onSelected: (selected) {
                            if (selected) {
                              notifier.setOrientation(
                                TimerOrientation.vertical,
                              );
                            }
                          },
                        ),
                      ),
                      AppSpacing.gapW8,
                      Expanded(
                        child: ChoiceChip(
                          key: const Key('orientation_horizontal_chip'),
                          avatar: const Icon(
                            Icons.view_column_rounded,
                            size: 18.0,
                          ),
                          label: const Text('Horizontal'),
                          selected:
                              settings.orientation ==
                              TimerOrientation.horizontal,
                          onSelected: (selected) {
                            if (selected) {
                              notifier.setOrientation(
                                TimerOrientation.horizontal,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapH24,

                  // 5. Ukuran Overlay (FR-008: 50% - 100%)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('Ukuran Overlay', style: sectionTitleStyle),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 4.0,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: AppRadius.buttonRadius,
                        ),
                        child: Text(
                          '${(settings.scale * 100).round()}%',
                          style: AppTypography.caption12.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    key: const Key('scale_slider'),
                    value: settings.scale.clamp(0.5, 1.0),
                    min: 0.5,
                    max: 1.0,
                    divisions: 10,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceVariant,
                    onChanged: (val) {
                      notifier.setScale(double.parse(val.toStringAsFixed(2)));
                    },
                  ),
                  AppSpacing.gapH16,

                  // 6. Mode Getar Saat Timer Selesai
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Getar Saat Timer Habis',
                          style: sectionTitleStyle,
                        ),
                      ),
                      AppSpacing.gapW16,
                      Switch.adaptive(
                        key: const Key('vibration_switch'),
                        value: settings.isVibrationEnabled,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) {
                          notifier.setVibrationEnabled(val);
                        },
                      ),
                    ],
                  ),
                  AppSpacing.gapH16,

                  // 7. Panduan Ketukan Overlay
                  Container(
                    padding: AppSpacing.p12,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: AppRadius.buttonRadius,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(
                          Icons.touch_app_outlined,
                          size: 20.0,
                          color: AppColors.primary,
                        ),
                        AppSpacing.gapW8,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Panduan Ketukan Overlay',
                                style: AppTypography.caption12.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              AppSpacing.gapH4,
                              Text(
                                '• Ketuk 1x: Memulai hitung mundur timer.\n• Ketuk 2x: Mereset timer kembali ke durasi awal.',
                                style: AppTypography.caption12.copyWith(
                                  color: AppColors.text,
                                  height: 1.35,
                                ),
                                textAlign: TextAlign.justify,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.gapH24,

          // 8. Pratinjau Overlay Langsung (SCR-004: Tampilan Saja)
          Row(
            children: <Widget>[
              const Icon(
                Icons.visibility_outlined,
                size: 20.0,
                color: AppColors.textMuted,
              ),
              AppSpacing.gapW8,
              Text('Pratinjau Overlay', style: sectionTitleStyle),
            ],
          ),
          AppSpacing.gapH12,
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 120.0),
            padding: AppSpacing.p16,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius: AppRadius.cardRadius,
              border: Border.all(
                color: AppColors.border,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: IgnorePointer(
                ignoring: true,
                child: OverlayContainer(
                  key: ValueKey('preview_${settings.hashCode}'),
                  settings: settings,
                  isInteractive: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
