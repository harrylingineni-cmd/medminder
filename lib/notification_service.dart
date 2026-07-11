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

  // A "notification channel" is Android's way of grouping notifications so
  // the user can control their behaviour (sound, importance, etc.) in one
  // place under Settings. We only need one channel for medication reminders.
  static const _channelId = 'medication_reminders';
  static const _channelName = 'Medication Reminders';
  static const _channelDescription =
      'Reminders to take your medication at the scheduled time';

  /// Must be called once before any scheduling happens — we call this from
  /// main() before runApp().
  Future<void> init() async {
    // The `timezone` package ships its own database of the world's time
    // zones (rules for daylight saving, offsets, etc). It has to be loaded
    // once before we can create any "zoned" date/times.
    tz_data.initializeTimeZones();

    // Tell the timezone package which zone the phone is actually in, so
    // "8:30 AM" means 8:30 AM local time, not UTC.
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: initSettings);
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
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  /// Schedules a notification that fires every day at [hour]:[minute]
  /// (24-hour clock), reminding the user to take [medicationName] at
  /// [dosage].
  ///
  /// [id] must be unique per medication — scheduling a new notification
  /// with the same id replaces any previous one, which is also how
  /// `cancel` knows which reminder to stop.
  Future<void> scheduleDailyMedicationReminder({
    required int id,
    required String medicationName,
    required String dosage,
    required int hour,
    required int minute,
  }) async {
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

  /// Cancels the reminder previously scheduled with this [id] (for example
  /// when the user deletes that medication).
  Future<void> cancel(int id) => _plugin.cancel(id: id);

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
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
