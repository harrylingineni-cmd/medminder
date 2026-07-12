import 'dart:async'; // For Timer, used to re-check "is it due yet?"
import 'dart:convert'; // For turning our data into text so it can be saved
import 'package:app_settings/app_settings.dart'; // Opens the phone's Settings screens
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For local storage
import 'due_status_storage.dart'; // Tracks "taken today" / "snoozed" per medication
import 'notification_service.dart'; // Schedules the medication reminders

import 'package:flutter/material.dart';

import 'medication_state.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? notificationWarning;
  try {
    await NotificationService.instance.init();
    final permissionsGranted = await NotificationService.instance
        .requestPermissions();
    if (!permissionsGranted) {
      notificationWarning =
          'Notification or exact-alarm access is off. Reminders may not appear on time.';
    }
  } catch (_) {
    notificationWarning =
        'Reminders are unavailable right now. You can still review the medication schedule.';
  }

  runApp(MedTrackerApp(initialNotificationWarning: notificationWarning));
}

class MedTrackerApp extends StatelessWidget {
  const MedTrackerApp({
    super.key,
    this.initialNotificationWarning,
    this.nowProvider = DateTime.now,
  });

  /// Turn this medication into a Map so it can be saved as JSON text.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'time': time,
    'hour': hour,
    'minute': minute,
  };

  /// Recreate a Medication from a Map that was loaded out of storage.
  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    // Older saved medications (from before reminders were added) won't
    // have an id/hour/minute yet, so fall back to sensible defaults
    // rather than crashing.
    id:
        json['id'] as int? ??
        DateTime.now().millisecondsSinceEpoch.remainder(1000000000),
    name: json['name'] as String,
    dosage: json['dosage'] as String,
    time: json['time'] as String,
    hour: json['hour'] as int? ?? 8,
    minute: json['minute'] as int? ?? 0,
  );
}

// ─── Storage Helper ────────────────────────────────────────────────────────

/// All the code for reading and writing medications to the device lives here.
///
/// SharedPreferences stores simple key→value pairs on the device.
/// Because it can only store strings, we convert each Medication to a JSON
/// string before saving, and parse it back when loading.
class MedicationStorage {
  // The key used to look up our list inside SharedPreferences.
  static const _storageKey = 'medications';

  /// Load all saved medications from the device.
  /// Returns an empty list if nothing has been saved yet.
  static Future<List<Medication>> load() async {
    final prefs = await SharedPreferences.getInstance();
    // getStringList returns null if the key doesn't exist yet, so we use ?? []
    final jsonStrings = prefs.getStringList(_storageKey) ?? [];
    return jsonStrings
        .map((s) => Medication.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  /// Save the full list of medications to the device, replacing the old list.
  static Future<void> save(List<Medication> medications) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStrings = medications.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonStrings);
  }
}

// ─── App Root ──────────────────────────────────────────────────────────────

/// The root of the app. Sets up the overall look and feel.
class MedTrackerApp extends StatelessWidget {
  const MedTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedMinder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A4B8C)),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 20),
          bodyMedium: TextStyle(fontSize: 18),
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          labelLarge: TextStyle(fontSize: 18),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          border: OutlineInputBorder(),
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(
        notificationWarning: initialNotificationWarning,
        nowProvider: nowProvider,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.notificationWarning,
    this.nowProvider = DateTime.now,
  });

  final String? notificationWarning;
  final DateTime Function() nowProvider;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// `WidgetsBindingObserver` lets us find out when the user comes back to the
