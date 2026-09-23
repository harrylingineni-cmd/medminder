import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('es'),
    Locale('hi'),
    Locale('ar'),
    Locale('bn'),
    Locale('pt'),
    Locale('ru'),
    Locale('ja'),
    Locale('de'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'My Medications'**
  String get appTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to MediGuard'**
  String get welcomeTitle;

  /// No description provided for @welcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'MediGuard helps you remember to take your medications on time.'**
  String get welcomeDescription;

  /// No description provided for @pleaseRead.
  ///
  /// In en, this message translates to:
  /// **'Please Read'**
  String get pleaseRead;

  /// No description provided for @disclaimerText.
  ///
  /// In en, this message translates to:
  /// **'MediGuard is a reminder tool, not a medical device. It does not provide medical advice and does not guarantee that a medication has been taken. It is not a substitute for a doctor or pharmacist. Always check the medication label before taking any medicine. In an emergency, contact your local emergency services.'**
  String get disclaimerText;

  /// No description provided for @privacyStatement.
  ///
  /// In en, this message translates to:
  /// **'Your information is stored only on your device. We do not collect or share your data.'**
  String get privacyStatement;

  /// No description provided for @readPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read our Privacy Policy'**
  String get readPrivacyPolicy;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'I Understand — Get Started'**
  String get getStarted;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @aboutMediGuard.
  ///
  /// In en, this message translates to:
  /// **'About MediGuard'**
  String get aboutMediGuard;

  /// No description provided for @myMedications.
  ///
  /// In en, this message translates to:
  /// **'My Medications'**
  String get myMedications;

  /// No description provided for @findGeneric.
  ///
  /// In en, this message translates to:
  /// **'Find Generic'**
  String get findGeneric;

  /// No description provided for @addMedication.
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMedication;

  /// No description provided for @editMedication.
  ///
  /// In en, this message translates to:
  /// **'Edit Medication'**
  String get editMedication;

  /// No description provided for @saveMedication.
  ///
  /// In en, this message translates to:
  /// **'Save Medication'**
  String get saveMedication;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @medicationName.
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get medicationName;

  /// No description provided for @medicationNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Lisinopril'**
  String get medicationNameHint;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// No description provided for @dosageHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 500 mg'**
  String get dosageHint;

  /// No description provided for @howManyTimesPerDay.
  ///
  /// In en, this message translates to:
  /// **'How Many Times a Day?'**
  String get howManyTimesPerDay;

  /// No description provided for @onceADay.
  ///
  /// In en, this message translates to:
  /// **'Once a day'**
  String get onceADay;

  /// No description provided for @twiceADay.
  ///
  /// In en, this message translates to:
  /// **'Twice a day'**
  String get twiceADay;

  /// No description provided for @threeTimesADay.
  ///
  /// In en, this message translates to:
  /// **'3 times a day'**
  String get threeTimesADay;

  /// No description provided for @fourTimesADay.
  ///
  /// In en, this message translates to:
  /// **'4 times a day'**
  String get fourTimesADay;

  /// No description provided for @fiveTimesADay.
  ///
  /// In en, this message translates to:
  /// **'5 times a day'**
  String get fiveTimesADay;

  /// No description provided for @setTimesMode.
  ///
  /// In en, this message translates to:
  /// **'How Would You Like to Set the Times?'**
  String get setTimesMode;

  /// No description provided for @evenIntervals.
  ///
  /// In en, this message translates to:
  /// **'Even Intervals'**
  String get evenIntervals;

  /// No description provided for @customTimes.
  ///
  /// In en, this message translates to:
  /// **'Custom Times'**
  String get customTimes;

  /// No description provided for @firstDoseTime.
  ///
  /// In en, this message translates to:
  /// **'First Dose Time'**
  String get firstDoseTime;

  /// No description provided for @tapToSelectFirstDose.
  ///
  /// In en, this message translates to:
  /// **'Tap to select the first dose time'**
  String get tapToSelectFirstDose;

  /// No description provided for @hoursBetweenDoses.
  ///
  /// In en, this message translates to:
  /// **'Hours Between Doses'**
  String get hoursBetweenDoses;

  /// No description provided for @everyHours.
  ///
  /// In en, this message translates to:
  /// **'Every {hours} hour{hoursPlural}'**
  String everyHours(
    Object horasPlural,
    Object hours,
    Object hoursPlural,
    Object stundenPlural,
  );

  /// No description provided for @calculatedTimesNote.
  ///
  /// In en, this message translates to:
  /// **'We calculated these times for you — tap any one below to fine-tune it.'**
  String get calculatedTimesNote;

  /// No description provided for @timeToTake.
  ///
  /// In en, this message translates to:
  /// **'Time to Take'**
  String get timeToTake;

  /// No description provided for @doseTime.
  ///
  /// In en, this message translates to:
  /// **'Dose {index} Time'**
  String doseTime(Object index);

  /// No description provided for @tapToSelectTime.
  ///
  /// In en, this message translates to:
  /// **'Tap to select a time'**
  String get tapToSelectTime;

  /// No description provided for @keepRemindingMeFor.
  ///
  /// In en, this message translates to:
  /// **'Keep Reminding Me For'**
  String get keepRemindingMeFor;

  /// No description provided for @reminderWindowExplanation.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t confirm, we\'ll remind you every 5 minutes until this much time has passed.'**
  String get reminderWindowExplanation;

  /// No description provided for @minutesOption.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesOption(Object minutes);

  /// No description provided for @medicationDue.
  ///
  /// In en, this message translates to:
  /// **'Medication Due'**
  String get medicationDue;

  /// No description provided for @scheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for {time}'**
  String scheduledFor(Object time);

  /// No description provided for @checkLabel.
  ///
  /// In en, this message translates to:
  /// **'Check the medication label before taking it'**
  String get checkLabel;

  /// No description provided for @iveTakenIt.
  ///
  /// In en, this message translates to:
  /// **'I\'ve taken it'**
  String get iveTakenIt;

  /// No description provided for @remindMeIn10Minutes.
  ///
  /// In en, this message translates to:
  /// **'Remind Me in 10 Minutes'**
  String get remindMeIn10Minutes;

  /// No description provided for @noMedicationsYet.
  ///
  /// In en, this message translates to:
  /// **'No medications yet'**
  String get noMedicationsYet;

  /// No description provided for @tapAddMedication.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add Medication\" below\nto add your first one.'**
  String get tapAddMedication;

  /// No description provided for @deleteMedication.
  ///
  /// In en, this message translates to:
  /// **'Delete this medication?'**
  String get deleteMedication;

  /// No description provided for @deleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed and its reminders will stop. This cannot be undone.'**
  String deleteConfirmation(Object name);

  /// No description provided for @keepMedication.
  ///
  /// In en, this message translates to:
  /// **'Keep Medication'**
  String get keepMedication;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @remindersMayNotAppear.
  ///
  /// In en, this message translates to:
  /// **'Reminders may not appear on time.'**
  String get remindersMayNotAppear;

  /// No description provided for @turnOnNotifications.
  ///
  /// In en, this message translates to:
  /// **'Turn On Notifications'**
  String get turnOnNotifications;

  /// No description provided for @turnOnExactAlarms.
  ///
  /// In en, this message translates to:
  /// **'Turn On Exact Alarms'**
  String get turnOnExactAlarms;

  /// No description provided for @remindsEvery5Min.
  ///
  /// In en, this message translates to:
  /// **'Reminds every 5 min for {minutes} min if missed'**
  String remindsEvery5Min(Object minutes);

  /// No description provided for @taken.
  ///
  /// In en, this message translates to:
  /// **'Taken · {time}'**
  String taken(Object time);

  /// No description provided for @validationErrorName.
  ///
  /// In en, this message translates to:
  /// **'Please enter the medication name.'**
  String get validationErrorName;

  /// No description provided for @validationErrorDosage.
  ///
  /// In en, this message translates to:
  /// **'Please enter the dosage.'**
  String get validationErrorDosage;

  /// No description provided for @validationErrorFirstDose.
  ///
  /// In en, this message translates to:
  /// **'Please select the time of the first dose.'**
  String get validationErrorFirstDose;

  /// No description provided for @validationErrorTime.
  ///
  /// In en, this message translates to:
  /// **'Please select a time.'**
  String get validationErrorTime;

  /// No description provided for @validationErrorAllTimes.
  ///
  /// In en, this message translates to:
  /// **'Please set a time for every dose.'**
  String get validationErrorAllTimes;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @india.
  ///
  /// In en, this message translates to:
  /// **'India'**
  String get india;

  /// No description provided for @unitedStates.
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get unitedStates;

  /// No description provided for @medicineName.
  ///
  /// In en, this message translates to:
  /// **'Medicine Name'**
  String get medicineName;

  /// No description provided for @typeMedicineName.
  ///
  /// In en, this message translates to:
  /// **'Type a medicine name'**
  String get typeMedicineName;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @isThisYourMedicine.
  ///
  /// In en, this message translates to:
  /// **'Is this your medicine?'**
  String get isThisYourMedicine;

  /// No description provided for @noExactMatch.
  ///
  /// In en, this message translates to:
  /// **'We could not find an exact match for what you typed. This is the closest medicine name we found:'**
  String get noExactMatch;

  /// No description provided for @closestMatch.
  ///
  /// In en, this message translates to:
  /// **'Closest match found'**
  String get closestMatch;

  /// No description provided for @yesThisIsMyMedicine.
  ///
  /// In en, this message translates to:
  /// **'Yes, this is my medicine'**
  String get yesThisIsMyMedicine;

  /// No description provided for @noThatIsNotIt.
  ///
  /// In en, this message translates to:
  /// **'No, that is not it'**
  String get noThatIsNotIt;

  /// No description provided for @brandNameYouSearched.
  ///
  /// In en, this message translates to:
  /// **'Brand name you searched'**
  String get brandNameYouSearched;

  /// No description provided for @medicineMatched.
  ///
  /// In en, this message translates to:
  /// **'Medicine matched'**
  String get medicineMatched;

  /// No description provided for @genericActiveIngredient.
  ///
  /// In en, this message translates to:
  /// **'Generic (active ingredient)'**
  String get genericActiveIngredient;

  /// No description provided for @sameIngredient.
  ///
  /// In en, this message translates to:
  /// **'Same active ingredient — it works the same way in the body, and usually costs less.'**
  String get sameIngredient;

  /// No description provided for @askPharmacist.
  ///
  /// In en, this message translates to:
  /// **'Ask your pharmacist for the generic version.'**
  String get askPharmacist;

  /// No description provided for @notFoundIndia.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find \"{brand}\". Please check the spelling. This app currently covers a starting list of common Indian brands — ask your pharmacist if this one isn\'t listed yet.'**
  String notFoundIndia(Object brand);

  /// No description provided for @notFoundUS.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find \"{brand}\". Please check the spelling and try again, or ask your pharmacist.'**
  String notFoundUS(Object brand);

  /// No description provided for @couldNotReachService.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the lookup service'**
  String get couldNotReachService;

  /// No description provided for @checkInternet.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get checkInternet;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @forInformationOnly.
  ///
  /// In en, this message translates to:
  /// **'For Information Only'**
  String get forInformationOnly;

  /// No description provided for @disclaimerGeneric.
  ///
  /// In en, this message translates to:
  /// **'This tool is for information only and is not medical advice. \"Same active ingredient\" means the medicines work the same way in the body — but brands can still differ in inactive ingredients, dose form, or manufacturer. Always confirm with your doctor or pharmacist before switching medicines.'**
  String get disclaimerGeneric;

  /// No description provided for @openWebsite.
  ///
  /// In en, this message translates to:
  /// **'Open Website'**
  String get openWebsite;

  /// No description provided for @useFinderAnyDevice.
  ///
  /// In en, this message translates to:
  /// **'Use the finder on any phone or computer.'**
  String get useFinderAnyDevice;

  /// No description provided for @aboutPrivacyTooltip.
  ///
  /// In en, this message translates to:
  /// **'About / Privacy'**
  String get aboutPrivacyTooltip;

  /// No description provided for @permissionBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders may not appear on time.'**
  String get permissionBannerTitle;

  /// No description provided for @notificationPermission.
  ///
  /// In en, this message translates to:
  /// **'Turn On Notifications'**
  String get notificationPermission;

  /// No description provided for @exactAlarmPermission.
  ///
  /// In en, this message translates to:
  /// **'Turn On Exact Alarms'**
  String get exactAlarmPermission;

  /// No description provided for @timePickerHelpTextSingle.
  ///
  /// In en, this message translates to:
  /// **'Select time to take medication'**
  String get timePickerHelpTextSingle;

  /// No description provided for @timePickerHelpTextMultiple.
  ///
  /// In en, this message translates to:
  /// **'Select time for dose {index}'**
  String timePickerHelpTextMultiple(Object index);

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save medication.'**
  String get saveError;

  /// No description provided for @dailyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Time for your medication'**
  String get dailyReminderTitle;

  /// No description provided for @dailyReminderBody.
  ///
  /// In en, this message translates to:
  /// **'{medicationName} - {dosage}'**
  String dailyReminderBody(Object dosage, Object medicationName);

  /// No description provided for @snoozeReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder: time for your medication'**
  String get snoozeReminderTitle;

  /// No description provided for @snoozeReminderBody.
  ///
  /// In en, this message translates to:
  /// **'{medicationName} - {dosage}'**
  String snoozeReminderBody(Object dosage, Object medicationName);

  /// No description provided for @repeatReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder: please confirm your medication'**
  String get repeatReminderTitle;

  /// No description provided for @repeatReminderBody.
  ///
  /// In en, this message translates to:
  /// **'{medicationName} - {dosage} - still waiting for you to confirm'**
  String repeatReminderBody(Object dosage, Object medicationName);

  /// No description provided for @couldNotOpenPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Could not open the privacy policy link.'**
  String get couldNotOpenPrivacyPolicy;

  /// No description provided for @couldNotOpenWebsite.
  ///
  /// In en, this message translates to:
  /// **'Could not open the website.'**
  String get couldNotOpenWebsite;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'de',
    'en',
    'es',
    'hi',
    'id',
    'ja',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
