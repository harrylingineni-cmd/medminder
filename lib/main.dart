import 'dart:async'; // For Timer, used to re-check "is it due yet?"
import 'dart:convert'; // For turning our data into text so it can be saved
import 'package:app_settings/app_settings.dart'; // Opens the phone's Settings screens
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For local storage
import 'due_status_storage.dart'; // Tracks "taken today" / "snoozed" per dose
import 'find_generic_screen.dart'; // "Find Generic" tab — brand-to-generic lookup
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

  // Set up notifications before rendering. A notification plug-in failure
  // must not prevent the user from opening and reading their schedule; the
  // home-screen permission warning provides the recoverable state instead.
  try {
    await NotificationService.instance.init();
  } catch (_) {}

  runApp(const MedTrackerApp());
}

// ─── Small Shared Helpers ──────────────────────────────────────────────────

/// Turns a 24-hour hour/minute pair into a friendly string like "8:30 AM".
/// Used everywhere we display a dose time, so every screen formats times
/// exactly the same way.
String formatHourMinute(int hour, int minute) {
  final hourOfPeriod = hour % 12 == 0 ? 12 : hour % 12;
  final minuteStr = minute.toString().padLeft(2, '0');
  final period = hour >= 12 ? 'PM' : 'AM';
  return '$hourOfPeriod:$minuteStr $period';
}

/// Plain-language label for a dose count, e.g. 2 -> "Twice a day". Avoids
/// medical shorthand like "BID"/"TID" so it stays clear for older adults.
String timesPerDayLabel(int count) {
  switch (count) {
    case 1:
      return 'Once a day';
    case 2:
      return 'BID · Twice a day';
    case 3:
      return 'TID · 3 times a day';
    case 4:
      return 'QID · 4 times a day';
    default:
      return '$count times a day';
  }
}

/// Calculates a true 24-hour even schedule. BID is every 12 hours, TID every
/// 8 hours, and QID every 6 hours. Results are sorted by clock time so the UI
/// and due-state logic always agree on what "today" means.
List<DoseTime> evenlySpacedDoseTimes(TimeOfDay start, int count) {
  final intervalMinutes = (24 * 60) ~/ count;
  final startMinutes = start.hour * 60 + start.minute;
  final times = <DoseTime>[
    for (var index = 0; index < count; index++)
      DoseTime(
        hour: ((startMinutes + intervalMinutes * index) % (24 * 60)) ~/ 60,
        minute: (startMinutes + intervalMinutes * index) % 60,
      ),
  ];
  times.sort(
    (left, right) => (left.hour * 60 + left.minute).compareTo(
      right.hour * 60 + right.minute,
    ),
  );
  return times;
}

bool hasDuplicateDoseTimes(Iterable<DoseTime> times) {
  final unique = <int>{};
  for (final time in times) {
    if (!unique.add(time.hour * 60 + time.minute)) return true;
  }
  return false;
}

// ─── Data Model ────────────────────────────────────────────────────────────

/// One time of day a medication should be taken. A medication now has a
/// LIST of these instead of a single time, so it can support multiple doses
/// a day, each tracked independently.
class DoseTime {
  final int hour; // 24-hour hour (0-23)
  final int minute; // 0-59

  const DoseTime({required this.hour, required this.minute});

  /// Friendly display string, e.g. "8:30 AM".
  String get label => formatHourMinute(hour, minute);

  Map<String, dynamic> toJson() => {'hour': hour, 'minute': minute};

  factory DoseTime.fromJson(Map<String, dynamic> json) =>
      DoseTime(hour: json['hour'] as int, minute: json['minute'] as int);
}

/// Represents one medication the user wants to track.
class Medication {
  final int id; // Also used to derive this medication's notification ids.
  final String name;
  final String dosage;

  // Every time of day this medication should be taken, e.g. [8:00 AM,
  // 2:00 PM, 8:00 PM] for "3 times a day". Each entry is tracked as a
  // completely separate dose — see due_status_storage.dart.
  final List<DoseTime> doseTimes;

  // How many minutes we keep sending "please confirm" repeat reminders
  // after a dose becomes due, if the user hasn't tapped "I've taken it"
  // (or snoozed) yet. Chosen by the user when adding/editing the
  // medication — see the reminder-window selector in AddMedicationScreen.
  // Applies to every dose of this medication.
  final int reminderWindowMinutes;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.doseTimes,
    this.reminderWindowMinutes = 30,
  });

  /// Turn this medication into a Map so it can be saved as JSON text.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'doseTimes': doseTimes.map((d) => d.toJson()).toList(),
    'reminderWindowMinutes': reminderWindowMinutes,
  };

  /// Recreate a Medication from a Map that was loaded out of storage.
  factory Medication.fromJson(Map<String, dynamic> json) {
    final rawDoseTimes = json['doseTimes'] as List?;
    final doseTimes = rawDoseTimes != null
        ? rawDoseTimes
              .map((d) => DoseTime.fromJson(d as Map<String, dynamic>))
              .toList()
        : [
            // Medications saved before multi-dose support only ever had a
            // single hour/minute pair. Migrate that into a one-item dose
            // list so they keep loading — and reminding — exactly as
            // before, just now represented the same way as every other
            // medication.
            DoseTime(
              hour: json['hour'] as int? ?? 8,
              minute: json['minute'] as int? ?? 0,
            ),
          ];
    return Medication(
      // MedicationStorage assigns a stable, safe id while loading if an older
      // record has no id (or has one outside the current notification range).
      id: json['id'] as int? ?? 0,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      doseTimes: doseTimes,
      // Older saved medications (from before repeat reminders existed)
      // won't have this field yet, so default to 30 minutes.
      reminderWindowMinutes: json['reminderWindowMinutes'] as int? ?? 30,
    );
  }
}

