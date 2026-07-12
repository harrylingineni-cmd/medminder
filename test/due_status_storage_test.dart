import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:med_app/due_status_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('medication is due only after its scheduled time', () {
    final now = DateTime(2026, 7, 12, 9);

    expect(
      isMedicationDue(hour: 8, minute: 30, status: null, now: now),
      isTrue,
    );
    expect(
      isMedicationDue(hour: 9, minute: 30, status: null, now: now),
      isFalse,
    );
  });

  test('taken medication is not due again on the same day', () async {
    final now = DateTime(2026, 7, 12, 9);
    await DueStatusStorage.markTakenToday(1, when: now);
    final status = (await DueStatusStorage.loadAll())[1];

    expect(
      isMedicationDue(hour: 8, minute: 30, status: status, now: now),
      isFalse,
    );
    expect(
      isMedicationDue(
        hour: 8,
        minute: 30,
        status: status,
        now: now.add(const Duration(days: 1)),
      ),
      isTrue,
    );
  });

  test('snooze blocks a dose until its expiry', () async {
    final now = DateTime(2026, 7, 12, 9);
    final snoozeUntil = now.add(const Duration(minutes: 10));
    await DueStatusStorage.snooze(2, snoozeUntil);
    final status = (await DueStatusStorage.loadAll())[2];

    expect(
      isMedicationDue(hour: 8, minute: 30, status: status, now: now),
      isFalse,
    );
    expect(
      isMedicationDue(hour: 8, minute: 30, status: status, now: snoozeUntil),
      isTrue,
    );
  });

  test('removing a medication also removes its saved status', () async {
    await DueStatusStorage.markTakenToday(3, when: DateTime(2026, 7, 12));

    await DueStatusStorage.remove(3);

    expect(await DueStatusStorage.loadAll(), isEmpty);
  });

  test('date keys are stable and zero-padded', () {
    expect(DueStatusStorage.todayString(DateTime(2026, 2, 3)), '2026-02-03');
  });
}
