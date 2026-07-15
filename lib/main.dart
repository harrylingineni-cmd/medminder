import 'dart:async'; // For Timer, used to re-check "is it due yet?"
import 'dart:convert'; // For turning our data into text so it can be saved
import 'package:app_settings/app_settings.dart'; // Opens the phone's Settings screens
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For local storage
import 'due_status_storage.dart'; // Tracks "taken today" / "snoozed" per medication
import 'notification_service.dart'; // Schedules the medication reminders
import 'welcome_screen.dart'; // First-launch welcome / disclaimer screen

// The SharedPreferences key used to remember "the user has already seen the
// welcome/disclaimer screen". Once this is set to true, we skip straight to
// HomeScreen on every future launch.
const String _welcomeSeenPrefsKey = 'has_seen_welcome';

// ─── App Entry Point ───────────────────────────────────────────────────────

void main() async {
  // This line is required before using SharedPreferences.
  // It makes sure Flutter is fully set up before we touch storage.
  WidgetsFlutterBinding.ensureInitialized();

  // Set up the notification plugin and ask for the permissions we need
  // (showing notifications, and scheduling them at an exact time) before
  // the user even opens the Add Medication screen.
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermissions();

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

  // How many minutes we keep sending "please confirm" repeat reminders
  // after the dose becomes due, if the user hasn't tapped "I've taken it"
  // (or snoozed) yet. Chosen by the user when adding/editing the
  // medication — see the reminder-window selector in AddMedicationScreen.
  final int reminderWindowMinutes;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.time,
    required this.hour,
    required this.minute,
    this.reminderWindowMinutes = 30,
  });

  /// Turn this medication into a Map so it can be saved as JSON text.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'time': time,
    'hour': hour,
    'minute': minute,
    'reminderWindowMinutes': reminderWindowMinutes,
  };

  /// Recreate a Medication from a Map that was loaded out of storage.
  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    // Older saved medications (from before reminders were added) won't
    // have an id/hour/minute yet, so fall back to sensible defaults
    // rather than crashing. New ids are kept under `NotificationService
    // .idSpace` so the daily/snooze/repeat notification id "bands"
    // derived from them (see notification_service.dart) never collide.
    id:
        json['id'] as int? ??
        DateTime.now().millisecondsSinceEpoch.remainder(
          NotificationService.idSpace,
        ),
    name: json['name'] as String,
    dosage: json['dosage'] as String,
    time: json['time'] as String,
    hour: json['hour'] as int? ?? 8,
    minute: json['minute'] as int? ?? 0,
    // Older saved medications (from before repeat reminders existed)
    // won't have this field yet, so default to 30 minutes.
    reminderWindowMinutes: json['reminderWindowMinutes'] as int? ?? 30,
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
      home: const AppEntryPoint(),
    );
  }
}

// ─── App Entry Point ───────────────────────────────────────────────────────

