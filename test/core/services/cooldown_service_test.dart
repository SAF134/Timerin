import 'package:flutter_test/flutter_test.dart';
import 'package:timerin/core/services/cooldown_service.dart';

void main() {
  group('CooldownService Tests', () {
    late CooldownService service;

    setUp(() {
      service = CooldownService();
    });

    test('canExecute returns true initially for any action', () {
      expect(service.canExecute('test_action'), isTrue);
      expect(service.getRemainingCooldown('test_action'), Duration.zero);
    });

    test('records execution and prevents execution within 5 minutes', () {
      final now = DateTime(2026, 10, 29, 12, 0);
      service.recordExecution('refresh_access', now: now);

      // 1 minute later -> cannot execute
      final oneMinLater = now.add(const Duration(minutes: 1));
      expect(service.canExecute('refresh_access', now: oneMinLater), isFalse);
      expect(
        service.getRemainingCooldown('refresh_access', now: oneMinLater),
        const Duration(minutes: 4),
      );

      // 5 minutes later -> can execute
      final fiveMinLater = now.add(const Duration(minutes: 5));
      expect(service.canExecute('refresh_access', now: fiveMinLater), isTrue);
      expect(
        service.getRemainingCooldown('refresh_access', now: fiveMinLater),
        Duration.zero,
      );
    });

    test('formatRemaining formats minutes and seconds correctly', () {
      expect(
        CooldownService.formatRemaining(
          const Duration(minutes: 4, seconds: 30),
        ),
        '4 menit 30 detik',
      );
      expect(
        CooldownService.formatRemaining(const Duration(minutes: 2)),
        '2 menit',
      );
      expect(
        CooldownService.formatRemaining(const Duration(seconds: 45)),
        '45 detik',
      );
      expect(CooldownService.formatRemaining(Duration.zero), '0 detik');
    });

    test('reset clears all recorded actions', () {
      final now = DateTime.now();
      service.recordExecution('action1', now: now);
      expect(service.canExecute('action1'), isFalse);

      service.reset();
      expect(service.canExecute('action1'), isTrue);
    });
  });
}
