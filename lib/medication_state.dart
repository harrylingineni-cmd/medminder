import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const int snoozeNotificationIdOffset = 1000000000;
const int maxMedicationId = 999999999;

String localDateKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

DateTime minutePrecision(DateTime value) =>
    DateTime(value.year, value.month, value.day, value.hour, value.minute);

class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.time,
    required this.hour,
    required this.minute,
  });

  final int id;
  final String name;
  final String dosage;
  final String time;
  final int hour;
  final int minute;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'time': time,
    'hour': hour,
    'minute': minute,
  };
}

class MedicationLoadResult {
  const MedicationLoadResult({
    required this.medications,
    required this.migrated,
  });

  final List<Medication> medications;
  final bool migrated;
}

class PendingNotificationCancellationStorage {
  static const _storageKey = 'pending_notification_cancellations';
  static final Set<int> _sessionFallback = {};

  static Future<Set<int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs
        .getStringList(_storageKey)
        ?.map(int.tryParse)
        .whereType<int>()
        .toSet();
    return {...?stored, ..._sessionFallback};
  }

  static Future<bool> enqueue(int id) async {
    _sessionFallback.add(id);
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = (await load())..add(id);
      final saved = await prefs.setStringList(
        _storageKey,
        pending.map((value) => value.toString()).toList()..sort(),
      );
      if (saved) _sessionFallback.remove(id);
      return saved;
    } catch (_) {
      return false;
    }
  }

  static Future<void> removeSuccessful(Iterable<int> ids) async {
    final completed = ids.toSet();
    if (completed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final pending = (await load())..removeAll(completed);
    final saved = await prefs.setStringList(
      _storageKey,
      pending.map((value) => value.toString()).toList()..sort(),
    );
    if (saved) _sessionFallback.removeAll(completed);
  }
}

class ReminderRetryStorage {
  static const _storageKey = 'medications_needing_reminder_retry';

  static Future<Set<int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
            .getStringList(_storageKey)
            ?.map(int.tryParse)
            .whereType<int>()
            .toSet() ??
        {};
  }

  static Future<void> add(int medicationId) async {
    final prefs = await SharedPreferences.getInstance();
    final values = (await load())..add(medicationId);
    final saved = await prefs.setStringList(
      _storageKey,
      values.map((value) => value.toString()).toList()..sort(),
    );
    if (!saved) throw StateError('Reminder retry could not be saved.');
  }

  static Future<void> remove(int medicationId) async {
    final prefs = await SharedPreferences.getInstance();
    final values = (await load())..remove(medicationId);
    final saved = await prefs.setStringList(
      _storageKey,
      values.map((value) => value.toString()).toList()..sort(),
    );
    if (!saved) throw StateError('Reminder retry could not be cleared.');
  }
}

class MedicationStorage {
  static const _storageKey = 'medications';

  static Future<List<Medication>> load() async =>
      (await loadWithMetadata()).medications;

  static Future<MedicationLoadResult> loadWithMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStrings = prefs.getStringList(_storageKey) ?? [];
    final reservedIds = await PendingNotificationCancellationStorage.load();
    final usedIds = <int>{};
    var migrated = false;

    final medications = <Medication>[];
    for (final encoded in jsonStrings) {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Medication data is not an object.');
      }

      final rawId = decoded['id'];
      var id = rawId is int ? rawId : null;
      final invalidId =
          id == null ||
          id < 0 ||
          id > maxMedicationId ||
          usedIds.contains(id) ||
          reservedIds.contains(id) ||
          reservedIds.contains(id + snoozeNotificationIdOffset);
      if (invalidId) {
        id = _nextAvailableId(usedIds, reservedIds);
        migrated = true;
      }

      final name = decoded['name'];
      final dosage = decoded['dosage'];
      if (name is! String || dosage is! String) {
        throw const FormatException(
          'Medication name or dosage is unavailable.',
        );
      }

