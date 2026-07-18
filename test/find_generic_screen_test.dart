import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_app/find_generic_screen.dart';
import 'package:med_app/rxnav_service.dart';

Future<void> selectUnitedStates(WidgetTester tester) async {
  await tester.tap(find.text('United States'));
  await tester.pump();
}

void main() {
  testWidgets('requires confirmation before showing an approximate generic', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FindGenericScreen(
          lookupUnitedStates: (_) async => const RxNavLookupResult.found(
            genericName: 'Simvastatin',
            matchedMedicineName: 'Simvastatin 10 MG Oral Tablet [Zocor]',
            requiresMatchConfirmation: true,
          ),
        ),
      ),
    );
    await selectUnitedStates(tester);
    await tester.enterText(find.byType(TextField), 'Zocorr');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Search'));
    await tester.pumpAndSettle();

    expect(find.text('Check this possible match'), findsOneWidget);
    expect(find.text('Simvastatin 10 MG Oral Tablet [Zocor]'), findsOneWidget);
    expect(find.text('Simvastatin'), findsNothing);

    final confirmButton = find.text('Yes, the name matches the label');
    await tester.ensureVisible(confirmButton);
    await tester.pumpAndSettle();
    await tester.tap(confirmButton);
    await tester.pump();

    expect(find.text('Simvastatin'), findsOneWidget);
  });

  testWidgets('ignores a US response after the user switches countries', (
    tester,
  ) async {
    final lookup = Completer<RxNavLookupResult>();
    await tester.pumpWidget(
      MaterialApp(
        home: FindGenericScreen(lookupUnitedStates: (_) => lookup.future),
      ),
    );
    await selectUnitedStates(tester);
    await tester.enterText(find.byType(TextField), 'Advil');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Search'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('India'));
    await tester.pump();
    lookup.complete(
      const RxNavLookupResult.found(
        genericName: 'Ibuprofen',
        matchedMedicineName: 'Advil',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ibuprofen'), findsNothing);
    expect(find.text('Medicine matched by RxNorm'), findsNothing);
  });

  testWidgets('ignores an older response after a new search starts', (
    tester,
  ) async {
    final firstLookup = Completer<RxNavLookupResult>();
    final secondLookup = Completer<RxNavLookupResult>();
    var lookupCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: FindGenericScreen(
          lookupUnitedStates: (_) {
            lookupCount++;
            return lookupCount == 1 ? firstLookup.future : secondLookup.future;
          },
        ),
      ),
    );
    await selectUnitedStates(tester);
    await tester.enterText(find.byType(TextField), 'Advil');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Search'));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Tylenol');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Search'));
    await tester.pump();
    expect(lookupCount, 2);

    firstLookup.complete(
      const RxNavLookupResult.found(
        genericName: 'Ibuprofen',
        matchedMedicineName: 'Advil',
      ),
    );
    await tester.pump();
    expect(find.text('Ibuprofen'), findsNothing);

    secondLookup.complete(
      const RxNavLookupResult.found(
        genericName: 'Acetaminophen',
        matchedMedicineName: 'Tylenol',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acetaminophen'), findsOneWidget);
    expect(find.text('Ibuprofen'), findsNothing);
  });

  testWidgets('shows a recoverable error when RxNav cannot be reached', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FindGenericScreen(
          lookupUnitedStates: (_) async =>
              const RxNavLookupResult.networkError(),
        ),
      ),
    );
    await selectUnitedStates(tester);
    await tester.enterText(find.byType(TextField), 'Advil');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Search'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't reach the lookup service"), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
  });
}
