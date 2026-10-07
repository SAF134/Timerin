import 'package:flutter_test/flutter_test.dart';
import 'package:timerin/features/subscription/domain/access_state.dart';

void main() {
  group('AccessState Domain Tests (T-009 / PRD §3, FR-013, FR-014)', () {
    test('AccessStatus properties and helpers return correct booleans', () {
      const newState = AccessState(
        status: AccessStatus.baru,
        remainingAccess: Duration.zero,
      );
      expect(newState.isNew, isTrue);
      expect(newState.canActivateOverlay, isFalse);

      const trialState = AccessState(
        status: AccessStatus.trial,
        remainingAccess: Duration(hours: 18),
      );
      expect(trialState.isTrial, isTrue);
      expect(trialState.canActivateOverlay, isTrue);

      const subState = AccessState(
        status: AccessStatus.berlangganan,
        remainingAccess: Duration(days: 15),
      );
      expect(subState.isSubscribed, isTrue);
      expect(subState.canActivateOverlay, isTrue);

      const expiredState = AccessState(
        status: AccessStatus.habis,
        remainingAccess: Duration.zero,
      );
      expect(expiredState.isExpired, isTrue);
      expect(expiredState.canActivateOverlay, isFalse);
    });

    test('remainingFormatted displays intuitive Indonesian string', () {
      const newState = AccessState(
        status: AccessStatus.baru,
        remainingAccess: Duration.zero,
      );
      expect(newState.remainingFormatted, 'Trial 24 jam siap dimulai');

      const expiredState = AccessState(
        status: AccessStatus.habis,
        remainingAccess: Duration.zero,
      );
      expect(expiredState.remainingFormatted, 'Masa aktif habis');

      const daysState = AccessState(
        status: AccessStatus.berlangganan,
        remainingAccess: Duration(days: 10),
      );
      expect(daysState.remainingFormatted, 'sisa 10 hari');

      const hoursState = AccessState(
        status: AccessStatus.trial,
        remainingAccess: Duration(hours: 18, minutes: 30),
      );
      expect(hoursState.remainingFormatted, 'sisa 18 jam');

      const minutesState = AccessState(
        status: AccessStatus.trial,
        remainingAccess: Duration(minutes: 45),
      );
      expect(minutesState.remainingFormatted, 'sisa 45 menit');

      const secondsState = AccessState(
        status: AccessStatus.trial,
        remainingAccess: Duration(seconds: 30),
      );
      expect(secondsState.remainingFormatted, 'sisa 30 detik');
    });
  });
}
