import 'dart:async';

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

  final String? initialNotificationWarning;
  final DateTime Function() nowProvider;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationWarning = widget.notificationWarning;
    _loadState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
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
    }
  }

  Future<void> _acknowledge() async {
    final occurrence = _occurrence;
    final now = widget.nowProvider();
    if (occurrence == null ||
        !occurrence.isActionable(now) ||
        _actionInProgress) {
      return;
    }

    setState(() {
      _actionError = null;
      _actionInProgress = true;
    });
    final acknowledgement = MedicationAcknowledgement(
      medicationId: occurrence.medication.id,
      scheduledDate: occurrence.scheduledDate,
      acknowledgedAt: now,
    );
    try {
      await MedicationStateStorage.acknowledge(acknowledgement);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _actionError =
            'The acknowledgement could not be saved. Please try again.';
        _actionInProgress = false;
      });
      return;
    }

    if (occurrence.snoozedUntil != null) {
      try {
        await MedicationStateStorage.clearSnooze(
          occurrence.medication.id,
          occurrence.scheduledDate,
        );
      } catch (_) {
        _notificationWarning =
            'Marked as taken, but old snooze data could not be cleared.';
      }
      try {
        final cancelled = await NotificationService.instance.cancelSnooze(
          occurrence.medication.id,
        );
        if (!cancelled) {
          _notificationWarning =
              'An extra reminder may still appear. The app will retry cancelling it.';
        }
      } catch (_) {
        _notificationWarning =
            'Marked as taken, but an extra reminder may still appear.';
      }
    }

    try {
      if (!mounted) return;
      setState(() {
        _lastAcknowledgement = acknowledgement;
        _lastAcknowledgedMedication = occurrence.medication;
      });
      await _loadState();
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  Future<void> _snooze() async {
    final occurrence = _occurrence;
    final now = widget.nowProvider();
    if (occurrence == null ||
        !occurrence.isActionable(now) ||
        _actionInProgress) {
      return;
    }

    setState(() {
      _actionError = null;
      _actionInProgress = true;
    });
    final snooze = MedicationSnooze(
      medicationId: occurrence.medication.id,
      scheduledDate: occurrence.scheduledDate,
      snoozeUntil: now.add(const Duration(minutes: 10)),
    );
    try {
      await NotificationService.instance.scheduleSnoozeReminder(
        medication: occurrence.medication,
        snoozeUntil: snooze.snoozeUntil,
      );
      try {
        await MedicationStateStorage.saveSnooze(snooze);
      } catch (_) {
        final cancelled = await NotificationService.instance.cancelSnooze(
          occurrence.medication.id,
        );
        if (!cancelled) {
          _notificationWarning =
              'An extra reminder may appear because snooze recovery failed.';
        }
        rethrow;
      }
      if (!mounted) return;
      await _loadState();
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _actionError =
            'The reminder could not be scheduled. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  void _continueAfterAcknowledgement() {
    setState(() {
      _lastAcknowledgement = null;
      _lastAcknowledgedMedication = null;
    });
    _recompute(widget.nowProvider());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_storageError != null) {
      return _StorageUnavailableState(
        message: _storageError!,
        onRetry: _loadState,
        onOpenCaregiver: _openCaregiverSetup,
      );
    }
    if (_lastAcknowledgement != null && _lastAcknowledgedMedication != null) {
      return _AcknowledgementState(
        acknowledgement: _lastAcknowledgement!,
        medication: _lastAcknowledgedMedication!,
        nextOccurrence: _occurrence,
        onContinue: _continueAfterAcknowledgement,
      );
    }
    if (_medications.isEmpty || _occurrence == null) {
      return _PatientEmptyState(onOpenCaregiver: _openCaregiverSetup);
    }
    return _NextMedicationView(
      occurrence: _occurrence!,
      now: widget.nowProvider(),
      actionError: _actionError,
      actionInProgress: _actionInProgress,
      onTaken: _acknowledge,
      onSnooze: _snooze,
    );
  }
}

