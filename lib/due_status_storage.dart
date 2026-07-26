import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ─── "Due / Taken / Snoozed" Logic ─────────────────────────────────────────
//
// This file answers one question, per DOSE (not per medication): "has this
// dose already been dealt with today, or is it still due?"
//
// A medication can now have several dose times a day (e.g. morning,
// afternoon, evening), and each one is tracked completely separately here —
// taking the morning dose never affects whether the afternoon dose is due.
// Each dose is identified by the pair (medicationId, doseIndex), where
// doseIndex is its position in that medication's list of dose times.
//
// For each dose we remember two things:
//   1. takenDate   — the date (like "2026-07-12") the user last tapped
//                     "I've taken it" for that dose. If this equals *today's*
//                     date, the dose is done for today.
//   2. snoozeUntil — if the user tapped "Remind me in 10 minutes" for that
//                     dose, this is the exact moment the snooze ends. Until
//                     that moment passes, the dose is temporarily not due.
//
// Neither of these needs to be explicitly "reset" every day — that's the
// trick. `takenDate` only matches *today*, so as soon as the calendar day
// changes, the stored date is "yesterday" and no longer matches, so the
// dose becomes due again automatically. Same idea for `snoozeUntil`: once
// that moment is in the past, it simply stops blocking the reminder.

/// The stored due/taken/snooze state for a single dose of a single
/// medication.
class DueStatusEntry {
  final int medicationId;
  final int doseIndex;
  final String? takenDate; // e.g. "2026-07-12", or null if never taken.
  final int? snoozeUntilMillis; // epoch millis, or null if not snoozed.

  DueStatusEntry({
    required this.medicationId,
    required this.doseIndex,
    this.takenDate,
    this.snoozeUntilMillis,
  });

  Map<String, dynamic> toJson() => {
    'medicationId': medicationId,
    'doseIndex': doseIndex,
    'takenDate': takenDate,
    'snoozeUntilMillis': snoozeUntilMillis,
  };

  factory DueStatusEntry.fromJson(Map<String, dynamic> json) => DueStatusEntry(
    medicationId: json['medicationId'] as int,
    // Entries saved before multi-dose support won't have this field yet —
    // back then a medication only ever had one dose, so treat it as dose 0.
    doseIndex: json['doseIndex'] as int? ?? 0,
    takenDate: json['takenDate'] as String?,
    snoozeUntilMillis: json['snoozeUntilMillis'] as int?,
  );
}

/// Identifies a single dose: which medication it belongs to, and its
/// position (0-based) in that medication's list of dose times. Dart records
/// like this have built-in structural equality, so a `(int, int)` record
/// works as a normal, hashable Map key.
typedef DoseKey = (int medicationId, int doseIndex);

/// Reads and writes the due/taken/snooze state for every dose of every
/// medication.
///
/// Just like `MedicationStorage`, everything is kept as one JSON string list
/// in SharedPreferences so it survives the app being closed.
class DueStatusStorage {
  static const _storageKey = 'due_status';

