import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_app/due_status_storage.dart';
import 'package:med_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'has_seen_welcome': true});
  });

  testWidgets('shows the MediGuard empty state', (tester) async {
    await tester.pumpWidget(const MedTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('MediGuard'), findsOneWidget);
    expect(find.text('No medications yet'), findsOneWidget);
    expect(find.text('Add Medication'), findsOneWidget);
    expect(find.text('Find Generic'), findsOneWidget);

    await tester.tap(find.text('Find Generic'));
    await tester.pumpAndSettle();
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('United States'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('add form offers once, BID, TID, and QID only', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AddMedicationScreen(newMedicationId: 1000)),
    );

    expect(find.text('Once a day'), findsOneWidget);
    expect(find.text('BID · Twice a day'), findsOneWidget);
    expect(find.text('TID · 3 times a day'), findsOneWidget);
    expect(find.text('QID · 4 times a day'), findsOneWidget);
    expect(find.text('5 times a day'), findsNothing);
  });

  testWidgets('taking one due dose leaves the other dose due', (tester) async {
    SharedPreferences.setMockInitialValues({
      'has_seen_welcome': true,
      'medications': [
        jsonEncode({
          'id': 1000,
          'name': 'Example',
          'dosage': '10 mg',
          'doseTimes': [
            {'hour': 0, 'minute': 0},
            {'hour': 0, 'minute': 1},
          ],
          'reminderWindowMinutes': 30,
        }),
      ],
    });
    await tester.pumpWidget(const MedTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Medication Due'), findsNWidgets(2));
    final takenButton = find.text("I've taken it").first;
    await tester.ensureVisible(takenButton);
    await tester.pumpAndSettle();
    await tester.tap(takenButton);
    await tester.pumpAndSettle();

    expect(find.text('Medication Due'), findsOneWidget);
    final statuses = await DueStatusStorage.loadAll();
    expect(statuses[(1000, 0)]?.takenDate, isNotNull);
    expect(statuses[(1000, 1)], isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('corrupt saved medication data shows a recoverable error', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'has_seen_welcome': true,
      'medications': ['not-json'],
    });
    await tester.pumpWidget(const MedTrackerApp());
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Saved medication data could not be read'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
