// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Мои лекарства';

  @override
  String get welcomeTitle => 'Добро пожаловать в MediGuard';

  @override
  String get welcomeDescription =>
      'MediGuard помогает вам принимать лекарства вовремя.';

  @override
  String get pleaseRead => 'Пожалуйста, прочитайте';

  @override
  String get disclaimerText =>
      'MediGuard — это инструмент напоминаний, а не медицинское устройство. Он не предоставляет медицинских советов и не гарантирует, что лекарство было принято. Он не заменяет врача или фармацевта. Всегда проверяйте этикетку лекарства перед приемом. В экстренных случаях обращайтесь в местные службы скорой помощи.';

  @override
  String get privacyStatement =>
      'Ваша информация хранится только на вашем устройстве. Мы не собираем и не передаем ваши данные.';

  @override
  String get readPrivacyPolicy => 'Прочитать Политику конфиденциальности';

  @override
  String get getStarted => 'Понятно — Начать';

  @override
  String get close => 'Закрыть';

  @override
  String get aboutMediGuard => 'О MediGuard';

  @override
  String get myMedications => 'Мои лекарства';

  @override
  String get findGeneric => 'Найти дженерик';

  @override
  String get addMedication => 'Добавить лекарство';

  @override
  String get editMedication => 'Редактировать лекарство';

  @override
  String get saveMedication => 'Сохранить лекарство';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get medicationName => 'Название лекарства';

  @override
  String get medicationNameHint => 'напр. Лизиноприл';

  @override
  String get dosage => 'Дозировка';

  @override
  String get dosageHint => 'напр. 500 мг';

  @override
  String get howManyTimesPerDay => 'Сколько раз в день?';

  @override
  String get onceADay => 'Раз в день';

  @override
  String get twiceADay => 'Два раза в день';

  @override
  String get threeTimesADay => '3 раза в день';

  @override
  String get fourTimesADay => '4 раза в день';

  @override
  String get fiveTimesADay => '5 раз в день';

  @override
  String get setTimesMode => 'Как вы хотите установить время?';

  @override
  String get evenIntervals => 'Равные интервалы';

  @override
  String get customTimes => 'Свое время';

  @override
  String get firstDoseTime => 'Время первой дозы';

  @override
  String get tapToSelectFirstDose => 'Нажмите, чтобы выбрать время первой дозы';

  @override
  String get hoursBetweenDoses => 'Часы между дозами';

  @override
  String everyHours(
    Object horasPlural,
    Object hours,
    Object hoursPlural,
    Object stundenPlural,
  ) {
    return 'Каждые $hours часа';
  }

  @override
  String get calculatedTimesNote =>
      'Мы рассчитали эти времена для вас — нажмите на любое, чтобы скорректировать.';

  @override
  String get timeToTake => 'Время приема';

  @override
  String doseTime(Object index) {
    return 'Время дозы $index';
  }

  @override
  String get tapToSelectTime => 'Нажмите, чтобы выбрать время';

  @override
  String get keepRemindingMeFor => 'Продолжать напоминать';

  @override
  String get reminderWindowExplanation =>
      'Если вы не подтвердите, мы будем напоминать каждые 5 минут в течение этого времени.';

  @override
  String minutesOption(Object minutes) {
    return '$minutes мин';
  }

  @override
  String get medicationDue => 'Пора принимать лекарство';

  @override
  String scheduledFor(Object time) {
    return 'Запланировано на $time';
  }

  @override
  String get checkLabel => 'Проверьте этикетку лекарства перед приемом';

  @override
  String get iveTakenIt => 'Я принял';

  @override
  String get remindMeIn10Minutes => 'Напомнить через 10 минут';

  @override
  String get noMedicationsYet => 'Лекарств пока нет';

  @override
  String get tapAddMedication =>
      'Нажмите \"Добавить лекарство\" ниже\nчтобы добавить первое.';

  @override
  String get deleteMedication => 'Удалить это лекарство?';

  @override
  String deleteConfirmation(Object name) {
    return '$name будет удалено, и его напоминания остановятся. Это нельзя отменить.';
  }

  @override
  String get keepMedication => 'Оставить лекарство';

  @override
  String get delete => 'Удалить';

  @override
  String get remindersMayNotAppear => 'Напоминания могут не появиться вовремя.';

  @override
  String get turnOnNotifications => 'Включить уведомления';

  @override
  String get turnOnExactAlarms => 'Включить точные будильники';

  @override
  String remindsEvery5Min(Object minutes) {
    return 'Напоминает каждые 5 мин в течение $minutes мин, если пропущено';
  }

  @override
  String taken(Object time) {
    return 'Принято · $time';
  }

  @override
  String get validationErrorName => 'Введите название лекарства.';

  @override
  String get validationErrorDosage => 'Введите дозировку.';

  @override
  String get validationErrorFirstDose => 'Выберите время первой дозы.';

  @override
  String get validationErrorTime => 'Выберите время.';

  @override
  String get validationErrorAllTimes => 'Установите время для каждой дозы.';

  @override
  String get country => 'Страна';

  @override
  String get india => 'Индия';

  @override
  String get unitedStates => 'США';

  @override
  String get medicineName => 'Название лекарства';

  @override
  String get typeMedicineName => 'Введите название лекарства';

  @override
  String get search => 'Поиск';

  @override
  String get searching => 'Поиск...';

  @override
  String get isThisYourMedicine => 'Это ваше лекарство?';

  @override
  String get noExactMatch =>
      'Точное совпадение не найдено. Это ближайшее название лекарства, которое мы нашли:';

  @override
  String get closestMatch => 'Ближайшее совпадение';

  @override
  String get yesThisIsMyMedicine => 'Да, это мое лекарство';

  @override
  String get noThatIsNotIt => 'Нет, это не оно';

  @override
  String get brandNameYouSearched => 'Искомое торговое название';

  @override
  String get medicineMatched => 'Найденное лекарство';

  @override
  String get genericActiveIngredient => 'Дженерик (действующее вещество)';

  @override
  String get sameIngredient =>
      'То же действующее вещество — действует в организме одинаково и обычно стоит дешевле.';

  @override
  String get askPharmacist => 'Спросите у фармацевта дженерик-версию.';

  @override
  String notFoundIndia(Object brand) {
    return 'Мы не нашли \"$brand\". Проверьте написание. Приложение покрывает начальный список распространенных индийских брендов — спросите фармацевта, если его нет в списке.';
  }

  @override
  String notFoundUS(Object brand) {
    return 'Мы не нашли \"$brand\". Проверьте написание и попробуйте снова, или спросите фармацевта.';
  }

  @override
  String get couldNotReachService => 'Не удалось подключиться к сервису поиска';

  @override
  String get checkInternet =>
      'Проверьте интернет-соединение и попробуйте снова.';

  @override
  String get tryAgain => 'Попробовать снова';

  @override
  String get forInformationOnly => 'Только для информации';

  @override
  String get disclaimerGeneric =>
      'Инструмент только для информации, не медицинский совет. \"То же действующее вещество\" значит, что лекарства действуют одинаково — но бренды могут отличаться вспомогательными веществами, формой выпуска или производителем. Всегда консультируйтесь с врачом или фармацевтом перед заменой.';

  @override
  String get openWebsite => 'Открыть сайт';

  @override
  String get useFinderAnyDevice =>
      'Используйте поиск на любом телефоне или компьютере.';

  @override
  String get aboutPrivacyTooltip => 'О программе / Конфиденциальность';

  @override
  String get permissionBannerTitle => 'Напоминания могут не появиться вовремя.';

  @override
  String get notificationPermission => 'Включить уведомления';

  @override
  String get exactAlarmPermission => 'Включить точные будильники';

  @override
  String get timePickerHelpTextSingle => 'Выберите время приема лекарства';

  @override
  String timePickerHelpTextMultiple(Object index) {
    return 'Выберите время для дозы $index';
  }

  @override
  String get saveError => 'Не удалось сохранить лекарство.';

  @override
  String get dailyReminderTitle => 'Время вашего лекарства';

  @override
  String dailyReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get snoozeReminderTitle => 'Напоминание: время вашего лекарства';

  @override
  String snoozeReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get repeatReminderTitle => 'Напоминание: подтвердите прием лекарства';

  @override
  String repeatReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage — всё ещё ждём вашего подтверждения';
  }

  @override
  String get couldNotOpenPrivacyPolicy =>
      'Не удалось открыть ссылку на политику конфиденциальности.';

  @override
  String get couldNotOpenWebsite => 'Не удалось открыть сайт.';
}
