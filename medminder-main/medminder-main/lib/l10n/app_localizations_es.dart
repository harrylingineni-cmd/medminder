// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Mis Medicamentos';

  @override
  String get welcomeTitle => 'Bienvenido a MediGuard';

  @override
  String get welcomeDescription =>
      'MediGuard te ayuda a recordar tomar tus medicamentos a tiempo.';

  @override
  String get pleaseRead => 'Por Favor Lea';

  @override
  String get disclaimerText =>
      'MediGuard es una herramienta de recordatorio, no un dispositivo médico. No proporciona consejos médicos ni garantiza que se haya tomado un medicamento. No sustituye a un médico o farmacéutico. Verifique siempre la etiqueta del medicamento antes de tomar cualquier medicina. En caso de emergencia, contacte a los servicios de emergencia locales.';

  @override
  String get privacyStatement =>
      'Su información se almacena solo en su dispositivo. No recopilamos ni compartimos sus datos.';

  @override
  String get readPrivacyPolicy => 'Leer nuestra Política de Privacidad';

  @override
  String get getStarted => 'Entendido — Empezar';

  @override
  String get close => 'Cerrar';

  @override
  String get aboutMediGuard => 'Sobre MediGuard';

  @override
  String get myMedications => 'Mis Medicamentos';

  @override
  String get findGeneric => 'Buscar Genérico';

  @override
  String get addMedication => 'Añadir Medicamento';

  @override
  String get editMedication => 'Editar Medicamento';

  @override
  String get saveMedication => 'Guardar Medicamento';

  @override
  String get saveChanges => 'Guardar Cambios';

  @override
  String get medicationName => 'Nombre del Medicamento';

  @override
  String get medicationNameHint => 'ej. Lisinopril';

  @override
  String get dosage => 'Dosis';

  @override
  String get dosageHint => 'ej. 500 mg';

  @override
  String get howManyTimesPerDay => '¿Cuántas Veces al Día?';

  @override
  String get onceADay => 'Una vez al día';

  @override
  String get twiceADay => 'Dos veces al día';

  @override
  String get threeTimesADay => '3 veces al día';

  @override
  String get fourTimesADay => '4 veces al día';

  @override
  String get fiveTimesADay => '5 veces al día';

  @override
  String get setTimesMode => '¿Cómo Le Gustaría Establecer los Horarios?';

  @override
  String get evenIntervals => 'Intervalos Regulares';

  @override
  String get customTimes => 'Horarios Personalizados';

  @override
  String get firstDoseTime => 'Hora de la Primera Dosis';

  @override
  String get tapToSelectFirstDose =>
      'Toque para seleccionar la hora de la primera dosis';

  @override
  String get hoursBetweenDoses => 'Horas Entre Dosis';

  @override
  String everyHours(
    Object horasPlural,
    Object hours,
    Object hoursPlural,
    Object stundenPlural,
  ) {
    return 'Cada $hours hora$horasPlural';
  }

  @override
  String get calculatedTimesNote =>
      'Calculamos estos horarios para usted — toque cualquiera para ajustarlo.';

  @override
  String get timeToTake => 'Hora de Tomar';

  @override
  String doseTime(Object index) {
    return 'Hora de la Dosis $index';
  }

  @override
  String get tapToSelectTime => 'Toque para seleccionar una hora';

  @override
  String get keepRemindingMeFor => 'Seguir Recordándome Durante';

  @override
  String get reminderWindowExplanation =>
      'Si no confirma, le recordaremos cada 5 minutos hasta que pase este tiempo.';

  @override
  String minutesOption(Object minutes) {
    return '$minutes min';
  }

  @override
  String get medicationDue => 'Medicamento Pendiente';

  @override
  String scheduledFor(Object time) {
    return 'Programado para $time';
  }

  @override
  String get checkLabel =>
      'Verifique la etiqueta del medicamento antes de tomarlo';

  @override
  String get iveTakenIt => 'Ya lo tomé';

  @override
  String get remindMeIn10Minutes => 'Recordarme en 10 Minutos';

  @override
  String get noMedicationsYet => 'No hay medicamentos aún';

  @override
  String get tapAddMedication =>
      'Toque \"Añadir Medicamento\" abajo\npara agregar el primero.';

  @override
  String get deleteMedication => '¿Eliminar este medicamento?';

  @override
  String deleteConfirmation(Object name) {
    return '$name se eliminará y sus recordatorios se detendrán. No se puede deshacer.';
  }

  @override
  String get keepMedication => 'Mantener Medicamento';

  @override
  String get delete => 'Eliminar';

  @override
  String get remindersMayNotAppear =>
      'Los recordatorios pueden no aparecer a tiempo.';

  @override
  String get turnOnNotifications => 'Activar Notificaciones';

  @override
  String get turnOnExactAlarms => 'Activar Alarmas Exactas';

  @override
  String remindsEvery5Min(Object minutes) {
    return 'Recuerda cada 5 min por $minutes min si no confirma';
  }

  @override
  String taken(Object time) {
    return 'Tomado · $time';
  }

  @override
  String get validationErrorName =>
      'Por favor ingrese el nombre del medicamento.';

  @override
  String get validationErrorDosage => 'Por favor ingrese la dosis.';

  @override
  String get validationErrorFirstDose =>
      'Por favor seleccione la hora de la primera dosis.';

  @override
  String get validationErrorTime => 'Por favor seleccione una hora.';

  @override
  String get validationErrorAllTimes =>
      'Por favor establezca una hora para cada dosis.';

  @override
  String get country => 'País';

  @override
  String get india => 'India';

  @override
  String get unitedStates => 'Estados Unidos';

  @override
  String get medicineName => 'Nombre del Medicamento';

  @override
  String get typeMedicineName => 'Escriba un nombre de medicamento';

  @override
  String get search => 'Buscar';

  @override
  String get searching => 'Buscando...';

  @override
  String get isThisYourMedicine => '¿Es este su medicamento?';

  @override
  String get noExactMatch =>
      'No encontramos una coincidencia exacta. Este es el nombre de medicamento más cercano que encontramos:';

  @override
  String get closestMatch => 'Coincidencia más cercana';

  @override
  String get yesThisIsMyMedicine => 'Sí, este es mi medicamento';

  @override
  String get noThatIsNotIt => 'No, ese no es';

  @override
  String get brandNameYouSearched => 'Nombre de marca que buscó';

  @override
  String get medicineMatched => 'Medicamento encontrado';

  @override
  String get genericActiveIngredient => 'Genérico (ingrediente activo)';

  @override
  String get sameIngredient =>
      'Mismo ingrediente activo — funciona igual en el cuerpo y suele costar menos.';

  @override
  String get askPharmacist => 'Pida a su farmacéutico la versión genérica.';

  @override
  String notFoundIndia(Object brand) {
    return 'No encontramos \"$brand\". Verifique la ortografía. Esta app cubre una lista inicial de marcas comunes en India — consulte a su farmacéutico si no está en la lista.';
  }

  @override
  String notFoundUS(Object brand) {
    return 'No encontramos \"$brand\". Verifique la ortografía e intente de nuevo, o consulte a su farmacéutico.';
  }

  @override
  String get couldNotReachService =>
      'No se pudo conectar al servicio de búsqueda';

  @override
  String get checkInternet =>
      'Verifique su conexión a internet e intente de nuevo.';

  @override
  String get tryAgain => 'Intentar de Nuevo';

  @override
  String get forInformationOnly => 'Solo Para Información';

  @override
  String get disclaimerGeneric =>
      'Esta herramienta es solo para información y no es consejo médico. \"Mismo ingrediente activo\" significa que los medicamentos funcionan igual en el cuerpo — pero las marcas pueden diferir en ingredientes inactivos, forma de dosificación o fabricante. Siempre confirme con su médico o farmacéutico antes de cambiar medicamentos.';

  @override
  String get openWebsite => 'Abrir Sitio Web';

  @override
  String get useFinderAnyDevice =>
      'Use el buscador en cualquier teléfono o computadora.';

  @override
  String get aboutPrivacyTooltip => 'Acerca de / Privacidad';

  @override
  String get permissionBannerTitle =>
      'Los recordatorios pueden no aparecer a tiempo.';

  @override
  String get notificationPermission => 'Activar Notificaciones';

  @override
  String get exactAlarmPermission => 'Activar Alarmas Exactas';

  @override
  String get timePickerHelpTextSingle =>
      'Seleccione la hora para tomar el medicamento';

  @override
  String timePickerHelpTextMultiple(Object index) {
    return 'Seleccione la hora para la dosis $index';
  }

  @override
  String get saveError => 'No se pudo guardar el medicamento.';

  @override
  String get dailyReminderTitle => 'Hora de su medicamento';

  @override
  String dailyReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get snoozeReminderTitle => 'Recordatorio: hora de su medicamento';

  @override
  String snoozeReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get repeatReminderTitle =>
      'Recordatorio: por favor confirme su medicamento';

  @override
  String repeatReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage - aún esperando su confirmación';
  }

  @override
  String get couldNotOpenPrivacyPolicy =>
      'No se pudo abrir el enlace de la política de privacidad.';

  @override
  String get couldNotOpenWebsite => 'No se pudo abrir el sitio web.';
}
