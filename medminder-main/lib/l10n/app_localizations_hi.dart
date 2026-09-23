// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'मेरी दवाएं';

  @override
  String get welcomeTitle => 'MediGuard में आपका स्वागत है';

  @override
  String get welcomeDescription =>
      'MediGuard आपको समय पर दवा लेने की याद दिलाता है।';

  @override
  String get pleaseRead => 'कृपया पढ़ें';

  @override
  String get disclaimerText =>
      'MediGuard एक रिमाइंडर टूल है, चिकित्सा उपकरण नहीं। यह चिकित्सा सलाह नहीं देता और यह गारंटी नहीं देता कि दवा ली गई है। यह डॉक्टर या फार्मासिस्ट का विकल्प नहीं है। कोई भी दवा लेने से पहले हमेशा लेबल जांचें। आपात स्थिति में स्थानीय आपातकालीन सेवाओं से संपर्क करें।';

  @override
  String get privacyStatement =>
      'आपकी जानकारी केवल आपके डिवाइस पर संग्रहीत है। हम आपका डेटा एकत्र या साझा नहीं करते।';

  @override
  String get readPrivacyPolicy => 'हमारी गोपनीयता नीति पढ़ें';

  @override
  String get getStarted => 'मैं समझता हूँ — शुरू करें';

  @override
  String get close => 'बंद करें';

  @override
  String get aboutMediGuard => 'MediGuard के बारे में';

  @override
  String get myMedications => 'मेरी दवाएं';

  @override
  String get findGeneric => 'जेनेरिक खोजें';

  @override
  String get addMedication => 'दवा जोड़ें';

  @override
  String get editMedication => 'दवा संपादित करें';

  @override
  String get saveMedication => 'दवा सहेजें';

  @override
  String get saveChanges => 'परिवर्तन सहेजें';

  @override
  String get medicationName => 'दवा का नाम';

  @override
  String get medicationNameHint => 'उदाहरण: लिसिनोप्रिल';

  @override
  String get dosage => 'खुराक';

  @override
  String get dosageHint => 'उदाहरण: 500 mg';

  @override
  String get howManyTimesPerDay => 'दिन में कितनी बार?';

  @override
  String get onceADay => 'दिन में एक बार';

  @override
  String get twiceADay => 'दिन में दो बार';

  @override
  String get threeTimesADay => 'दिन में 3 बार';

  @override
  String get fourTimesADay => 'दिन में 4 बार';

  @override
  String get fiveTimesADay => 'दिन में 5 बार';

  @override
  String get setTimesMode => 'आप समय कैसे सेट करना चाहेंगे?';

  @override
  String get evenIntervals => 'समान अंतराल';

  @override
  String get customTimes => 'कस्टम समय';

  @override
  String get firstDoseTime => 'पहली खुराक का समय';

  @override
  String get tapToSelectFirstDose => 'पहली खुराक का समय चुनने के लिए टैप करें';

  @override
  String get hoursBetweenDoses => 'खुराक के बीच घंटे';

  @override
  String everyHours(
    Object horasPlural,
    Object hours,
    Object hoursPlural,
    Object stundenPlural,
  ) {
    return 'हर $hours घंटे';
  }

  @override
  String get calculatedTimesNote =>
      'हमने आपके लिए ये समय गणना किए हैं — समायोजित करने के लिए नीचे किसी पर टैप करें।';

  @override
  String get timeToTake => 'लेने का समय';

  @override
  String doseTime(Object index) {
    return 'खुराक $index का समय';
  }

  @override
  String get tapToSelectTime => 'समय चुनने के लिए टैप करें';

  @override
  String get keepRemindingMeFor => 'मुझे याद दिलाते रहें';

  @override
  String get reminderWindowExplanation =>
      'यदि आप पुष्टि नहीं करते, तो हम आपको हर 5 मिनट में याद दिलाएंगे जब तक यह समय बीत न जाए।';

  @override
  String minutesOption(Object minutes) {
    return '$minutes मिनट';
  }

  @override
  String get medicationDue => 'दवा का समय';

  @override
  String scheduledFor(Object time) {
    return 'निर्धारित: $time';
  }

  @override
  String get checkLabel => 'दवा लेने से पहले लेबल जांचें';

  @override
  String get iveTakenIt => 'मैंने ले ली';

  @override
  String get remindMeIn10Minutes => '10 मिनट में याद दिलाएं';

  @override
  String get noMedicationsYet => 'अभी कोई दवा नहीं';

  @override
  String get tapAddMedication =>
      'नीचे \"दवा जोड़ें\" पर टैप करें\nअपनी पहली दवा जोड़ने के लिए।';

  @override
  String get deleteMedication => 'इस दवा को हटाएं?';

  @override
  String deleteConfirmation(Object name) {
    return '$name हटा दी जाएगी और इसके रिमाइंडर रुक जाएंगे। इसे पूर्ववत नहीं किया जा सकता।';
  }

  @override
  String get keepMedication => 'दवा रखें';

  @override
  String get delete => 'हटाएं';

  @override
  String get remindersMayNotAppear => 'रिमाइंडर समय पर दिखाई नहीं दे सकते।';

  @override
  String get turnOnNotifications => 'सूचनाएं चालू करें';

  @override
  String get turnOnExactAlarms => 'सटीक अलार्म चालू करें';

  @override
  String remindsEvery5Min(Object minutes) {
    return 'यदि छूट जाए तो हर 5 मिनट में $minutes मिनट तक याद दिलाता है';
  }

  @override
  String taken(Object time) {
    return 'लिया · $time';
  }

  @override
  String get validationErrorName => 'कृपया दवा का नाम दर्ज करें।';

  @override
  String get validationErrorDosage => 'कृपया खुराक दर्ज करें।';

  @override
  String get validationErrorFirstDose => 'कृपया पहली खुराक का समय चुनें।';

  @override
  String get validationErrorTime => 'कृपया समय चुनें।';

  @override
  String get validationErrorAllTimes => 'कृपया हर खुराक के लिए समय सेट करें।';

  @override
  String get country => 'देश';

  @override
  String get india => 'भारत';

  @override
  String get unitedStates => 'संयुक्त राज्य';

  @override
  String get medicineName => 'दवा का नाम';

  @override
  String get typeMedicineName => 'दवा का नाम टाइप करें';

  @override
  String get search => 'खोजें';

  @override
  String get searching => 'खोज रहा है...';

  @override
  String get isThisYourMedicine => 'क्या यह आपकी दवा है?';

  @override
  String get noExactMatch =>
      'हमें कोई सटीक मिलान नहीं मिला। यह सबसे निकटतम दवा का नाम है जो हमें मिला:';

  @override
  String get closestMatch => 'सबसे निकटतम मिलान';

  @override
  String get yesThisIsMyMedicine => 'हाँ, यह मेरी दवा है';

  @override
  String get noThatIsNotIt => 'नहीं, यह वह नहीं है';

  @override
  String get brandNameYouSearched => 'आपने जो ब्रांड खोजा';

  @override
  String get medicineMatched => 'मिली हुई दवा';

  @override
  String get genericActiveIngredient => 'जेनेरिक (सक्रिय घटक)';

  @override
  String get sameIngredient =>
      'समान सक्रिय घटक — यह शरीर में उसी तरह काम करता है, और आमतौर पर कम खर्चीला होता है।';

  @override
  String get askPharmacist =>
      'अपने फार्मासिस्ट से जेनेरिक संस्करण के लिए पूछें।';

  @override
  String notFoundIndia(Object brand) {
    return 'हमें \"$brand\" नहीं मिला। वर्तनी जांचें। यह ऐप वर्तमान में सामान्य भारतीय ब्रांडों की एक प्रारंभिक सूची को कवर करता है — यदि यह सूचीबद्ध नहीं है तो अपने फार्मासिस्ट से पूछें।';
  }

  @override
  String notFoundUS(Object brand) {
    return 'हमें \"$brand\" नहीं मिला। वर्तनी जांचें और पुनः प्रयास करें, या अपने फार्मासिस्ट से पूछें।';
  }

  @override
  String get couldNotReachService => 'खोज सेवा तक नहीं पहुंच सके';

  @override
  String get checkInternet =>
      'कृपया अपना इंटरनेट कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get tryAgain => 'फिर कोशिश करें';

  @override
  String get forInformationOnly => 'केवल जानकारी के लिए';

  @override
  String get disclaimerGeneric =>
      'यह उपकरण केवल जानकारी के लिए है और चिकित्सा सलाह नहीं है। \"समान सक्रिय घटक\" का अर्थ है कि दवाएं शरीर में उसी तरह काम करती हैं — लेकिन ब्रांड निष्क्रिय घटकों, खुराक रूप या निर्माता में भिन्न हो सकते हैं। दवा बदलने से पहले हमेशा अपने डॉक्टर या फार्मासिस्ट से पुष्टि करें।';

  @override
  String get openWebsite => 'वेबसाइट खोलें';

  @override
  String get useFinderAnyDevice =>
      'किसी भी फोन या कंप्यूटर पर खोजक का उपयोग करें।';

  @override
  String get aboutPrivacyTooltip => 'बारे में / गोपनीयता';

  @override
  String get permissionBannerTitle => 'रिमाइंडर समय पर दिखाई नहीं दे सकते।';

  @override
  String get notificationPermission => 'सूचनाएं चालू करें';

  @override
  String get exactAlarmPermission => 'सटीक अलार्म चालू करें';

  @override
  String get timePickerHelpTextSingle => 'दवा लेने का समय चुनें';

  @override
  String timePickerHelpTextMultiple(Object index) {
    return 'खुराक $index के लिए समय चुनें';
  }

  @override
  String get saveError => 'दवा सहेजी नहीं जा सकी।';

  @override
  String get dailyReminderTitle => 'आपकी दवा का समय';

  @override
  String dailyReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get snoozeReminderTitle => 'रिमाइंडर: आपकी दवा का समय';

  @override
  String snoozeReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get repeatReminderTitle => 'रिमाइंडर: कृपया अपनी दवा की पुष्टि करें';

  @override
  String repeatReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage - अभी भी आपके पुष्टि करने की प्रतीक्षा है';
  }

  @override
  String get couldNotOpenPrivacyPolicy => 'गोपनीयता नीति लिंक नहीं खोल सके।';

  @override
  String get couldNotOpenWebsite => 'वेबसाइट नहीं खोल सके।';
}
