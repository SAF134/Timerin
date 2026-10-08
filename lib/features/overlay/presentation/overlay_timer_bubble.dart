import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_typography.dart';
import 'package:timerin/features/overlay/domain/timer_countdown.dart';
import 'package:timerin/features/overlay/services/vibration_service.dart';

/// Lingkaran timer spell overlay (SCR-007, FR-010).
///
/// Berdiameter default 56 dp (memenuhi target sentuh NFR-007 >= 48 dp),
/// dengan latar `AppColors.overlayBg` (navy 85% opacity), border transisi warna,
/// dan tampilan detik/indikator selesai.
class OverlayTimerBubble extends StatefulWidget {
  const OverlayTimerBubble({
    super.key,
    this.countdown,
    this.size = 56.0,
    this.initialDuration = const Duration(seconds: 30),
    this.warningThresholdSeconds = 5,
    this.showMinutesSeconds = false,
    this.isInteractive = true,
    this.isVibrationEnabled = true,
    this.onTap,
  });

  /// Controller hitung mundur (jika null, bubble membuat instance sendiri).
  final TimerCountdown? countdown;

  /// Diameter lingkaran timer (default 56 dp).
  final double size;

  /// Durasi awal jika membuat controller internal.
  final Duration initialDuration;

  /// Ambang peringatan detik (default 5 detik).
  final int warningThresholdSeconds;

  /// Format waktu mm:ss jika true, atau detik total jika false (FR-006).
  final bool showMinutesSeconds;

  /// Apakah bubble dapat merespons ketukan (false untuk pratinjau statis).
  final bool isInteractive;

  /// Apakah getaran fisik aktif saat timer habis.
  final bool isVibrationEnabled;

  /// Callback tambahan saat bubble diketuk.
  final VoidCallback? onTap;

  @override
  State<OverlayTimerBubble> createState() => _OverlayTimerBubbleState();
}

class _OverlayTimerBubbleState extends State<OverlayTimerBubble> {
  TimerCountdown? _internalCountdown;
  Timer? _vibrationTimer;
  bool _hasVibratedForCurrentFinish = false;

  TimerCountdown get _countdown => widget.countdown ?? _internalCountdown!;

  @override
  void initState() {
    super.initState();
    if (widget.countdown == null) {
      _internalCountdown = TimerCountdown(
        duration: widget.initialDuration,
        warningThresholdSeconds: widget.warningThresholdSeconds,
      );
    }
    _countdown.addListener(_handleCountdownUpdate);
  }

