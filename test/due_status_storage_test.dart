import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:med_app/due_status_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('each dose is tracked independently', () async {
    final now = DateTime(2026, 7, 15, 12);
    await DueStatusStorage.markTakenToday(1000, 0, when: now);

    final statuses = await DueStatusStorage.loadAll();
    expect(statuses[(1000, 0)]?.takenDate, '2026-07-15');
    expect(statuses[(1000, 1)], isNull);
    expect(
      isMedicationDue(
        hour: 8,
        minute: 0,
        reminderWindowMinutes: 30,
        status: statuses[(1000, 0)],
        now: now,
      ),
      isFalse,
    );
    expect(
      isMedicationDue(
        hour: 8,
        minute: 0,
        reminderWindowMinutes: 30,
        status: statuses[(1000, 1)],
        now: now,
      ),
      isTrue,
    );
  });

  test('snooze blocks a dose only until its expiry', () async {
    final now = DateTime(2026, 7, 15, 12);
    await DueStatusStorage.snooze(
      1000,
      0,
      now.add(const Duration(minutes: 10)),
    );
    final status = (await DueStatusStorage.loadAll())[(1000, 0)];

    expect(
      isMedicationDue(
        hour: 8,
        minute: 0,
        reminderWindowMinutes: 30,
        status: status,
        now: now,
      ),
      isFalse,
    );
    expect(
      isMedicationDue(
        hour: 8,
        minute: 0,
        reminderWindowMinutes: 30,
        status: status,
        now: now.add(const Duration(minutes: 11)),
      ),
      isTrue,
    );
  });

  test('a late dose stays due across midnight until its window ends', () {
    expect(
      isMedicationDue(
        hour: 23,
        minute: 55,
        reminderWindowMinutes: 60,
        status: null,
        now: DateTime(2026, 7, 16, 0, 30),
      ),
      isTrue,
    );
    expect(
      isMedicationDue(
        hour: 23,
        minute: 55,
        reminderWindowMinutes: 30,
        status: null,
        now: DateTime(2026, 7, 16, 0, 30),
      ),
      isFalse,
    );
  });

  test('taking a late dose after midnight applies to its scheduled date', () {
    final status = DueStatusEntry(
      medicationId: 1000,
      doseIndex: 0,
      takenDate: '2026-07-15',
    );

    expect(
      isMedicationDue(
        hour: 23,
        minute: 55,
        reminderWindowMinutes: 60,
        status: status,
        now: DateTime(2026, 7, 16, 0, 5),
      ),
      isFalse,
    );
    expect(
      isMedicationDue(
        hour: 23,
        minute: 55,
        reminderWindowMinutes: 60,
        status: status,
        now: DateTime(2026, 7, 16, 23, 56),
      ),
      isTrue,
    );
  });

  test('legacy status without doseIndex migrates to dose zero', () async {
    SharedPreferences.setMockInitialValues({
      'due_status': [
        jsonEncode({
          'medicationId': 1000,
          'takenDate': '2026-07-15',
          'snoozeUntilMillis': null,
        }),
      ],
    });

    final statuses = await DueStatusStorage.loadAll();
    expect(statuses[(1000, 0)]?.doseIndex, 0);
  });

  test(
    'clearing a medication leaves other medication statuses intact',
    () async {
      await DueStatusStorage.markTakenToday(
        1000,
        0,
        when: DateTime(2026, 7, 15),
      );
      await DueStatusStorage.markTakenToday(
        2000,
        0,
        when: DateTime(2026, 7, 15),
      );

      await DueStatusStorage.clearForMedication(1000);
      final statuses = await DueStatusStorage.loadAll();
      expect(statuses[(1000, 0)], isNull);
      expect(statuses[(2000, 0)], isNotNull);
    },
  );
}
