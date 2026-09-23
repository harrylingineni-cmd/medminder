// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Obat Saya';

  @override
  String get welcomeTitle => 'Selamat Datang di MediGuard';

  @override
  String get welcomeDescription =>
      'MediGuard membantu Anda ingat minum obat tepat waktu.';

  @override
  String get pleaseRead => 'Harap Baca';

  @override
  String get disclaimerText =>
      'MediGuard adalah alat pengingat, bukan alat medis. Ini tidak memberikan saran medis dan tidak menjamin obat diminum. Ini bukan pengganti dokter atau apoteker. Selalu cek label obat sebelum diminum. Darurat: hubungi layanan darurat setempat.';

  @override
  String get privacyStatement =>
      'Data Anda hanya disimpan di perangkat. Kami tidak mengumpulkan atau membagikan data.';

  @override
  String get readPrivacyPolicy => 'Baca Kebijakan Privasi';

  @override
  String get getStarted => 'Saya Mengerti — Mulai';

  @override
  String get close => 'Tutup';

  @override
  String get aboutMediGuard => 'Tentang MediGuard';

  @override
  String get myMedications => 'Obat Saya';

  @override
  String get findGeneric => 'Cari Generik';

  @override
  String get addMedication => 'Tambah Obat';

  @override
  String get editMedication => 'Edit Obat';

  @override
  String get saveMedication => 'Simpan Obat';

  @override
  String get saveChanges => 'Simpan Perubahan';

  @override
  String get medicationName => 'Nama Obat';

  @override
  String get medicationNameHint => 'cth. Lisinopril';

  @override
  String get dosage => 'Dosis';

  @override
  String get dosageHint => 'cth. 500 mg';

  @override
  String get howManyTimesPerDay => 'Berapa Kali Sehari?';

  @override
  String get onceADay => 'Sekali sehari';

  @override
  String get twiceADay => 'Dua kali sehari';

  @override
  String get threeTimesADay => '3 kali sehari';

  @override
  String get fourTimesADay => '4 kali sehari';

  @override
  String get fiveTimesADay => '5 kali sehari';

  @override
  String get setTimesMode => 'Bagaimana Anda Ingin Mengatur Waktu?';

  @override
  String get evenIntervals => 'Interval Sama';

  @override
  String get customTimes => 'Waktu Kustom';

  @override
  String get firstDoseTime => 'Waktu Dosis Pertama';

  @override
  String get tapToSelectFirstDose => 'Sentuh untuk pilih waktu dosis pertama';

  @override
  String get hoursBetweenDoses => 'Jam Antara Dosis';

  @override
  String everyHours(
    Object horasPlural,
    Object hours,
    Object hoursPlural,
    Object stundenPlural,
  ) {
    return 'Setiap $hours jam';
  }

  @override
  String get calculatedTimesNote =>
      'Kami hitung waktunya — sentuh untuk sesuaikan.';

  @override
  String get timeToTake => 'Waktu Minum';

  @override
  String doseTime(Object index) {
    return 'Waktu Dosis $index';
  }

  @override
  String get tapToSelectTime => 'Sentuh untuk pilih waktu';

  @override
  String get keepRemindingMeFor => 'Terus Ingatkan Saya Selama';

  @override
  String get reminderWindowExplanation =>
      'Jika tidak konfirmasi, kami ingatkan tiap 5 menit sampai waktu ini habis.';

  @override
  String minutesOption(Object minutes) {
    return '$minutes menit';
  }

  @override
  String get medicationDue => 'Waktu Minum Obat';

  @override
  String scheduledFor(Object time) {
    return 'Dijadwalkan $time';
  }

  @override
  String get checkLabel => 'Cek label obat sebelum diminum';

  @override
  String get iveTakenIt => 'Sudah diminum';

  @override
  String get remindMeIn10Minutes => 'Ingatkan 10 Menit Lagi';

  @override
  String get noMedicationsYet => 'Belum ada obat';

  @override
  String get tapAddMedication =>
      'Sentuh \"Tambah Obat\" di bawah\nuntuk tambah obat pertama.';

  @override
  String get deleteMedication => 'Hapus obat ini?';

  @override
  String deleteConfirmation(Object name) {
    return '$name akan dihapus dan pengingatnya berhenti. Tidak bisa dibatalkan.';
  }

  @override
  String get keepMedication => 'Simpan Obat';

  @override
  String get delete => 'Hapus';

  @override
  String get remindersMayNotAppear =>
      'Pengingat mungkin tidak muncul tepat waktu.';

  @override
  String get turnOnNotifications => 'Nyalakan Notifikasi';

  @override
  String get turnOnExactAlarms => 'Nyalakan Alarm Tepat';

  @override
  String remindsEvery5Min(Object minutes) {
    return 'Mengingat tiap 5 menit selama $minutes menit jika lupa';
  }

  @override
  String taken(Object time) {
    return 'Diminum · $time';
  }

  @override
  String get validationErrorName => 'Masukkan nama obat.';

  @override
  String get validationErrorDosage => 'Masukkan dosis.';

  @override
  String get validationErrorFirstDose => 'Pilih waktu dosis pertama.';

  @override
  String get validationErrorTime => 'Pilih waktu.';

  @override
  String get validationErrorAllTimes => 'Atur waktu untuk setiap dosis.';

  @override
  String get country => 'Negara';

  @override
  String get india => 'India';

  @override
  String get unitedStates => 'Amerika Serikat';

  @override
  String get medicineName => 'Nama Obat';

  @override
  String get typeMedicineName => 'Ketik nama obat';

  @override
  String get search => 'Cari';

  @override
  String get searching => 'Mencari...';

  @override
  String get isThisYourMedicine => 'Apakah ini obat Anda?';

  @override
  String get noExactMatch => 'Tidak ketemu yang persis. Ini yang paling mirip:';

  @override
  String get closestMatch => 'Paling mirip';

  @override
  String get yesThisIsMyMedicine => 'Ya, ini obat saya';

  @override
  String get noThatIsNotIt => 'Bukan, itu bukan';

  @override
  String get brandNameYouSearched => 'Merek yang dicari';

  @override
  String get medicineMatched => 'Obat ditemukan';

  @override
  String get genericActiveIngredient => 'Generik (bahan aktif)';

  @override
  String get sameIngredient =>
      'Bahan aktif sama — cara kerja di tubuh sama, biasanya lebih murah.';

  @override
  String get askPharmacist => 'Tanya apoteker untuk versi generiknya.';

  @override
  String notFoundIndia(Object brand) {
    return '\" $brand\" tidak ditemukan. Cek ejaan. Aplikasi ini daftar awal merek India umum — tanya apoteker kalau tidak terdaftar.';
  }

  @override
  String notFoundUS(Object brand) {
    return '\" $brand\" tidak ditemukan. Cek ejaan dan coba lagi, atau tanya apoteker.';
  }

  @override
  String get couldNotReachService => 'Tidak bisa hubungi layanan pencarian';

  @override
  String get checkInternet => 'Cek koneksi internet dan coba lagi.';

  @override
  String get tryAgain => 'Coba Lagi';

  @override
  String get forInformationOnly => 'Hanya Untuk Info';

  @override
  String get disclaimerGeneric =>
      'Alat ini hanya info, bukan saran medis. \"Bahan aktif sama\" berarti kerja di tubuh sama — tapi merek beda bisa beda bahan pengisi, bentuk sediaan, atau pabrik. Selalu konfirmasi ke dokter/apoteker sebelum ganti obat.';

  @override
  String get openWebsite => 'Buka Website';

  @override
  String get useFinderAnyDevice =>
      'Gunakan pencarian di HP atau komputer mana saja.';

  @override
  String get aboutPrivacyTooltip => 'Tentang / Privasi';

  @override
  String get permissionBannerTitle =>
      'Pengingat mungkin tidak muncul tepat waktu.';

  @override
  String get notificationPermission => 'Nyalakan Notifikasi';

  @override
  String get exactAlarmPermission => 'Nyalakan Alarm Tepat';

  @override
  String get timePickerHelpTextSingle => 'Pilih waktu minum obat';

  @override
  String timePickerHelpTextMultiple(Object index) {
    return 'Pilih waktu untuk dosis $index';
  }

  @override
  String get saveError => 'Gagal simpan obat.';

  @override
  String get dailyReminderTitle => 'Waktu obat Anda';

  @override
  String dailyReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get snoozeReminderTitle => 'Pengingat: waktu obat Anda';

  @override
  String snoozeReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get repeatReminderTitle => 'Pengingat: konfirmasi obat Anda';

  @override
  String repeatReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage - menunggu konfirmasi Anda';
  }

  @override
  String get couldNotOpenPrivacyPolicy =>
      'Tidak bisa buka link kebijakan privasi.';

  @override
  String get couldNotOpenWebsite => 'Tidak bisa buka website.';
}
