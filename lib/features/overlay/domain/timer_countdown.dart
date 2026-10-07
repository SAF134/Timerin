import 'dart:async';
import 'package:flutter/foundation.dart';

/// Status state machine untuk timer hitung mundur overlay (FR-010).
enum TimerCountdownStatus {
  /// Timer siap dan belum dimulai.
  idle,

  /// Timer sedang menghitung mundur (sisa > ambang batas peringatan).
  running,

  /// Timer mendekati selesai (sisa <= 5 detik).
  warning,

  /// Timer mencapai 0 dan siap dimulai ulang.
  finished,
}

/// Abstraksi stopwatch monotonik untuk kepatuhan NFR-001 dan pengujian deterministik.
abstract class MonotonicStopwatch {
  void start();
  void stop();
  void reset();
  int get elapsedMilliseconds;
  bool get isRunning;
}

class SystemMonotonicStopwatch implements MonotonicStopwatch {
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void start() => _stopwatch.start();

  @override
  void stop() => _stopwatch.stop();

  @override
  void reset() => _stopwatch.reset();

  @override
  int get elapsedMilliseconds => _stopwatch.elapsedMilliseconds;

  @override
  bool get isRunning => _stopwatch.isRunning;
}

/// Pengelola hitung mundur monotonik untuk satu timer spell overlay (FR-010, NFR-001).
///
/// Menggunakan jam monotonik perangkat (`Stopwatch`), kebal manipulasi jam sistem.
class TimerCountdown extends ChangeNotifier {
  TimerCountdown({
    Duration duration = const Duration(seconds: 30),
    this.warningThresholdSeconds = 5,
    MonotonicStopwatch Function()? stopwatchFactory,
    Timer Function(Duration interval, void Function(Timer timer) callback)?
    timerFactory,
  }) : _duration = duration,
       _stopwatch = stopwatchFactory?.call() ?? SystemMonotonicStopwatch(),
       _timerFactory = timerFactory ?? Timer.periodic {
    _remainingSeconds = _duration.inSeconds;
  }

  final Duration _duration;
  final int warningThresholdSeconds;
  final MonotonicStopwatch _stopwatch;
  final Timer Function(Duration interval, void Function(Timer timer) callback)
  _timerFactory;

  Timer? _timer;
  TimerCountdownStatus _status = TimerCountdownStatus.idle;
  late int _remainingSeconds;

  TimerCountdownStatus get status => _status;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _duration.inSeconds;
  bool get isRunning =>
      _status == TimerCountdownStatus.running ||
      _status == TimerCountdownStatus.warning;
  bool get isFinished => _status == TimerCountdownStatus.finished;
  bool get isIdle => _status == TimerCountdownStatus.idle;

  /// Rasio progres sisa waktu (1.0 = penuh, 0.0 = habis).
  double get progress {
    if (totalSeconds <= 0) return 0.0;
    if (_status == TimerCountdownStatus.idle) return 1.0;
    if (_status == TimerCountdownStatus.finished) return 0.0;
    return (_remainingSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  /// Memulai atau mengulang hitung mundur dari awal (FR-010).
  void startOrRestart() {
    _timer?.cancel();
    _stopwatch.reset();
    _stopwatch.start();

    _remainingSeconds = _duration.inSeconds;
    _status = _remainingSeconds <= warningThresholdSeconds
        ? TimerCountdownStatus.warning
        : TimerCountdownStatus.running;

    _timer = _timerFactory(const Duration(milliseconds: 100), (_) => _tick());
    notifyListeners();
  }

  /// Menghentikan dan mereset timer kembali ke status `idle`.
  void reset() {
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
    _stopwatch.reset();

    _status = TimerCountdownStatus.idle;
    _remainingSeconds = _duration.inSeconds;
    notifyListeners();
  }

  /// Evaluasi tick monotonik.
  void _tick() {
    final elapsedMs = _stopwatch.elapsedMilliseconds;
    final totalMs = _duration.inMilliseconds;
    final remainingMs = totalMs - elapsedMs;

    if (remainingMs <= 0) {
      _stopwatch.stop();
      _timer?.cancel();
      _timer = null;
      _remainingSeconds = 0;
      _status = TimerCountdownStatus.finished;
      notifyListeners();
    } else {
      final remainingSec = (remainingMs / 1000).ceil();
      final newStatus = remainingSec <= warningThresholdSeconds
          ? TimerCountdownStatus.warning
          : TimerCountdownStatus.running;

      if (remainingSec != _remainingSeconds || newStatus != _status) {
        _remainingSeconds = remainingSec;
        _status = newStatus;
        notifyListeners();
      }
    }
  }

  /// Format teks waktu tampilan (FR-006: detik total atau mm:ss).
  String formatTime({bool showMinutesSeconds = false}) {
    if (_status == TimerCountdownStatus.finished) {
      return '0';
    }
    if (!showMinutesSeconds) {
      return '$_remainingSeconds';
    }
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
    super.dispose();
  }
}
