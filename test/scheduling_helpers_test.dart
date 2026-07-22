import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_app/main.dart';
import 'package:med_app/notification_service.dart';

void main() {
  group('multi-dose schedules', () {
    test('once daily keeps the selected time', () {
      final times = evenlySpacedDoseTimes(
        const TimeOfDay(hour: 8, minute: 30),
        1,
      );

      expect(times.map((time) => (time.hour, time.minute)), [(8, 30)]);
    });

    test('BID is spaced 12 hours apart', () {
      final times = evenlySpacedDoseTimes(
        const TimeOfDay(hour: 8, minute: 30),
        2,
      );

      expect(times.map((time) => (time.hour, time.minute)), [
        (8, 30),
        (20, 30),
      ]);
    });

    test('TID is spaced 8 hours apart and sorted by clock time', () {
      final times = evenlySpacedDoseTimes(
        const TimeOfDay(hour: 8, minute: 0),
        3,
      );

      expect(times.map((time) => (time.hour, time.minute)), [
        (0, 0),
        (8, 0),
        (16, 0),
      ]);
    });

    test('QID is spaced 6 hours apart and sorted by clock time', () {
      final times = evenlySpacedDoseTimes(
        const TimeOfDay(hour: 8, minute: 0),
        4,
      );

      expect(times.map((time) => (time.hour, time.minute)), [
        (2, 0),
        (8, 0),
        (14, 0),
        (20, 0),
      ]);
    });

    test('detects duplicate custom dose times', () {
      expect(
        hasDuplicateDoseTimes(const [
          DoseTime(hour: 8, minute: 0),
          DoseTime(hour: 8, minute: 0),
        ]),
        isTrue,
      );
    });
  });

  test('old single-dose medication data still loads', () {
    final medication = Medication.fromJson({
      'id': 1000,
      'name': 'Example',
      'dosage': '10 mg',
      'hour': 9,
      'minute': 15,
    });

    expect(medication.doseTimes, hasLength(1));
    expect(medication.doseTimes.single.hour, 9);
    expect(medication.doseTimes.single.minute, 15);
  });

  test('multi-dose medication data round-trips', () {
    final original = Medication(
      id: 1000,
      name: 'Example',
      dosage: '10 mg',
      doseTimes: const [
        DoseTime(hour: 8, minute: 0),
        DoseTime(hour: 20, minute: 0),
      ],
      reminderWindowMinutes: 60,
    );

    final restored = Medication.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.name, original.name);
    expect(restored.dosage, original.dosage);
    expect(restored.doseTimes.map((time) => (time.hour, time.minute)), [
      (8, 0),
      (20, 0),
    ]);
    expect(restored.reminderWindowMinutes, 60);
  });

  testWidgets('editing a legacy five-dose schedule preserves all times', (
    tester,
  ) async {
    final legacyMedication = Medication(
      id: 1000,
      name: 'Example',
      dosage: '10 mg',
      doseTimes: const [
        DoseTime(hour: 6, minute: 0),
        DoseTime(hour: 9, minute: 0),
        DoseTime(hour: 12, minute: 0),
        DoseTime(hour: 15, minute: 0),
        DoseTime(hour: 18, minute: 0),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: AddMedicationScreen(existing: legacyMedication)),
    );

    expect(find.text('5 times a day'), findsOneWidget);
    expect(find.text('Dose 5 Time'), findsOneWidget);
  });

  test('notification ids are unique across dose and reminder kinds', () {
    final ids = <int>{};
    for (final medicationId in [42000, 43000]) {
      for (
        var dose = 0;
        dose < NotificationService.maxDosesPerMedication;
        dose++
      ) {
        final baseId = NotificationService.doseNotificationBaseId(
          medicationId,
          dose,
        );
        ids
          ..add(baseId)
          ..add(NotificationService.snoozeNotificationId(baseId));
        for (var slot = 1; slot <= 12; slot++) {
          ids
            ..add(NotificationService.repeatNotificationId(baseId, slot))
            ..add(NotificationService.snoozeRepeatNotificationId(baseId, slot));
        }
      }
    }

    expect(ids, hasLength(NotificationService.maxDosesPerMedication * 2 * 26));
    expect(ids.every((id) => id >= -0x80000000 && id <= 0x7fffffff), isTrue);
  });

  test('snooze collision checks use the next dose across the schedule', () {
    final nextDose = nextMedicationDoseAfter(const [
      DoseTime(hour: 8, minute: 0),
      DoseTime(hour: 14, minute: 0),
      DoseTime(hour: 20, minute: 0),
    ], DateTime(2026, 7, 15, 13, 55));

    expect(nextDose, DateTime(2026, 7, 15, 14));
  });

  test('an expired reminder chain advances to the next occurrence', () {
    final anchor = reminderChainAnchor(
      doseTime: const DoseTime(hour: 8, minute: 0),
      now: DateTime(2026, 7, 15, 9, 1),
      reminderWindowMinutes: 60,
      takenDate: null,
      snoozeSeriesActive: false,
    );

    expect(anchor, DateTime(2026, 7, 16, 8));
  });

  test('a reminder chain crossing midnight keeps its original occurrence', () {
    final anchor = reminderChainAnchor(
      doseTime: const DoseTime(hour: 23, minute: 55),
      now: DateTime(2026, 7, 16, 0, 30),
      reminderWindowMinutes: 60,
      takenDate: null,
      snoozeSeriesActive: false,
    );

    expect(anchor, DateTime(2026, 7, 15, 23, 55));
  });
}
