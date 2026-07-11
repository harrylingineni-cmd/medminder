import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:med_app/medication_state.dart';

void main() {
  group('MedicationSchedule', () {
    final morning = const Medication(
      id: 1,
      name: 'Morning medicine',
      dosage: '10 mg',
      time: '8:00 AM',
      hour: 8,
      minute: 0,
    );
    final evening = const Medication(
      id: 2,
      name: 'Evening medicine',
      dosage: '5 mg',
      time: '6:00 PM',
      hour: 18,
      minute: 0,
    );

    test('selects earliest overdue occurrence before a future occurrence', () {
      final occurrence = MedicationSchedule.nextOccurrence(
        medications: [evening, morning],
        acknowledgements: const [],
        snoozes: const [],
        now: DateTime(2026, 7, 11, 12),
      );

      expect(occurrence?.medication.id, morning.id);
      expect(occurrence?.isOverdue(DateTime(2026, 7, 11, 12)), isTrue);
    });

    test('advances after acknowledgement', () {
      final now = DateTime(2026, 7, 11, 12);
      final occurrence = MedicationSchedule.nextOccurrence(
        medications: [morning, evening],
        acknowledgements: [
          MedicationAcknowledgement(
            medicationId: morning.id,
            scheduledDate: localDateKey(now),
            acknowledgedAt: now,
          ),
        ],
        snoozes: const [],
        now: now,
      );

      expect(occurrence?.medication.id, evening.id);
      expect(occurrence?.scheduledAt, DateTime(2026, 7, 11, 18));
    });

    test('shows tomorrow after every occurrence today is acknowledged', () {
      final now = DateTime(2026, 7, 11, 20);
      final occurrence = MedicationSchedule.nextOccurrence(
        medications: [morning],
        acknowledgements: [
          MedicationAcknowledgement(
            medicationId: morning.id,
            scheduledDate: localDateKey(now),
            acknowledgedAt: now,
          ),
        ],
        snoozes: const [],
        now: now,
      );

      expect(occurrence?.scheduledAt, DateTime(2026, 7, 12, 8));
      expect(occurrence?.isActionable(now), isFalse);
    });

    test('active snooze is represented without becoming acknowledged', () {
      final now = DateTime(2026, 7, 11, 12);
      final snoozeUntil = now.add(const Duration(minutes: 10));
      final occurrence = MedicationSchedule.nextOccurrence(
        medications: [morning],
        acknowledgements: const [],
        snoozes: [
          MedicationSnooze(
            medicationId: morning.id,
            scheduledDate: localDateKey(now),
            snoozeUntil: snoozeUntil,
          ),
        ],
        now: now,
      );

      expect(occurrence?.medication.id, morning.id);
      expect(occurrence?.snoozedUntil, snoozeUntil);
    });

    test('due unsnoozed medication takes priority over a later snooze', () {
      final now = DateTime(2026, 7, 11, 18);
      final occurrence = MedicationSchedule.nextOccurrence(
        medications: [morning, evening],
        acknowledgements: const [],
        snoozes: [
          MedicationSnooze(
            medicationId: morning.id,
            scheduledDate: localDateKey(now),
            snoozeUntil: now.add(const Duration(minutes: 10)),
          ),
        ],
        now: now,
      );

      expect(occurrence?.medication.id, evening.id);
      expect(occurrence?.snoozedUntil, isNull);
    });

    test('same-time medications preserve caregiver list order', () {
      final second = Medication(
        id: 9,
        name: 'Listed first',
        dosage: '1 tablet',
        time: '8:00 AM',
        hour: 8,
        minute: 0,
      );
      final occurrence = MedicationSchedule.nextOccurrence(
        medications: [second, morning],
        acknowledgements: const [],
        snoozes: const [],
        now: DateTime(2026, 7, 11, 9),
      );

      expect(occurrence?.medication.id, second.id);
    });

    test('orders multiple upcoming occurrences by scheduled time', () {
      final occurrence = MedicationSchedule.nextOccurrence(
        medications: [evening, morning],
        acknowledgements: const [],
        snoozes: const [],
        now: DateTime(2026, 7, 11, 6),
      );

      expect(occurrence?.medication.id, morning.id);
    });

    test('uses a separate notification id for snoozes', () {
      final snooze = MedicationSnooze(
        medicationId: 17,
        scheduledDate: '2026-07-11',
        snoozeUntil: DateTime(2026, 7, 11, 8, 10),
      );

      expect(snooze.notificationId, 17 + snoozeNotificationIdOffset);
    });
  });

  group('MedicationStorage migration', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'migrates missing and duplicate ids to stable unique values',
      () async {
        SharedPreferences.setMockInitialValues({
          'medications': [
            jsonEncode({
              'name': 'First',
              'dosage': '1 mg',
              'time': '8:00 AM',
              'hour': 8,
              'minute': 0,
            }),
            jsonEncode({
              'id': 7,
              'name': 'Second',
              'dosage': '2 mg',
              'time': '9:00 AM',
              'hour': 9,
              'minute': 0,
            }),
            jsonEncode({
              'id': 7,
              'name': 'Third',
              'dosage': '3 mg',
              'time': '10:00 AM',
              'hour': 10,
              'minute': 0,
            }),
          ],
        });

        final firstLoad = await MedicationStorage.load();
        final secondLoad = await MedicationStorage.load();

        expect(firstLoad.map((value) => value.id).toSet().length, 3);
        expect(
          secondLoad.map((value) => value.id).toList(),
          firstLoad.map((value) => value.id).toList(),
        );
      },
    );

    test(
      'throws instead of treating corrupt medication data as empty',
      () async {
        SharedPreferences.setMockInitialValues({
          'medications': ['not valid json'],
        });

        expect(MedicationStorage.load(), throwsFormatException);
      },
    );

    test('migrates unsafe ids and invalid time fields', () async {
      SharedPreferences.setMockInitialValues({
        'pending_notification_cancellations': ['12', '1000000013'],
        'medications': [
          jsonEncode({
            'id': -1,
            'name': 'Negative',
            'dosage': '1 mg',
            'hour': 99,
            'minute': -4,
          }),
          jsonEncode({
            'id': 12,
            'name': 'Reserved',
            'dosage': '2 mg',
            'time': '9:00 AM',
            'hour': 9,
            'minute': 0,
          }),
          jsonEncode({
            'id': maxMedicationId + 1,
            'name': 'Oversized',
            'dosage': '3 mg',
            'time': '10:00 AM',
            'hour': 10,
            'minute': 0,
          }),
        ],
      });

      final medications = await MedicationStorage.load();

      expect(medications.map((value) => value.id).toSet().length, 3);
      expect(
        medications.every(
          (value) =>
              value.id >= 0 && value.id <= maxMedicationId && value.id != 12,
        ),
        isTrue,
      );
      expect(medications.first.hour, 8);
      expect(medications.first.minute, 0);
      expect(medications.first.time, '8:00 AM');
    });

    test('preserves a valid legacy display time during migration', () async {
      SharedPreferences.setMockInitialValues({
        'medications': [
          jsonEncode({
            'id': 10,
            'name': 'Legacy',
            'dosage': '1 mg',
            'time': '3:45 PM',
          }),
        ],
      });

      final result = await MedicationStorage.loadWithMetadata();

      expect(result.migrated, isTrue);
      expect(result.medications.single.hour, 15);
      expect(result.medications.single.minute, 45);
      expect(result.medications.single.time, '3:45 PM');
    });
  });

  group('MedicationStateStorage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('acknowledgement replaces the same occurrence', () async {
      final first = DateTime(2026, 7, 11, 8, 1);
      final second = DateTime(2026, 7, 11, 8, 2);
      await MedicationStateStorage.acknowledge(
        MedicationAcknowledgement(
          medicationId: 1,
          scheduledDate: localDateKey(first),
          acknowledgedAt: first,
        ),
      );
      await MedicationStateStorage.acknowledge(
        MedicationAcknowledgement(
          medicationId: 1,
          scheduledDate: localDateKey(second),
          acknowledgedAt: second,
        ),
      );

      final values = await MedicationStateStorage.loadAcknowledgements(second);
      expect(values, hasLength(1));
      expect(values.single.acknowledgedAt, second);
    });

    test(
      'old and malformed acknowledgement records are ignored or pruned',
      () async {
        final now = DateTime(2026, 7, 11, 12);
        SharedPreferences.setMockInitialValues({
          'medication_acknowledgements': [
            'malformed',
            jsonEncode({
              'medicationId': 1,
              'scheduledDate': '2026-06-01',
              'acknowledgedAt': '2026-06-01T08:00:00',
            }),
            jsonEncode({
              'medicationId': 2,
              'scheduledDate': localDateKey(now),
              'acknowledgedAt': now.toIso8601String(),
            }),
          ],
        });

        final values = await MedicationStateStorage.loadAcknowledgements(now);
        expect(values.map((value) => value.medicationId), [2]);
      },
    );

    test('rewrites storage when every acknowledgement is malformed', () async {
      SharedPreferences.setMockInitialValues({
        'medication_acknowledgements': ['malformed'],
      });

      final values = await MedicationStateStorage.loadAcknowledgements(
        DateTime(2026, 7, 11, 12),
      );
      final preferences = await SharedPreferences.getInstance();

      expect(values, isEmpty);
      expect(preferences.getStringList('medication_acknowledgements'), isEmpty);
    });

    test('snooze replaces and clears a medication occurrence', () async {
      final now = DateTime.now();
      final date = localDateKey(now);
      await MedicationStateStorage.saveSnooze(
        MedicationSnooze(
          medicationId: 7,
          scheduledDate: date,
          snoozeUntil: now.add(const Duration(minutes: 10)),
        ),
      );
      final replacement = MedicationSnooze(
        medicationId: 7,
        scheduledDate: date,
        snoozeUntil: now.add(const Duration(minutes: 20)),
      );
      await MedicationStateStorage.saveSnooze(replacement);

      var values = await MedicationStateStorage.loadSnoozes(now);
      expect(values, hasLength(1));
      expect(values.single.snoozeUntil, replacement.snoozeUntil);

      await MedicationStateStorage.clearSnooze(7, date);
      values = await MedicationStateStorage.loadSnoozes(now);
      expect(values, isEmpty);
    });

    test(
      'malformed and old snoozes are pruned and clear-all removes a medication',
      () async {
        final now = DateTime(2026, 7, 11, 12);
        SharedPreferences.setMockInitialValues({
          'medication_snoozes': [
            'malformed',
            jsonEncode({
              'medicationId': 1,
              'scheduledDate': '2026-06-01',
              'snoozeUntil': '2026-06-01T08:10:00',
            }),
            jsonEncode({
              'medicationId': 7,
              'scheduledDate': localDateKey(now),
              'snoozeUntil': now
                  .add(const Duration(minutes: 10))
                  .toIso8601String(),
            }),
            jsonEncode({
              'medicationId': 8,
              'scheduledDate': localDateKey(now),
              'snoozeUntil': now
                  .add(const Duration(minutes: 20))
                  .toIso8601String(),
            }),
          ],
        });

        var values = await MedicationStateStorage.loadSnoozes(now);
        expect(values.map((value) => value.medicationId), [7, 8]);

        await MedicationStateStorage.clearAllSnoozesForMedication(7);
        values = await MedicationStateStorage.loadSnoozes(now);
        expect(values.map((value) => value.medicationId), [8]);
      },
    );
  });

  group('PendingNotificationCancellationStorage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('deduplicates and removes successful cancellation ids', () async {
      expect(await PendingNotificationCancellationStorage.enqueue(42), isTrue);
      expect(await PendingNotificationCancellationStorage.enqueue(42), isTrue);
      expect(await PendingNotificationCancellationStorage.enqueue(43), isTrue);

      expect(await PendingNotificationCancellationStorage.load(), {42, 43});
      await PendingNotificationCancellationStorage.removeSuccessful([42]);
      expect(await PendingNotificationCancellationStorage.load(), {43});
    });
  });

  group('ReminderRetryStorage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('persists, deduplicates, and removes reminder retry ids', () async {
      await ReminderRetryStorage.add(91);
      await ReminderRetryStorage.add(91);
      await ReminderRetryStorage.add(92);

      expect(await ReminderRetryStorage.load(), {91, 92});
      await ReminderRetryStorage.remove(91);
      expect(await ReminderRetryStorage.load(), {92});
    });
  });
}