  /// Load the status for every dose that has one recorded. Doses with no
  /// entry yet (e.g. a brand new medication) are simply absent from the
  /// returned map — treat that as "not taken, not snoozed".
  static Future<Map<DoseKey, DueStatusEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStrings = prefs.getStringList(_storageKey) ?? [];
    final entries = jsonStrings.map(
      (s) => DueStatusEntry.fromJson(jsonDecode(s) as Map<String, dynamic>),
    );
    return {for (final e in entries) (e.medicationId, e.doseIndex): e};
  }

  static Future<void> _saveAll(Map<DoseKey, DueStatusEntry> all) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStrings = all.values.map((e) => jsonEncode(e.toJson())).toList();
    // setStringList returns false (rather than throwing) if the platform
    // write fails, e.g. disk full or a storage-plugin error. Ignoring that
    // used to mean a failed "I've taken it" or snooze tap would look
    // successful in the UI while nothing was actually persisted.
    final saved = await prefs.setStringList(_storageKey, jsonStrings);
    if (!saved) {
      throw StateError('Failed to save medication due/taken/snooze status.');
    }
  }

  /// Record that dose [doseIndex] of [medicationId] was taken. This clears
  /// any snooze on that specific dose, since it's now been dealt with.
  /// Other doses of the same medication are untouched.
  ///
  /// [when] should be the date of the occurrence actually being confirmed
  /// (see [currentDoseOccurrence]) — normally that's just today, but for a
  /// late-night dose confirmed shortly after midnight it's last night's
  /// date. Defaults to right now if omitted, which is correct for every
  /// case except that one.
  static Future<void> markTakenToday(
    int medicationId,
    int doseIndex, {
    DateTime? when,
  }) async {
    final all = await loadAll();
    all[(medicationId, doseIndex)] = DueStatusEntry(
      medicationId: medicationId,
      doseIndex: doseIndex,
      takenDate: todayString(when),
      snoozeUntilMillis: null,
    );
    await _saveAll(all);
  }

  /// Record that dose [doseIndex] of [medicationId] was snoozed until
  /// [until]. Keeps whatever takenDate was already stored for that dose
  /// (there shouldn't be one for today, since you can't snooze something
  /// you've already taken, but this is safer).
  static Future<void> snooze(
    int medicationId,
    int doseIndex,
    DateTime until,
  ) async {
    final all = await loadAll();
    final key = (medicationId, doseIndex);
    all[key] = DueStatusEntry(
      medicationId: medicationId,
      doseIndex: doseIndex,
      takenDate: all[key]?.takenDate,
      snoozeUntilMillis: until.millisecondsSinceEpoch,
    );
    await _saveAll(all);
  }

  /// Removes every stored dose status for [medicationId] — every dose, for
  /// every day. Called when a medication is deleted (its statuses are no
  /// longer meaningful) and when it's edited (its dose times/count may have
  /// changed, so an old "dose 1 was taken" entry could now refer to a
  /// completely different time of day — safest to start fresh).
  static Future<void> clearForMedication(int medicationId) async {
    final all = await loadAll();
    all.removeWhere((key, _) => key.$1 == medicationId);
    await _saveAll(all);
  }

  /// Today's date as "yyyy-MM-dd", used to check/record `takenDate`.
  static String todayString([DateTime? when]) {
    final d = when ?? DateTime.now();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

/// Which scheduled occurrence of a dose (at [hour]:[minute]) should
/// currently be treated as "the one in play" — or null if none should.
///
/// Normally that's today's occurrence. But if today's time hasn't arrived
/// yet, it might still be YESTERDAY's occurrence, carried forward as long as
/// [now] is within [reminderWindowMinutes] of it (e.g. it's 12:05 AM and the
/// dose was due at 11:50 PM last night). Only once that window has also
/// elapsed does this return null — meaning neither occurrence applies right
/// now.
///
/// This is the one place that decides "which night does this moment belong
/// to" for a dose. Both [isMedicationDue] and `_markTaken` in main.dart call
/// it, so a dose confirmed just after midnight is always checked and
/// recorded against the same occurrence — they can never disagree.
DateTime? currentDoseOccurrence({
  required int hour,
  required int minute,
  required int reminderWindowMinutes,
  required DateTime now,
}) {
  final scheduledToday = DateTime(now.year, now.month, now.day, hour, minute);
  if (!now.isBefore(scheduledToday)) return scheduledToday;

  final scheduledYesterday = scheduledToday.subtract(const Duration(days: 1));
  final yesterdayWindowEnd = scheduledYesterday.add(
    Duration(minutes: reminderWindowMinutes),
  );
  return now.isBefore(yesterdayWindowEnd) ? scheduledYesterday : null;
}

/// The single rule for whether a dose counts as "due right now":
///
/// 1. It must currently have an applicable occurrence at all — see
///    [currentDoseOccurrence]. (This is what lets a late-night dose, e.g.
///    11:50 PM, keep showing as due for a while after midnight, instead of
///    resetting the instant the calendar date rolls over.)
/// 2. It must not already be marked taken for that occurrence.
/// 3. It must not currently be within a snooze period.
///
/// All three must hold for the dose to show up as due. This is checked
/// separately for every dose of every medication — taking the morning dose
/// has no effect on whether the evening dose (of the same medication) is
/// due.
bool isMedicationDue({
  required int hour,
  required int minute,
  required int reminderWindowMinutes,
  required DueStatusEntry? status,
  required DateTime now,
}) {
  final scheduledOccurrence = currentDoseOccurrence(
    hour: hour,
    minute: minute,
    reminderWindowMinutes: reminderWindowMinutes,
    now: now,
  );
  if (scheduledOccurrence == null) {
    return false; // Not due yet today, and yesterday's window is over.
  }

  if (status?.takenDate == DueStatusStorage.todayString(scheduledOccurrence)) {
    return false; // This occurrence was already taken.
  }

  final snoozeUntilMillis = status?.snoozeUntilMillis;
  if (snoozeUntilMillis != null) {
    final snoozeUntil = DateTime.fromMillisecondsSinceEpoch(snoozeUntilMillis);
    if (now.isBefore(snoozeUntil)) {
      return false; // Still within the snooze window.
    }
  }

  return true;
}