      final rawHour = decoded['hour'];
      final rawMinute = decoded['minute'];
      final displayTime = decoded['time'];
      final parsedDisplayTime = displayTime is String
          ? _parseStoredTime(displayTime)
          : null;
      final numericTimeIsValid =
          rawHour is int &&
          rawHour >= 0 &&
          rawHour <= 23 &&
          rawMinute is int &&
          rawMinute >= 0 &&
          rawMinute <= 59;
      final hour = numericTimeIsValid ? rawHour : parsedDisplayTime?.hour ?? 8;
      final minute = numericTimeIsValid
          ? rawMinute
          : parsedDisplayTime?.minute ?? 0;
      final displayMatchesSchedule =
          parsedDisplayTime?.hour == hour &&
          parsedDisplayTime?.minute == minute;
      if (!numericTimeIsValid || !displayMatchesSchedule) migrated = true;

      final medication = Medication(
        id: id,
        name: name,
        dosage: dosage,
        time: displayTime is String && displayMatchesSchedule
            ? displayTime
            : _formatStoredTime(hour, minute),
        hour: hour,
        minute: minute,
      );
      usedIds.add(id);
      medications.add(medication);
    }

    if (migrated) await save(medications);
    return MedicationLoadResult(medications: medications, migrated: migrated);
  }

  static Future<void> save(List<Medication> medications) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStrings = medications
        .map((medication) => jsonEncode(medication.toJson()))
        .toList();
    final saved = await prefs.setStringList(_storageKey, jsonStrings);
    if (!saved) throw StateError('Medication data could not be saved.');
  }

  static Future<int> createId() async {
    final medications = await load();
    final pending = await PendingNotificationCancellationStorage.load();
    return _nextAvailableId(
      medications.map((medication) => medication.id).toSet(),
      pending,
    );
  }

  static int _nextAvailableId(Set<int> used, Set<int> reserved) {
    var candidate = DateTime.now().microsecondsSinceEpoch.remainder(
      maxMedicationId + 1,
    );
    while (used.contains(candidate) ||
        reserved.contains(candidate) ||
        reserved.contains(candidate + snoozeNotificationIdOffset)) {
      candidate = (candidate + 1) % (maxMedicationId + 1);
    }
    return candidate;
  }

  static String _formatStoredTime(int hour, int minute) {
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute ${hour < 12 ? 'AM' : 'PM'}';
  }

  static ({int hour, int minute})? _parseStoredTime(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return null;
    final displayHour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (displayHour == null ||
        displayHour < 1 ||
        displayHour > 12 ||
        minute == null ||
        minute > 59) {
      return null;
    }
    final isPm = match.group(3)!.toUpperCase() == 'PM';
    final hour = displayHour % 12 + (isPm ? 12 : 0);
    return (hour: hour, minute: minute);
  }
}

class MedicationAcknowledgement {
  const MedicationAcknowledgement({
    required this.medicationId,
    required this.scheduledDate,
    required this.acknowledgedAt,
  });

  final int medicationId;
  final String scheduledDate;
  final DateTime acknowledgedAt;

  Map<String, dynamic> toJson() => {
    'medicationId': medicationId,
    'scheduledDate': scheduledDate,
    'acknowledgedAt': acknowledgedAt.toIso8601String(),
  };

  static MedicationAcknowledgement? tryParse(String encoded) {
    try {
      final json = jsonDecode(encoded);
      if (json is! Map<String, dynamic>) return null;
      final medicationId = json['medicationId'];
      final scheduledDate = json['scheduledDate'];
      final acknowledgedAt = DateTime.tryParse('${json['acknowledgedAt']}');
      if (medicationId is! int ||
          scheduledDate is! String ||
          acknowledgedAt == null) {
        return null;
      }
      return MedicationAcknowledgement(
        medicationId: medicationId,
        scheduledDate: scheduledDate,
        acknowledgedAt: acknowledgedAt,
      );
    } catch (_) {
      return null;
    }
  }
}

class MedicationSnooze {
  const MedicationSnooze({
    required this.medicationId,
    required this.scheduledDate,
    required this.snoozeUntil,
  });