/// Decides which screen to show first: the welcome/disclaimer screen (only
/// on the very first launch) or straight to HomeScreen (every launch after
/// that). Reading the "have we shown it before?" flag from SharedPreferences
/// is asynchronous, so this widget shows a brief loading spinner while it
/// checks.
class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  // Null while we're still checking storage; true/false once we know.
  bool? _hasSeenWelcome;

  @override
  void initState() {
    super.initState();
    _checkIfWelcomeWasSeen();
  }

  Future<void> _checkIfWelcomeWasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_welcomeSeenPrefsKey) ?? false;
    setState(() => _hasSeenWelcome = seen);
  }

  /// Called when the user taps "I Understand — Get Started" on the welcome
  /// screen. Saves the flag so it never shows automatically again, then
  /// swaps to HomeScreen.
  Future<void> _completeWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeSeenPrefsKey, true);
    setState(() => _hasSeenWelcome = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSeenWelcome == null) {
      // Still reading from storage — show a brief spinner.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_hasSeenWelcome == false) {
      return WelcomeScreen(isFirstLaunch: true, onContinue: _completeWelcome);
    }
    return const HomeScreen();
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
      _rescheduleAllReminderChains();
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
    await _rescheduleAllReminderChains();
  }

  /// (Re)schedules the "please confirm" repeat chain for every medication.
  /// Safe to call as often as we like — see `_scheduleReminderChain` for
  /// why this never creates duplicate or stacked-up notifications.
  ///
  /// We call this whenever the app starts or comes back to the foreground,
  /// because that's the only time our Dart code actually runs to figure out
  /// "what's the next dose, and how much of its repeat window is left?" —
  /// the repeat notifications themselves keep firing while the app is
  /// closed (that's the whole point of exact-alarm scheduling), but nothing
  /// re-plans *tomorrow's* chain until the app is opened again. In
  /// practice, opening the app once a day (e.g. to check the medication
  /// list) is enough to keep every future day's chain freshly scheduled.
  Future<void> _rescheduleAllReminderChains() async {
    for (final medication in _medications) {
      await _scheduleReminderChain(medication);
    }
  }

  /// Schedules (or re-schedules) the repeat-until-confirmed chain for a
  /// single [medication], anchored to whichever occurrence of its daily
  /// reminder is "next":
  ///   - If it hasn't been taken yet today, the chain is anchored to
  ///     *today's* scheduled time — this covers both "not due yet" (the
  ///     chain is scheduled ahead of time, ready to go) and "currently due,
  ///     mid-repeat-cycle" (re-scheduling with the same ids is harmless and
  ///     just re-confirms what should already be pending).
  ///   - If it has already been taken today, the chain is anchored to
  ///     *tomorrow's* scheduled time instead, ready for the next day.
  ///   - If the user is currently within an active snooze, we don't touch
  ///     the chain at all — it was already cancelled when they snoozed (see
  ///     `_snooze`), and there's nothing useful to schedule until the
  ///     snooze itself fires or the day rolls over.
  Future<void> _scheduleReminderChain(Medication medication) async {
    final status = _dueStatus[medication.id];
    final now = DateTime.now();

    final snoozeUntilMillis = status?.snoozeUntilMillis;
    if (snoozeUntilMillis != null) {
      final snoozeUntil = DateTime.fromMillisecondsSinceEpoch(
        snoozeUntilMillis,
      );
      if (now.isBefore(snoozeUntil)) return; // Currently snoozed — skip.
    }

    var anchor = DateTime(
      now.year,
      now.month,
      now.day,
      medication.hour,
      medication.minute,
    );
    final takenToday = status?.takenDate == DueStatusStorage.todayString(now);
    if (takenToday) {
      anchor = anchor.add(const Duration(days: 1));
    }

    await NotificationService.instance.scheduleRepeatReminders(
      medicationId: medication.id,
      medicationName: medication.name,
      dosage: medication.dosage,
      anchorTime: anchor,
      reminderWindowMinutes: medication.reminderWindowMinutes,
    );
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
  /// pending snooze reminder AND the whole repeat-until-confirmed chain for
  /// it (so it stops pinging every 5 minutes), and removes its due card.
  Future<void> _markTaken(Medication medication) async {
    await DueStatusStorage.markTakenToday(medication.id);
    await NotificationService.instance.cancel(
      NotificationService.snoozeNotificationId(medication.id),
    );
    await NotificationService.instance.cancelRepeatReminders(medication.id);
    _dueStatus = await DueStatusStorage.loadAll();
    _recomputeDue();
  }

  /// "Remind me in 10 minutes" — hides the due card for now, cancels the
  /// repeat-until-confirmed chain (snoozing counts as "dealt with" for now,
  /// so the every-5-minutes pings should stop), and schedules a one-time
  /// reminder notification 10 minutes from now.
  Future<void> _snooze(Medication medication) async {
    final snoozeUntil = DateTime.now().add(const Duration(minutes: 10));
    await DueStatusStorage.snooze(medication.id, snoozeUntil);
    await NotificationService.instance.cancelRepeatReminders(medication.id);
    await NotificationService.instance.scheduleOneOffReminder(
      id: NotificationService.snoozeNotificationId(medication.id),
      medicationName: medication.name,
      dosage: medication.dosage,
      fireAt: snoozeUntil,
    );
    _dueStatus = await DueStatusStorage.loadAll();
    _recomputeDue();
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
      setState(() => _medications = updated);
      await MedicationStorage.save(updated); // Persist to device storage

      // Schedule a daily reminder that fires at this medication's time,
      // plus its repeat-until-confirmed chain for the next time it's due.
      await NotificationService.instance.scheduleDailyMedicationReminder(
        id: newMed.id,
        medicationName: newMed.name,
        dosage: newMed.dosage,
        hour: newMed.hour,
        minute: newMed.minute,
      );
      await _scheduleReminderChain(newMed);
      _recomputeDue();
    }
  }

  /// Navigate to the Add Medication screen pre-filled with [medication]'s
  /// details, and apply whatever the user saves back over the original.
  Future<void> _editMedication(int index) async {
    final original = _medications[index];
    final updatedMed = await Navigator.push<Medication>(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicationScreen(existing: original),
      ),
    );
    if (updatedMed == null) return; // User tapped Cancel / went back.

    final updated = [..._medications];
    updated[index] = updatedMed;
    setState(() => _medications = updated);
    await MedicationStorage.save(updated);

    // The time or reminder window may have changed, so cancel the old
    // repeat chain and re-schedule everything from scratch. The daily and
    // snooze ids stay the same (same medication id), so re-scheduling the
    // daily reminder simply overwrites the old one.
    await NotificationService.instance.cancelRepeatReminders(updatedMed.id);
    await NotificationService.instance.scheduleDailyMedicationReminder(
      id: updatedMed.id,
      medicationName: updatedMed.name,
      dosage: updatedMed.dosage,
      hour: updatedMed.hour,
      minute: updatedMed.minute,
    );
    await _scheduleReminderChain(updatedMed);
    _recomputeDue();
  }

  /// Remove the medication at [index] from the list, save, and stop all of
  /// its reminder notifications (daily, any pending snooze, and the whole
  /// repeat-until-confirmed chain).
  Future<void> _deleteMedication(int index) async {
    final removed = _medications[index];
    final updated = [..._medications]..removeAt(index);
    setState(() => _medications = updated);
    await MedicationStorage.save(updated);
    await NotificationService.instance.cancel(removed.id);
    await NotificationService.instance.cancel(
      NotificationService.snoozeNotificationId(removed.id),
    );
    await NotificationService.instance.cancelRepeatReminders(removed.id);
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
        actions: [
          // Lets the user re-read the welcome/disclaimer screen and privacy
          // policy link at any time, not just on first launch.
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WelcomeScreen(
                  isFirstLaunch: false,
                  onContinue: () => Navigator.pop(context),
                ),
              ),
            ),
            icon: const Icon(Icons.info_outline, size: 28),
            tooltip: 'About / Privacy',
          ),
        ],
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
        icon: const Icon(Icons.add, size: 30),
        label: const Text(
          'Add Medication',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  /// The scrollable list of medication cards.
  Widget _buildMedicationList() {
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
        return _MedicationCard(
          medication: _medications[index],
          onDelete: () => _deleteMedication(index),
          onTap: () => _editMedication(index),
        );
      },
    );
  }
}

