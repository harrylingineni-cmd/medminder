// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Meine Medikamente';

  @override
  String get welcomeTitle => 'Willkommen bei MediGuard';

  @override
  String get welcomeDescription =>
      'MediGuard hilft Ihnen, Ihre Medikamente pünktlich einzunehmen.';

  @override
  String get pleaseRead => 'Bitte lesen';

  @override
  String get disclaimerText =>
      'MediGuard ist ein Erinnerungs-Tool, kein Medizinprodukt. Es bietet keine medizinische Beratung und garantiert nicht, dass ein Medikament eingenommen wurde. Es ersetzt keinen Arzt oder Apotheker. Prüfen Sie immer das Medikamentenetikett vor der Einnahme. Im Notfall kontaktieren Sie den örtlichen Rettungsdienst.';

  @override
  String get privacyStatement =>
      'Ihre Daten werden nur auf Ihrem Gerät gespeichert. Wir sammeln oder teilen keine Daten.';

  @override
  String get readPrivacyPolicy => 'Datenschutzerklärung lesen';

  @override
  String get getStarted => 'Verstanden — Loslegen';

  @override
  String get close => 'Schließen';

  @override
  String get aboutMediGuard => 'Über MediGuard';

  @override
  String get myMedications => 'Meine Medikamente';

  @override
  String get findGeneric => 'Generikum finden';

  @override
  String get addMedication => 'Medikament hinzufügen';

  @override
  String get editMedication => 'Medikament bearbeiten';

  @override
  String get saveMedication => 'Medikament speichern';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get medicationName => 'Medikamentenname';

  @override
  String get medicationNameHint => 'z. B. Lisinopril';

  @override
  String get dosage => 'Dosierung';

  @override
  String get dosageHint => 'z. B. 500 mg';

  @override
  String get howManyTimesPerDay => 'Wie oft täglich?';

  @override
  String get onceADay => 'Einmal täglich';

  @override
  String get twiceADay => 'Zweimal täglich';

  @override
  String get threeTimesADay => '3-mal täglich';

  @override
  String get fourTimesADay => '4-mal täglich';

  @override
  String get fiveTimesADay => '5-mal täglich';

  @override
  String get setTimesMode => 'Wie möchten Sie die Zeiten festlegen?';

  @override
  String get evenIntervals => 'Gleiche Abstände';

  @override
  String get customTimes => 'Eigene Zeiten';

  @override
  String get firstDoseTime => 'Zeit der ersten Dosis';

  @override
  String get tapToSelectFirstDose =>
      'Tippen Sie, um die Zeit der ersten Dosis zu wählen';

  @override
  String get hoursBetweenDoses => 'Stunden zwischen Dosen';

  @override
  String everyHours(
    Object horasPlural,
    Object hours,
    Object hoursPlural,
    Object stundenPlural,
  ) {
    return 'Alle $hours Stunde$stundenPlural';
  }

  @override
  String get calculatedTimesNote =>
      'Wir haben diese Zeiten berechnet — tippen Sie auf eine, um sie anzupassen.';

  @override
  String get timeToTake => 'Einnahmezeit';

  @override
  String doseTime(Object index) {
    return 'Dosis $index Zeit';
  }

  @override
  String get tapToSelectTime => 'Tippen Sie, um eine Zeit zu wählen';

  @override
  String get keepRemindingMeFor => 'Weiter erinnern für';

  @override
  String get reminderWindowExplanation =>
      'Wenn Sie nicht bestätigen, erinnern wir Sie alle 5 Minuten so lange.';

  @override
  String minutesOption(Object minutes) {
    return '$minutes Min';
  }

  @override
  String get medicationDue => 'Medikament fällig';

  @override
  String scheduledFor(Object time) {
    return 'Geplant für $time';
  }

  @override
  String get checkLabel =>
      'Prüfen Sie das Medikamentenetikett vor der Einnahme';

  @override
  String get iveTakenIt => 'Eingenommen';

  @override
  String get remindMeIn10Minutes => 'In 10 Min. erinnern';

  @override
  String get noMedicationsYet => 'Noch keine Medikamente';

  @override
  String get tapAddMedication =>
      'Tippen Sie unten auf \"Medikament hinzufügen\"\num das erste hinzuzufügen.';

  @override
  String get deleteMedication => 'Dieses Medikament löschen?';

  @override
  String deleteConfirmation(Object name) {
    return '$name wird entfernt und seine Erinnerungen stoppen. Nicht rückgängig machbar.';
  }

  @override
  String get keepMedication => 'Medikament behalten';

  @override
  String get delete => 'Löschen';

  @override
  String get remindersMayNotAppear =>
      'Erinnerungen erscheinen evtl. nicht pünktlich.';

  @override
  String get turnOnNotifications => 'Benachrichtigungen aktivieren';

  @override
  String get turnOnExactAlarms => 'Exakte Wecker aktivieren';

  @override
  String remindsEvery5Min(Object minutes) {
    return 'Erinnert alle 5 Min für $minutes Min bei Vergessen';
  }

  @override
  String taken(Object time) {
    return 'Eingenommen · $time';
  }

  @override
  String get validationErrorName => 'Bitte Medikamentennamen eingeben.';

  @override
  String get validationErrorDosage => 'Bitte Dosierung eingeben.';

  @override
  String get validationErrorFirstDose => 'Bitte Zeit der ersten Dosis wählen.';

  @override
  String get validationErrorTime => 'Bitte Zeit wählen.';

  @override
  String get validationErrorAllTimes =>
      'Bitte für jede Dosis eine Zeit festlegen.';

  @override
  String get country => 'Land';

  @override
  String get india => 'Indien';

  @override
  String get unitedStates => 'USA';

  @override
  String get medicineName => 'Medikamentenname';

  @override
  String get typeMedicineName => 'Medikamentennamen eingeben';

  @override
  String get search => 'Suchen';

  @override
  String get searching => 'Suche...';

  @override
  String get isThisYourMedicine => 'Ist das Ihr Medikament?';

  @override
  String get noExactMatch =>
      'Keine exakte Übereinstimmung gefunden. Das ist der nächste Treffer:';

  @override
  String get closestMatch => 'Nächster Treffer';

  @override
  String get yesThisIsMyMedicine => 'Ja, das ist meins';

  @override
  String get noThatIsNotIt => 'Nein, das ist es nicht';

  @override
  String get brandNameYouSearched => 'Gesuchter Markenname';

  @override
  String get medicineMatched => 'Gefundenes Medikament';

  @override
  String get genericActiveIngredient => 'Generikum (Wirkstoff)';

  @override
  String get sameIngredient =>
      'Derselbe Wirkstoff — wirkt im Körper gleich und ist meist günstiger.';

  @override
  String get askPharmacist => 'Fragen Sie Ihren Apotheker nach dem Generikum.';

  @override
  String notFoundIndia(Object brand) {
    return '\" $brand\" nicht gefunden. Schreiben Sie korrekt. Die App deckt eine Startliste gängiger indischer Marken ab — fragen Sie Ihren Apotheker, falls es fehlt.';
  }

  @override
  String notFoundUS(Object brand) {
    return '\" $brand\" nicht gefunden. Schreiben Sie korrekt und versuchen Sie es erneut, oder fragen Sie Ihren Apotheker.';
  }

  @override
  String get couldNotReachService => 'Suchdienst nicht erreichbar';

  @override
  String get checkInternet =>
      'Prüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get forInformationOnly => 'Nur zur Information';

  @override
  String get disclaimerGeneric =>
      'Dieses Tool ist nur informativ, keine medizinische Beratung. \"Derselbe Wirkstoff\" bedeutet gleiche Wirkung im Körper — aber Marken können sich in Hilfsstoffen, Darreichungsform oder Hersteller unterscheiden. Vor Wechsel immer Arzt/Apotheker fragen.';

  @override
  String get openWebsite => 'Website öffnen';

  @override
  String get useFinderAnyDevice =>
      'Nutzen Sie die Suche auf jedem Handy oder PC.';

  @override
  String get aboutPrivacyTooltip => 'Info / Datenschutz';

  @override
  String get permissionBannerTitle =>
      'Erinnerungen erscheinen evtl. nicht pünktlich.';

  @override
  String get notificationPermission => 'Benachrichtigungen aktivieren';

  @override
  String get exactAlarmPermission => 'Exakte Wecker aktivieren';

  @override
  String get timePickerHelpTextSingle => 'Einnahmezeit wählen';

  @override
  String timePickerHelpTextMultiple(Object index) {
    return 'Zeit für Dosis $index wählen';
  }

  @override
  String get saveError => 'Medikament konnte nicht gespeichert werden.';

  @override
  String get dailyReminderTitle => 'Zeit für Ihr Medikament';

  @override
  String dailyReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get snoozeReminderTitle => 'Erinnerung: Zeit für Ihr Medikament';

  @override
  String snoozeReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get repeatReminderTitle => 'Erinnerung: bitte Medikament bestätigen';

  @override
  String repeatReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage - wartet noch auf Bestätigung';
  }

  @override
  String get couldNotOpenPrivacyPolicy =>
      'Datenschutz-Link konnte nicht geöffnet werden.';

  @override
  String get couldNotOpenWebsite => 'Website konnte nicht geöffnet werden.';
}