// app (e.g. after visiting Settings), via `didChangeAppLifecycleState`.
class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Medication> _medications = [];
  List<MedicationAcknowledgement> _acknowledgements = [];
  List<MedicationSnooze> _snoozes = [];
  MedicationOccurrence? _occurrence;
  MedicationAcknowledgement? _lastAcknowledgement;
  Medication? _lastAcknowledgedMedication;
  Timer? _refreshTimer;
  bool _isLoading = true;
  bool _actionInProgress = false;
  String? _storageError;
  String? _notificationWarning;
  String? _actionError;

  // ── "Due" tracking ──
  // For every medication, `_dueStatus` holds whether/when it was taken or
  // snoozed today. `_dueMedications` is the subset of `_medications` that
  // are currently due, recomputed whenever anything relevant changes.
  Map<int, DueStatusEntry> _dueStatus = {};
  List<Medication> _dueMedications = [];

  // ── Permission banner ──
  // Both default to `true` (assume granted) until we've actually checked,
  // so the warning banner doesn't flash on screen for a split second.
  bool _notificationsEnabled = true;
  bool _exactAlarmsEnabled = true;

  // Re-checks which medications are due every 30 seconds, so a medication
  // becomes due (and its card appears) without the user needing to
  // manually refresh or reopen the app right at the scheduled time.
  Timer? _dueCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load saved medications as soon as the screen appears.
    _loadMedications();
    _checkPermissions();
    _dueCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _recomputeDue(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dueCheckTimer?.cancel();
    super.dispose();
  }

  /// Called when the app is backgrounded, resumed, etc. We care about
  /// "resumed" — the user switching back to the app, for example after
  /// tapping our permission banner and changing a setting.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
      _recomputeDue();
    }
  }

  Future<void> _loadMedications() async {
    final loaded = await MedicationStorage.load();
    final dueStatus = await DueStatusStorage.loadAll();
    setState(() {
      _medications = loaded;
      _dueStatus = dueStatus;
      _isLoading = false;
    });
    _recomputeDue();
  }

  /// Ask Android whether notifications / exact alarms are currently allowed,
  /// and show/hide the warning banner accordingly.
  Future<void> _checkPermissions() async {
    final notificationsEnabled = await NotificationService.instance
        .areNotificationsEnabled();
    final exactAlarmsEnabled = await NotificationService.instance
        .canScheduleExactAlarms();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = notificationsEnabled;
      _exactAlarmsEnabled = exactAlarmsEnabled;
    });
  }

  /// Re-checks, for every medication, whether it counts as "due" right now
  /// (see `isMedicationDue` in due_status_storage.dart for the exact rule),
  /// and updates `_dueMedications` so the due cards on screen stay current.
  void _recomputeDue() {
    if (!mounted) return;
    final now = DateTime.now();
    final due = _medications
        .where(
          (m) => isMedicationDue(
            hour: m.hour,
            minute: m.minute,
            status: _dueStatus[m.id],
            now: now,
          ),
        )
        .toList();
    setState(() => _dueMedications = due);
  }

  /// "I've taken it" — marks the dose as done for today, cancels any
  /// pending snooze reminder for it, and removes its due card.
  Future<void> _markTaken(Medication medication) async {
    await DueStatusStorage.markTakenToday(medication.id);
    await NotificationService.instance.cancel(
      NotificationService.snoozeNotificationId(medication.id),
    );
    _dueStatus = await DueStatusStorage.loadAll();
    _recomputeDue();
  }

  /// "Remind me in 10 minutes" — hides the due card for now, and schedules
  /// a one-time reminder notification 10 minutes from now.
  Future<void> _snooze(Medication medication) async {
    final snoozeUntil = DateTime.now().add(const Duration(minutes: 10));
    await DueStatusStorage.snooze(medication.id, snoozeUntil);
    await NotificationService.instance.scheduleOneOffReminder(
      id: NotificationService.snoozeNotificationId(medication.id),
      medicationName: medication.name,
      dosage: medication.dosage,
      fireAt: snoozeUntil,
    );
    _dueStatus = await DueStatusStorage.loadAll();
    _recomputeDue();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadState();
  }

  Future<void> _loadState() async {
    _refreshTimer?.cancel();
    final now = widget.nowProvider();
    try {
      final loadResult = await MedicationStorage.loadWithMetadata();
      final medications = loadResult.medications;
      if (loadResult.migrated) {
        await NotificationService.instance.reconcileMedicationReminders(
          medications,
        );
      }
      final acknowledgements =
          await MedicationStateStorage.loadAcknowledgements(now);
      final reminderRetries = await ReminderRetryStorage.load();
      var snoozes = await MedicationStateStorage.loadSnoozes(now);

      final expired = snoozes
          .where(
            (value) =>
                value.scheduledDate != localDateKey(now) ||
                !value.snoozeUntil.isAfter(now),
          )
          .toList();
      for (final snooze in expired) {
        await MedicationStateStorage.clearSnooze(
          snooze.medicationId,
          snooze.scheduledDate,
        );
        if (snooze.scheduledDate != localDateKey(now)) {
          final cancelled = await NotificationService.instance.cancelSnooze(
            snooze.medicationId,
          );
          if (!cancelled) {
            _notificationWarning =
                'An old reminder may still appear. The app will retry cancelling it.';
          }
        }
      }
      if (expired.isNotEmpty) {
        snoozes = await MedicationStateStorage.loadSnoozes(now);
      }

      if (!mounted) return;
      setState(() {
        _medications = medications;
        _acknowledgements = acknowledgements;
        _snoozes = snoozes;
        _storageError = null;
        _isLoading = false;
        if (reminderRetries.any(
          (id) => medications.any((medication) => medication.id == id),
        )) {
          _notificationWarning =
              'One or more medication reminders need attention. Open caregiver setup to retry.';
        }
      });
      _recompute(now);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _storageError =
            'Medication data is unavailable. The app will not treat this as an empty schedule.';
      });
    }
  }

  void _recompute(DateTime now) {
    final occurrence = MedicationSchedule.nextOccurrence(
      medications: _medications,
      acknowledgements: _acknowledgements,
      snoozes: _snoozes,
      now: now,
    );
    if (mounted) setState(() => _occurrence = occurrence);
    _armRefreshTimer(now, occurrence);
  }

  void _armRefreshTimer(DateTime now, MedicationOccurrence? occurrence) {
    _refreshTimer?.cancel();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final boundaries = <DateTime>[midnight];
    if (occurrence != null && occurrence.scheduledAt.isAfter(now)) {
      boundaries.add(occurrence.scheduledAt);
    }
    final snoozeUntil = occurrence?.snoozedUntil;
    if (snoozeUntil != null && snoozeUntil.isAfter(now)) {
      boundaries.add(snoozeUntil);
    }
    boundaries.sort();
    final delay = boundaries.first.difference(now) + const Duration(seconds: 1);
    _refreshTimer = Timer(delay, _loadState);
  }

  Future<void> _openCaregiverSetup() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const CaregiverScheduleScreen()),
    );
    if (mounted) await _loadState();
  }

  Future<void> _retryNotificationPermissions() async {
    try {
      await NotificationService.instance.init();
      final granted = await NotificationService.instance.requestPermissions();
      if (!mounted) return;
      setState(
        () => _notificationWarning = granted
            ? null
            : 'Notification or exact-alarm access is still off. Reminders may not appear on time.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _notificationWarning =
            'Reminder permissions could not be checked. Please try again.',
      );
      _recomputeDue();
    }
  }

  /// Remove the medication at [index] from the list, save, and stop its
  /// reminder notifications (both the daily one and any pending snooze).
  Future<void> _deleteMedication(int index) async {
    final removed = _medications[index];
    final updated = [..._medications]..removeAt(index);
    setState(() => _medications = updated);
    await MedicationStorage.save(updated);
    await NotificationService.instance.cancel(removed.id);
    await NotificationService.instance.cancel(
      NotificationService.snoozeNotificationId(removed.id),
    );
    _recomputeDue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A4B8C), // deep blue = high contrast
        foregroundColor: Colors.white,
        title: const Text(
          'My Medications',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),
      // Show a spinner while loading. Once loaded, stack (top to bottom):
      // the permission warning banner (if needed), any due-medication
      // cards, then the full medication list below.
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (!_notificationsEnabled || !_exactAlarmsEnabled)
                  _buildPermissionBanner(),
                if (_dueMedications.isNotEmpty) _buildDueSection(),
                Expanded(
                  child: _medications.isEmpty
                      ? _buildEmptyState()
                      : _buildMedicationList(),
                ),
              ],
            ),
      // A large, labelled button so the action is obvious.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddForm,
        backgroundColor: const Color(0xFF1A4B8C),
        foregroundColor: Colors.white,
        title: const Text(
          'My Medication',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _openCaregiverSetup,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Caregiver setup'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_notificationWarning != null)
              _MessageBanner(
                message: _notificationWarning!,
                icon: Icons.notifications_off_outlined,
                actionLabel: 'Retry',
                onAction: _retryNotificationPermissions,
                onDismiss: () => setState(() => _notificationWarning = null),
              ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  /// Warning banner shown when Android has notification permission or
  /// exact-alarm permission turned off, since reminders may then be late
  /// or may not show up at all. Tapping a button opens the exact Settings
  /// screen the user needs, using the `app_settings` package.
  Widget _buildPermissionBanner() {
    return Container(
      width: double.infinity,
      color: Colors.red.shade700,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Reminders may not appear on time.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!_notificationsEnabled)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _permissionButton(
                'Turn On Notifications',
                () => AppSettings.openAppSettings(
                  type: AppSettingsType.notification,
                ),
              ),
            ),
          if (!_exactAlarmsEnabled)
            _permissionButton(
              'Turn On Exact Alarms',
              () => AppSettings.openAppSettings(type: AppSettingsType.alarm),
            ),
        ],
      ),
    );
  }

  /// One large white button used inside the permission banner.
  Widget _permissionButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.red.shade700,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// The stack of "due now" cards, one per medication that is currently due.
  Widget _buildDueSection() {
    return Column(
      children: _dueMedications
          .map(
            (medication) => _DueMedicationCard(
              medication: medication,
              onTaken: () => _markTaken(medication),
              onSnooze: () => _snooze(medication),
            ),
          )
          .toList(),
    );
  }

  /// Friendly message shown when the list is empty.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 90,
              color: Colors.blue.shade200,
            ),
            const SizedBox(height: 28),
            const Text(
              'No medications set up',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            const Text(
              'Tap "Add Medication" below\nto add your first one.',
              style: TextStyle(
                fontSize: 20,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: onOpenCaregiver,
              child: const Text('Open caregiver setup'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorageUnavailableState extends StatelessWidget {
  const _StorageUnavailableState({
    required this.message,
    required this.onRetry,
    required this.onOpenCaregiver,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onOpenCaregiver;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 72, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
            TextButton(
              onPressed: onOpenCaregiver,
              child: const Text('Open caregiver setup'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.message,
    required this.icon,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF4D6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF765000)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16, height: 1.3),
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            IconButton(
              onPressed: onDismiss,
              tooltip: 'Dismiss message',
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class CaregiverScheduleScreen extends StatefulWidget {
  const CaregiverScheduleScreen({super.key});

  @override
  State<CaregiverScheduleScreen> createState() =>
      _CaregiverScheduleScreenState();
}

class _CaregiverScheduleScreenState extends State<CaregiverScheduleScreen> {
  List<Medication> _medications = [];
  bool _isLoading = true;
  String? _error;
  String? _warning;
  Medication? _medicationNeedingReminderRetry;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final loadResult = await MedicationStorage.loadWithMetadata();
      final medications = loadResult.medications;
      if (loadResult.migrated) {
        await NotificationService.instance.reconcileMedicationReminders(
          medications,
        );
      }
      final reminderRetries = await ReminderRetryStorage.load();
      Medication? retryMedication;
      for (final medication in medications) {
        if (reminderRetries.contains(medication.id)) {
          retryMedication = medication;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _medications = medications;
        _isLoading = false;
        _error = null;
        if (retryMedication != null) {
          _warning =
              'The reminder for ${retryMedication.name} needs to be scheduled.';
          _medicationNeedingReminderRetry = retryMedication;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error =
            'Medication data is unavailable. Retry before changing the schedule.';
      });
    }
  }

  Future<void> _openAddForm() async {
    final newMedication = await Navigator.push<Medication>(
      context,
      MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
    );
    if (newMedication == null || !mounted) return;

    final updated = [..._medications, newMedication];
    try {
      await MedicationStorage.save(updated);
      if (mounted) setState(() => _medications = updated);
      try {
        await NotificationService.instance.scheduleDailyMedicationReminder(
          id: newMedication.id,
          medicationName: newMedication.name,
          dosage: newMedication.dosage,
          hour: newMedication.hour,
          minute: newMedication.minute,
        );
        await ReminderRetryStorage.remove(newMedication.id);
      } catch (_) {
        try {
          await ReminderRetryStorage.add(newMedication.id);
        } catch (_) {
          // The current screen warning remains the fallback for this session.
        }
        if (mounted) {
          setState(() {
            _warning =
                'Medication saved, but its reminder could not be scheduled.';
            _medicationNeedingReminderRetry = newMedication;
          });
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _warning =
            'The medication could not be saved. No reminder was added.',
      );
    }
  }

  Future<void> _retryReminder() async {
    final medication = _medicationNeedingReminderRetry;
    if (medication == null) return;
    try {
      await NotificationService.instance.scheduleDailyMedicationReminder(
        id: medication.id,
        medicationName: medication.name,
        dosage: medication.dosage,
        hour: medication.hour,
        minute: medication.minute,
      );
      await ReminderRetryStorage.remove(medication.id);
      if (!mounted) return;
      setState(() {
        _warning = null;
        _medicationNeedingReminderRetry = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _warning =
            'The reminder still could not be scheduled. Check Android permissions and try again.',
      );
    }
  }

  Future<void> _deleteMedication(int index) async {
    final medication = _medications[index];
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete medication?'),
            content: Text(
              'Delete ${medication.name} and cancel its reminders?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep medication'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    final updated = [..._medications]..removeAt(index);
    try {
      await MedicationStorage.save(updated);
      if (mounted) setState(() => _medications = updated);
      try {
        await ReminderRetryStorage.remove(medication.id);
      } catch (_) {
        // Deletion remains authoritative even if retry metadata cleanup fails.
      }
      try {
        await MedicationStateStorage.clearAllSnoozesForMedication(
          medication.id,
        );
      } catch (_) {
        if (mounted) {
          setState(
            () => _warning =
                'The medication was deleted, but old snooze data could not be cleared.',
          );
        }
      }
      final cancelled = await NotificationService.instance
          .cancelAllForMedication(medication.id);
      if (!cancelled && mounted) {
        setState(
          () => _warning =
              'The medication was deleted, but an old reminder may still appear. Cancellation will be retried.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(
        () =>
            _warning = 'The medication could not be deleted. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A4B8C),
        foregroundColor: Colors.white,
        title: const Text(
          'Medication Schedule',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          if (_warning != null)
            _MessageBanner(
              message: _warning!,
              icon: Icons.warning_amber,
              actionLabel: _medicationNeedingReminderRetry == null
                  ? null
                  : 'Retry',
              onAction: _medicationNeedingReminderRetry == null
                  ? null
                  : _retryReminder,
              onDismiss: () => setState(() {
                _warning = null;
                _medicationNeedingReminderRetry = null;
              }),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _error == null && !_isLoading
          ? FloatingActionButton.extended(
              onPressed: _openAddForm,
              backgroundColor: const Color(0xFF1A4B8C),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add, size: 30),
              label: const Text(
                'Add Medication',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        16,
        20,
        16,
        100,
      ), // bottom padding clears the FAB
      itemCount: _medications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              'Set reminders using the medication label or instructions from a healthcare professional.',
              style: TextStyle(fontSize: 18, height: 1.4),
            ),
          );
        }
        final medicationIndex = index - 1;
        return _MedicationCard(
          medication: _medications[medicationIndex],
          onDelete: () => _deleteMedication(medicationIndex),
        );
      },
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.medication, required this.onDelete});

  final Medication medication;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3EBF8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.medication,
                color: Color(0xFF1A4B8C),
                size: 36,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(medication.dosage, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 6),
                  Text(
                    medication.dosage,
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        medication.time,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 30,
              ),
              tooltip: 'Delete',
              padding: const EdgeInsets.all(12),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Due Medication Card ───────────────────────────────────────────────────

/// The prominent card shown at the top of the home screen when a medication
/// is due: its scheduled time has arrived and it hasn't been taken (or
/// snoozed) yet today. Uses a bold amber/orange colour so it stands out
/// clearly from the ordinary medication list below.
class _DueMedicationCard extends StatelessWidget {
  const _DueMedicationCard({
    required this.medication,
    required this.onTaken,
    required this.onSnooze,
  });

  final Medication medication;
  final VoidCallback onTaken;
  final VoidCallback onSnooze;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF4E5), // soft amber — stands out, stays readable
      elevation: 5,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFCC7A00), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading
            Row(
              children: [
                const Icon(
                  Icons.notifications_active,
                  color: Color(0xFFCC7A00),
                  size: 32,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Medication Due',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8A4B00),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name and dosage
            Text(
              medication.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              medication.dosage,
              style: const TextStyle(fontSize: 20, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            // Safety reminder
            const Row(
              children: [
                Icon(Icons.info_outline, size: 22, color: Colors.black54),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Check the medication label before taking it',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // "I've taken it" — big, green, primary action.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTaken,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.check_circle, size: 28),
                label: const Text(
                  "I've taken it",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // "Remind me in 10 minutes" — big, secondary action.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSnooze,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A4B8C),
                  side: const BorderSide(color: Color(0xFF1A4B8C), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.snooze, size: 26),
                label: const Text(
                  'Remind Me in 10 Minutes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Medication Screen ─────────────────────────────────────────────────

/// A form screen for entering a new medication.
class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  TimeOfDay? _selectedTime;
  bool _isPreparing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      helpText: 'Select time to take medication',
      builder: (context, child) {
        // Make the time picker's own text a bit larger too.
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.2)),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) setState(() => _selectedTime = picked);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a time.',
            style: TextStyle(fontSize: 18),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPreparing = true);
    try {
      final id = await MedicationStorage.createId();
      if (!mounted) return;
      Navigator.pop(
        context,
        Medication(
          id: id,
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim(),
          time: _formatTime(_selectedTime!),
          hour: _selectedTime!.hour,
          minute: _selectedTime!.minute,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPreparing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The medication could not be prepared. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A4B8C),
        foregroundColor: Colors.white,
        title: const Text(
          'Add Medication',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Medication Name ──────────────────────────────────────────
              const Text(
                'Medication Name',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 20),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g. Lisinopril',
                  prefixIcon: Icon(Icons.medication, size: 28),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter the medication name.'
                    : null,
              ),
              const SizedBox(height: 28),
              const Text(
                'Dosage',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dosageController,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  hintText: 'e.g. 10 mg',
                  prefixIcon: Icon(Icons.scale, size: 28),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter the dosage.'
                    : null,
              ),
              const SizedBox(height: 28),
              const Text(
                'Reminder Time',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // We use a GestureDetector + Container to make a tappable box
              // that looks like a form field but opens the time picker.
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black54),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 28,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime == null
                            ? 'Tap to select a time'
                            : _formatTime(_selectedTime!),
                        style: TextStyle(
                          fontSize: 20,
                          color: _selectedTime == null
                              ? Colors.black45
                              : Colors.black87,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedTime == null
                              ? 'Tap to select a time'
                              : _formatTime(_selectedTime!),
                          style: TextStyle(
                            fontSize: 20,
                            color: _selectedTime == null
                                ? Colors.black54
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 44),
              ElevatedButton.icon(
                onPressed: _isPreparing ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A4B8C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isPreparing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : const Icon(Icons.save, size: 28),
                label: const Text(
                  'Save Medication',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatClock(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${value.hour < 12 ? 'AM' : 'PM'}';
}