  final int medicationId;
  final String scheduledDate;
  final DateTime snoozeUntil;

  int get notificationId => medicationId + snoozeNotificationIdOffset;

  Map<String, dynamic> toJson() => {
    'medicationId': medicationId,
    'scheduledDate': scheduledDate,
    'snoozeUntil': snoozeUntil.toIso8601String(),
  };

  static MedicationSnooze? tryParse(String encoded) {
    try {
      final json = jsonDecode(encoded);
      if (json is! Map<String, dynamic>) return null;
      final medicationId = json['medicationId'];
      final scheduledDate = json['scheduledDate'];
      final snoozeUntil = DateTime.tryParse('${json['snoozeUntil']}');
      if (medicationId is! int ||
          scheduledDate is! String ||
          snoozeUntil == null) {
        return null;
      }
      return MedicationSnooze(
        medicationId: medicationId,
        scheduledDate: scheduledDate,
        snoozeUntil: snoozeUntil,
      );
    } catch (_) {
      return null;
    }
  }
}

class MedicationStateStorage {
  static const _acknowledgementsKey = 'medication_acknowledgements';
  static const _snoozesKey = 'medication_snoozes';

  static Future<List<MedicationAcknowledgement>> loadAcknowledgements(
    DateTime now,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final rawValues = prefs.getStringList(_acknowledgementsKey) ?? [];
    final values = rawValues
        .map(MedicationAcknowledgement.tryParse)
        .whereType<MedicationAcknowledgement>()
        .toList();
    final retained = values
        .where((value) => _withinRetention(value.scheduledDate, now))
        .toList();
    if (retained.length != rawValues.length) {
      await _saveAcknowledgements(retained);
    }
    return retained;
  }

  static Future<void> acknowledge(MedicationAcknowledgement value) async {
    final values = (await loadAcknowledgements(value.acknowledgedAt))
      ..removeWhere(
        (existing) =>
            existing.medicationId == value.medicationId &&
            existing.scheduledDate == value.scheduledDate,
      )
      ..add(value);
    await _saveAcknowledgements(values);
  }

  static Future<List<MedicationSnooze>> loadSnoozes(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    final rawValues = prefs.getStringList(_snoozesKey) ?? [];
    final values = rawValues
        .map(MedicationSnooze.tryParse)
        .whereType<MedicationSnooze>()
        .toList();
    final retained = values
        .where((value) => _withinRetention(value.scheduledDate, now))
        .toList();
    if (retained.length != rawValues.length) await _saveSnoozes(retained);
    return retained;
  }

  static Future<void> saveSnooze(MedicationSnooze value) async {
    final values = (await loadSnoozes(DateTime.now()))
      ..removeWhere(
        (existing) =>
            existing.medicationId == value.medicationId &&
            existing.scheduledDate == value.scheduledDate,
      )
      ..add(value);
    await _saveSnoozes(values);
  }

  static Future<void> clearSnooze(
    int medicationId,
    String scheduledDate,
  ) async {
    final values = (await loadSnoozes(DateTime.now()))
      ..removeWhere(
        (existing) =>
            existing.medicationId == medicationId &&
            existing.scheduledDate == scheduledDate,
      );
    await _saveSnoozes(values);
  }

  static Future<void> clearAllSnoozesForMedication(int medicationId) async {
    final values = (await loadSnoozes(DateTime.now()))
      ..removeWhere((existing) => existing.medicationId == medicationId);
    await _saveSnoozes(values);
  }

  static Future<void> _saveAcknowledgements(
    List<MedicationAcknowledgement> values,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setStringList(
      _acknowledgementsKey,
      values.map((value) => jsonEncode(value.toJson())).toList(),
    );
    if (!saved) throw StateError('Acknowledgement could not be saved.');
  }