class _NextMedicationView extends StatelessWidget {
  const _NextMedicationView({
    required this.occurrence,
    required this.now,
    required this.actionError,
    required this.actionInProgress,
    required this.onTaken,
    required this.onSnooze,
  });

  final MedicationOccurrence occurrence;
  final DateTime now;
  final String? actionError;
  final bool actionInProgress;
  final VoidCallback onTaken;
  final VoidCallback onSnooze;

  @override
  Widget build(BuildContext context) {
    final snoozedUntil = occurrence.snoozedUntil;
    final isToday = occurrence.scheduledDate == localDateKey(now);
    final actionable = occurrence.isActionable(now);
    final status = snoozedUntil != null
        ? 'SNOOZED UNTIL ${_formatClock(snoozedUntil)}'
        : !isToday
        ? 'NEXT: TOMORROW AT ${occurrence.medication.time}'
        : occurrence.isDue(now)
        ? 'REMINDER DUE'
        : occurrence.isOverdue(now)
        ? 'REMINDER OVERDUE · SCHEDULED ${occurrence.medication.time}'
        : 'SCHEDULED FOR ${occurrence.medication.time}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            status,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A4B8C),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FC),
              border: Border.all(color: const Color(0xFF1A4B8C), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.medication,
                  size: 56,
                  color: Color(0xFF1A4B8C),
                ),
                const SizedBox(height: 20),
                Text(
                  occurrence.medication.name,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  occurrence.medication.dosage,
                  style: const TextStyle(fontSize: 26),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Check the medication label before taking it.',
            style: TextStyle(fontSize: 20, height: 1.35),
          ),
          if (actionError != null) ...[
            const SizedBox(height: 18),
            Text(
              actionError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (actionable) ...[
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: actionInProgress ? null : onTaken,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A4B8C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 30),
              label: const Text(
                'I’ve taken it',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            if (snoozedUntil == null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: actionInProgress ? null : onSnooze,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A4B8C),
                  side: const BorderSide(color: Color(0xFF1A4B8C), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                icon: const Icon(Icons.snooze, size: 30),
                label: const Text(
                  'Remind me in 10 minutes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _AcknowledgementState extends StatelessWidget {
  const _AcknowledgementState({
    required this.acknowledgement,
    required this.medication,
    required this.nextOccurrence,
    required this.onContinue,
  });

  final MedicationAcknowledgement acknowledgement;
  final Medication medication;
  final MedicationOccurrence? nextOccurrence;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 96,
              color: Color(0xFF1A4B8C),
            ),
            const SizedBox(height: 24),
            const Text(
              'Marked as taken',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '${medication.name} · ${medication.dosage}\n${_formatClock(acknowledgement.acknowledgedAt)}',
              style: const TextStyle(fontSize: 21, height: 1.45),
              textAlign: TextAlign.center,
            ),
            if (nextOccurrence != null) ...[
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 18),
              const Text(
                'Next reminder',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                '${nextOccurrence!.medication.name} · ${nextOccurrence!.medication.time}',
                style: const TextStyle(fontSize: 20),
              ),
            ],
            const SizedBox(height: 34),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A4B8C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientEmptyState extends StatelessWidget {
  const _PatientEmptyState({required this.onOpenCaregiver});

  final VoidCallback onOpenCaregiver;

  @override
  Widget build(BuildContext context) {
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
              'A caregiver can add the first medication and reminder.',
              style: TextStyle(fontSize: 20, color: Colors.black54),
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
      itemCount: _medications.length + 1,
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
                    medication.time,
                    style: const TextStyle(fontSize: 18, color: Colors.black54),
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
              tooltip: 'Delete ${medication.name}',
              padding: const EdgeInsets.all(12),
            ),
          ],
        ),
      ),
    );
  }
}

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
      helpText: 'Select medication reminder time',
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
        const SnackBar(content: Text('Please select a reminder time.')),
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
              Semantics(
                button: true,
                label: _selectedTime == null
                    ? 'Select reminder time'
                    : 'Reminder time ${_formatTime(_selectedTime!)}',
                child: InkWell(
                  onTap: _pickTime,
                  borderRadius: BorderRadius.circular(4),
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
