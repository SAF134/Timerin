import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_radius.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/core/theme/app_typography.dart';
import 'package:timerin/data/models/timer_settings_model.dart';
import 'package:timerin/data/repositories/timer_settings_repository.dart';
import 'package:timerin/features/overlay/presentation/overlay_container.dart';
import 'package:timerin/features/overlay/services/vibration_service.dart';

/// Kartu pengaturan konfigurasi timer overlay beserta pratinjau langsung (SCR-004, FR-005..FR-009, FR-018).
class TimerSettingsCard extends ConsumerStatefulWidget {
  const TimerSettingsCard({super.key, this.isLocked = false});

  /// Status apakah pengaturan dikunci karena overlay sedang aktif.
  final bool isLocked;

  @override
  ConsumerState<TimerSettingsCard> createState() => _TimerSettingsCardState();
}

class _TimerSettingsCardState extends ConsumerState<TimerSettingsCard>
    with WidgetsBindingObserver {
  bool _isHapticEnabled = true;

  bool get isLocked => widget.isLocked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkHaptic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkHaptic();
    }
  }

  Future<void> _checkHaptic() async {
    bool isHaptic = true;
    try {
      isHaptic = await VibrationService.isHapticFeedbackEnabled();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isHapticEnabled = isHaptic;
      });
      // Jika izin haptik tidak aktif di sistem, matikan otomatis switch getaran
      if (!isHaptic && ref.read(timerSettingsProvider).isVibrationEnabled) {
        await ref
            .read(timerSettingsProvider.notifier)
            .setVibrationEnabled(false);
      }
    }
  }

  Future<void> _showHapticDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
          ),
          title: const Text(
            'Umpan Balik Haptik Belum Aktif',
            style: AppTypography.title20,
          ),
          content: const Text(
            'Fitur getaran memerlukan pengaturan umpan balik haptik aktif pada perangkat Anda agar getaran dapat berfungsi saat timer habis. Silakan aktifkan di Pengaturan Suara & Getaran sistem.',
            style: AppTypography.body14,
            textAlign: TextAlign.justify,
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
                      Navigator.of(dialogContext).pop();
                      VibrationService.openHapticSettings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      minimumSize: const Size.fromHeight(44.0),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.buttonRadius,
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Buka Setelan'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showCustomDurationDialog(
    BuildContext context,
    int timerIndex,
    int currentDuration,
  ) {
    int selectedValue = currentDuration > 0
        ? currentDuration.clamp(
            TimerDurationPresets.minCustomSeconds,
            TimerDurationPresets.maxCustomSeconds,
          )
        : 60;

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
  Widget build(BuildContext context) {
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
                              InkWell(
                                key: Key('timer_duration_dropdown_$index'),
                                onTap: () => _showCustomDurationDialog(
                                  context,
                                  index,
                                  duration,
                                ),
                                borderRadius: AppRadius.buttonRadius,
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
                                        Icons.edit_outlined,
                                        size: 16.0,
                                        color: AppColors.primary,
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

                  // 6. Transparansi Overlay (10% - 100%)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('Transparansi Overlay', style: sectionTitleStyle),
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
                          '${(settings.backgroundOpacity * 100).round()}%',
                          style: AppTypography.caption12.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    key: const Key('transparency_slider'),
                    value: settings.backgroundOpacity.clamp(0.1, 1.0),
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceVariant,
                    onChanged: (val) {
                      notifier.setBackgroundOpacity(
                        double.parse(val.toStringAsFixed(2)),
                      );
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
                        value: _isHapticEnabled && settings.isVibrationEnabled,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) async {
                          if (val) {
                            final isHaptic =
                                await VibrationService.isHapticFeedbackEnabled();
                            if (!isHaptic) {
                              if (context.mounted) {
                                setState(() {
                                  _isHapticEnabled = false;
                                });
                                await _showHapticDialog(context);
                              }
                              return;
                            }
                          }
                          await notifier.setVibrationEnabled(val);
                        },
                      ),
                    ],
                  ),
                  AppSpacing.gapH16,

                  // 7. Panduan Ketukan Overlay (Terpisah 1x & 2x)
                  Row(
                    children: <Widget>[
                      // Kartu Kiri: Ketuk 1x (Mulai)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 12.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: AppRadius.cardRadius,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                  vertical: 4.0,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: AppRadius.buttonRadius,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(
                                      Icons.touch_app_rounded,
                                      size: 15.0,
                                      color: AppColors.textOnPrimary,
                                    ),
                                    SizedBox(width: 2.0),
                                    Text(
                                      '1X',
                                      style: TextStyle(
                                        color: AppColors.textOnPrimary,
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AppSpacing.gapW8,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Ketuk 1x',
                                      style: AppTypography.caption12.copyWith(
                                        color: AppColors.textMuted,
                                        fontSize: 11.0,
                                      ),
                                    ),
                                    Text(
                                      'Mulai',
                                      style: AppTypography.body14.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppSpacing.gapW12,
                      // Kartu Kanan: Ketuk 2x (Reset)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 12.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: AppRadius.cardRadius,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                  vertical: 4.0,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: AppRadius.buttonRadius,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(
                                      Icons.touch_app_rounded,
                                      size: 15.0,
                                      color: AppColors.textOnPrimary,
                                    ),
                                    SizedBox(width: 2.0),
                                    Text(
                                      '2X',
                                      style: TextStyle(
                                        color: AppColors.textOnPrimary,
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AppSpacing.gapW8,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Ketuk 2x',
                                      style: AppTypography.caption12.copyWith(
                                        color: AppColors.textMuted,
                                        fontSize: 11.0,
                                      ),
                                    ),
                                    Text(
                                      'Reset',
                                      style: AppTypography.body14.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
          AppSpacing.gapH24,

          // 9. Tombol Simpan Pengaturan Overlay
          ElevatedButton.icon(
            key: const Key('save_timer_settings_button'),
            onPressed: isLocked
                ? null
                : () async {
                    await notifier.updateSettings(settings);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Pengaturan overlay berhasil disimpan.',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                    }
                  },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Simpan Pengaturan Overlay'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48.0),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.buttonRadius,
              ),
              elevation: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}
