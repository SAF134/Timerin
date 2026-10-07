import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Format tampilan waktu pada lingkaran timer (FR-006).
enum TimeDisplayFormat {
  /// Detik total (120, 119, 118...)
  seconds,

  /// Format menit dan detik (02:00, 01:59...)
  minutesSeconds,
}

/// Orientasi susunan timer pada overlay (FR-009).
enum TimerOrientation {
  /// Susunan berjejer ke bawah
  vertical,

  /// Susunan berjejer ke samping
  horizontal,
}

/// Preset durasi umum timer spell Mobile Legends (FR-007).
abstract final class TimerDurationPresets {
  static const int sec30 = 30;
  static const int min1 = 60;
  static const int min2 = 120;
  static const int min3 = 180;

  static const List<int> standardPresets = <int>[sec30, min1, min2, min3];

  static const int minCustomSeconds = 5;
  static const int maxCustomSeconds = 600;

  static String formatDurationLabel(int seconds) {
    if (seconds == 30) return '30 dtk';
    if (seconds == 60) return '1 mnt';
    if (seconds == 120) return '2 mnt';
    if (seconds == 180) return '3 mnt';
    if (seconds % 60 == 0) return '${seconds ~/ 60} mnt';
    return '$seconds dtk';
  }
}

/// Model pengaturan timer lokal beserta koordinat posisi mengambang (FR-005 s.d. FR-009, FR-011, FR-018).
@immutable
class TimerSettings {
  const TimerSettings({
    this.timerCount = 3,
    this.timeFormat = TimeDisplayFormat.seconds,
    this.orientation = TimerOrientation.vertical,
    this.scale = 1.0,
    this.durations = const <int>[30, 60, 120, 180, 30],
    this.positionX,
    this.positionY,
  });

  /// Jumlah timer aktif: 1–5 (FR-005, default 3 per SCR-004).
  final int timerCount;

  /// Format teks waktu: detik atau mm:ss (FR-006).
  final TimeDisplayFormat timeFormat;

  /// Orientasi susunan: vertikal atau horizontal (FR-009).
  final TimerOrientation orientation;

  /// Skala ukuran overlay: 50%–150% (0.5 – 1.5) (FR-008).
  final double scale;

  /// Durasi masing-masing timer dalam detik (FR-007).
  final List<int> durations;

  /// Koordinat horizontal (X) posisi overlay dalam satuan dp jika pernah digeser (FR-011, SCR-007).
  /// Null mengartikan posisi default (kiri-tengah layar).
  final double? positionX;

  /// Koordinat vertikal (Y) posisi overlay dalam satuan dp jika pernah digeser (FR-011, SCR-007).
  /// Null mengartikan posisi default (kiri-tengah layar).
  final double? positionY;

  /// Apakah overlay menggunakan posisi tersimpan kustom.
  bool get hasCustomPosition => positionX != null && positionY != null;

  /// Mengambil durasi dalam detik untuk timer ke-[index] (0-indexed).
  int getDurationFor(int index) {
    if (index >= 0 && index < durations.length) {
      return durations[index].clamp(
        TimerDurationPresets.minCustomSeconds,
        TimerDurationPresets.maxCustomSeconds,
      );
    }
    return TimerDurationPresets.sec30;
  }

  /// Membuat salinan model dengan durasi baru untuk timer ke-[index].
  TimerSettings copyWithDuration(int index, int newDurationSeconds) {
    final clamped = newDurationSeconds.clamp(
      TimerDurationPresets.minCustomSeconds,
      TimerDurationPresets.maxCustomSeconds,
    );
    final updated = List<int>.from(durations);
    while (updated.length <= index) {
      updated.add(TimerDurationPresets.sec30);
    }
    updated[index] = clamped;
    return copyWith(durations: updated);
  }

  TimerSettings copyWith({
    int? timerCount,
    TimeDisplayFormat? timeFormat,
    TimerOrientation? orientation,
    double? scale,
    List<int>? durations,
    double? positionX,
    double? positionY,
    bool clearPosition = false,
  }) {
    return TimerSettings(
      timerCount: (timerCount ?? this.timerCount).clamp(1, 5),
      timeFormat: timeFormat ?? this.timeFormat,
      orientation: orientation ?? this.orientation,
      scale: (scale ?? this.scale).clamp(0.5, 1.5),
      durations: durations != null
          ? List<int>.unmodifiable(
              durations.map(
                (d) => d.clamp(
                  TimerDurationPresets.minCustomSeconds,
                  TimerDurationPresets.maxCustomSeconds,
                ),
              ),
            )
          : this.durations,
      positionX: clearPosition ? null : (positionX ?? this.positionX),
      positionY: clearPosition ? null : (positionY ?? this.positionY),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'timerCount': timerCount,
      'timeFormat': timeFormat.name,
      'orientation': orientation.name,
      'scale': scale,
      'durations': durations,
      'positionX': positionX,
      'positionY': positionY,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory TimerSettings.fromMap(Map<String, dynamic> map) {
    final rawCount = (map['timerCount'] as num?)?.toInt() ?? 3;
    final rawFormat = map['timeFormat'] as String?;
    final rawOrientation = map['orientation'] as String?;
    final rawScale = (map['scale'] as num?)?.toDouble() ?? 1.0;
    final rawDurations =
        (map['durations'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList() ??
        const <int>[30, 60, 120, 180, 30];
    final rawX = (map['positionX'] as num?)?.toDouble();
    final rawY = (map['positionY'] as num?)?.toDouble();

    final timeFormat = TimeDisplayFormat.values.firstWhere(
      (e) => e.name == rawFormat,
      orElse: () => TimeDisplayFormat.seconds,
    );

    final orientation = TimerOrientation.values.firstWhere(
      (e) => e.name == rawOrientation,
      orElse: () => TimerOrientation.vertical,
    );

    return TimerSettings(
      timerCount: rawCount.clamp(1, 5),
      timeFormat: timeFormat,
      orientation: orientation,
      scale: rawScale.clamp(0.5, 1.5),
      durations: List<int>.unmodifiable(
        rawDurations.map(
          (d) => d.clamp(
            TimerDurationPresets.minCustomSeconds,
            TimerDurationPresets.maxCustomSeconds,
          ),
        ),
      ),
      positionX: rawX,
      positionY: rawY,
    );
  }

  factory TimerSettings.fromJson(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return TimerSettings.fromMap(decoded);
      }
      return const TimerSettings();
    } catch (_) {
      return const TimerSettings();
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimerSettings &&
        other.timerCount == timerCount &&
        other.timeFormat == timeFormat &&
        other.orientation == orientation &&
        other.scale == scale &&
        listEquals(other.durations, durations) &&
        other.positionX == positionX &&
        other.positionY == positionY;
  }

  @override
  int get hashCode => Object.hash(
    timerCount,
    timeFormat,
    orientation,
    scale,
    Object.hashAll(durations),
    positionX,
    positionY,
  );
}
