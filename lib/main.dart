import 'dart:async'; // For Timer, used to re-check "is it due yet?"
import 'dart:convert'; // For turning our data into text so it can be saved
import 'package:app_settings/app_settings.dart'; // Opens the phone's Settings screens
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For local storage
import 'due_status_storage.dart'; // Tracks "taken today" / "snoozed" per medication
import 'notification_service.dart'; // Schedules the medication reminders

// ─── App Entry Point ───────────────────────────────────────────────────────

void main() async {
  // This line is required before using SharedPreferences.
  // It makes sure Flutter is fully set up before we touch storage.
  WidgetsFlutterBinding.ensureInitialized();

  // Set up the notification plugin and ask for the permissions we need
  // (showing notifications, and scheduling them at an exact time) before
  // the user even opens the Add Medication screen.
  try {
    await NotificationService.instance.init();
    await NotificationService.instance.requestPermissions();
  } catch (_) {
    // The schedule remains useful even if Android's notification service is
    // temporarily unavailable. HomeScreen will show a permission warning.
  }

  runApp(const MedTrackerApp());
}

// ─── Data Model ────────────────────────────────────────────────────────────

/// Represents one medication the user wants to track.
class Medication {
  final int id; // Also used as the notification id for this medication.
  final String name;
  final String dosage;
  final String time; // Displayed as "8:30 AM"
  final int hour; // 24-hour hour (0-23), used to schedule the reminder.
  final int minute; // 0-59, used to schedule the reminder.

  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.time,
    required this.hour,
    required this.minute,
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
    final saved = await prefs.setStringList(_storageKey, jsonStrings);
    if (!saved) throw StateError('Medication data could not be saved.');
  }
}

// ─── App Root ──────────────────────────────────────────────────────────────