// ─── Medication Card ───────────────────────────────────────────────────────

/// A single card in the medication list showing name, dosage, and time.
/// Tapping anywhere on the card (other than the delete button) opens it for
/// editing, including its reminder window.
class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.medication,
    required this.onDelete,
    required this.onTap,
  });

  final Medication medication;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                      ),
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
                    const SizedBox(height: 4),
                    Text(
                      'Reminds every 5 min for '
                      '${medication.reminderWindowMinutes} min if missed',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black45,
                        fontStyle: FontStyle.italic,
                      ),
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

/// A form screen for entering a new medication, or editing an existing one
/// if [existing] is passed in.
class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key, this.existing});

  /// When editing, the medication being edited. Null when adding a new one.
  final Medication? existing;

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

  // How many minutes to keep sending "please confirm" repeat reminders if
  // the dose isn't confirmed. 30 minutes is a reasonable default.
  int _selectedWindowMinutes = 30;

  // The reminder-window choices offered to the user, in minutes.
  static const _windowOptions = [15, 30, 60];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    // If we're editing an existing medication, pre-fill every field with
    // its current values so the user only has to change what they want to.
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _dosageController.text = existing.dosage;
      _selectedTime = TimeOfDay(hour: existing.hour, minute: existing.minute);
      _selectedWindowMinutes = existing.reminderWindowMinutes;
    }
  }

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
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  /// One big tappable button for a single reminder-window choice (e.g.
  /// "30 min"). Highlighted blue when it's the currently selected option.
  Widget _buildWindowOption(int minutes) {
    final selected = _selectedWindowMinutes == minutes;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton(
          onPressed: () => setState(() => _selectedWindowMinutes = minutes),
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? const Color(0xFF1A4B8C) : Colors.white,
            foregroundColor: selected ? Colors.white : const Color(0xFF1A4B8C),
            side: const BorderSide(color: Color(0xFF1A4B8C), width: 2),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            '$minutes min',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
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

    // Send the new (or edited) medication back to HomeScreen. When editing,
    // keep the original id so it keeps using the same notification ids
    // (the daily reminder, snooze, and repeat chain all get overwritten in
    // place rather than duplicated).
    Navigator.pop(
      context,
      Medication(
        id:
            widget.existing?.id ??
            // Android notification ids must fit in a 32-bit int, and every
            // other notification for this medication is derived from this
            // id by adding multiples of `NotificationService.idSpace` (see
            // that constant's comment) — so the id itself must stay well
            // under that to leave room for all of them.
            DateTime.now().millisecondsSinceEpoch.remainder(
              NotificationService.idSpace,
            ),
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        time: _formatTime(_selectedTime!),
        hour: _selectedTime!.hour,
        minute: _selectedTime!.minute,
        reminderWindowMinutes: _selectedWindowMinutes,
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
        title: Text(
          _isEditing ? 'Edit Medication' : 'Add Medication',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
              const SizedBox(height: 28),

              // ── Reminder Window ─────────────────────────────────────────
              const Text(
                'Keep Reminding Me For',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'If you don\'t confirm, we\'ll remind you every 5 minutes '
                'until this much time has passed.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Row(
                children: _windowOptions
                    .map((minutes) => _buildWindowOption(minutes))
                    .toList(),
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
                label: Text(
                  _isEditing ? 'Save Changes' : 'Save Medication',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
