// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '我的药物';

  @override
  String get welcomeTitle => '欢迎使用 MediGuard';

  @override
  String get welcomeDescription => 'MediGuard 帮助您准时服药。';

  @override
  String get pleaseRead => '请阅读';

  @override
  String get disclaimerText =>
      'MediGuard 是提醒工具，非医疗设备。它不提供医疗建议，也不保证药物已被服用。它不能替代医生或药剂师。服药前请务必核对药品标签。紧急情况请联系当地急救服务。';

  @override
  String get privacyStatement => '您的信息仅存储在您的设备上。我们不收集或分享您的数据。';

  @override
  String get readPrivacyPolicy => '阅读隐私政策';

  @override
  String get getStarted => '我明白 — 开始使用';

  @override
  String get close => '关闭';

  @override
  String get aboutMediGuard => '关于 MediGuard';

  @override
  String get myMedications => '我的药物';

  @override
  String get findGeneric => '查找通用名';

  @override
  String get addMedication => '添加药物';

  @override
  String get editMedication => '编辑药物';

  @override
  String get saveMedication => '保存药物';

  @override
  String get saveChanges => '保存更改';

  @override
  String get medicationName => '药物名称';

  @override
  String get medicationNameHint => '例如：赖诺普利';

  @override
  String get dosage => '剂量';

  @override
  String get dosageHint => '例如：500 mg';

  @override
  String get howManyTimesPerDay => '每天服用几次？';

  @override
  String get onceADay => '每天一次';

  @override
  String get twiceADay => '每天两次';

  @override
  String get threeTimesADay => '每天三次';

  @override
  String get fourTimesADay => '每天四次';

  @override
  String get fiveTimesADay => '每天五次';

  @override
  String get setTimesMode => '您想如何设置时间？';

  @override
  String get evenIntervals => '等间隔';

  @override
  String get customTimes => '自定义时间';

  @override
  String get firstDoseTime => '首次服药时间';

  @override
  String get tapToSelectFirstDose => '点击选择首次服药时间';

  @override
  String get hoursBetweenDoses => '剂量间隔小时数';

  @override
  String everyHours(
    Object horasPlural,
    Object hours,
    Object hoursPlural,
    Object stundenPlural,
  ) {
    return '每 $hours 小时';
  }

  @override
  String get calculatedTimesNote => '我们为您计算了这些时间 — 点击下方任意一项可微调。';

  @override
  String get timeToTake => '服药时间';

  @override
  String doseTime(Object index) {
    return '第 $index 次服药时间';
  }

  @override
  String get tapToSelectTime => '点击选择时间';

  @override
  String get keepRemindingMeFor => '继续提醒我';

  @override
  String get reminderWindowExplanation => '如果您未确认，我们将每 5 分钟提醒一次，持续您设定的时长。';

  @override
  String minutesOption(Object minutes) {
    return '$minutes 分钟';
  }

  @override
  String get medicationDue => '该服药了';

  @override
  String scheduledFor(Object time) {
    return '预定时间：$time';
  }

  @override
  String get checkLabel => '服药前请核对药品标签';

  @override
  String get iveTakenIt => '我已服用';

  @override
  String get remindMeIn10Minutes => '10 分钟后再提醒';

  @override
  String get noMedicationsYet => '暂无药物';

  @override
  String get tapAddMedication => '点击下方\"添加药物\"\n添加您的第一种药物。';

  @override
  String get deleteMedication => '删除此药物？';

  @override
  String deleteConfirmation(Object name) {
    return '$name 将被移除，其提醒将停止。此操作无法撤销。';
  }

  @override
  String get keepMedication => '保留药物';

  @override
  String get delete => '删除';

  @override
  String get remindersMayNotAppear => '提醒可能无法准时显示。';

  @override
  String get turnOnNotifications => '开启通知权限';

  @override
  String get turnOnExactAlarms => '开启精确闹钟权限';

  @override
  String remindsEvery5Min(Object minutes) {
    return '若未确认，每 5 分钟提醒一次，持续 $minutes 分钟';
  }

  @override
  String taken(Object time) {
    return '已服用 · $time';
  }

  @override
  String get validationErrorName => '请输入药物名称。';

  @override
  String get validationErrorDosage => '请输入剂量。';

  @override
  String get validationErrorFirstDose => '请选择首次服药时间。';

  @override
  String get validationErrorTime => '请选择时间。';

  @override
  String get validationErrorAllTimes => '请为每次服药设置时间。';

  @override
  String get country => '国家';

  @override
  String get india => '印度';

  @override
  String get unitedStates => '美国';

  @override
  String get medicineName => '药品名称';

  @override
  String get typeMedicineName => '输入药品名称';

  @override
  String get search => '搜索';

  @override
  String get searching => '搜索中...';

  @override
  String get isThisYourMedicine => '这是您的药吗？';

  @override
  String get noExactMatch => '未找到完全匹配。我们找到的最接近的药品名称是：';

  @override
  String get closestMatch => '找到的最接近匹配';

  @override
  String get yesThisIsMyMedicine => '是的，这是我的药';

  @override
  String get noThatIsNotIt => '不，这不是';

  @override
  String get brandNameYouSearched => '您搜索的品牌名';

  @override
  String get medicineMatched => '匹配的药品';

  @override
  String get genericActiveIngredient => '通用名（有效成分）';

  @override
  String get sameIngredient => '相同有效成分 — 在体内作用相同，通常价格更低。';

  @override
  String get askPharmacist => '请向药剂师咨询通用名版本。';

  @override
  String notFoundIndia(Object brand) {
    return '未找到“$brand”。请检查拼写。本应用目前涵盖常见印度品牌的初始列表 — 若未列出，请咨询药剂师。';
  }

  @override
  String notFoundUS(Object brand) {
    return '未找到“$brand”。请检查拼写并重试，或咨询药剂师。';
  }

  @override
  String get couldNotReachService => '无法连接查询服务';

  @override
  String get checkInternet => '请检查网络连接并重试。';

  @override
  String get tryAgain => '重试';

  @override
  String get forInformationOnly => '仅供参考';

  @override
  String get disclaimerGeneric =>
      '本工具仅供参考，不构成医疗建议。“相同有效成分”指药物在体内作用方式相同 — 但品牌间可能在非活性成分、剂型或制造商上有差异。换药前请务必咨询医生或药剂师。';

  @override
  String get openWebsite => '打开网站';

  @override
  String get useFinderAnyDevice => '可在任何手机或电脑上使用查找器。';

  @override
  String get aboutPrivacyTooltip => '关于 / 隐私';

  @override
  String get permissionBannerTitle => '提醒可能无法准时显示。';

  @override
  String get notificationPermission => '开启通知权限';

  @override
  String get exactAlarmPermission => '开启精确闹钟权限';

  @override
  String get timePickerHelpTextSingle => '选择服药时间';

  @override
  String timePickerHelpTextMultiple(Object index) {
    return '选择第 $index 次服药时间';
  }

  @override
  String get saveError => '无法保存药物。';

  @override
  String get dailyReminderTitle => '该服药了';

  @override
  String dailyReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get snoozeReminderTitle => '提醒：该服药了';

  @override
  String snoozeReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get repeatReminderTitle => '提醒：请确认您的药物';

  @override
  String repeatReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage - 仍在等待您确认';
  }

  @override
  String get couldNotOpenPrivacyPolicy => '无法打开隐私政策链接。';

  @override
  String get couldNotOpenWebsite => '无法打开网站。';
}
