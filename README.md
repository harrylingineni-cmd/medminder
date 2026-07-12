# MedMinder

MedMinder is a small, Android-first medication reminder app built as a student project. A user can save a medication name, dosage, and daily time. When that time arrives, the app shows a prominent due card with **I've taken it** and **Remind Me in 10 Minutes** actions.

This project aims to be easy to understand, easy to test, and useful as a lightweight reminder. It has not been clinically validated with people who have dementia.

## Safety boundary

MedMinder is not a medical device and does not provide medical advice. It cannot verify that medication was swallowed, guarantee that every notification will arrive, or replace support from a caregiver or healthcare professional.

- **I've taken it** records a button tap, not confirmed ingestion.
- The app does not recommend dosages or advise what to do about a missed dose.
- Medication details should come from the label or instructions from a healthcare professional.
- Android permissions, battery settings, and device behavior can delay or prevent notifications.

## Current features

- Save medication name, dosage, and daily reminder time.
- Show all saved medications on the home screen.
- Highlight medications that are currently due.
- Mark a due medication as taken for the current day.
- Snooze a due medication for ten minutes.
- Warn when Android notification or exact-alarm access is unavailable.
- Confirm before deleting a medication and cancel its reminders.
- Store medication and due-state data locally using `SharedPreferences`.

There are no accounts, cloud synchronization, remote caregiver alerts, medication lookup, adherence reports, or medical recommendations.

## Project structure

```text
lib/main.dart
  Medication model, local schedule storage, and the Flutter screens

lib/due_status_storage.dart
  Taken/snoozed state and the rule for deciding whether a medication is due

lib/notification_service.dart
  Android notification setup, daily reminders, snoozes, and cancellation
```

## Run locally

Install Flutter with a Dart SDK compatible with `^3.12.2`, then run:

```bash
flutter pub get
flutter run
```

The reminder implementation is intended for Android. Other generated platform folders have not been verified for reminder behavior.

## Verify changes

```bash
flutter analyze
flutter test
flutter build appbundle
```

Before publishing, test on a physical Android phone:

- Notification and exact-alarm permission approval and denial
- A daily reminder while the app is backgrounded
- A ten-minute snooze
- Marking a snoozed medication as taken
- Reboot and app-update reminder behavior
- Large system text and a narrow screen

## Google Play preparation

Before a production release, the student owner should:

- Choose an available app name and final application ID.
- Add a production icon and store screenshots.
- Host a public privacy policy and link it in the app and Play Console.
- Complete the Data safety and Health apps declarations accurately.
- Create a signed Android App Bundle.
- Run any closed test required for the developer account.

Use fictional medication information in demos, screenshots, and automated tests.

## Project ownership

Pull requests are proposals for the student owner to understand and approve. The student should be able to explain the main code paths and product decisions before merging or publishing them.
