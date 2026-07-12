import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ─── "Due / Taken / Snoozed" Logic ─────────────────────────────────────────
//
// This file answers one question: "has this medication already been dealt
// with today, or is it still due?"
//
// For each medication we remember two things, keyed by the medication's id:
//   1. takenDate   — the date (like "2026-07-12") the user last tapped
//                     "I've taken it". If this equals *today's* date, the
//                     medication is done for today.
//   2. snoozeUntil — if the user tapped "Remind me in 10 minutes", this is
//                     the exact moment the snooze ends. Until that moment
//                     passes, the medication is temporarily not due.
//
// Neither of these needs to be explicitly "reset" every day — that's the
// trick. `takenDate` only matches *today*, so as soon as the calendar day
// changes, the stored date is "yesterday" and no longer matches, so the
// medication becomes due again automatically. Same idea for `snoozeUntil`:
// once that moment is in the past, it simply stops blocking the reminder.

/// The stored due/taken/snooze state for a single medication.
class DueStatusEntry {
  final int medicationId;
  final String? takenDate; // e.g. "2026-07-12", or null if never taken.
  final int? snoozeUntilMillis; // epoch millis, or null if not snoozed.

  const DueStatusEntry({
    required this.medicationId,
    this.takenDate,
    this.snoozeUntilMillis,
  });

  Map<String, dynamic> toJson() => {
    'medicationId': medicationId,
    'takenDate': takenDate,
    'snoozeUntilMillis': snoozeUntilMillis,
  };

  factory DueStatusEntry.fromJson(Map<String, dynamic> json) => DueStatusEntry(
    medicationId: json['medicationId'] as int,
    takenDate: json['takenDate'] as String?,
    snoozeUntilMillis: json['snoozeUntilMillis'] as int?,
  );
}

/// Reads and writes the due/taken/snooze state for all medications.
///
/// Just like `MedicationStorage`, everything is kept as one JSON string list
/// in SharedPreferences so it survives the app being closed.
class DueStatusStorage {
  static const _storageKey = 'due_status';

  /// Load the status for every medication that has one recorded.
  /// Medications with no entry yet (e.g. brand new ones) are simply absent
  /// from the returned map — treat that as "not taken, not snoozed".
  static Future<Map<int, DueStatusEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStrings = prefs.getStringList(_storageKey) ?? [];
    final entries = jsonStrings.map(
      (s) => DueStatusEntry.fromJson(jsonDecode(s) as Map<String, dynamic>),
    );
    return {for (final e in entries) e.medicationId: e};
  }

  static Future<void> _saveAll(Map<int, DueStatusEntry> all) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStrings = all.values.map((e) => jsonEncode(e.toJson())).toList();
    final saved = await prefs.setStringList(_storageKey, jsonStrings);
    if (!saved) throw StateError('Medication status could not be saved.');
  }

  /// Record that [medicationId] was taken today. This clears any snooze,
  /// since the dose has now been dealt with.
  static Future<void> markTakenToday(int medicationId, {DateTime? when}) async {
    final all = await loadAll();
    all[medicationId] = DueStatusEntry(
      medicationId: medicationId,
      takenDate: todayString(when),
      snoozeUntilMillis: null,
    );
    await _saveAll(all);
  }

  /// Record that [medicationId] was snoozed until [until]. Keeps whatever
  /// takenDate was already stored (there shouldn't be one for today, since
  /// you can't snooze something you've already taken, but this is safer).
  static Future<void> snooze(int medicationId, DateTime until) async {
    final all = await loadAll();
    all[medicationId] = DueStatusEntry(
      medicationId: medicationId,
      takenDate: all[medicationId]?.takenDate,
      snoozeUntilMillis: until.millisecondsSinceEpoch,
    );
    await _saveAll(all);
  }

  /// Remove stale taken/snooze state when a medication is deleted.
  static Future<void> remove(int medicationId) async {
    final all = (await loadAll())..remove(medicationId);
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

/// The single rule for whether a medication counts as "due right now":
///
/// 1. Its scheduled time today must have already arrived.
/// 2. It must not already be marked taken for today.
/// 3. It must not currently be within a snooze period.
///
/// All three must hold for the medication to show up as due.
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
