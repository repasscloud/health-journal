import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/platform/security/journal_pin.dart';

import 'installation_key_test.dart' show MemoryKeyStore;

void main() {
  test(
    'PIN is optional, salted, throttled across restart and required to disable',
    () async {
      final store = MemoryKeyStore();
      var now = DateTime.utc(2026, 11, 19);
      var pin = JournalPin(store, clock: () => now);
      expect(await pin.isEnabled(), isFalse);
      await expectLater(
        pin.configure(current: '', next: '12'),
        throwsArgumentError,
      );
      expect(await pin.configure(current: '', next: '121234'), isTrue);
      final initialVerifier = store.value;
      expect(initialVerifier, isNot(contains('121234')));
      expect(await pin.configure(current: '121234', next: '121234'), isTrue);
      expect(store.value, isNot(initialVerifier));

      expect(await pin.configure(current: '111111', next: ''), isFalse);
      expect(await Future.wait([pin.verify('111111'), pin.verify('111111')]), [
        false,
        false,
      ]);
      pin = JournalPin(store, clock: () => now);
      expect(await pin.isEnabled(), isTrue);
      expect(await pin.verify('121234'), isFalse);
      now = now.add(const Duration(seconds: 3));
      expect(await pin.verify('121234'), isTrue);
      expect(await pin.configure(current: '121234', next: ''), isTrue);
      expect(await pin.isEnabled(), isFalse);
    },
  );

  test('corrupt settings fail closed', () async {
    final store = MemoryKeyStore()..value = '[2, "unknown"]';
    await expectLater(JournalPin(store).isEnabled(), throwsFormatException);
  });
}
