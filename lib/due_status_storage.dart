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
    await prefs.setStringList(_storageKey, jsonStrings);
  }

  /// Record that dose [doseIndex] of [medicationId] was taken today. This
  /// clears any snooze on that specific dose, since it's now been dealt
  /// with. Other doses of the same medication are untouched.
  static Future<void> markTakenToday(int medicationId, int doseIndex) async {
    final all = await loadAll();
    all[(medicationId, doseIndex)] = DueStatusEntry(
      medicationId: medicationId,
      doseIndex: doseIndex,
      takenDate: todayString(),
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

/// The single rule for whether a dose counts as "due right now":
///
/// 1. Its scheduled time today must have already arrived.
/// 2. It must not already be marked taken for today.
/// 3. It must not currently be within a snooze period.
///
/// All three must hold for the dose to show up as due. This is checked
/// separately for every dose of every medication — taking the morning dose
/// has no effect on whether the evening dose (of the same medication) is
/// due.
bool isMedicationDue({
  required int hour,
  required int minute,
  required DueStatusEntry? status,
  required DateTime now,
}) {
  final scheduledToday = DateTime(now.year, now.month, now.day, hour, minute);
  if (now.isBefore(scheduledToday)) {
    return false; // Scheduled time hasn't happened yet today.
  }

  if (status?.takenDate == DueStatusStorage.todayString(now)) {
    return false; // Already taken today.
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