// ─── Storage Helper ────────────────────────────────────────────────────────

/// All the code for reading and writing medications to the device lives here.
///
/// SharedPreferences stores simple key→value pairs on the device.
/// Because it can only store strings, we convert each Medication to a JSON
/// string before saving, and parse it back when loading.
class MedicationStorage {
  static const _storageKey = 'medications';
  static const _nextIdSlotKey = 'next_medication_id_slot';
  static const _pendingCleanupKey = 'pending_notification_cleanup_ids';
  static const _pendingDoseCleanupKey = 'pending_dose_notification_cleanup_ids';

  static bool _isSafeId(int id) =>
      id > 0 &&
      id < NotificationService.idSpace &&
      id % NotificationService.medicationIdSpace == 0;

  static Medication _withId(Medication medication, int id) => Medication(
    id: id,
    name: medication.name,
    dosage: medication.dosage,
    doseTimes: medication.doseTimes,
    reminderWindowMinutes: medication.reminderWindowMinutes,
  );

  /// Load all saved medications from the device.
  /// Returns an empty list if nothing has been saved yet.
  static Future<List<Medication>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStrings = prefs.getStringList(_storageKey) ?? [];
    final loaded = jsonStrings
        .map((s) => Medication.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    final idCounts = <int, int>{};
    for (final medication in loaded) {
      idCounts.update(medication.id, (count) => count + 1, ifAbsent: () => 1);
    }

    final usedIds = {
      for (final medication in loaded)
        if (_isSafeId(medication.id)) medication.id,
    };
    final keptSafeIds = <int>{};
    var nextSlot = 1;
    int nextFreeId() {
      while (usedIds.contains(
        nextSlot * NotificationService.medicationIdSpace,
      )) {
        nextSlot++;
      }
      final id = nextSlot * NotificationService.medicationIdSpace;
      nextSlot++;
      return id;
    }

    final replacements = <int, int>{};
    final oldIdsToCleanUp = <int>{};
    var changed = false;
    final normalized = <Medication>[];
    for (final medication in loaded) {
      if (_isSafeId(medication.id) && keptSafeIds.add(medication.id)) {
        normalized.add(medication);
        continue;
      }

      final newId = nextFreeId();
      usedIds.add(newId);
      normalized.add(_withId(medication, newId));
      changed = true;
      if (medication.id != 0) {
        oldIdsToCleanUp.add(medication.id);
        // A duplicated old id has ambiguous state, so do not copy it to one
        // of the duplicates arbitrarily.
        if (idCounts[medication.id] == 1) {
          replacements[medication.id] = newId;
        }
      }
    }

    if (changed) {
      await _addPendingCleanupIds(prefs, oldIdsToCleanUp);
      await DueStatusStorage.remapMedicationIds(replacements);
      await _saveWithPreferences(prefs, normalized);
    }

    final highestSlot = usedIds.isEmpty
        ? 0
        : usedIds.reduce((left, right) => left > right ? left : right) ~/
              NotificationService.medicationIdSpace;
    final storedNextSlot = prefs.getInt(_nextIdSlotKey) ?? 1;
    if (storedNextSlot <= highestSlot) {
      final saved = await prefs.setInt(_nextIdSlotKey, highestSlot + 1);
      if (!saved) throw StateError('Medication id counter could not be saved.');
    }
    return normalized;
  }

  /// Save the full list of medications to the device, replacing the old list.
  static Future<void> save(List<Medication> medications) async {
    final prefs = await SharedPreferences.getInstance();
    await _saveWithPreferences(prefs, medications);
  }

  static Future<void> _saveWithPreferences(
    SharedPreferences prefs,
    List<Medication> medications,
  ) async {
    final jsonStrings = medications.map((m) => jsonEncode(m.toJson())).toList();
    final saved = await prefs.setStringList(_storageKey, jsonStrings);
    if (!saved) throw StateError('Medication schedule could not be saved.');
  }

  static Future<int> allocateId() async {
    final prefs = await SharedPreferences.getInstance();
    final slot = prefs.getInt(_nextIdSlotKey) ?? 1;
    final maxSlot =
        NotificationService.idSpace ~/ NotificationService.medicationIdSpace;
    if (slot >= maxSlot) throw StateError('No medication ids are available.');
    final saved = await prefs.setInt(_nextIdSlotKey, slot + 1);
    if (!saved) throw StateError('Medication id counter could not be saved.');
    return slot * NotificationService.medicationIdSpace;
  }

  static Future<void> _addPendingCleanupIds(
    SharedPreferences prefs,
    Iterable<int> ids,
  ) async {
    final pending = <String>{
      ...prefs.getStringList(_pendingCleanupKey) ?? [],
      ...ids.map((id) => '$id'),
    };
    final saved = await prefs.setStringList(
      _pendingCleanupKey,
      pending.toList(),
    );
    if (!saved) throw StateError('Reminder cleanup could not be queued.');
  }

  static Future<void> queueNotificationCleanup(int medicationId) async {
    final prefs = await SharedPreferences.getInstance();
    await _addPendingCleanupIds(prefs, [medicationId]);
  }

