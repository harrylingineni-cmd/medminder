import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Everything related to showing and scheduling local medication reminder
/// notifications lives in this one class.
///
/// It is a singleton (there is only ever one `NotificationService` for the
/// whole app) so that any screen can call `NotificationService.instance`
/// without having to pass an instance around.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Future<void>? _initializing;

  // A "notification channel" is Android's way of grouping notifications so
  // the user can control their behaviour (sound, importance, etc.) in one
  // place under Settings. We only need one channel for medication reminders.
  static const _channelId = 'medication_reminders';
  static const _channelName = 'Medication Reminders';
  static const _channelDescription =
      'Reminders to take your medication at the scheduled time';

  // ── Notification id "bands" ────────────────────────────────────────────
  //
  // Every scheduled notification needs a unique numeric id, and a single
  // medication can now have several *doses* a day (e.g. morning, afternoon,
  // evening), each needing its own independent daily reminder, snooze
  // reminder, and repeat-until-confirmed chain. We build every one of these
  // ids out of the medication's own id in two layers:
  //
  //   Layer 1 — pick out which DOSE of the medication this is:
  //     doseId = medicationId + doseIndex * doseSlotSpace
  //   (doseIndex 0 = the 1st dose time, 1 = the 2nd, and so on, up to
  //   `maxDosesPerMedication - 1`.)
  //
  //   Layer 2 — pick out which KIND of notification this is, for that dose,
  //   exactly as before (see `doseNotificationBaseId`, `snoozeNotificationId`,
  //   `repeatNotificationId` below):
  //
  //     daily reminder id        = doseId                (band 0)
  //     snooze reminder id       = doseId + 1 * idSpace  (band 1)
  //     repeat reminder #1 id    = doseId + 2 * idSpace  (band 2)
  //     repeat reminder #2 id    = doseId + 3 * idSpace  (band 3)
  //     ...and so on, one band per repeat.
  //
  // `medicationIdSpace` (the gap reserved between one medication's ids and
  // the next) must be bigger than the largest possible
  // `doseIndex * doseSlotSpace` offset (see `Medication`'s id generation in
  // main.dart, which uses this same constant), and `idSpace` must in turn be
  // bigger than the largest possible medication id, so none of these bands
  // ever overlap — while the very top band still stays comfortably under
  // Android's 32-bit notification id limit (about 2.14 billion).
  static const int idSpace = 100000000; // 100 million

  // The current form offers once, BID, TID, and QID. Keep one extra internal
  // slot so a five-dose schedule saved by the student's previous version can
  // still be edited or deleted without leaving notifications behind.
  static const int maxDosesPerMedication = 5;

  // The id offset between one dose and the next, within the same
  // medication. Only offsets 0 (daily) through 1 + _maxRepeatSlots (the
  // last possible repeat) are ever actually used, so 100 leaves generous
  // headroom.
  static const int doseSlotSpace = 100;

  // The id range reserved for one medication's doses. Must be bigger than
  // `maxDosesPerMedication * doseSlotSpace` (5 * 100 = 500) so that no dose
  // of one medication can ever collide with a dose of another. New
  // medication ids (see main.dart) are always generated as an exact
  // multiple of this, guaranteeing that.
  static const int medicationIdSpace = 1000;
  static const int _maxPlatformNotificationId = 0x7fffffff;
  static const int _minPlatformNotificationId = -0x80000000;
  static const int _iosPendingNotificationLimit = 64;

  // How often the "please confirm" reminder repeats once a dose is due.
  static const int repeatIntervalMinutes = 5;

  // The longest reminder window we offer (see AddMedicationScreen) divided
  // by the repeat interval, i.e. the most repeat notifications any one dose
  // could ever need at once. Used only to know how many ids to try
  // cancelling — cancelling an id that was never scheduled is a safe no-op,
  // so it's fine for this to be a generous upper bound.
  static const int _maxRepeatSlots = 60 ~/ repeatIntervalMinutes;

  /// Must be called once before any scheduling happens — we call this from
  /// main() before runApp().
  Future<void> init() async {
    if (_initialized) return;
    final inProgress = _initializing;
    if (inProgress != null) {
      await inProgress;
      return;
    }
    final initialization = _initialize();
    _initializing = initialization;
    try {
      await initialization;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initialize() async {
    // The `timezone` package ships its own database of the world's time
    // zones (rules for daylight saving, offsets, etc). It has to be loaded
    // once before we can create any "zoned" date/times.
    tz_data.initializeTimeZones();

    // Tell the timezone package which zone the phone is actually in, so
    // "8:30 AM" means 8:30 AM local time, not UTC.
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  /// Asks the user for the two permissions Android requires for scheduled
  /// reminders. Safe to call multiple times — Android just no-ops if the
  /// permission has already been granted (or already denied).
  ///
  /// - Notifications permission (Android 13+ / API 33+): without this the
  ///   app simply cannot show any notification at all.
  /// - Exact alarm permission (Android 12+ / API 31+): without this,
  ///   Android is still allowed to *delay* the reminder by several minutes
  ///   (or longer) to save battery, which isn't good enough for a
  ///   medication reminder.
  Future<void> requestPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Schedules a notification that fires every day at [hour]:[minute]
  /// (24-hour clock), reminding the user to take [medicationName] at
  /// [dosage].
  ///
  /// [id] must be unique per dose — scheduling a new notification with the
  /// same id replaces any previous one, which is also how `cancel` knows
  /// which reminder to stop. Pass `doseNotificationBaseId(medicationId,
  /// doseIndex)` here, not the bare medication id.
  Future<void> scheduleDailyMedicationReminder({
    required int id,
    required String medicationName,
    required String dosage,
    required int hour,
    required int minute,
  }) async {
    await _makeRoomForCriticalNotification(id);
    await _plugin.zonedSchedule(
      id: id,
      title: 'Time for your medication',
      body: '$medicationName - $dosage',
      scheduledDate: _nextInstanceOf(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // exactAllowWhileIdle = fire at the exact minute requested, even if
      // the phone is in Doze/low-power idle mode. This is what actually
      // requires the exact-alarm permission requested above.
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Repeat every day at this time of day, forever, instead of firing
      // just once.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedules a single, one-time reminder that fires at [fireAt] — used
  /// for the "Remind me in 10 minutes" snooze button. Unlike
  /// `scheduleDailyMedicationReminder`, this does NOT repeat: it has no
  /// `matchDateTimeComponents`, so it fires once and is done.
  ///
  /// [id] should be a different notification id than the dose's daily
  /// reminder (see `snoozeNotificationId` below), so snoozing never cancels
  /// or overwrites the daily reminder.
  Future<void> scheduleOneOffReminder({
    required int id,
    required String medicationName,
    required String dosage,
    required DateTime fireAt,
  }) async {
    await _makeRoomForCriticalNotification(id);
    await _plugin.zonedSchedule(
      id: id,
      title: 'Reminder: time for your medication',
      body: '$medicationName - $dosage',
      scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Schedules the "please confirm you've taken it" repeat chain for one
  /// dose: a one-off notification every [repeatIntervalMinutes] minutes,
  /// starting [repeatIntervalMinutes] minutes after [anchorTime] (the
  /// moment that dose's *original* daily reminder fires), and continuing
  /// until [reminderWindowMinutes] minutes have passed.
  ///
  /// [id] identifies the dose — pass `doseNotificationBaseId(medicationId,
  /// doseIndex)`, the same id used for that dose's daily reminder.
  ///
  /// Each repeat gets its own fixed id (see `repeatNotificationId`), so
  /// calling this again later — e.g. because the user re-opened the app —
  /// simply *overwrites* the same notifications with the same fire times
  /// instead of creating new, duplicate ones. That's what keeps repeats
  /// from stacking up.
  ///
  /// These are intentionally one-off notifications. A calendar-matching
  /// notification can fire today even when its requested start date is
  /// tomorrow, which would make reminders continue after the user taps Taken.
  /// The app explicitly schedules tomorrow's chain after Taken or Snooze.
  Future<void> scheduleRepeatReminders({
    required int id,
    required String medicationName,
    required String dosage,
    required DateTime anchorTime,
    required int reminderWindowMinutes,
  }) async {
    final now = DateTime.now();
    final requestedCount = reminderWindowMinutes ~/ repeatIntervalMinutes;
    final futureSlots = <int>[];
    for (var slot = 1; slot <= requestedCount; slot++) {
      final fireAt = anchorTime.add(
        Duration(minutes: repeatIntervalMinutes * slot),
      );
      if (fireAt.isAfter(now)) futureSlots.add(slot);
    }
    final allowedCount = await _countThatFitsPendingLimit([
      for (var slot = 1; slot <= _maxRepeatSlots; slot++)
        repeatNotificationId(id, slot),
    ], futureSlots.length);
    final allowedSlots = futureSlots.take(allowedCount).toSet();

    for (var slot = 1; slot <= _maxRepeatSlots; slot++) {
      final repeatId = repeatNotificationId(id, slot);
      if (!allowedSlots.contains(slot)) {
        await cancel(repeatId);
        continue;
      }
      final fireAt = anchorTime.add(
        Duration(minutes: repeatIntervalMinutes * slot),
      );

      await _plugin.zonedSchedule(
        id: repeatId,
        title: 'Reminder: please confirm your medication',
        body: '$medicationName - $dosage - still waiting for you to confirm',
        scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  /// Schedules one-off follow-ups after a ten-minute snooze. Negative ids are
  /// deliberately used as a separate collision-free namespace from the
  /// positive ids used by the normal one-off repeat series.
  Future<void> scheduleSnoozeRepeatReminders({
    required int id,
    required String medicationName,
    required String dosage,
    required DateTime snoozeUntil,
    required int reminderWindowMinutes,
  }) async {
    final requestedCount = reminderWindowMinutes ~/ repeatIntervalMinutes;
    final repeatCount = await _countThatFitsPendingLimit([
      for (var slot = 1; slot <= _maxRepeatSlots; slot++)
        snoozeRepeatNotificationId(id, slot),
    ], requestedCount);
    for (var slot = 1; slot <= repeatCount; slot++) {
      await _plugin.zonedSchedule(
        id: snoozeRepeatNotificationId(id, slot),
        title: 'Reminder: please confirm your medication',
        body: '$medicationName - $dosage - still waiting for you to confirm',
        scheduledDate: tz.TZDateTime.from(
          snoozeUntil.add(Duration(minutes: repeatIntervalMinutes * slot)),
          tz.local,
        ),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
    for (var slot = repeatCount + 1; slot <= _maxRepeatSlots; slot++) {
      await cancel(snoozeRepeatNotificationId(id, slot));
    }
  }

  Future<int> _countThatFitsPendingLimit(
    List<int> replaceableIds,
    int requestedCount,
  ) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return requestedCount;
    final replaceable = replaceableIds.toSet();
    final pending = await _plugin.pendingNotificationRequests();
    final unrelatedCount = pending
        .where((request) => !replaceable.contains(request.id))
        .length;
    final available = _iosPendingNotificationLimit - unrelatedCount;
    if (available <= 0) return 0;
    return available < requestedCount ? available : requestedCount;
  }

  Future<void> _makeRoomForCriticalNotification(int id) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    final pending = await _plugin.pendingNotificationRequests();
    if (pending.any((request) => request.id == id) ||
        pending.length < _iosPendingNotificationLimit) {
      return;
    }
    // Daily dose and snooze alerts are more important than follow-ups. Remove
    // one follow-up if iOS's fixed pending-request limit is already full.
    for (final request in pending.reversed) {
      if (request.id < 0 || request.id >= 2 * idSpace) {
        await cancel(request.id);
        return;
      }
    }
    throw StateError('iOS has no pending notification slot available.');
  }

  /// Cancels every repeat reminder that could possibly be pending for dose
  /// [id] — called when the user confirms "I've taken it" or snoozes, so
  /// the repeats stop immediately instead of continuing to fire.
  ///
  /// It loops over every *possible* repeat slot rather than just the ones
  /// we know we scheduled, because cancelling an id Android doesn't
  /// recognise is a harmless no-op — that keeps this simple and safe even
  /// if the reminder window changed since the chain was first scheduled.
  Future<void> cancelRepeatReminders(int id) async {
    for (var slot = 1; slot <= _maxRepeatSlots; slot++) {
      await cancel(repeatNotificationId(id, slot));
    }
  }

  Future<void> cancelSnoozeRepeatReminders(int id) async {
    for (var slot = 1; slot <= _maxRepeatSlots; slot++) {
      await cancel(snoozeRepeatNotificationId(id, slot));
    }
  }

  /// Cancels the reminder previously scheduled with this [id] (for example
  /// when the user deletes that medication).
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  Future<void> _cancelIfPlatformIdIsValid(int id) async {
    if (id < _minPlatformNotificationId || id > _maxPlatformNotificationId) {
      return;
    }
    await cancel(id);
  }

  Future<void> cancelAllForDose(int doseId) async {
    await _cancelIfPlatformIdIsValid(doseId);
    await _cancelIfPlatformIdIsValid(snoozeNotificationId(doseId));
    for (var slot = 1; slot <= _maxRepeatSlots; slot++) {
      await _cancelIfPlatformIdIsValid(repeatNotificationId(doseId, slot));
      await _cancelIfPlatformIdIsValid(
        snoozeRepeatNotificationId(doseId, slot),
      );
    }
  }

  /// Cancels absolutely everything that could be scheduled for
  /// [medicationId] — every dose slot's daily reminder, snooze reminder,
  /// and repeat chain — regardless of how many doses that medication
  /// currently has. Used when deleting a medication, and when editing one
  /// (since its dose times/count may have changed, the safest thing is to
  /// wipe every possible dose slot and reschedule fresh).
  ///
  /// It's safe (and cheap) to loop over every *possible* dose slot rather
  /// than just the ones currently in use, for the same reason
  /// `cancelRepeatReminders` does: cancelling an id that was never
  /// scheduled is a harmless no-op.
  Future<void> cancelAllForMedication(int medicationId) async {
    for (var doseIndex = 0; doseIndex < maxDosesPerMedication; doseIndex++) {
      final doseId = doseNotificationBaseId(medicationId, doseIndex);
      await cancelAllForDose(doseId);
    }
  }

  /// The base notification id for one specific dose of one medication (its
  /// daily reminder id — see the "Notification id bands" comment above
  /// `idSpace`). Every other notification for that same dose (snooze,
  /// repeats) is derived from this by adding multiples of `idSpace` on top.
  static int doseNotificationBaseId(int medicationId, int doseIndex) =>
      medicationId + doseIndex * doseSlotSpace;

  /// A dose's daily reminder, its "snoozed" one-off reminder, and its
  /// repeat-until-confirmed chain must all use different notification ids,
  /// otherwise scheduling one would silently replace another. This derives
  /// the snooze id from the dose's own base id (see
  /// `doseNotificationBaseId`) by shifting it into the next
  /// `idSpace`-sized band.
  static int snoozeNotificationId(int doseId) => doseId + idSpace;

  /// Derives the id for repeat number [slot] (1 = the first repeat, 5
  /// minutes after the original reminder; 2 = ten minutes after; and so
  /// on), by shifting the dose's base id into band `1 + slot` (band 0 is
  /// the daily reminder, band 1 is the snooze — see `idSpace` above).
  static int repeatNotificationId(int doseId, int slot) =>
      doseId + (1 + slot) * idSpace;

  static int snoozeRepeatNotificationId(int doseId, int slot) =>
      -repeatNotificationId(doseId, slot);

  /// Whether the app currently has permission to show notifications at all.
  /// Used to show the "reminders may not appear" warning banner.
  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosPermissions = await iosPlugin?.checkPermissions();
    return iosPermissions?.isEnabled ?? true;
  }

  /// Whether the app currently has permission to schedule *exact* alarms.
  /// Without this, Android may delay reminders by several minutes.
  Future<bool> canScheduleExactAlarms() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await androidPlugin?.canScheduleExactNotifications() ?? true;
  }

  /// Returns the next moment (today or tomorrow) that matches [hour]:[minute].
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + 1,
        hour,
        minute,
      );
    }
    return scheduled;
  }
}
