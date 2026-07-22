# MediGuard

MediGuard is a small Flutter app that helps people remember when it is time to
take their medication. It is designed around large text, simple actions, local
storage, and on-device reminders.

## What it supports

- Once-daily, BID (twice daily), TID (three times daily), and QID (four times
  daily) schedules
- Evenly spaced or custom dose times
- A separate taken/snoozed status for every dose
- Repeat reminders every five minutes for a selected 15, 30, or 60 minute
  window
- A ten-minute snooze with its own follow-up reminders
- An offline India brand-name lookup and a live US RxNorm lookup that asks the
  user to confirm any approximate match
- Local-only saved medication data; no account or MediGuard server is required

MediGuard is a reminder tool, not medical advice. The frequency and exact times
must come from the prescription, medication label, pharmacist, or clinician.
The US Find Generic tab sends only the medicine name entered into that search
box to the National Library of Medicine's RxNav service. It does not send the
saved medication schedule, dosage, reminder history, or taken/snoozed status.
MediGuard uses publicly available NLM data; NLM does not endorse or recommend
the app and is not responsible for it.

## Run the project

```sh
flutter pub get
flutter run
```

Run the automated checks with:

```sh
flutter analyze
flutter test
```

Scheduled notifications should also be tested on a physical Android or iOS
device because emulator and desktop behavior can differ from a real phone.
On iOS, MediGuard keeps dose and snooze alerts ahead of follow-up reminders
when the operating system's pending-notification limit is reached.