  static Future<List<int>> pendingNotificationCleanupIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_pendingCleanupKey) ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .toList();
  }

  static Future<void> completeNotificationCleanup(int medicationId) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = {...prefs.getStringList(_pendingCleanupKey) ?? []}
      ..remove('$medicationId');
    final saved = await prefs.setStringList(
      _pendingCleanupKey,
      pending.toList(),
    );
    if (!saved) throw StateError('Reminder cleanup status could not be saved.');
  }

  static Future<void> queueDoseNotificationCleanup(int doseId) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = <String>{
      ...prefs.getStringList(_pendingDoseCleanupKey) ?? [],
      '$doseId',
    };
    final saved = await prefs.setStringList(
      _pendingDoseCleanupKey,
      pending.toList(),
    );
    if (!saved) throw StateError('Dose reminder cleanup could not be queued.');
  }

  static Future<List<int>> pendingDoseNotificationCleanupIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_pendingDoseCleanupKey) ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .toList();
  }

  static Future<void> completeDoseNotificationCleanup(int doseId) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = {...prefs.getStringList(_pendingDoseCleanupKey) ?? []}
      ..remove('$doseId');
    final saved = await prefs.setStringList(
      _pendingDoseCleanupKey,
      pending.toList(),
    );
    if (!saved) {
      throw StateError('Dose reminder cleanup status could not be saved.');
    }
  }
}

// ─── App Root ──────────────────────────────────────────────────────────────

/// The root of the app. Sets up the overall look and feel.
class MedTrackerApp extends StatelessWidget {
  const MedTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediGuard',
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
    if (mounted) setState(() => _hasSeenWelcome = seen);
  }

  /// Called when the user taps "I Understand — Get Started" on the welcome
  /// screen. Saves the flag so it never shows automatically again, then
  /// swaps to HomeScreen.
  Future<void> _completeWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeSeenPrefsKey, true);
    if (mounted) setState(() => _hasSeenWelcome = true);
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
    return const MainNavScreen();
  }
}

// ─── Main Navigation (Bottom Tab Bar) ──────────────────────────────────────

/// The app's main screen once the welcome/disclaimer has been seen: a
/// bottom navigation bar switching between the two top-level features —
/// "My Medications" (the original home screen, unchanged) and "Find
/// Generic" (brand-to-generic medicine lookup).
///
/// Each tab keeps its own AppBar/FloatingActionButton exactly as before;
/// this widget only adds the bottom bar around them. We use an
/// `IndexedStack` (instead of just swapping which widget is built) so both
/// tabs' screens are created once and stay alive in the background when
/// you switch away — important for "My Medications", which runs a
/// due-dose-checking timer and needs to keep its loaded state.
class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedTabIndex = 0;

  // The two tab screens, in the same order as the bottom nav items below.
  static const _tabScreens = [HomeScreen(), FindGenericScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedTabIndex, children: _tabScreens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedTabIndex = index),
        // Large icons + always-visible labels + high-contrast selected
        // colour make the two tabs easy to tell apart and easy to tap for
        // older adults.
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE3EBF8),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 14,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.bold
                : FontWeight.normal,
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF1A4B8C)
                : Colors.black54,
          ),
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.medication_outlined, size: 28),
            selectedIcon: Icon(
              Icons.medication,
              size: 28,
              color: Color(0xFF1A4B8C),
            ),
            label: 'My Medications',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined, size: 28),
            selectedIcon: Icon(
              Icons.search,
              size: 28,
              color: Color(0xFF1A4B8C),
            ),
            label: 'Find Generic',
          ),
        ],
      ),
    );
  }
}

// ─── Due Dose ──────────────────────────────────────────────────────────────

/// Identifies one specific dose of one specific medication that is
/// currently due — e.g. "the 2 PM dose of Lisinopril". Used to build the
/// due-medication cards and to route "I've taken it" / "Remind me" taps
/// back to the correct dose (and only that dose).
class _DueDose {
  final Medication medication;
  final int doseIndex;

  const _DueDose({required this.medication, required this.doseIndex});

  DoseTime get doseTime => medication.doseTimes[doseIndex];
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
  bool _actionInProgress = false;
  String? _storageError;

  // ── "Due" tracking ──
  // For every DOSE (medicationId, doseIndex), `_dueStatus` holds whether/
  // when it was taken or snoozed today. `_dueDoses` is the subset of doses,
  // across all medications, that are currently due — recomputed whenever
  // anything relevant changes.
  Map<DoseKey, DueStatusEntry> _dueStatus = {};
  List<_DueDose> _dueDoses = [];

  // ── Permission banner ──
  // Both default to `true` (assume granted) until we've actually checked,
  // so the warning banner doesn't flash on screen for a split second.
  bool _notificationsEnabled = true;
  bool _exactAlarmsEnabled = true;

