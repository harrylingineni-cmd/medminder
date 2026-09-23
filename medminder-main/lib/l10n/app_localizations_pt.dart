// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Meus Medicamentos';

  @override
  String get welcomeTitle => 'Bem-vindo ao MediGuard';

  @override
  String get welcomeDescription =>
      'O MediGuard ajuda você a lembrar de tomar seus medicamentos no horário.';

  @override
  String get pleaseRead => 'Por Favor Leia';

  @override
  String get disclaimerText =>
      'O MediGuard é uma ferramenta de lembrete, não um dispositivo médico. Não fornece aconselhamento médico nem garante que um medicamento foi tomado. Não substitui um médico ou farmacêutico. Verifique sempre o rótulo do medicamento antes de tomar qualquer remédio. Em emergência, contate os serviços de emergência locais.';

  @override
  String get privacyStatement =>
      'Suas informações ficam armazenadas apenas no seu dispositivo. Não coletamos nem compartilhamos seus dados.';

  @override
  String get readPrivacyPolicy => 'Ler nossa Política de Privacidade';

  @override
  String get getStarted => 'Entendi — Começar';

  @override
  String get close => 'Fechar';

  @override
  String get aboutMediGuard => 'Sobre o MediGuard';

  @override
  String get myMedications => 'Meus Medicamentos';

  @override
  String get findGeneric => 'Buscar Genérico';

  @override
  String get addMedication => 'Adicionar Medicamento';

  @override
  String get editMedication => 'Editar Medicamento';

  @override
  String get saveMedication => 'Salvar Medicamento';

  @override
  String get saveChanges => 'Salvar Alterações';

  @override
  String get medicationName => 'Nome do Medicamento';

  @override
  String get medicationNameHint => 'ex. Losartana';

  @override
  String get dosage => 'Dosagem';

  @override
  String get dosageHint => 'ex. 500 mg';

  @override
  String get howManyTimesPerDay => 'Quantas Vezes por Dia?';

  @override
  String get onceADay => 'Uma vez ao dia';

  @override
  String get twiceADay => 'Duas vezes ao dia';

  @override
  String get threeTimesADay => '3 vezes ao dia';

  @override
  String get fourTimesADay => '4 vezes ao dia';

  @override
  String get fiveTimesADay => '5 vezes ao dia';

  @override
  String get setTimesMode => 'Como Gostaria de Definir os Horários?';

  @override
  String get evenIntervals => 'Intervalos Regulares';

  @override
  String get customTimes => 'Horários Personalizados';

  @override
  String get firstDoseTime => 'Horário da Primeira Dose';

  @override
  String get tapToSelectFirstDose =>
      'Toque para selecionar o horário da primeira dose';

  @override
  String get hoursBetweenDoses => 'Horas Entre Doses';

  @override
  String everyHours(
    Object horasPlural,
    Object hours,
    Object hoursPlural,
    Object stundenPlural,
  ) {
    return 'A cada $hours hora$horasPlural';
  }

  @override
  String get calculatedTimesNote =>
      'Calculamos estes horários para você — toque em qualquer um para ajustar.';

  @override
  String get timeToTake => 'Horário de Tomar';

  @override
  String doseTime(Object index) {
    return 'Horário da Dose $index';
  }

  @override
  String get tapToSelectTime => 'Toque para selecionar um horário';

  @override
  String get keepRemindingMeFor => 'Continuar Me Lembrando Por';

  @override
  String get reminderWindowExplanation =>
      'Se você não confirmar, lembraremos a cada 5 minutos até passar este tempo.';

  @override
  String minutesOption(Object minutes) {
    return '$minutes min';
  }

  @override
  String get medicationDue => 'Medicamento Pendente';

  @override
  String scheduledFor(Object time) {
    return 'Agendado para $time';
  }

  @override
  String get checkLabel => 'Verifique o rótulo do medicamento antes de tomá-lo';

  @override
  String get iveTakenIt => 'Já tomei';

  @override
  String get remindMeIn10Minutes => 'Lembrar em 10 Minutos';

  @override
  String get noMedicationsYet => 'Nenhum medicamento ainda';

  @override
  String get tapAddMedication =>
      'Toque em \"Adicionar Medicamento\" abaixo\npara adicionar o primeiro.';

  @override
  String get deleteMedication => 'Excluir este medicamento?';

  @override
  String deleteConfirmation(Object name) {
    return '$name será removido e seus lembretes pararão. Não pode ser desfeito.';
  }

  @override
  String get keepMedication => 'Manter Medicamento';

  @override
  String get delete => 'Excluir';

  @override
  String get remindersMayNotAppear =>
      'Lembretes podem não aparecer no horário.';

  @override
  String get turnOnNotifications => 'Ativar Notificações';

  @override
  String get turnOnExactAlarms => 'Ativar Alarmes Exatos';

  @override
  String remindsEvery5Min(Object minutes) {
    return 'Lembra a cada 5 min por $minutes min se esquecido';
  }

  @override
  String taken(Object time) {
    return 'Tomado · $time';
  }

  @override
  String get validationErrorName => 'Por favor insira o nome do medicamento.';

  @override
  String get validationErrorDosage => 'Por favor insira a dosagem.';

  @override
  String get validationErrorFirstDose =>
      'Por favor selecione o horário da primeira dose.';

  @override
  String get validationErrorTime => 'Por favor selecione um horário.';

  @override
  String get validationErrorAllTimes =>
      'Por favor defina um horário para cada dose.';

  @override
  String get country => 'País';

  @override
  String get india => 'Índia';

  @override
  String get unitedStates => 'Estados Unidos';

  @override
  String get medicineName => 'Nome do Medicamento';

  @override
  String get typeMedicineName => 'Digite o nome de um medicamento';

  @override
  String get search => 'Buscar';

  @override
  String get searching => 'Buscando...';

  @override
  String get isThisYourMedicine => 'Este é o seu medicamento?';

  @override
  String get noExactMatch =>
      'Não encontramos uma correspondência exata. Este é o nome de medicamento mais próximo que encontramos:';

  @override
  String get closestMatch => 'Correspondência mais próxima';

  @override
  String get yesThisIsMyMedicine => 'Sim, este é meu medicamento';

  @override
  String get noThatIsNotIt => 'Não, esse não é';

  @override
  String get brandNameYouSearched => 'Nome da marca que você buscou';

  @override
  String get medicineMatched => 'Medicamento encontrado';

  @override
  String get genericActiveIngredient => 'Genérico (princípio ativo)';

  @override
  String get sameIngredient =>
      'Mesmo princípio ativo — funciona da mesma forma no corpo e geralmente custa menos.';

  @override
  String get askPharmacist => 'Peça ao seu farmacêutico a versão genérica.';

  @override
  String notFoundIndia(Object brand) {
    return 'Não encontramos \"$brand\". Verifique a ortografia. Este app cobre uma lista inicial de marcas comuns na Índia — pergunte ao seu farmacêutico se esta não está listada.';
  }

  @override
  String notFoundUS(Object brand) {
    return 'Não encontramos \"$brand\". Verifique a ortografia e tente novamente, ou pergunte ao seu farmacêutico.';
  }

  @override
  String get couldNotReachService =>
      'Não foi possível alcançar o serviço de busca';

  @override
  String get checkInternet =>
      'Verifique sua conexão com a internet e tente novamente.';

  @override
  String get tryAgain => 'Tentar Novamente';

  @override
  String get forInformationOnly => 'Apenas Para Informação';

  @override
  String get disclaimerGeneric =>
      'Esta ferramenta é apenas para informação e não é aconselhamento médico. \"Mesmo princípio ativo\" significa que os medicamentos funcionam da mesma forma no corpo — mas as marcas podem diferir em ingredientes inativos, forma de dosagem ou fabricante. Sempre confirme com seu médico ou farmacêutico antes de trocar medicamentos.';

  @override
  String get openWebsite => 'Abrir Site';

  @override
  String get useFinderAnyDevice =>
      'Use o buscador em qualquer telefone ou computador.';

  @override
  String get aboutPrivacyTooltip => 'Sobre / Privacidade';

  @override
  String get permissionBannerTitle =>
      'Lembretes podem não aparecer no horário.';

  @override
  String get notificationPermission => 'Ativar Notificações';

  @override
  String get exactAlarmPermission => 'Ativar Alarmes Exatos';

  @override
  String get timePickerHelpTextSingle =>
      'Selecione o horário para tomar o medicamento';

  @override
  String timePickerHelpTextMultiple(Object index) {
    return 'Selecione o horário para a dose $index';
  }

  @override
  String get saveError => 'Não foi possível salvar o medicamento.';

  @override
  String get dailyReminderTitle => 'Hora do seu medicamento';

  @override
  String dailyReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get snoozeReminderTitle => 'Lembrete: hora do seu medicamento';

  @override
  String snoozeReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage';
  }

  @override
  String get repeatReminderTitle =>
      'Lembrete: por favor confirme seu medicamento';

  @override
  String repeatReminderBody(Object dosage, Object medicationName) {
    return '$medicationName - $dosage - ainda aguardando sua confirmação';
  }

  @override
  String get couldNotOpenPrivacyPolicy =>
      'Não foi possível abrir o link da política de privacidade.';

  @override
  String get couldNotOpenWebsite => 'Não foi possível abrir o site.';
}