  static Future<void> _saveSnoozes(List<MedicationSnooze> values) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setStringList(
      _snoozesKey,
      values.map((value) => jsonEncode(value.toJson())).toList(),
    );
    if (!saved) throw StateError('Snooze could not be saved.');
  }

  static bool _withinRetention(String dateKey, DateTime now) {
    final date = DateTime.tryParse(dateKey);
    if (date == null) return false;
    final today = DateTime(now.year, now.month, now.day);
    return !date.isBefore(today.subtract(const Duration(days: 7)));
  }
}

class MedicationOccurrence {
  const MedicationOccurrence({
    required this.medication,
    required this.scheduledAt,
    this.snoozedUntil,
  });

  final Medication medication;
  final DateTime scheduledAt;
  final DateTime? snoozedUntil;

  String get scheduledDate => localDateKey(scheduledAt);

  bool isDue(DateTime now) =>
      minutePrecision(scheduledAt) == minutePrecision(now);

  bool isOverdue(DateTime now) =>
      minutePrecision(scheduledAt).isBefore(minutePrecision(now));

  bool isActionable(DateTime now) =>
      scheduledDate == localDateKey(now) && (isDue(now) || isOverdue(now));
}

class MedicationSchedule {
  static MedicationOccurrence? nextOccurrence({
    required List<Medication> medications,
    required List<MedicationAcknowledgement> acknowledgements,
    required List<MedicationSnooze> snoozes,
    required DateTime now,
  }) {
    if (medications.isEmpty) return null;
    final todayKey = localDateKey(now);
    final acknowledged = acknowledgements
        .map((value) => '${value.medicationId}:${value.scheduledDate}')
        .toSet();
    final snoozeByOccurrence = {
      for (final value in snoozes)
        '${value.medicationId}:${value.scheduledDate}': value,
    };

    final today = _occurrencesForDate(medications, now)
        .where(
          (value) => !acknowledged.contains('${value.medication.id}:$todayKey'),
        )
        .map((value) {
          final snooze = snoozeByOccurrence['${value.medication.id}:$todayKey'];
          return MedicationOccurrence(
            medication: value.medication,
            scheduledAt: value.scheduledAt,
            snoozedUntil: snooze != null && snooze.snoozeUntil.isAfter(now)
                ? snooze.snoozeUntil
                : null,
          );
        })
        .toList();

    final activeSnoozes =
        today.where((value) => value.snoozedUntil != null).toList()
          ..sort((a, b) => a.snoozedUntil!.compareTo(b.snoozedUntil!));
    final notSnoozed = today
        .where((value) => value.snoozedUntil == null)
        .toList();
    final due = notSnoozed.where((value) => value.isActionable(now)).toList();
    if (due.isNotEmpty) return due.first;

    final upcoming = <MedicationOccurrence>[...notSnoozed, ...activeSnoozes]
      ..sort((a, b) {
        final aTime = a.snoozedUntil ?? a.scheduledAt;
        final bTime = b.snoozedUntil ?? b.scheduledAt;
        return aTime.compareTo(bTime);
      });
    if (upcoming.isNotEmpty) return upcoming.first;

    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return _occurrencesForDate(medications, tomorrow).first;
  }

  static List<MedicationOccurrence> _occurrencesForDate(
    List<Medication> medications,
    DateTime date,
  ) {
    final indexed =
        medications.indexed.map((entry) {
          final (index, medication) = entry;
          return (
            index: index,
            occurrence: MedicationOccurrence(
              medication: medication,
              scheduledAt: DateTime(
                date.year,
                date.month,
                date.day,
                medication.hour,
                medication.minute,
              ),
            ),
          );
        }).toList()..sort((a, b) {
          final byTime = a.occurrence.scheduledAt.compareTo(
            b.occurrence.scheduledAt,
          );
          if (byTime != 0) return byTime;
          final byIndex = a.index.compareTo(b.index);
          if (byIndex != 0) return byIndex;
          return a.occurrence.medication.id.compareTo(
            b.occurrence.medication.id,
          );
        });
    return indexed.map((value) => value.occurrence).toList();
  }
}
