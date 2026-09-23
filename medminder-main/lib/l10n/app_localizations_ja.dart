// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '私の薬';

  @override
  String get welcomeTitle => 'MediGuardへようこそ';

  @override
  String get welcomeDescription => 'MediGuardは、お薬を時間通りに服用するのをお手伝いします。';

  @override
  String get pleaseRead => '必ずお読みください';

  @override
  String get disclaimerText =>
      'MediGuardはリマインダーツールであり、医療機器ではありません。医療アドバイスを提供せず、服薬を保証するものでもありません。医師や薬剤師の代わりにはなりません。服薬前には必ず薬のラベルを確認してください。緊急時は地域の救急サービスに連絡してください。';

  @override
  String get privacyStatement => 'お客様の情報はお使いのデバイスにのみ保存されます。データの収集や共有は行いません。';

  @override
  String get readPrivacyPolicy => 'プライバシーポリシーを読む';

  @override
  String get getStarted => '理解しました — 開始する';

  @override
  String get close => '閉じる';

  @override
  String get aboutMediGuard => 'MediGuardについて';

  @override
  String get myMedications => '私の薬';

  @override
  String get findGeneric => 'ジェネリックを探す';

  @override
  String get addMedication => '薬を追加';

  @override
  String get editMedication => '薬を編集';

  @override
  String get saveMedication => '薬を保存';

  @override
  String get saveChanges => '変更を保存';

  @override
  String get medicationName => '薬の名前';

  @override
  String get medicationNameHint => '例: リシノプリル';

  @override
  String get dosage => '用量';

  @override
  String get dosageHint => '例: 500 mg';

  @override
  String get howManyTimesPerDay => '1日何回？';

  @override
  String get onceADay => '1日1回';

  @override
  String get twiceADay => '1日2回';

  @override
  String get threeTimesADay => '1日3回';

  @override
  String get fourTimesADay => '1日4回';

  @override
  String get fiveTimesADay => '1日5回';

  @override
  String get setTimesMode => '時間をどう設定しますか？';

  @override
  String get evenIntervals => '等間隔';

  @override
  String get customTimes => 'カスタム時間';

  @override
  String get firstDoseTime => '初回服用時間';

  @override
  String get tapToSelectFirstDose => 'タップして初回服用時間を選択';

  @override
  String get hoursBetweenDoses => '服用間隔（時間）';

  @override
  String everyHours(
    Object horasPlural,
    Object hours,
    Object hoursPlural,
    Object stundenPlural,
  ) {
    return '$hours時間ごと';
  }

  @override
  String get calculatedTimesNote => '時間を計算しました — タップして微調整できます。';

  @override
  String get timeToTake => '服用時間';

  @override
  String doseTime(Object index) {
    return '第$index回服用時間';
  }

  @override
  String get tapToSelectTime => 'タップして時間を選択';

  @override
  String get keepRemindingMeFor => 'リマインドし続ける';

  @override
  String get reminderWindowExplanation => '確認しない場合、この時間が経過するまで5分ごとにリマインドします。';

  @override
  String minutesOption(Object minutes) {
    return '$minutes分';
  }

  @override
  String get medicationDue => '服用時間です';

  @override
  String scheduledFor(Object time) {
    return '予定時刻: $time';
  }

  @override
  String get checkLabel => '服用前に薬のラベルを確認してください';

  @override
  String get iveTakenIt => '服用しました';

  @override
  String get remindMeIn10Minutes => '10分後にリマインド';

  @override
  String get noMedicationsYet => '薬が登録されていません';

  @override
  String get tapAddMedication => '下の\"薬を追加\"をタップ\n最初の薬を登録してください。';

  @override
  String get deleteMedication => 'この薬を削除しますか？';

  @override
  String deleteConfirmation(Object name) {
    return '$nameが削除され、リマインダーが停止します。元に戻せません。';
  }

  @override
  String get keepMedication => '薬を残す';

  @override
  String get delete => '削除';

  @override
  String get remindersMayNotAppear => 'リマインダーが時間通りに表示されない可能性があります。';

  @override
  String get turnOnNotifications => '通知をオンにする';

  @override
  String get turnOnExactAlarms => '正確なアラームをオンにする';

  @override
  String remindsEvery5Min(Object minutes) {
    return '未確認の場合、$minutes分間5分ごとにリマインド';
  }

  @override
  String taken(Object time) {
    return '服用済み · $time';
  }

  @override
  String get validationErrorName => '薬の名前を入力してください。';

  @override
  String get validationErrorDosage => '用量を入力してください。';

  @override
  String get validationErrorFirstDose => '初回服用時間を選択してください。';

  @override
  String get validationErrorTime => '時間を選択してください。';

  @override
  String get validationErrorAllTimes => 'すべての回の時間を設定してください。';

  @override
  String get country => '国';

  @override
  String get india => 'インド';

  @override
  String get unitedStates => 'アメリカ';

  @override
  String get medicineName => '薬の名前';

  @override
  String get typeMedicineName => '薬の名前を入力';

  @override
  String get search => '検索';

  @override
  String get searching => '検索中...';

  @override
  String get isThisYourMedicine => 'これはあなたの薬ですか？';

  @override
  String get noExactMatch => '完全一致が見つかりませんでした。最も近い薬の名前:';

  @override
  String get closestMatch => '最も近い一致';

  @override
  String get yesThisIsMyMedicine => 'はい、これが私の薬です';

  @override
  String get noThatIsNotIt => 'いいえ、違います';

  @override
  String get brandNameYouSearched => '検索した商品名';

  @override
  String get medicineMatched => '一致した薬';

  @override
  String get genericActiveIngredient => '一般名（有効成分）';

  @override
  String get sameIngredient => '同じ有効成分 — 体内で同じように働き、通常は安価です。';

  @override
  String get askPharmacist => '薬剤師にジェネリック医薬品を相談してください。';

  @override
  String notFoundIndia(Object brand) {
    return '\"$brand\" が見つかりません。スペルを確認してください。このアプリは一般的なインドのブランドの初期リストを対象としています — リストにない場合は薬剤師に相談してください。';
  }

  @override
  String notFoundUS(Object brand) {
    return '\"$brand\" が見つかりません。スペルを確認して再試行するか、薬剤師に相談してください。';
  }

  @override
  String get couldNotReachService => '検索サービスに接続できません';

  @override
  String get checkInternet => 'インターネット接続を確認して再試行してください。';

  @override
  String get tryAgain => '再試行';

  @override
  String get forInformationOnly => '参考情報のみ';

  @override
  String get disclaimerGeneric =>
      'このツールは参考情報のみであり、医療アドバイスではありません。「同じ有効成分」とは体内での働きが同じという意味ですが、添加剤、剤形、製造元が異なる場合があります。薬を変更する前に必ず医師や薬剤師に相談してください。';

  @override
  String get openWebsite => 'ウェブサイトを開く';

  @override
  String get useFinderAnyDevice => 'どのスマホやPCでも検索ツールをご利用いただけます。';

  @override
  String get aboutPrivacyTooltip => 'このアプリについて / プライバシー';

  @override
  String get permissionBannerTitle => 'リマインダーが時間通りに表示されない可能性があります。';

  @override
  String get notificationPermission => '通知をオンにする';

  @override
  String get exactAlarmPermission => '正確なアラームをオンにする';

  @override
  String get timePickerHelpTextSingle => '服薬時間を選択';

  @override
  String timePickerHelpTextMultiple(Object index) {
    return '第$index回服用時間を選択';
  }

  @override
  String get saveError => '薬を保存できませんでした。';

  @override
  String get dailyReminderTitle => 'お薬の時間です';

  @override
  String dailyReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get snoozeReminderTitle => 'リマインダー: お薬の時間です';

  @override
  String snoozeReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get repeatReminderTitle => 'リマインダー: 服薬を確認してください';

  @override
  String repeatReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage - 確認をお待ちしています';
  }

  @override
  String get couldNotOpenPrivacyPolicy => 'プライバシーポリシーのリンクを開けませんでした。';

  @override
  String get couldNotOpenWebsite => 'ウェブサイトを開けませんでした。';
}
