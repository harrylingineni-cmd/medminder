import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:med_app/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('empty schedule explains how to add a medication', (
    tester,
  ) async {
    await tester.pumpWidget(const MedTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('No medications yet'), findsOneWidget);
    expect(find.text('Add Medication'), findsOneWidget);
  });

  testWidgets('due medication shows taken and snooze actions', (tester) async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'medications': [
        jsonEncode(
          Medication(
            id: 10,
            name: 'Example Medicine',
            dosage: '5 mg',
            time: _formatTime(now),
            hour: now.hour,
            minute: now.minute,
          ).toJson(),
        ),
      ],
    });

    await tester.pumpWidget(const MedTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Medication Due'), findsOneWidget);
    expect(find.text("I've taken it"), findsOneWidget);
    expect(find.text('Remind Me in 10 Minutes'), findsOneWidget);
  });

  testWidgets('marking a due medication taken hides the due card', (
    tester,
  ) async {
    final now = DateTime.now();
    await MedicationStorage.save([
      Medication(
        id: 11,
        name: 'Taken Example',
        dosage: '5 mg',
        time: _formatTime(now),
        hour: now.hour,
        minute: now.minute,
      ),
    ]);
    await tester.pumpWidget(const MedTrackerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text("I've taken it"));
    await tester.pumpAndSettle();

    expect(find.text('Medication Due'), findsNothing);
    expect(find.text('Taken Example'), findsOneWidget);
  });

  testWidgets('failed snooze remains due and explains the problem', (
    tester,
  ) async {
    final now = DateTime.now();
    await MedicationStorage.save([
      Medication(
        id: 12,
        name: 'Snooze Example',
        dosage: '5 mg',
        time: _formatTime(now),
        hour: now.hour,
        minute: now.minute,
      ),
    ]);
    await tester.pumpWidget(const MedTrackerApp());
    await tester.pumpAndSettle();

    final snoozeButton = find.text('Remind Me in 10 Minutes');
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(snoozeButton);
    await tester.pumpAndSettle();

    expect(find.text('Medication Due'), findsOneWidget);
    expect(
      find.text('The snooze reminder could not be scheduled. Try again.'),
      findsOneWidget,
    );
  });

  testWidgets('add form validates all required information', (tester) async {
    await tester.pumpWidget(const MedTrackerApp());
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
    expect(find.text('Please select a time.'), findsOneWidget);
  });

  testWidgets('valid medication is saved even if its reminder fails', (
    tester,
  ) async {
    await tester.pumpWidget(const MedTrackerApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Medication'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Saved Example');
    await tester.enterText(find.byType(TextFormField).at(1), '10 mg');
    await tester.tap(find.text('Tap to select a time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Medication'));
    await tester.pumpAndSettle();

    expect(find.text('Saved Example'), findsOneWidget);
    expect(await MedicationStorage.load(), hasLength(1));
    expect(
      find.textContaining('reminder could not be scheduled'),
      findsOneWidget,
    );
  });

  testWidgets('delete requires confirmation and persists removal', (
    tester,
  ) async {
    await MedicationStorage.save(const [
      Medication(
        id: 20,
        name: 'Keep Me',
        dosage: '1 tablet',
        time: '11:59 PM',
        hour: 23,
        minute: 59,
      ),
    ]);
    await tester.pumpWidget(const MedTrackerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Delete medication?'), findsOneWidget);
    await tester.tap(find.text('Keep medication'));
    await tester.pumpAndSettle();
    expect(find.text('Keep Me'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Keep Me'), findsNothing);
    expect(await MedicationStorage.load(), isEmpty);
  });

  testWidgets('corrupt medication data shows a recoverable error', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'medications': ['not valid json'],
    });

    await tester.pumpWidget(const MedTrackerApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('could not be read'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('No medications yet'), findsNothing);
  });
}

String _formatTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${value.hour < 12 ? 'AM' : 'PM'}';
}
