// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'আমার ঔষধ';

  @override
  String get welcomeTitle => 'MediGuard-এ স্বাগতম';

  @override
  String get welcomeDescription =>
      'MediGuard আপনাকে সময়ে ঔষধ খাওয়ার কথা মনে করিয়ে দেয়।';

  @override
  String get pleaseRead => 'দয়া করে পড়ুন';

  @override
  String get disclaimerText =>
      'MediGuard একটি রিমাইন্ডার টুল, চিকিৎসা যন্ত্র নয়। এটি চিকিৎসা পরামর্শ দেয় না এবং ঔষধ খাওয়া হয়েছে কিনা তা নিশ্চিত করে না। এটি ডাক্তার বা ফার্মাসিস্টের বিকল্প নয়। যেকোনো ঔষধ খাওয়ার আগে সবসময় লেবেল যাচাই করুন। জরুরি পরিস্থিতিতে স্থানীয় জরুরি সেবার সাথে যোগাযোগ করুন।';

  @override
  String get privacyStatement =>
      'আপনার তথ্য শুধুমাত্র আপনার ডিভাইসে সংরক্ষিত থাকে। আমরা আপনার ডেটা সংগ্রহ বা শেয়ার করি না।';

  @override
  String get readPrivacyPolicy => 'আমাদের গোপনীয়তা নীতি পড়ুন';

  @override
  String get getStarted => 'আমি বুঝেছি — শুরু করুন';

  @override
  String get close => 'বন্ধ করুন';

  @override
  String get aboutMediGuard => 'MediGuard সম্পর্কে';

  @override
  String get myMedications => 'আমার ঔষধ';

  @override
  String get findGeneric => 'জেনেরিক খুঁজুন';

  @override
  String get addMedication => 'ঔষধ যোগ করুন';

  @override
  String get editMedication => 'ঔষধ সম্পাদনা করুন';

  @override
  String get saveMedication => 'ঔষধ সংরক্ষণ করুন';

  @override
  String get saveChanges => 'পরিবর্তন সংরক্ষণ করুন';

  @override
  String get medicationName => 'ঔষধের নাম';

  @override
  String get medicationNameHint => 'যেমন: লিসিনোপ্রিল';

  @override
  String get dosage => 'ডোজ';

  @override
  String get dosageHint => 'যেমন: ৫০০ মিগ্রা';

  @override
  String get howManyTimesPerDay => 'দিনে কতবার?';

  @override
  String get onceADay => 'দিনে একবার';

  @override
  String get twiceADay => 'দিনে দুবার';

  @override
  String get threeTimesADay => 'দিনে ৩ বার';

  @override
  String get fourTimesADay => 'দিনে ৪ বার';

  @override
  String get fiveTimesADay => 'দিনে ৫ বার';

  @override
  String get setTimesMode => 'আপনি কিভাবে সময় নির্ধারণ করতে চান?';

  @override
  String get evenIntervals => 'সমান ব্যবধান';

  @override
  String get customTimes => 'কাস্টম সময়';

  @override
  String get firstDoseTime => 'প্রথম ডোজের সময়';

  @override
  String get tapToSelectFirstDose =>
      'প্রথম ডোজের সময় নির্বাচন করতে ট্যাপ করুন';

  @override
  String get hoursBetweenDoses => 'ডোজের মাঝপথে ঘন্টা';

  @override
  String everyHours(
    Object horasPlural,
    Object hours,
    Object hoursPlural,
    Object stundenPlural,
  ) {
    return 'প্রতি $hours ঘন্টা';
  }

  @override
  String get calculatedTimesNote =>
      'আমরা আপনার জন্য এই সময়গুলো हिसাব করে দিয়েছি — যেকোনো একটি ট্যাপ করে ফাইন-টিউন করুন।';

  @override
  String get timeToTake => 'খাওয়ার সময়';

  @override
  String doseTime(Object index) {
    return 'ডোজ $index-এর সময়';
  }

  @override
  String get tapToSelectTime => 'সময় নির্বাচন করতে ট্যাপ করুন';

  @override
  String get keepRemindingMeFor => 'আমাকে মনে করিয়ে দিন';

  @override
  String get reminderWindowExplanation =>
      'আপনি কনফার্ম না করলে, আমরা প্রতি ৫ মিনিটে মনে করিয়ে দিব এই সময় পর্যন্ত।';

  @override
  String minutesOption(Object minutes) {
    return '$minutes মিনিট';
  }

  @override
  String get medicationDue => 'ঔষধের সময়';

  @override
  String scheduledFor(Object time) {
    return 'নির্ধারিত: $time';
  }

  @override
  String get checkLabel => 'ঔষধ খাওয়ার আগে লেবেল যাচাই করুন';

  @override
  String get iveTakenIt => 'আমি খেয়েছি';

  @override
  String get remindMeIn10Minutes => '১০ মিনিট পর মনে করিয়ে দিন';

  @override
  String get noMedicationsYet => 'এখনো কোন ঔষধ নেই';

  @override
  String get tapAddMedication =>
      'নিচে \"ঔষধ যোগ করুন\"-এ ট্যাপ করুন\nআপনার প্রথম ঔষধ যোগ করতে।';

  @override
  String get deleteMedication => 'এই ঔষধটি মুছুন?';

  @override
  String deleteConfirmation(Object name) {
    return '$name মুছে যাবে এবং এর রিমাইন্ডার বন্ধ হয়ে যাবে। এটি অনড় করা যাবে না।';
  }

  @override
  String get keepMedication => 'ঔষধ রাখুন';

  @override
  String get delete => 'মুছুন';

  @override
  String get remindersMayNotAppear => 'রিমাইন্ডার সময়মতো দেখাবে না।';

  @override
  String get turnOnNotifications => 'বিজ্ঞপ্তি চালু করুন';

  @override
  String get turnOnExactAlarms => 'সঠিক অ্যালার্ম চালু করুন';

  @override
  String remindsEvery5Min(Object minutes) {
    return 'ভুলে গেলে প্রতি ৫ মিনিটে $minutes মিনিট পর্যন্ত মনে করিয়ে দেয়';
  }

  @override
  String taken(Object time) {
    return 'খেয়েছি · $time';
  }

  @override
  String get validationErrorName => 'দয়া করে ঔষধের নাম লিখুন।';

  @override
  String get validationErrorDosage => 'দয়া করে ডোজ লিখুন।';

  @override
  String get validationErrorFirstDose =>
      'দয়া করে প্রথম ডোজের সময় নির্বাচন করুন।';

  @override
  String get validationErrorTime => 'দয়া করে সময় নির্বাচন করুন।';

  @override
  String get validationErrorAllTimes =>
      'প্রতিটি ডোজের জন্য সময় নির্ধারণ করুন।';

  @override
  String get country => 'দেশ';

  @override
  String get india => 'ভারত';

  @override
  String get unitedStates => 'সংযুক্ত রাষ্ট্র';

  @override
  String get medicineName => 'ঔষধের নাম';

  @override
  String get typeMedicineName => 'ঔষধের নাম লিখুন';

  @override
  String get search => 'খুঁজুন';

  @override
  String get searching => 'খুঁজছে...';

  @override
  String get isThisYourMedicine => 'কি এটি আপনার ঔষধ?';

  @override
  String get noExactMatch =>
      'আমরা সঠিক মিল খুঁজে পাইনি। এটি সবচেয়ে কাছাকাছি ঔষধের নাম যা আমরা পেয়েছি:';

  @override
  String get closestMatch => 'সর্বোচ্চ মিল';

  @override
  String get yesThisIsMyMedicine => 'হ্যাঁ, এটি আমার ঔষধ';

  @override
  String get noThatIsNotIt => 'না, এটি সেটা নয়';

  @override
  String get brandNameYouSearched => 'আপনি যা খুঁজেছেন তার ব্র্যান্ডের নাম';

  @override
  String get medicineMatched => 'মেলানো ঔষধ';

  @override
  String get genericActiveIngredient => 'জেনেরিক (সক্রিয় উপাদান)';

  @override
  String get sameIngredient =>
      'একই সক্রিয় উপাদান — এটি শরীরে একইভাবে কাজ করে, এবং সাধারণত সস্তা।';

  @override
  String get askPharmacist => 'আপনার ফার্মাসিস্ট থেকে জেনেরিক ভার্সন চান।';

  @override
  String notFoundIndia(Object brand) {
    return 'আমরা \"$brand\" খুঁজে পাইনি। বানান যাচাই করুন। এই অ্যাপটি ফिलহাল সাধারণ ভারতীয় ব্র্যান্ডের একটি প্রাথমিক তালিকা কভার করে — যদি এটি তালিকাভুক্ত না থাকে তবে আপনার ফার্মাসিস্টে জিজ্ঞাসা করুন।';
  }

  @override
  String notFoundUS(Object brand) {
    return 'আমরা \"$brand\" খুঁজে পাইনি। বানান যাচাই করুন এবং আবার চেষ্টা করুন, অথবা আপনার ফার্মাসিস্টে জিজ্ঞাসা করুন।';
  }

  @override
  String get couldNotReachService => 'খোঁজা পরিষেবায় পৌঁছানো যায়নি';

  @override
  String get checkInternet =>
      'দয়া করে আপনার ইন্টারনেট সংযোগ যাচাই করুন এবং আবার চেষ্টা করুন।';

  @override
  String get tryAgain => 'আবার চেষ্টা করুন';

  @override
  String get forInformationOnly => 'শুধু তথ্যের জন্য';

  @override
  String get disclaimerGeneric =>
      'এই টুলটি শুধুমাত্র তথ্যের জন্য, চিকিৎসা পরামর্শ নয়। \"একই সক্রিয় উপাদান\" বলতে বোঝায় ঔষধগুলো শরীরে একইভাবে কাজ করে — কিন্তু ব্র্যান্ডগুলো অক্রিয় উপাদান, ডোজ রূপ, বা নির্মাতায় ভিন্ন হতে পারে। ঔষধ পরিবর্তন করার আগে সর্বদা আপনার ডাক্তার বা ফার্মাসিস্টের সাথে পরামর্শ করুন।';

  @override
  String get openWebsite => 'ওয়েবসাইট খুলুন';

  @override
  String get useFinderAnyDevice =>
      'যেকোনো ফোন বা কম্পিউটারে খোঁজা টুলটি ব্যবহার করুন।';

  @override
  String get aboutPrivacyTooltip => 'সম্পর্কে / গোপনীয়তা';

  @override
  String get permissionBannerTitle => 'রিমাইন্ডার সময়মতো দেখাবে না।';

  @override
  String get notificationPermission => 'বিজ্ঞপ্তি চালু করুন';

  @override
  String get exactAlarmPermission => 'সঠিক অ্যালার্ম চালু করুন';

  @override
  String get timePickerHelpTextSingle => 'ঔষধ খাওয়ার সময় নির্বাচন করুন';

  @override
  String timePickerHelpTextMultiple(Object index) {
    return 'ডোজ $index-এর জন্য সময় নির্বাচন করুন';
  }

  @override
  String get saveError => 'ঔষধ সংরক্ষণ করা যায়নি।';

  @override
  String get dailyReminderTitle => 'আপনার ঔষধের সময়';

  @override
  String dailyReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get snoozeReminderTitle => 'রিমাইন্ডার: আপনার ঔষধের সময়';

  @override
  String snoozeReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get repeatReminderTitle =>
      'রিমাইন্ডার: দয়া করে আপনার ঔষধ কনফার্ম করুন';

  @override
  String repeatReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage - এখনও আপনার কনফার্মেশনের অপেক্ষায়';
  }

  @override
  String get couldNotOpenPrivacyPolicy => 'গোপনীয়তা নীতির লিংক খুলা যায়নি।';

  @override
  String get couldNotOpenWebsite => 'ওয়েবসাইট খুলা যায়নি।';
}
