import 'package:flutter/material.dart';
import 'package:timerin/core/theme/app_colors.dart';
import 'package:timerin/core/theme/app_typography.dart';
import 'package:timerin/features/overlay/domain/timer_countdown.dart';

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

  /// Callback tambahan saat bubble diketuk.
  final VoidCallback? onTap;

  @override
  State<OverlayTimerBubble> createState() => _OverlayTimerBubbleState();
}

class _OverlayTimerBubbleState extends State<OverlayTimerBubble> {
  TimerCountdown? _internalCountdown;

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
  }

  @override
  void didUpdateWidget(covariant OverlayTimerBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.countdown != null && _internalCountdown != null) {
      _internalCountdown!.dispose();
      _internalCountdown = null;
    } else if (widget.countdown == null && _internalCountdown == null) {
      _internalCountdown = TimerCountdown(
        duration: widget.initialDuration,
        warningThresholdSeconds: widget.warningThresholdSeconds,
      );
    }
  }

  @override
  void dispose() {
    _internalCountdown?.dispose();
    super.dispose();
  }

  void _handleTap() {
    _countdown.startOrRestart();
    widget.onTap?.call();
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
              ? 'Timer selesai, ketuk untuk mulai ulang'
              : isIdle
              ? 'Timer siap, durasi ${_countdown.totalSeconds} detik, ketuk untuk memulai'
              : 'Timer berjalan, sisa ${_countdown.remainingSeconds} detik, ketuk untuk mulai ulang',
          child: GestureDetector(
            onTap: _handleTap,
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
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.accent,
                              size: 26.0,
                            )
                          : Text(
                              _countdown.formatTime(
                                showMinutesSeconds: widget.showMinutesSeconds,
                              ),
                              textAlign: TextAlign.center,
                              style: AppTypography.title20.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                                fontSize: widget.size >= 56 ? 18.0 : 14.0,
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
