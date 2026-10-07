/// Abstraksi jam monotonik perangkat untuk mencegah eksploitasi perubahan jam sistem (NFR-001).
abstract class MonotonicClock {
  int get elapsedMilliseconds;
}

/// Implementasi standar jam monotonik berbasis [Stopwatch] hardware.
class SystemMonotonicClock implements MonotonicClock {
  SystemMonotonicClock() {
    _stopwatch.start();
  }

  final Stopwatch _stopwatch = Stopwatch();

  @override
  int get elapsedMilliseconds => _stopwatch.elapsedMilliseconds;
}