  @override
  void didUpdateWidget(covariant OverlayTimerBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.countdown != oldWidget.countdown) {
      (oldWidget.countdown ?? _internalCountdown)?.removeListener(
        _handleCountdownUpdate,
      );
      if (widget.countdown != null && _internalCountdown != null) {
        _internalCountdown!.dispose();
        _internalCountdown = null;
      } else if (widget.countdown == null && _internalCountdown == null) {
        _internalCountdown = TimerCountdown(
          duration: widget.initialDuration,
          warningThresholdSeconds: widget.warningThresholdSeconds,
        );
      }
      _countdown.addListener(_handleCountdownUpdate);
    } else if (widget.countdown == null &&
        widget.initialDuration != oldWidget.initialDuration) {
      // Perbarui durasi internal jika pengguna mengubah durasi timer
      if (_internalCountdown != null) {
        _internalCountdown!.removeListener(_handleCountdownUpdate);
        _internalCountdown!.dispose();
        _internalCountdown = TimerCountdown(
          duration: widget.initialDuration,
          warningThresholdSeconds: widget.warningThresholdSeconds,
        );
        _countdown.addListener(_handleCountdownUpdate);
      }
    }
  }

  @override
  void dispose() {
    _stopVibration();
    _countdown.removeListener(_handleCountdownUpdate);
    _internalCountdown?.dispose();
    super.dispose();
  }

  void _handleCountdownUpdate() {
    if (_countdown.isFinished) {
      if (!_hasVibratedForCurrentFinish) {
        _hasVibratedForCurrentFinish = true;
        _startSpellReadyVibration();
      }
    } else {
      _hasVibratedForCurrentFinish = false;
      _stopVibration();
    }
  }

  /// Denyut getaran perangkat 2–3 detik memberi sinyal spell musuh ready.
  void _startSpellReadyVibration() {
    _stopVibration();
    if (!widget.isVibrationEnabled) return;

    // 1. Getaran perangkat keras native via Android Vibrator (2.4 detik)
    VibrationService.vibrate(durationMs: 2400);

    // 2. Siarkan sinyal selesai ke aplikasi utama jika berjalan di overlay window
    try {
      FlutterOverlayWindow.shareData('TIMER_FINISHED').catchError((_) => null);
    } catch (_) {}

    // 3. Denyut haptic feedback sebagai pelengkap
    int pulseCount = 0;
    try {
      HapticFeedback.vibrate();
      HapticFeedback.heavyImpact();
    } catch (_) {}

    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) {
      pulseCount++;
      try {
        HapticFeedback.vibrate();
        HapticFeedback.heavyImpact();
      } catch (_) {}
      if (pulseCount >= 12 || !mounted) {
        timer.cancel();
        _vibrationTimer = null;
      }
    });
  }

  void _stopVibration() {
    VibrationService.cancel();
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
  }

  void _handleTap() {
    if (!widget.isInteractive) return;
    _stopVibration();
    // Ketika countdown sedang aktif, ketukan tunggal DIABAIKAN agar tidak sengaja ter-reset
    if (_countdown.isRunning) {
      return;
    }
    _countdown.startOrRestart();
    widget.onTap?.call();
  }

  void _handleDoubleTap() {
    if (!widget.isInteractive) return;
    _stopVibration();
    _countdown.reset();
  }

  Color _getStatusColor(TimerCountdownStatus status) {
    switch (status) {
      case TimerCountdownStatus.idle:
        return AppColors.textOnPrimary;
      case TimerCountdownStatus.running:
        return AppColors.accent;
      case TimerCountdownStatus.warning:
        return AppColors.warning;
      case TimerCountdownStatus.finished:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _countdown,
      builder: (context, _) {
        final status = _countdown.status;
        final statusColor = _getStatusColor(status);
        final isFinished = status == TimerCountdownStatus.finished;
        final isIdle = status == TimerCountdownStatus.idle;

        return Semantics(
          button: true,
          label: isFinished
              ? 'Timer selesai, ketuk sekali untuk mulai, ketuk dua kali untuk reset'
              : isIdle
              ? 'Timer siap, durasi ${_countdown.totalSeconds} detik, ketuk sekali untuk memulai'
              : 'Timer berjalan, sisa ${_countdown.remainingSeconds} detik, ketuk dua kali untuk reset',
          child: GestureDetector(
            onTap: widget.isInteractive ? _handleTap : null,
            onDoubleTap: widget.isInteractive ? _handleDoubleTap : null,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  // Indikator Progres Radial Melingkar (saat running/warning)
                  if (!isIdle && !isFinished)
                    SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: CircularProgressIndicator(
                        value: _countdown.progress,
                        strokeWidth: 3.0,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        backgroundColor: AppColors.border.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),

                  // Lingkaran Dasar Bubble Overlay
                  Container(
                    width: widget.size - 6.0,
                    height: widget.size - 6.0,
                    decoration: BoxDecoration(
                      color: AppColors.overlayBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isIdle
                            ? AppColors.border.withValues(alpha: 0.4)
                            : statusColor,
                        width: isFinished ? 2.5 : 1.5,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 6.0,
                          offset: const Offset(0, 2),
                        ),
                        if (isFinished)
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.45),
                            blurRadius: 8.0,
                            spreadRadius: 1.0,
                          ),
                      ],
                    ),
                    child: Center(
                      child: isFinished
                          ? Text(
                              '0',
                              textAlign: TextAlign.center,
                              style: AppTypography.title20.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w800,
                                fontSize: (widget.size * 0.28).clamp(
                                  10.0,
                                  15.0,
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _countdown.formatTime(
                                    showMinutesSeconds:
                                        widget.showMinutesSeconds,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: AppTypography.title20.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: (widget.size * 0.28).clamp(
                                      10.0,
                                      15.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