  // Re-checks which doses are due every 30 seconds, so a dose becoming due
  // (and its card appearing) doesn't require the user to manually refresh
  // or reopen the app right at the scheduled time.
  Timer? _dueCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load saved medications as soon as the screen appears.
    _loadMedications();
    _requestPermissionsAndCheck();
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
      unawaited(_checkPermissions());
      _recomputeDue();
      unawaited(_refreshReminderChainsAfterResume());
    }
  }

  Future<void> _refreshReminderChainsAfterResume() async {
    try {
      await _reconcileNotifications();
    } catch (_) {
      _showMessage('Some reminders could not be refreshed. Check permissions.');
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
      try {
        await _reconcileNotifications();
      } catch (_) {
        _showMessage(
          'Some reminders could not be refreshed. Check permissions.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _storageError =
            'Saved medication data could not be read. Please retry before changing the schedule.';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissionsAndCheck() async {
    try {
      await NotificationService.instance.init();
      await NotificationService.instance.requestPermissions();
    } catch (_) {
      // The permission banner below is the recoverable UI for this failure.
    }
    await _checkPermissions();
  }

  /// (Re)schedules the "please confirm" repeat chain for every dose of
  /// every medication. Safe to call as often as we like — see
  /// `_scheduleReminderChainForDose` for why this never creates duplicate
  /// or stacked-up notifications.
  ///
  /// We call this whenever the app starts or returns to the foreground so the
  /// next dose occurrence always has a fresh one-off follow-up series. Taken
  /// and Snooze also schedule the following day's series directly.
  Future<void> _reconcileNotifications() async {
    await NotificationService.instance.init();
    var hadError = false;
    for (final doseId
        in await MedicationStorage.pendingDoseNotificationCleanupIds()) {
      try {
        await NotificationService.instance.cancelAllForDose(doseId);
        await MedicationStorage.completeDoseNotificationCleanup(doseId);
      } catch (_) {
        hadError = true;
      }
    }
    for (final oldId
        in await MedicationStorage.pendingNotificationCleanupIds()) {
      try {
        await NotificationService.instance.cancelAllForMedication(oldId);
        await MedicationStorage.completeNotificationCleanup(oldId);
      } catch (_) {
        hadError = true;
      }
    }
    for (final medication in _medications) {
      try {
        await _scheduleDailyReminders(medication);
        for (
          var doseIndex = medication.doseTimes.length;
          doseIndex < NotificationService.maxDosesPerMedication;
          doseIndex++
        ) {
          await NotificationService.instance.cancelAllForDose(
            NotificationService.doseNotificationBaseId(
              medication.id,
              doseIndex,
            ),
          );
        }
      } catch (_) {
        hadError = true;
      }
    }
    for (final medication in _medications) {
      try {
        await _scheduleReminderChain(medication);
      } catch (_) {
        hadError = true;
      }
    }
    if (hadError) throw StateError('Some reminders could not be reconciled.');
  }

  /// Schedules the repeat-until-confirmed chain for every dose of a single
  /// [medication], one dose at a time.
  Future<void> _scheduleReminderChain(Medication medication) async {
    for (
      var doseIndex = 0;
      doseIndex < medication.doseTimes.length;
      doseIndex++
    ) {
      await _scheduleReminderChainForDose(medication, doseIndex);
    }
  }

  /// Schedules (or re-schedules) the repeat-until-confirmed chain for a
  /// single dose ([doseIndex] of [medication]), anchored to whichever
  /// occurrence of that dose's daily reminder is "next":
  ///   - If it hasn't been taken yet today, the chain is anchored to
  ///     *today's* scheduled time — this covers both "not due yet" (the
  ///     chain is scheduled ahead of time, ready to go) and "currently due,
  ///     mid-repeat-cycle" (re-scheduling with the same ids is harmless and
  ///     just re-confirms what should already be pending).
  ///   - If it has already been taken today, the chain is anchored to
  ///     *tomorrow's* scheduled time instead, ready for the next day.
  ///   - If the user is currently within an active snooze for this dose, the
  ///     normal series starts tomorrow while a separate one-off snooze series
  ///     handles the current dose.
  Future<void> _scheduleReminderChainForDose(
    Medication medication,
    int doseIndex,
  ) async {
    final status = _dueStatus[(medication.id, doseIndex)];
    final now = DateTime.now();

    final snoozeUntilMillis = status?.snoozeUntilMillis;
    final snoozeSeriesActive =
        snoozeUntilMillis != null &&
        now.isBefore(
          DateTime.fromMillisecondsSinceEpoch(
            snoozeUntilMillis,
          ).add(Duration(minutes: medication.reminderWindowMinutes)),
        );

    final doseTime = medication.doseTimes[doseIndex];
    var anchor = DateTime(
      now.year,
      now.month,
      now.day,
      doseTime.hour,
      doseTime.minute,
    );
    final takenToday = status?.takenDate == DueStatusStorage.todayString(now);
    if (takenToday || snoozeSeriesActive) {
      anchor = DateTime(
        now.year,
        now.month,
        now.day + 1,
        doseTime.hour,
        doseTime.minute,
      );
    }

    await NotificationService.instance.scheduleRepeatReminders(
      id: NotificationService.doseNotificationBaseId(medication.id, doseIndex),
      medicationName: medication.name,
      dosage: medication.dosage,
      anchorTime: anchor,
      reminderWindowMinutes: medication.reminderWindowMinutes,
    );
  }

  /// Ask Android whether notifications / exact alarms are currently allowed,
  /// and show/hide the warning banner accordingly.
  Future<void> _checkPermissions() async {
    bool notificationsEnabled;
    bool exactAlarmsEnabled;
    try {
      notificationsEnabled = await NotificationService.instance
          .areNotificationsEnabled();
      exactAlarmsEnabled = await NotificationService.instance
          .canScheduleExactAlarms();
    } catch (_) {
      notificationsEnabled = false;
      exactAlarmsEnabled = false;
    }
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = notificationsEnabled;
      _exactAlarmsEnabled = exactAlarmsEnabled;
    });
  }

  /// Re-checks, for every dose of every medication, whether it counts as
  /// "due" right now (see `isMedicationDue` in due_status_storage.dart for
  /// the exact rule), and updates `_dueDoses` so the due cards on screen
  /// stay current. Each dose is checked completely independently — taking
  /// the 8 AM dose never affects whether the 2 PM dose shows as due.
  void _recomputeDue() {
    if (!mounted) return;
    final now = DateTime.now();
    final due = <_DueDose>[];
    for (final medication in _medications) {
      for (
        var doseIndex = 0;
        doseIndex < medication.doseTimes.length;
        doseIndex++
      ) {
        final doseTime = medication.doseTimes[doseIndex];
        final isDue = isMedicationDue(
          hour: doseTime.hour,
          minute: doseTime.minute,
          status: _dueStatus[(medication.id, doseIndex)],
          now: now,
        );
        if (isDue) {
          due.add(_DueDose(medication: medication, doseIndex: doseIndex));
        }
      }
    }
    setState(() => _dueDoses = due);
  }

  /// "I've taken it" for one dose — marks just that dose as done for today,
  /// cancels its pending snooze reminder AND its whole repeat-until-
  /// confirmed chain (so it stops pinging every 5 minutes), and removes its
  /// due card. Every other dose (of this medication or any other) is
  /// completely unaffected.
  Future<void> _markTaken(Medication medication, int doseIndex) async {
    if (_actionInProgress) return;
    setState(() => _actionInProgress = true);
    final doseId = NotificationService.doseNotificationBaseId(
      medication.id,
      doseIndex,
    );
    try {
      await MedicationStorage.queueDoseNotificationCleanup(doseId);
      await DueStatusStorage.markTakenToday(medication.id, doseIndex);
      _dueStatus = await DueStatusStorage.loadAll();
      _recomputeDue();
      try {
        await NotificationService.instance.cancelAllForDose(doseId);
        await _scheduleDailyReminderForDose(medication, doseIndex);
        // Recreate the one-off repeat series starting tomorrow. Cancelling
        // today's repeats must never disable the following dose occurrence.
        await _scheduleReminderChainForDose(medication, doseIndex);
        await MedicationStorage.completeDoseNotificationCleanup(doseId);
      } catch (_) {
        _showMessage(
          'Marked as taken, but some old reminders may still appear.',
        );
      }
    } catch (_) {
      _showMessage('Could not save that this dose was taken. Try again.');
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  /// "Remind me in 10 minutes" for one dose — hides that dose's due card
  /// for now, cancels its repeat-until-confirmed chain (snoozing counts as
  /// "dealt with" for now, so the every-5-minutes pings for this dose
  /// should stop), and schedules a one-time reminder notification 10
  /// minutes from now, just for this dose.
  Future<void> _snooze(Medication medication, int doseIndex) async {
    if (_actionInProgress) return;
    final snoozeUntil = DateTime.now().add(const Duration(minutes: 10));
    final doseTime = medication.doseTimes[doseIndex];
    final now = DateTime.now();
    var nextDose = DateTime(
      now.year,
      now.month,
      now.day,
      doseTime.hour,
      doseTime.minute,
    );
    if (!nextDose.isAfter(now)) {
      nextDose = DateTime(
        now.year,
        now.month,
        now.day + 1,
        doseTime.hour,
        doseTime.minute,
      );
    }
    final snoozeSeriesEnds = snoozeUntil.add(
      Duration(minutes: medication.reminderWindowMinutes),
    );
    if (!snoozeSeriesEnds.isBefore(nextDose)) {
      _showMessage(
        'Snooze is too close to the next scheduled dose. Check the label before continuing.',
      );
      return;
    }
    setState(() => _actionInProgress = true);
    final doseId = NotificationService.doseNotificationBaseId(
      medication.id,
      doseIndex,
    );
    var statusSaved = false;
    try {
      // Free today's normal follow-up slots before adding the snooze series,
      // which also leaves room under iOS's pending-notification limit.
      await NotificationService.instance.cancelRepeatReminders(doseId);
      await NotificationService.instance.scheduleOneOffReminder(
        id: NotificationService.snoozeNotificationId(doseId),
        medicationName: medication.name,
        dosage: medication.dosage,
        fireAt: snoozeUntil,
      );
      await NotificationService.instance.scheduleSnoozeRepeatReminders(
        id: doseId,
        medicationName: medication.name,
        dosage: medication.dosage,
        snoozeUntil: snoozeUntil,
        reminderWindowMinutes: medication.reminderWindowMinutes,
      );
      try {
        await DueStatusStorage.snooze(medication.id, doseIndex, snoozeUntil);
        statusSaved = true;
      } catch (_) {
        await NotificationService.instance.cancel(
          NotificationService.snoozeNotificationId(doseId),
        );
        await NotificationService.instance.cancelSnoozeRepeatReminders(doseId);
        rethrow;
      }
      _dueStatus = await DueStatusStorage.loadAll();
      _recomputeDue();
      // Standard repeats resume tomorrow; snooze-specific repeats cover today.
      await _scheduleReminderChainForDose(medication, doseIndex);
    } catch (_) {
      if (statusSaved) {
        try {
          _dueStatus = await DueStatusStorage.loadAll();
          _recomputeDue();
        } catch (_) {}
        _showMessage('Snoozed, but some old reminders may still appear.');
      } else {
        try {
          await NotificationService.instance.cancel(
            NotificationService.snoozeNotificationId(doseId),
          );
          await NotificationService.instance.cancelSnoozeRepeatReminders(
            doseId,
          );
        } catch (_) {}
        try {
          await _scheduleReminderChainForDose(medication, doseIndex);
        } catch (_) {}
        _showMessage('The snooze reminder could not be scheduled. Try again.');
      }
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(fontSize: 18))),
    );
  }

  /// Navigate to the Add Medication screen and wait for the result.
  Future<void> _openAddForm() async {
    int newMedicationId;
    try {
      newMedicationId = await MedicationStorage.allocateId();
    } catch (_) {
      _showMessage('A new medication could not be started. Please try again.');
      return;
    }
    if (!mounted) return;
    // Navigator.push opens a new screen. When that screen calls Navigator.pop
    // with a Medication object, it is returned here as `newMed`.
    final newMed = await Navigator.push<Medication>(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicationScreen(newMedicationId: newMedicationId),
      ),
    );
    // If the user tapped Save (not Cancel), add the new medication.
    if (newMed != null) {
      final updated = [..._medications, newMed];
      try {
        await MedicationStorage.save(updated);
        if (mounted) setState(() => _medications = updated);
        try {
          await _scheduleDailyReminders(newMed);
          await _scheduleReminderChain(newMed);
        } catch (_) {
          _showMessage(
            '${newMed.name} was saved, but some reminders could not be scheduled.',
          );
        }
        _recomputeDue();
      } catch (_) {
        _showMessage('The medication could not be saved. Please try again.');
      }
    }
  }

  Future<void> _scheduleDailyReminders(Medication medication) async {
    for (
      var doseIndex = 0;
      doseIndex < medication.doseTimes.length;
      doseIndex++
    ) {
      await _scheduleDailyReminderForDose(medication, doseIndex);
    }
  }

  Future<void> _scheduleDailyReminderForDose(
    Medication medication,
    int doseIndex,
  ) async {
    final doseTime = medication.doseTimes[doseIndex];
    await NotificationService.instance.scheduleDailyMedicationReminder(
      id: NotificationService.doseNotificationBaseId(medication.id, doseIndex),
      medicationName: medication.name,
      dosage: medication.dosage,
      hour: doseTime.hour,
      minute: doseTime.minute,
    );
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
    final scheduleChanged =
        original.doseTimes.length != updatedMed.doseTimes.length ||
        List.generate(
          original.doseTimes.length,
          (doseIndex) =>
              original.doseTimes[doseIndex].hour !=
                  updatedMed.doseTimes[doseIndex].hour ||
              original.doseTimes[doseIndex].minute !=
                  updatedMed.doseTimes[doseIndex].minute,
        ).any((changed) => changed);
    try {
      await MedicationStorage.save(updated);
    } catch (_) {
      _showMessage(
        'Changes could not be saved. The old schedule is unchanged.',
      );
      return;
    }
    if (mounted) setState(() => _medications = updated);

    // The number of doses and/or their times may have changed, so cancel
    // absolutely everything that could be scheduled for this medication's
    // OLD doses (daily reminders, snoozes, repeat chains — for every
    // possible dose slot, not just the ones it used to have), and clear its
    // taken/snoozed tracking too: a stored "dose 1 was taken today" entry
    // would otherwise keep pointing at dose index 1, even if that index now
    // means a completely different time of day. Then reschedule everything
    // fresh from the new dose list.
    var cleanupQueued = false;
    try {
      if (scheduleChanged) {
        await MedicationStorage.queueNotificationCleanup(updatedMed.id);
        cleanupQueued = true;
        await DueStatusStorage.clearForMedication(updatedMed.id);
        _dueStatus = await DueStatusStorage.loadAll();
        await NotificationService.instance.cancelAllForMedication(
          updatedMed.id,
        );
      }
      await _scheduleDailyReminders(updatedMed);
      await _scheduleReminderChain(updatedMed);
      if (cleanupQueued) {
        await MedicationStorage.completeNotificationCleanup(updatedMed.id);
      }
    } catch (_) {
      _showMessage(
        'Changes were saved, but some reminders could not be refreshed.',
      );
    }
    _recomputeDue();
  }

  /// Ask the user to confirm before deleting, since it cannot be undone and
  /// also stops all of the medication's reminders. Only calls
  /// [_deleteMedication] if they tap "Delete".
  Future<void> _confirmDeleteMedication(int index) async {
    final medication = _medications[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete this medication?',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${medication.name} will be removed and its reminders will '
          'stop. This cannot be undone.',
          style: const TextStyle(fontSize: 18, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "Keep medication" first and in the app's normal blue, so
              // the safe choice is the natural, prominent default.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A4B8C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Keep Medication',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // "Delete" is red so it's unmistakably the destructive option.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteMedication(index);
    }
  }

  /// Remove the medication at [index] from the list, save, and stop all of
  /// its reminder notifications (every dose's daily reminder, any pending
  /// snooze, and every dose's repeat-until-confirmed chain), and forget its
  /// taken/snoozed history.
  Future<void> _deleteMedication(int index) async {
    final removed = _medications[index];
    final updated = [..._medications]..removeAt(index);
    try {
      await MedicationStorage.queueNotificationCleanup(removed.id);
      await MedicationStorage.save(updated);
      if (mounted) setState(() => _medications = updated);
      try {
        try {
          await NotificationService.instance.cancelAllForMedication(removed.id);
          await DueStatusStorage.clearForMedication(removed.id);
          await MedicationStorage.completeNotificationCleanup(removed.id);
          _dueStatus = await DueStatusStorage.loadAll();
        } catch (_) {
          rethrow;
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A4B8C), // deep blue = high contrast
        foregroundColor: Colors.white,
        title: const Text(
          'MediGuard',
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
      // the permission warning banner (if needed), any due-dose cards, then
      // the full medication list below.
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _storageError != null
          ? _buildStorageError()
          : Column(
              children: [
                if (!_notificationsEnabled || !_exactAlarmsEnabled)
                  _buildPermissionBanner(),
                if (_dueDoses.isNotEmpty)
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(child: _buildDueSection()),
                  ),
                Expanded(
                  child: _medications.isEmpty
                      ? _buildEmptyState()
                      : _buildMedicationList(),
                ),
              ],
            ),
      // A large, labelled button so the action is obvious.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _storageError == null && !_actionInProgress
            ? _openAddForm
            : null,
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _storageError!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _loadMedications();
              },
              child: const Text('Retry'),
            ),
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

  /// The stack of "due now" cards, one per DOSE that is currently due (a
  /// medication with two due doses at once would show two separate cards).
  Widget _buildDueSection() {
    return Column(
      children: _dueDoses
          .map(
            (dueDose) => _DueMedicationCard(
              medication: dueDose.medication,
              doseTime: dueDose.doseTime,
              onTaken: () => _markTaken(dueDose.medication, dueDose.doseIndex),
              onSnooze: () => _snooze(dueDose.medication, dueDose.doseIndex),
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
          onDelete: () => _confirmDeleteMedication(index),
          onTap: () => _editMedication(index),
        );
      },
    );
  }
}

// ─── Medication Card ───────────────────────────────────────────────────────

/// A single card in the medication list showing name, dosage, and every
/// dose time. Tapping anywhere on the card (other than the delete button)
/// opens it for editing, including its dose times and reminder window.
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 8),
                    Text(
                      timesPerDayLabel(medication.doseTimes.length),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A4B8C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Every dose time, wrapping onto a new line if there
                    // isn't room for them all on one.
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: medication.doseTimes
                          .map(
                            (doseTime) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  doseTime.label,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
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

/// The prominent card shown at the top of the home screen when a specific
/// DOSE is due: its scheduled time has arrived and it hasn't been taken (or
/// snoozed) yet today. Uses a bold amber/orange colour so it stands out
/// clearly from the ordinary medication list below. A medication with
/// multiple doses due at once (rare, but possible if the app was closed for
/// a while) shows one of these cards per due dose.
class _DueMedicationCard extends StatelessWidget {
  const _DueMedicationCard({
    required this.medication,
    required this.doseTime,
    required this.onTaken,
    required this.onSnooze,
  });

  final Medication medication;
  final DoseTime doseTime;
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
            const SizedBox(height: 10),

            // Which dose time this card is for — important once a
            // medication has more than one dose a day.
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.black54),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Scheduled for ${doseTime.label}',
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                ),
              ],
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
  const AddMedicationScreen({super.key, this.existing, this.newMedicationId})
    : assert(existing != null || newMedicationId != null);

  /// When editing, the medication being edited. Null when adding a new one.
  final Medication? existing;
  final int? newMedicationId;

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  // The form key lets us validate all fields at once when the user taps Save.
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();

  // How many times a day this medication is taken (1-4). Drives how many
  // dose-time rows are shown below.
  int _timesPerDay = 1;

  // Only meaningful when _timesPerDay > 1: whether the user is setting
  // times via "Even Intervals" (pick a start time and let the selected
  // BID/TID/QID frequency determine the spacing) or "Custom Times" (pick
  // every dose time by hand). Both modes end up filling the same `_doseTimes`
  // list below, which is what's actually shown, individually tappable, and
  // saved.
  bool _useEvenIntervals = true;

  // Even-spacing input. The interval is derived from the selected frequency:
  // BID=12h, TID=8h, QID=6h. MediGuard never invents an arbitrary interval.
  TimeOfDay? _intervalStartTime;

  // The actual dose times — always exactly `_timesPerDay` entries long.
  // Null means "not picked yet" (only possible in Custom Times mode,
  // before the user has tapped that row).
  List<TimeOfDay?> _doseTimes = [null];

  // How many minutes to keep sending "please confirm" repeat reminders if
  // a dose isn't confirmed. 30 minutes is a reasonable default. Applies to
  // every dose of this medication.
  int _selectedWindowMinutes = 30;

  // The reminder-window choices offered to the user, in minutes.
  static const _windowOptions = [15, 30, 60];

  // New schedules use the four supported frequencies. A five-dose option is
  // shown only while editing one saved by the student's previous version, so
  // opening and saving it cannot silently discard the fifth time.
  List<int> get _timesPerDayOptions =>
      widget.existing != null && widget.existing!.doseTimes.length > 4
      ? const [1, 2, 3, 4, 5]
      : const [1, 2, 3, 4];

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
      _timesPerDay = existing.doseTimes.length.clamp(
        1,
        NotificationService.maxDosesPerMedication,
      );
      _doseTimes = existing.doseTimes
          .take(_timesPerDay)
          .map((d) => TimeOfDay(hour: d.hour, minute: d.minute))
          .toList();
      // We don't know whether this medication was originally set up with
      // even intervals or fully custom times, so start in Custom Times
      // mode with every saved time pre-filled exactly as-is. The user can
      // still switch to "Even Intervals" afterward if they'd rather have
      // the app recalculate them from a start time + interval.
      _useEvenIntervals = false;
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

  // ── "How many times a day" ─────────────────────────────────────────────

  void _setTimesPerDay(int count) {
    setState(() {
      _timesPerDay = count;
      if (_useEvenIntervals) {
        _recalculateEvenIntervalTimes();
      } else {
        _resizeDoseTimesList(count);
      }
    });
  }

  /// Grows or shrinks `_doseTimes` to exactly [count] entries, keeping
  /// whatever times were already picked (extra new slots start blank;
  /// entries beyond the new count are simply dropped).
  void _resizeDoseTimesList(int count) {
    if (_doseTimes.length == count) return;
    if (_doseTimes.length > count) {
      _doseTimes = _doseTimes.sublist(0, count);
    } else {
      _doseTimes = [
        ..._doseTimes,
        for (var i = _doseTimes.length; i < count; i++) null,
      ];
    }
  }

  // ── Even Intervals / Custom Times mode ─────────────────────────────────

  void _setUseEvenIntervals(bool useEvenIntervals) {
    setState(() {
      _useEvenIntervals = useEvenIntervals;
      if (useEvenIntervals) {
        _recalculateEvenIntervalTimes();
      }
    });
  }

  /// Fills `_doseTimes` with true 24-hour even spacing for the chosen count.
  void _recalculateEvenIntervalTimes() {
    final start = _intervalStartTime;
    if (start == null) {
      _resizeDoseTimesList(_timesPerDay);
      return;
    }
    _doseTimes = evenlySpacedDoseTimes(
      start,
      _timesPerDay,
    ).map((time) => TimeOfDay(hour: time.hour, minute: time.minute)).toList();
  }

  Future<void> _pickIntervalStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _intervalStartTime ?? TimeOfDay.now(),
      helpText: 'Select the time of the first dose',
      builder: _largeTextTimePickerBuilder,
    );
    if (picked != null) {
      setState(() {
        _intervalStartTime = picked;
        _recalculateEvenIntervalTimes();
      });
    }
  }

  // ── Individual dose time rows (used by both modes) ─────────────────────

  Future<void> _pickDoseTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _doseTimes[index] ?? TimeOfDay.now(),
      helpText: _timesPerDay == 1
          ? 'Select time to take medication'
          : 'Select time for dose ${index + 1}',
      builder: _largeTextTimePickerBuilder,
    );
    if (picked != null) {
      setState(() => _doseTimes[index] = picked);
    }
  }

  /// Makes the system time picker's own text a bit larger too, matching the
  /// rest of the app.
  Widget _largeTextTimePickerBuilder(BuildContext context, Widget? child) {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1.2)),
      child: child!,
    );
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

  /// The row of once-daily, BID, TID, and QID choice buttons.
  Widget _buildTimesPerDaySelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _timesPerDayOptions.map((count) {
        final selected = _timesPerDay == count;
        return OutlinedButton(
          onPressed: () => _setTimesPerDay(count),
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? const Color(0xFF1A4B8C) : Colors.white,
            foregroundColor: selected ? Colors.white : const Color(0xFF1A4B8C),
            side: const BorderSide(color: Color(0xFF1A4B8C), width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            timesPerDayLabel(count),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }

  /// The "Even Intervals" / "Custom Times" toggle, shown only when there's
  /// more than one dose a day (with a single dose, there's nothing to
  /// choose between).
  Widget _buildModeToggle() {
    return Row(
      children: [
        Expanded(child: _modeButton('Even Intervals', true)),
        const SizedBox(width: 10),
        Expanded(child: _modeButton('Custom Times', false)),
      ],
    );
  }

  Widget _modeButton(String label, bool value) {
    final selected = _useEvenIntervals == value;
    return OutlinedButton(
      onPressed: () => _setUseEvenIntervals(value),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? const Color(0xFF1A4B8C) : Colors.white,
        foregroundColor: selected ? Colors.white : const Color(0xFF1A4B8C),
        side: const BorderSide(color: Color(0xFF1A4B8C), width: 2),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// The tappable box for picking the first dose's time, in Even Intervals
  /// mode.
  Widget _buildIntervalStartTimeField() {
    return GestureDetector(
      onTap: _pickIntervalStartTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black54),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 28, color: Colors.black54),
            const SizedBox(width: 12),
            // Expanded lets long placeholder text wrap onto a second line
            // instead of overflowing off the right edge of the screen.
            Expanded(
              child: Text(
                _intervalStartTime == null
                    ? 'Tap to select the first dose time'
                    : formatHourMinute(
                        _intervalStartTime!.hour,
                        _intervalStartTime!.minute,
                      ),
                style: TextStyle(
                  fontSize: 20,
                  color: _intervalStartTime == null
                      ? Colors.black45
                      : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One tappable dose-time row. Labeled "Time to Take" for a once-a-day
  /// medication (matching the original single-time form), or "Dose N Time"
  /// once there's more than one.
  Widget _buildDoseTimeRow(int index) {
    final label = _timesPerDay == 1 ? 'Time to Take' : 'Dose ${index + 1} Time';
    final time = _doseTimes[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickDoseTime(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                  // Expanded lets long placeholder text wrap onto a second
                  // line instead of overflowing off the right edge of the
                  // screen.
                  Expanded(
                    child: Text(
                      time == null
                          ? 'Tap to select a time'
                          : formatHourMinute(time.hour, time.minute),
                      style: TextStyle(
                        fontSize: 20,
                        color: time == null ? Colors.black45 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 18)),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Validate the form; if everything looks good, pop back to HomeScreen
  /// and pass the new Medication as the result.
  void _save() {
    // _formKey.currentState!.validate() checks each field's validator function.
    if (!_formKey.currentState!.validate()) return;

    if (_timesPerDay > 1 && _useEvenIntervals && _intervalStartTime == null) {
      _showValidationError('Please select the time of the first dose.');
      return;
    }

    if (_doseTimes.any((t) => t == null)) {
      _showValidationError(
        _timesPerDay == 1
            ? 'Please select a time.'
            : 'Please set a time for every dose.',
      );
      return;
    }

    final doseTimes = _doseTimes
        .map((t) => DoseTime(hour: t!.hour, minute: t.minute))
        .toList();
    if (hasDuplicateDoseTimes(doseTimes)) {
      _showValidationError('Each dose needs a different time.');
      return;
    }
    doseTimes.sort(
      (left, right) => (left.hour * 60 + left.minute).compareTo(
        right.hour * 60 + right.minute,
      ),
    );

    // Send the new (or edited) medication back to HomeScreen. When editing,
    // keep the original id so it keeps using the same notification ids
    // (every dose's daily reminder, snooze, and repeat chain all get
    // overwritten in place rather than duplicated — see `_editMedication`
    // in HomeScreen for exactly how).
    Navigator.pop(
      context,
      Medication(
        id: widget.existing?.id ?? widget.newMedicationId!,
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        doseTimes: doseTimes,
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

              // ── How Many Times a Day ────────────────────────────────────
              const Text(
                'How Many Times a Day?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildTimesPerDaySelector(),
              const SizedBox(height: 10),
              const Text(
                'Use the frequency and exact times written on the prescription '
                'or medication label. MediGuard does not decide when medicine '
                'should be taken.',
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 28),

              // ── Even Intervals vs Custom Times (only if >1 dose) ────────
              if (_timesPerDay > 1) ...[
                const Text(
                  'How Would You Like to Set the Times?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildModeToggle(),
                const SizedBox(height: 24),
              ],

              if (_timesPerDay > 1 && _useEvenIntervals) ...[
                const Text(
                  'First Dose Time',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _buildIntervalStartTimeField(),
                const SizedBox(height: 20),
                Text(
                  'Evenly spaced over a full day. Tap any time below to '
                  'fine-tune it.',
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 16),
              ],

              // ── One tappable row per dose time ──────────────────────────
              for (var i = 0; i < _timesPerDay; i++) _buildDoseTimeRow(i),
              const SizedBox(height: 14),

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