/// The root of the app. Sets up the overall look and feel.
class MedTrackerApp extends StatelessWidget {
  const MedTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Medications',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A4B8C), // deep blue
        ),
        // ── Larger text throughout the whole app ──
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 20),
          bodyMedium: TextStyle(fontSize: 18),
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          labelLarge: TextStyle(fontSize: 18), // text inside buttons
        ),
        // ── Taller form fields so they are easy to tap ──
        inputDecorationTheme: const InputDecorationTheme(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          border: OutlineInputBorder(),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ─── Home Screen ───────────────────────────────────────────────────────────

/// The main screen showing the list of medications.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// `WidgetsBindingObserver` lets us find out when the user comes back to the
// app (e.g. after visiting Settings), via `didChangeAppLifecycleState`.
class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Medication> _medications = [];
  bool _isLoading = true; // True while we are reading from storage

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
  bool _actionInProgress = false;
  String? _storageError;

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
    try {
      final loaded = await MedicationStorage.load();
      final dueStatus = await DueStatusStorage.loadAll();
      if (!mounted) return;
      setState(() {
        _medications = loaded;
        _dueStatus = dueStatus;
        _storageError = null;
        _isLoading = false;
      });
      _recomputeDue();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _storageError =
            'Saved medication data could not be read. Please retry before changing the schedule.';
        _isLoading = false;
      });
    }
  }

  /// Ask Android whether notifications / exact alarms are currently allowed,
  /// and show/hide the warning banner accordingly.
  Future<void> _checkPermissions() async {
    var notificationsEnabled = false;
    var exactAlarmsEnabled = false;
    try {
      notificationsEnabled = await NotificationService.instance
          .areNotificationsEnabled();
      exactAlarmsEnabled = await NotificationService.instance
          .canScheduleExactAlarms();
    } catch (_) {
      // Keep both false so the user sees that reminders need attention.
    }
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
    if (_actionInProgress) return;
    setState(() => _actionInProgress = true);
    try {
      await DueStatusStorage.markTakenToday(medication.id);
      try {
        await NotificationService.instance.cancel(
          NotificationService.snoozeNotificationId(medication.id),
        );
      } catch (_) {
        _showMessage(
          'Marked as taken, but an old snooze reminder may still appear.',
        );
      }
      _dueStatus = await DueStatusStorage.loadAll();
      _recomputeDue();
    } catch (_) {
      _showMessage('Could not save that the medication was taken. Try again.');
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  /// "Remind me in 10 minutes" — hides the due card for now, and schedules
  /// a one-time reminder notification 10 minutes from now.
  Future<void> _snooze(Medication medication) async {
    if (_actionInProgress) return;
    setState(() => _actionInProgress = true);
    final snoozeUntil = DateTime.now().add(const Duration(minutes: 10));
    try {
      await NotificationService.instance.scheduleOneOffReminder(
        id: NotificationService.snoozeNotificationId(medication.id),
        medicationName: medication.name,
        dosage: medication.dosage,
        fireAt: snoozeUntil,
      );
      try {
        await DueStatusStorage.snooze(medication.id, snoozeUntil);
      } catch (_) {
        await NotificationService.instance.cancel(
          NotificationService.snoozeNotificationId(medication.id),
        );
        rethrow;
      }
      _dueStatus = await DueStatusStorage.loadAll();
      _recomputeDue();
    } catch (_) {
      _showMessage('The snooze reminder could not be scheduled. Try again.');
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  /// Navigate to the Add Medication screen and wait for the result.
  Future<void> _openAddForm() async {
    // Navigator.push opens a new screen. When that screen calls Navigator.pop
    // with a Medication object, it is returned here as `newMed`.
    final newMed = await Navigator.push<Medication>(
      context,
      MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
    );
    // If the user tapped Save (not Cancel), add the new medication.
    if (newMed != null) {
      final updated = [..._medications, newMed];
      try {
        await MedicationStorage.save(updated);
        if (mounted) setState(() => _medications = updated);
        try {
          await NotificationService.instance.scheduleDailyMedicationReminder(
            id: newMed.id,
            medicationName: newMed.name,
            dosage: newMed.dosage,
            hour: newMed.hour,
            minute: newMed.minute,
          );
        } catch (_) {
          _showMessage(
            '${newMed.name} was saved, but its reminder could not be scheduled.',
          );
        }
        _recomputeDue();
      } catch (_) {
        _showMessage('The medication could not be saved. Please try again.');
      }
    }
  }

  /// Remove the medication at [index] from the list, save, and stop its
  /// reminder notifications (both the daily one and any pending snooze).
  Future<void> _deleteMedication(int index) async {
    final removed = _medications[index];
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete medication?'),
            content: Text('Delete ${removed.name} and cancel its reminders?'),
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
    if (!confirmed) return;

    final updated = [..._medications]..removeAt(index);
    try {
      await MedicationStorage.save(updated);
      if (mounted) setState(() => _medications = updated);
      try {
        await DueStatusStorage.remove(removed.id);
      } catch (_) {
        _showMessage(
          '${removed.name} was deleted, but its old taken/snooze state could not be cleared.',
        );
      }
      try {
        await NotificationService.instance.cancel(removed.id);
        await NotificationService.instance.cancel(
          NotificationService.snoozeNotificationId(removed.id),
        );
      } catch (_) {
        _showMessage(
          '${removed.name} was deleted, but an old reminder may still appear.',
        );
      }
      _recomputeDue();
    } catch (_) {
      _showMessage('The medication could not be deleted. Please try again.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
          : _storageError != null
          ? _buildStorageError()
          : _buildSchedule(),
      // A large, labelled button so the action is obvious.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _storageError == null ? _openAddForm : null,
        backgroundColor: const Color(0xFF1A4B8C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 30),
        label: const Text(
          'Add Medication',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStorageError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _storageError!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loadMedications,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedule() {
    final showPermissionWarning =
        !_notificationsEnabled || !_exactAlarmsEnabled;
    if (_medications.isEmpty) {
      return Column(
        children: [
          if (showPermissionWarning) _buildPermissionBanner(),
          Expanded(child: _buildEmptyState()),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        if (showPermissionWarning) _buildPermissionBanner(),
        ..._dueMedications.map(
          (medication) => _DueMedicationCard(
            medication: medication,
            onTaken: _actionInProgress ? null : () => _markTaken(medication),
            onSnooze: _actionInProgress ? null : () => _snooze(medication),
          ),
        ),
        const SizedBox(height: 20),
        ..._medications.indexed.map(
          (entry) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: _MedicationCard(
              medication: entry.$2,
              onDelete: () => _deleteMedication(entry.$1),
            ),
          ),
        ),
      ],
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
              'No medications yet',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap "Add Medication" below\nto add your first one.',
              style: TextStyle(
                fontSize: 20,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Medication Card ───────────────────────────────────────────────────────

/// A single card in the medication list showing name, dosage, and time.
class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.medication, required this.onDelete});

  final Medication medication;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            // Blue icon badge on the left
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
            // Medication details in the middle
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
            // Delete button on the right — large tap target
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
  final VoidCallback? onTaken;
  final VoidCallback? onSnooze;

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
  // The form key lets us validate all fields at once when the user taps Save.
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();

  // Null until the user picks a time from the time picker.
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    // Free up memory when this screen is closed.
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  /// Open the built-in system time picker dialog.
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      helpText: 'Select time to take medication',
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  /// Convert a TimeOfDay to a human-friendly string like "8:30 AM".
  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Validate the form; if everything looks good, pop back to HomeScreen
  /// and pass the new Medication as the result.
  void _save() {
    // _formKey.currentState!.validate() checks each field's validator function.
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

    // Send the new medication back to HomeScreen.
    Navigator.pop(
      context,
      Medication(
        // Android notification ids must fit in a 32-bit int, so we can't
        // use the full millisecondsSinceEpoch value directly — this keeps
        // it small while still being unique enough for a simple app.
        id: DateTime.now().millisecondsSinceEpoch.remainder(1000000000),
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        time: _formatTime(_selectedTime!),
        hour: _selectedTime!.hour,
        minute: _selectedTime!.minute,
      ),
    );
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
      // SingleChildScrollView lets the page scroll if the keyboard pushes it up.
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the medication name.';
                  }
                  return null; // null means "no error"
                },
              ),
              const SizedBox(height: 28),

              // ── Dosage ───────────────────────────────────────────────────
              const Text(
                'Dosage',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dosageController,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  hintText: 'e.g. 500 mg',
                  prefixIcon: Icon(Icons.scale, size: 28),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the dosage.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // ── Time ─────────────────────────────────────────────────────
              const Text(
                'Time to Take',
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
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 44),

              // ── Save Button ───────────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A4B8C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.save, size: 28),
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
