import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:med_app/due_status_storage.dart';
import 'package:med_app/main.dart';
import 'package:med_app/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'legacy ids migrate into the safe notification range with due state',
    () async {
      const oldId = 999999999;
      SharedPreferences.setMockInitialValues({
        'medications': [
          jsonEncode({
            'id': oldId,
            'name': 'Example',
            'dosage': '10 mg',
            'hour': 8,
            'minute': 0,
          }),
        ],
        'due_status': [
          jsonEncode({
            'medicationId': oldId,
            'doseIndex': 0,
            'takenDate': '2026-07-15',
            'snoozeUntilMillis': null,
          }),
        ],
      });

      final medications = await MedicationStorage.load();
      final migratedId = medications.single.id;
      expect(migratedId, greaterThan(0));
      expect(migratedId, lessThan(NotificationService.idSpace));
      expect(migratedId % NotificationService.medicationIdSpace, 0);

      final due = await DueStatusStorage.loadAll();
      expect(due[(migratedId, 0)]?.takenDate, '2026-07-15');
      expect(due[(oldId, 0)], isNull);
      expect(
        await MedicationStorage.pendingNotificationCleanupIds(),
        contains(oldId),
      );
    },
  );

  test('duplicate saved ids are replaced and new ids stay monotonic', () async {
    Map<String, Object> medication(String name) => {
      'id': 1000,
      'name': name,
      'dosage': '10 mg',
      'doseTimes': [
        {'hour': 8, 'minute': 0},
      ],
      'reminderWindowMinutes': 30,
    };
    SharedPreferences.setMockInitialValues({
      'medications': [
        jsonEncode(medication('First')),
        jsonEncode(medication('Second')),
      ],
    });

    final medications = await MedicationStorage.load();
    expect(
      medications.map((medication) => medication.id).toSet(),
      hasLength(2),
    );

    final firstAllocated = await MedicationStorage.allocateId();
    final secondAllocated = await MedicationStorage.allocateId();
    expect(firstAllocated, greaterThan(medications.last.id));
    expect(
      secondAllocated,
      firstAllocated + NotificationService.medicationIdSpace,
    );
  });
}
