// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My Medications';

  @override
  String get welcomeTitle => 'Welcome to MediGuard';

  @override
  String get welcomeDescription =>
      'MediGuard helps you remember to take your medications on time.';

  @override
  String get pleaseRead => 'Please Read';

  @override
  String get disclaimerText =>
      'MediGuard is a reminder tool, not a medical device. It does not provide medical advice and does not guarantee that a medication has been taken. It is not a substitute for a doctor or pharmacist. Always check the medication label before taking any medicine. In an emergency, contact your local emergency services.';

  @override
  String get privacyStatement =>
      'Your information is stored only on your device. We do not collect or share your data.';

  @override
  String get readPrivacyPolicy => 'Read our Privacy Policy';

  @override
  String get getStarted => 'I Understand — Get Started';

  @override
  String get close => 'Close';

  @override
  String get aboutMediGuard => 'About MediGuard';

  @override
  String get myMedications => 'My Medications';

  @override
  String get findGeneric => 'Find Generic';

  @override
  String get addMedication => 'Add Medication';

  @override
  String get editMedication => 'Edit Medication';

  @override
  String get saveMedication => 'Save Medication';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get medicationName => 'Medication Name';

  @override
  String get medicationNameHint => 'e.g. Lisinopril';

  @override
  String get dosage => 'Dosage';

  @override
  String get dosageHint => 'e.g. 500 mg';

  @override
  String get howManyTimesPerDay => 'How Many Times a Day?';

  @override
  String get onceADay => 'Once a day';

  @override
  String get twiceADay => 'Twice a day';

  @override
  String get threeTimesADay => '3 times a day';

  @override
  String get fourTimesADay => '4 times a day';

  @override
  String get fiveTimesADay => '5 times a day';

  @override
  String get setTimesMode => 'How Would You Like to Set the Times?';

  @override
  String get evenIntervals => 'Even Intervals';

  @override
  String get customTimes => 'Custom Times';

  @override
  String get firstDoseTime => 'First Dose Time';

  @override
  String get tapToSelectFirstDose => 'Tap to select the first dose time';

  @override
  String get hoursBetweenDoses => 'Hours Between Doses';

  @override
  String everyHours(
    Object horasPlural,
    Object hours,
    Object hoursPlural,
    Object stundenPlural,
  ) {
    return 'Every $hours hour$hoursPlural';
  }

  @override
  String get calculatedTimesNote =>
      'We calculated these times for you — tap any one below to fine-tune it.';

  @override
  String get timeToTake => 'Time to Take';

  @override
  String doseTime(Object index) {
    return 'Dose $index Time';
  }

  @override
  String get tapToSelectTime => 'Tap to select a time';

  @override
  String get keepRemindingMeFor => 'Keep Reminding Me For';

  @override
  String get reminderWindowExplanation =>
      'If you don\'t confirm, we\'ll remind you every 5 minutes until this much time has passed.';

  @override
  String minutesOption(Object minutes) {
    return '$minutes min';
  }

  @override
  String get medicationDue => 'Medication Due';

  @override
  String scheduledFor(Object time) {
    return 'Scheduled for $time';
  }

  @override
  String get checkLabel => 'Check the medication label before taking it';

  @override
  String get iveTakenIt => 'I\'ve taken it';

  @override
  String get remindMeIn10Minutes => 'Remind Me in 10 Minutes';

  @override
  String get noMedicationsYet => 'No medications yet';

  @override
  String get tapAddMedication =>
      'Tap \"Add Medication\" below\nto add your first one.';

  @override
  String get deleteMedication => 'Delete this medication?';

  @override
  String deleteConfirmation(Object name) {
    return '$name will be removed and its reminders will stop. This cannot be undone.';
  }

  @override
  String get keepMedication => 'Keep Medication';

  @override
  String get delete => 'Delete';

  @override
  String get remindersMayNotAppear => 'Reminders may not appear on time.';

  @override
  String get turnOnNotifications => 'Turn On Notifications';

  @override
  String get turnOnExactAlarms => 'Turn On Exact Alarms';

  @override
  String remindsEvery5Min(Object minutes) {
    return 'Reminds every 5 min for $minutes min if missed';
  }

  @override
  String taken(Object time) {
    return 'Taken · $time';
  }

  @override
  String get validationErrorName => 'Please enter the medication name.';

  @override
  String get validationErrorDosage => 'Please enter the dosage.';

  @override
  String get validationErrorFirstDose =>
      'Please select the time of the first dose.';

  @override
  String get validationErrorTime => 'Please select a time.';

  @override
  String get validationErrorAllTimes => 'Please set a time for every dose.';

  @override
  String get country => 'Country';

  @override
  String get india => 'India';

  @override
  String get unitedStates => 'United States';

  @override
  String get medicineName => 'Medicine Name';

  @override
  String get typeMedicineName => 'Type a medicine name';

  @override
  String get search => 'Search';

  @override
  String get searching => 'Searching...';

  @override
  String get isThisYourMedicine => 'Is this your medicine?';

  @override
  String get noExactMatch =>
      'We could not find an exact match for what you typed. This is the closest medicine name we found:';

  @override
  String get closestMatch => 'Closest match found';

  @override
  String get yesThisIsMyMedicine => 'Yes, this is my medicine';

  @override
  String get noThatIsNotIt => 'No, that is not it';

  @override
  String get brandNameYouSearched => 'Brand name you searched';

  @override
  String get medicineMatched => 'Medicine matched';

  @override
  String get genericActiveIngredient => 'Generic (active ingredient)';

  @override
  String get sameIngredient =>
      'Same active ingredient — it works the same way in the body, and usually costs less.';

  @override
  String get askPharmacist => 'Ask your pharmacist for the generic version.';

  @override
  String notFoundIndia(Object brand) {
    return 'We couldn\'t find \"$brand\". Please check the spelling. This app currently covers a starting list of common Indian brands — ask your pharmacist if this one isn\'t listed yet.';
  }

  @override
  String notFoundUS(Object brand) {
    return 'We couldn\'t find \"$brand\". Please check the spelling and try again, or ask your pharmacist.';
  }

  @override
  String get couldNotReachService => 'Couldn\'t reach the lookup service';

  @override
  String get checkInternet =>
      'Please check your internet connection and try again.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get forInformationOnly => 'For Information Only';

  @override
  String get disclaimerGeneric =>
      'This tool is for information only and is not medical advice. \"Same active ingredient\" means the medicines work the same way in the body — but brands can still differ in inactive ingredients, dose form, or manufacturer. Always confirm with your doctor or pharmacist before switching medicines.';

  @override
  String get openWebsite => 'Open Website';

  @override
  String get useFinderAnyDevice => 'Use the finder on any phone or computer.';

  @override
  String get aboutPrivacyTooltip => 'About / Privacy';

  @override
  String get permissionBannerTitle => 'Reminders may not appear on time.';

  @override
  String get notificationPermission => 'Turn On Notifications';

  @override
  String get exactAlarmPermission => 'Turn On Exact Alarms';

  @override
  String get timePickerHelpTextSingle => 'Select time to take medication';

  @override
  String timePickerHelpTextMultiple(Object index) {
    return 'Select time for dose $index';
  }

  @override
  String get saveError => 'Could not save medication.';

  @override
  String get dailyReminderTitle => 'Time for your medication';

  @override
  String dailyReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get snoozeReminderTitle => 'Reminder: time for your medication';

  @override
  String snoozeReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get repeatReminderTitle => 'Reminder: please confirm your medication';

  @override
  String repeatReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage - still waiting for you to confirm';
  }

  @override
  String get couldNotOpenPrivacyPolicy =>
      'Could not open the privacy policy link.';

  @override
  String get couldNotOpenWebsite => 'Could not open the website.';
}
