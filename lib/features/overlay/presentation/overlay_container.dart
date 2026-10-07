import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timerin/core/theme/app_spacing.dart';
import 'package:timerin/data/models/timer_settings_model.dart';
import 'package:timerin/data/repositories/timer_settings_repository.dart';
import 'package:timerin/features/overlay/presentation/overlay_timer_bubble.dart';

/// Kontainer multi-timer overlay yang mendukung 1–5 timer, orientasi vertikal/horizontal,
/// skala ukuran 50%–150%, dan durasi per timer independen (FR-005 s.d. FR-010, SCR-007).
class OverlayContainer extends StatefulWidget {
  const OverlayContainer({super.key, this.settings, this.isInteractive = true});

  /// Pengaturan timer (jika null, akan membaca dari penyimpanan lokal dan broadcast stream).
  final TimerSettings? settings;

  /// Apakah bubble dapat merespons ketukan (default true; false jika pratinjau statis).
  final bool isInteractive;

  @override
  State<OverlayContainer> createState() => _OverlayContainerState();
}

class _OverlayContainerState extends State<OverlayContainer> {
  late TimerSettings _settings;
  StreamSubscription<dynamic>? _overlaySubscription;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings ?? const TimerSettings();

    if (widget.settings == null) {
      _loadLocalSettingsAndListen();
    }
  }

  @override
  void didUpdateWidget(covariant OverlayContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settings != null && widget.settings != oldWidget.settings) {
      _settings = widget.settings!;
    }
  }

  Future<void> _loadLocalSettingsAndListen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final repo = TimerSettingsRepository(prefs: prefs);
      if (mounted) {
        setState(() {
          _settings = repo.getSettings();
        });
      }
    } catch (_) {
      // Abaikan jika lingkungan pengujian
    }

    try {
      _overlaySubscription = FlutterOverlayWindow.overlayListener.listen((
        data,
      ) {
        if (!mounted || data == null) return;
        final jsonStr = data.toString();
        final updatedSettings = TimerSettings.fromJson(jsonStr);
        setState(() {
          _settings = updatedSettings;
        });
      });
    } catch (_) {
      // Abaikan jika channel overlay belum siap
    }
  }

  @override
  void dispose() {
    _overlaySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings ?? _settings;
    final count = settings.timerCount;
    final scale = settings.scale;
    final bubbleSize = 56.0 * scale;
    final gap = AppSpacing.s8 * scale;
    final showMinutesSeconds =
        settings.timeFormat == TimeDisplayFormat.minutesSeconds;
    final isVertical = settings.orientation == TimerOrientation.vertical;

    final bubbles = <Widget>[];
    for (int i = 0; i < count; i++) {
      final duration = Duration(seconds: settings.getDurationFor(i));
      bubbles.add(
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: isVertical ? gap / 2 : 0,
            horizontal: isVertical ? 0 : gap / 2,
          ),
          child: OverlayTimerBubble(
            key: ValueKey('overlay_timer_bubble_$i'),
            size: bubbleSize,
            initialDuration: duration,
            showMinutesSeconds: showMinutesSeconds,
          ),
        ),
      );
    }

    if (isVertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: bubbles,
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: bubbles,
      );
    }
  }
}
