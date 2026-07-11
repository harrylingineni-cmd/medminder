import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:med_app/main.dart';
import 'package:med_app/medication_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('empty patient screen directs caregiver to setup', (
    tester,
  ) async {
    await tester.pumpWidget(const MedTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('No medications set up'), findsOneWidget);
    expect(find.text('Open caregiver setup'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets(
    'tomorrow medication is visible without acknowledgement actions',
    (tester) async {
      final now = DateTime.now();
      await MedicationStorage.save([
        Medication(
          id: 101,
          name: 'Example Medicine',
          dosage: '10 mg',
          time: _formatTime(now),
          hour: now.hour,
          minute: now.minute,
        ),
      ]);
      await MedicationStateStorage.acknowledge(
        MedicationAcknowledgement(
          medicationId: 101,
          scheduledDate: localDateKey(now),
          acknowledgedAt: now,
        ),
      );

      await tester.pumpWidget(const MedTrackerApp());
      await tester.pumpAndSettle();

      expect(find.text('Example Medicine'), findsOneWidget);
      expect(find.text('I’ve taken it'), findsNothing);
      expect(find.text('Remind me in 10 minutes'), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    },
  );

  testWidgets('due medication can be acknowledged and advances', (
    tester,
  ) async {
    final now = DateTime.now();
    await MedicationStorage.save([
      Medication(
        id: 202,
        name: 'Example Medicine',
        dosage: '10 mg',
        time: _formatTime(now),
        hour: now.hour,
        minute: now.minute,
      ),
    ]);

    await tester.pumpWidget(MedTrackerApp(nowProvider: () => now));
    await tester.pumpAndSettle();
    expect(find.text('I’ve taken it'), findsOneWidget);

    await tester.tap(find.text('I’ve taken it'));
    await tester.pumpAndSettle();

    expect(find.text('Marked as taken'), findsOneWidget);
    expect(find.textContaining('Example Medicine'), findsWidgets);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('rapid taken and snooze taps produce one acknowledgement', (
    tester,
  ) async {
    final now = DateTime(2026, 7, 11, 8, 30);
    await MedicationStorage.save(const [
      Medication(
        id: 212,
        name: 'Race Example',
        dosage: '10 mg',
        time: '8:30 AM',
        hour: 8,
        minute: 30,
      ),
    ]);

    await tester.pumpWidget(MedTrackerApp(nowProvider: () => now));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I’ve taken it'));
    await tester.tap(find.text('Remind me in 10 minutes'));
    await tester.pumpAndSettle();

    expect(find.text('Marked as taken'), findsOneWidget);
    expect(await MedicationStateStorage.loadSnoozes(now), isEmpty);
    expect(
      await MedicationStateStorage.loadAcknowledgements(now),
      hasLength(1),
    );
  });

  testWidgets('caregiver screen contains management controls', (tester) async {
    await MedicationStorage.save(const [
      Medication(
        id: 303,
        name: 'Example Medicine',
        dosage: '5 mg',
        time: '8:30 AM',
        hour: 8,
        minute: 30,
      ),
    ]);

    await tester.pumpWidget(const MedTrackerApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Caregiver setup'));
    await tester.pumpAndSettle();

    expect(find.text('Medication Schedule'), findsOneWidget);
    expect(find.text('Add Medication'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Delete medication?'), findsOneWidget);
    expect(find.text('Keep medication'), findsOneWidget);

    await tester.tap(find.text('Keep medication'));
    await tester.pumpAndSettle();
    expect(find.text('Example Medicine'), findsOneWidget);
    expect((await MedicationStorage.load()).length, 1);
  });

  testWidgets('corrupt medication data is not presented as an empty schedule', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'medications': ['not valid json'],
    });

    await tester.pumpWidget(const MedTrackerApp());
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Medication data is unavailable'),
      findsOneWidget,
    );
    expect(find.text('No medications set up'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Open caregiver setup'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Retry before changing the schedule'),
      findsOneWidget,
    );
  });

  testWidgets('add form validates fields and requires a reminder time', (
    tester,
  ) async {
    await tester.pumpWidget(const MedTrackerApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Caregiver setup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Medication'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Medication'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter the medication name.'), findsOneWidget);
    expect(find.text('Please enter the dosage.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Example');
    await tester.enterText(find.byType(TextFormField).at(1), '5 mg');
    await tester.tap(find.text('Save Medication'));
    await tester.pumpAndSettle();
    expect(find.text('Please select a reminder time.'), findsOneWidget);
  });

  testWidgets(
    'valid add persists medication when platform reminder is absent',
    (tester) async {
      await tester.pumpWidget(const MedTrackerApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Caregiver setup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Medication'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Example Medicine',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '5 mg');
      await tester.tap(find.text('Tap to select a time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Medication'));
      await tester.pumpAndSettle();

      expect(find.text('Medication Schedule'), findsOneWidget);
      expect(find.text('Example Medicine'), findsOneWidget);
      expect((await MedicationStorage.load()), hasLength(1));
      expect(
        find.textContaining('reminder could not be scheduled'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'confirmed delete persists removal even if platform cancel fails',
    (tester) async {
      await MedicationStorage.save(const [
        Medication(
          id: 404,
          name: 'Delete Me',
          dosage: '1 mg',
          time: '8:30 AM',
          hour: 8,
          minute: 30,
        ),
      ]);
      await tester.pumpWidget(const MedTrackerApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Caregiver setup'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Me'), findsNothing);
      expect(await MedicationStorage.load(), isEmpty);
    },
  );
}

String _formatTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${value.hour < 12 ? 'AM' : 'PM'}';
}
