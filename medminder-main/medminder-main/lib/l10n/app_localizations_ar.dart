// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'أدوتيي';

  @override
  String get welcomeTitle => 'مرحباً بك في MediGuard';

  @override
  String get welcomeDescription =>
      'يساعدك MediGuard على تذكر تناول أدويتك في الوقت المحدد.';

  @override
  String get pleaseRead => 'يرجى القراءة';

  @override
  String get disclaimerText =>
      'MediGuard أداة تذكير، وليس جهازاً طبياً. لا يقدم نصائح طبية ولا يضمن تناول الدواء. لا يغني عن الطبيب أو الصيدلي. تحقق دائماً من ملصق الدواء قبل تناوله. في الطوارئ، اتصل بخدمات الطوارئ المحلية.';

  @override
  String get privacyStatement =>
      'معلوماتك مخزنة فقط على جهازك. لا نجمع ولا نشارك بياناتك.';

  @override
  String get readPrivacyPolicy => 'قراءة سياسة الخصوصية';

  @override
  String get getStarted => 'أفهم — ابدأ';

  @override
  String get close => 'إغلاق';

  @override
  String get aboutMediGuard => 'حول MediGuard';

  @override
  String get myMedications => 'أدوتيي';

  @override
  String get findGeneric => 'البحث عن بديل عام';

  @override
  String get addMedication => 'إضافة دواء';

  @override
  String get editMedication => 'تعديل دواء';

  @override
  String get saveMedication => 'حفظ الدواء';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get medicationName => 'اسم الدواء';

  @override
  String get medicationNameHint => 'مثال: ليسينوبريل';

  @override
  String get dosage => 'الجرعة';

  @override
  String get dosageHint => 'مثال: 500 ملغ';

  @override
  String get howManyTimesPerDay => 'كم مرة في اليوم؟';

  @override
  String get onceADay => 'مرة واحدة يومياً';

  @override
  String get twiceADay => 'مرتين يومياً';

  @override
  String get threeTimesADay => '3 مرات يومياً';

  @override
  String get fourTimesADay => '4 مرات يومياً';

  @override
  String get fiveTimesADay => '5 مرات يومياً';

  @override
  String get setTimesMode => 'كيف تريد تعيين الأوقات؟';

  @override
  String get evenIntervals => 'فواصل منتظمة';

  @override
  String get customTimes => 'أوقات مخصصة';

  @override
  String get firstDoseTime => 'وقت الجرعة الأولى';

  @override
  String get tapToSelectFirstDose => 'اضغط لاختيار وقت الجرعة الأولى';

  @override
  String get hoursBetweenDoses => 'ساعات بين الجرعات';

  @override
  String everyHours(
    Object horasPlural,
    Object hours,
    Object hoursPlural,
    Object stundenPlural,
  ) {
    return 'كل $hours ساعة';
  }

  @override
  String get calculatedTimesNote =>
      'حسبنا هذه الأوقات لك — اضغط على أي منها لضبطه.';

  @override
  String get timeToTake => 'وقت الأخذ';

  @override
  String doseTime(Object index) {
    return 'وقت الجرعة $index';
  }

  @override
  String get tapToSelectTime => 'اضغط لاختيار وقت';

  @override
  String get keepRemindingMeFor => 'استمر في تذكيري لمدة';

  @override
  String get reminderWindowExplanation =>
      'إذا لم تؤكد، سنذكرك كل 5 دقائق حتى تنقضي هذه المدة.';

  @override
  String minutesOption(Object minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get medicationDue => 'حان وقت الدواء';

  @override
  String scheduledFor(Object time) {
    return 'مجدول لـ $time';
  }

  @override
  String get checkLabel => 'تحقق من ملصق الدواء قبل تناوله';

  @override
  String get iveTakenIt => 'لقد تناولته';

  @override
  String get remindMeIn10Minutes => 'ذكرني خلال 10 دقائق';

  @override
  String get noMedicationsYet => 'لا توجد أدوية بعد';

  @override
  String get tapAddMedication =>
      'اضغط على \"إضافة دواء\" أدناه\nلإضافة أول دواء لك.';

  @override
  String get deleteMedication => 'حذف هذا الدواء؟';

  @override
  String deleteConfirmation(Object name) {
    return 'سيتم حذف $name وتتوقف تذكيراته. لا يمكن التراجع.';
  }

  @override
  String get keepMedication => 'الاحتفاظ بالدواء';

  @override
  String get delete => 'حذف';

  @override
  String get remindersMayNotAppear => 'قد لا تظهر التذكيرات في الوقت المحدد.';

  @override
  String get turnOnNotifications => 'تفعيل الإشعارات';

  @override
  String get turnOnExactAlarms => 'تفعيل التنبيهات الدقيقة';

  @override
  String remindsEvery5Min(Object minutes) {
    return 'يذكر كل 5 دقيقة لمدة $minutes دقيقة إذا فاتك';
  }

  @override
  String taken(Object time) {
    return 'تم تناوله · $time';
  }

  @override
  String get validationErrorName => 'يرجى إدخال اسم الدواء.';

  @override
  String get validationErrorDosage => 'يرجى إدخال الجرعة.';

  @override
  String get validationErrorFirstDose => 'يرجى اختيار وقت الجرعة الأولى.';

  @override
  String get validationErrorTime => 'يرجى اختيار وقت.';

  @override
  String get validationErrorAllTimes => 'يرجى تعيين وقت لكل جرعة.';

  @override
  String get country => 'البلد';

  @override
  String get india => 'الهند';

  @override
  String get unitedStates => 'الولايات المتحدة';

  @override
  String get medicineName => 'اسم الدواء';

  @override
  String get typeMedicineName => 'اكتب اسم دواء';

  @override
  String get search => 'بحث';

  @override
  String get searching => 'جاري البحث...';

  @override
  String get isThisYourMedicine => 'هل هذا دواؤك؟';

  @override
  String get noExactMatch => 'لم نجد تطابقاً دقيقاً. هذا أقرب اسم دواء وجدناه:';

  @override
  String get closestMatch => 'أقرب تطابق';

  @override
  String get yesThisIsMyMedicine => 'نعم، هذا دوائي';

  @override
  String get noThatIsNotIt => 'لا، هذا ليس هو';

  @override
  String get brandNameYouSearched => 'الاسم التجاري الذي بحثت عنه';

  @override
  String get medicineMatched => 'الدواء المطابق';

  @override
  String get genericActiveIngredient => 'الاسم العام (المادة الفعالة)';

  @override
  String get sameIngredient =>
      'نفس المادة الفعالة — تعمل بنفس الطريقة في الجسم، وعادة ما تكلف أقل.';

  @override
  String get askPharmacist => 'اسأل الصيدلي عن النسخة العامة.';

  @override
  String notFoundIndia(Object brand) {
    return 'لم نجد \"$brand\". تحقق من الإملاء. يغطي هذا التطبيق قائمة أولية بالعلامات التجارية الهندية الشائعة — اسأل الصيدلي إذا لم تكن مدرجة.';
  }

  @override
  String notFoundUS(Object brand) {
    return 'لم نجد \"$brand\". تحقق من الإملاء وحاول مرة أخرى، أو اسأل الصيدلي.';
  }

  @override
  String get couldNotReachService => 'تعذر الوصول لخدمة البحث';

  @override
  String get checkInternet =>
      'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get forInformationOnly => 'للمعلومية فقط';

  @override
  String get disclaimerGeneric =>
      'هذه الأداة للمعلومات فقط وليست نصيحة طبية. \"نفس المادة الفعالة\" يعني أن الأدوية تعمل بنفس الطريقة في الجسم — لكن العلامات التجارية قد تختلف في المكونات غير النشطة أو شكل الجرعة أو الشركة المصنعة. استشر طبيبك أو صيدليك دائماً قبل تغيير الدواء.';

  @override
  String get openWebsite => 'فتح الموقع';

  @override
  String get useFinderAnyDevice => 'استخدم أداة البحث على أي هاتف أو كمبيوتر.';

  @override
  String get aboutPrivacyTooltip => 'حول / الخصوصية';

  @override
  String get permissionBannerTitle => 'قد لا تظهر التذكيرات في الوقت المحدد.';

  @override
  String get notificationPermission => 'تفعيل الإشعارات';

  @override
  String get exactAlarmPermission => 'تفعيل التنبيهات الدقيقة';

  @override
  String get timePickerHelpTextSingle => 'اختر وقت تناول الدواء';

  @override
  String timePickerHelpTextMultiple(Object index) {
    return 'اختر وقت الجرعة $index';
  }

  @override
  String get saveError => 'تعذر حفظ الدواء.';

  @override
  String get dailyReminderTitle => 'حان وقت دوائك';

  @override
  String dailyReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get snoozeReminderTitle => 'تذكير: حان وقت دوائك';

  @override
  String snoozeReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get repeatReminderTitle => 'تذكير: يرجى تأكيد دوائك';

  @override
  String repeatReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage - لا يزال بانتظار تأكيدك';
  }

  @override
  String get couldNotOpenPrivacyPolicy => 'تعذر فتح رابط سياسة الخصوصية.';

  @override
  String get couldNotOpenWebsite => 'تعذر فتح الموقع.';
}
