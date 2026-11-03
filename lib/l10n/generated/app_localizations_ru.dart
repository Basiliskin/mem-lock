// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'LeaveCheck';

  @override
  String get protecting => 'Защита работает';

  @override
  String get notProtecting => 'Защита не работает';

  @override
  String get nothingToDo => 'Ничего нажимать не нужно';

  @override
  String get enable => 'Включить защиту';

  @override
  String get startFailed =>
      'Не удалось включить. Проверьте разрешения в настройках.';

  @override
  String get serviceTitle => 'Защита работает';

  @override
  String get serviceText => 'Напомним о вещах, когда вы уйдёте';

  @override
  String get reminderChannel => 'Напоминания';

  @override
  String get reminderTitle => 'Ваши вещи с вами?';

  @override
  String get actionHaveEverything => 'Всё при мне';

  @override
  String get actionForgot => 'Я что-то забыл';

  @override
  String get reminderBody => 'Вы ушли с места. Проверьте вещи.';

  @override
  String get dontWorry => 'Не волнуйтесь';

  @override
  String get goBackAdvice => 'Вернитесь на это место или позвоните туда.';

  @override
  String get openMap => 'Открыть на карте';

  @override
  String get toMain => 'На главный экран';

  @override
  String get noMapApp => 'Не найдено приложение карт.';

  @override
  String get coordinates => 'Координаты';

  @override
  String get helperEntry => 'Для близких: удерживайте 2 секунды';

  @override
  String get quietPlaces => 'Тихие места';

  @override
  String get noQuietPlaces => 'Тихих мест пока нет.';

  @override
  String get markQuietPlace => 'Отметить место, где я сейчас';

  @override
  String get noFixToMark =>
      'Место не сохранено: не удалось точно определить, где вы. Проверьте, что геолокация включена, выйдите ближе к окну или на улицу и попробуйте снова.';

  @override
  String get alreadyQuiet => 'Это место уже отмечено.';

  @override
  String get saveFailed => 'Не удалось сохранить. Попробуйте снова.';

  @override
  String get remove => 'Удалить';

  @override
  String get removeQuestion =>
      'Удалить это место? Снова отметить его можно будет, только находясь там.';

  @override
  String get confirmRemove => 'Да, удалить';

  @override
  String get cancel => 'Отмена';

  @override
  String get helperSettings => 'Настройки для близких';

  @override
  String get reminderOptions => 'Напоминание';

  @override
  String get reminderChannelNoVibration => 'Напоминания без вибрации';

  @override
  String get reminderChannelStrong => 'Напоминания с сильной вибрацией';

  @override
  String get testReminder => 'Проверить напоминание';

  @override
  String get stopTest => 'Остановить проверку';

  @override
  String get testFailed => 'Не удалось запустить проверку.';

  @override
  String get soundHeading => 'Звук';

  @override
  String get toneRising => 'Два сигнала';

  @override
  String get toneBell => 'Колокольчик';

  @override
  String get tonePulse => 'Частые сигналы';

  @override
  String get recordVoice => 'Записать голос';

  @override
  String get stopRecording => 'Закончить запись';

  @override
  String get voiceInUse => 'Сейчас звучит записанный голос.';

  @override
  String get micRefused =>
      'Нет доступа к микрофону. Разрешите его в настройках телефона.';

  @override
  String get recordFailed => 'Запись не удалась. Попробуйте снова.';

  @override
  String get vibrationHeading => 'Вибрация';

  @override
  String get vibrationOff => 'Без вибрации';

  @override
  String get vibrationNormal => 'Обычная';

  @override
  String get vibrationStrong => 'Сильная';

  @override
  String get silentHeading => 'Когда телефон без звука';

  @override
  String get silentAloud => 'Всё равно звучать';

  @override
  String get silentVibrate => 'Только вибрация';

  @override
  String get nothingOnSilent =>
      'На беззвучном напоминание не будет ни слышно, ни ощутимо.';

  @override
  String get textHeading => 'Текст';

  @override
  String get setupNext => 'Дальше';

  @override
  String get setupBack => 'Назад';

  @override
  String get setupStart => 'Начать';

  @override
  String get setupAllow => 'Разрешить';

  @override
  String get setupAllowed => 'Разрешено ✓';

  @override
  String get setupOpenSettings => 'Открыть настройки телефона';

  @override
  String get setupBlocked => 'Сначала разрешите, чтобы продолжить.';

  @override
  String get setupWelcomeTitle => 'Настройка для близкого';

  @override
  String get setupWelcomeText =>
      'Настройте приложение на телефоне близкого человека. Это займёт несколько минут.';

  @override
  String get setupLocationTitle => 'Разрешите геолокацию';

  @override
  String get setupLocationText =>
      'LeaveCheck использует геолокацию, чтобы напоминать о вещах, когда вы уходите с места, и показывать последнее место, даже когда приложение закрыто или не используется. Данные о местоположении остаются на этом телефоне. На следующем экране выберите «Разрешить всегда».';

  @override
  String get setupWhyLocation =>
      'Без этого приложение не заметит, что человек ушёл.';

  @override
  String get setupNotificationsTitle => 'Разрешите уведомления';

  @override
  String get setupNotificationsText => 'Так напоминание появится на экране.';

  @override
  String get setupWhyNotifications =>
      'Без этого напоминание не появится на экране.';

  @override
  String get setupActivityTitle => 'Разрешите данные о движении';

  @override
  String get setupActivityText =>
      'Так приложение сможет распознавать движение человека.';

  @override
  String get setupWhyActivity =>
      'Это разрешение нужно, чтобы продолжить настройку.';

  @override
  String get setupNoRideDetection =>
      'На этом телефоне нет нужных сервисов Google, поэтому напоминания после поездки на поезде или автобусе работать не будут. Напоминания при уходе с места будут работать.';

  @override
  String get setupBatteryTitle => 'Отключите экономию заряда';

  @override
  String get setupBatteryText =>
      'Разрешите приложению работать без ограничений.';

  @override
  String get setupWhyBattery => 'Иначе телефон может закрыть приложение.';

  @override
  String get setupPhoneTitle => 'Телефон должен быть при себе';

  @override
  String get setupPhoneText =>
      'Если телефон останется в забытой сумке, приложение ничего не заметит. Носите его в кармане или в чехле на шее.';

  @override
  String get setupQuietTitle => 'Отметьте дом';

  @override
  String get setupQuietText =>
      'Уходя из тихого места, человек не получит напоминания. Отметить можно, только находясь там.';

  @override
  String get setupOpenQuiet => 'Отметить место';

  @override
  String get setupOptionsTitle => 'Напоминание';

  @override
  String get setupSilentText =>
      'Когда телефон без звука, напоминание всё равно звучит вслух, с громкостью будильника. Можно выбрать «Только вибрация». Здесь же можно изменить звук, текст и записать голос.';

  @override
  String get setupChangeOptions => 'Настроить напоминание';

  @override
  String get setupDoneTitle => 'Готово';

  @override
  String get setupDoneText =>
      'Нажмите «Начать», и приложение заработает. Больше ничего нажимать не нужно.';

  @override
  String get tapToFix => 'Нажмите, чтобы исправить';

  @override
  String get fix => 'Исправить';

  @override
  String get problemLocationOff => 'Геолокация выключена';

  @override
  String get problemLocationNotStarting =>
      'Геолокация не запускается. Проверьте настройки геолокации.';

  @override
  String get problemActivityPermission =>
      'Нет разрешения на данные о движении, поэтому напоминания после поездки не появятся.';

  @override
  String get problemLocationPermission =>
      'Нет разрешения на геолокацию. Выберите «Разрешить всегда».';

  @override
  String get problemNotifications => 'Уведомления запрещены';

  @override
  String get openPreviousMap => 'Предыдущее место на карте';

  @override
  String get lowBattery => 'Телефон скоро разрядится';

  @override
  String get lowBatteryWhy =>
      'Поставьте его на зарядку, иначе защита отключится.';

  @override
  String get lowBatteryChannel => 'Низкий заряд';

  @override
  String get staySetting => 'Как часто напоминать';

  @override
  String get stayMoreOften => 'Чаще';

  @override
  String get stayNormal => 'Обычно';

  @override
  String get stayLessOften => 'Реже';

  @override
  String get reminderTitleLabel => 'Заголовок: «Ваши вещи с вами?»';

  @override
  String get reminderBodyLabel =>
      'Сообщение: «Вы ушли с места. Проверьте вещи.»';

  @override
  String setupProgress(int step, int total) {
    return 'Шаг $step из $total';
  }

  @override
  String stayHint(int minutes) {
    return 'Если человек пробыл на месте $minutes мин.';
  }

  @override
  String monthDay(String day, String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'm1': 'января',
      'm2': 'февраля',
      'm3': 'марта',
      'm4': 'апреля',
      'm5': 'мая',
      'm6': 'июня',
      'm7': 'июля',
      'm8': 'августа',
      'm9': 'сентября',
      'm10': 'октября',
      'm11': 'ноября',
      'm12': 'декабря',
      'other': '',
    });
    return '$day $_temp0';
  }

  @override
  String whenToday(String clock) {
    return 'Вы были здесь до $clock';
  }

  @override
  String whenOtherDay(String clock, String date) {
    return 'Вы были здесь до $clock, $date';
  }

  @override
  String previousToday(String clock) {
    return 'Предыдущее: до $clock';
  }

  @override
  String previousOtherDay(String clock, String date) {
    return 'Предыдущее: до $clock, $date';
  }

  @override
  String markedAt(String date, String clock) {
    return 'Отмечено $date в $clock';
  }

  @override
  String get languageSetting => 'Язык';

  @override
  String get languagePhone => 'Как на телефоне';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePreview => 'Следующее напоминание';

  @override
  String get advancedSettings => 'Точные значения';

  @override
  String advancedNow(String name) {
    return 'Сейчас: $name';
  }

  @override
  String get advancedCustom => 'Свои значения';

  @override
  String get advancedPresetHelp =>
      'Выбор варианта заменит время и размер места.';

  @override
  String get advancedStayTime => 'Сколько пробыть на месте';

  @override
  String get advancedStayArea => 'Размер места';

  @override
  String get advancedSpeed => 'Скорость транспорта';

  @override
  String get advancedWalking => 'Сколько идти после поездки';

  @override
  String get unitMinutes => 'мин';

  @override
  String get unitMeters => 'м';

  @override
  String get unitKmh => 'км/ч';

  @override
  String get unitSeconds => 'сек';

  @override
  String advancedRange(
    String min,
    String max,
    String unit,
    String recommended,
  ) {
    return 'от $min до $max $unit, рекомендуем $recommended';
  }

  @override
  String advancedLimit(String label, String min, String max, String unit) {
    return '$label: можно от $min до $max $unit. Не сохранено.';
  }

  @override
  String increaseValue(String label) {
    return 'Больше: $label';
  }

  @override
  String decreaseValue(String label) {
    return 'Меньше: $label';
  }

  @override
  String get saveValues => 'Сохранить';

  @override
  String get resetToRecommended => 'Вернуть рекомендуемые';

  @override
  String get valuesSaved => 'Значения сохранены';

  @override
  String get valuesReset => 'Рекомендуемые значения возвращены';

  @override
  String get riskTitle => 'Напоминания могут не прийти:';

  @override
  String get riskStayTime =>
      'при таком времени короткие остановки останутся без напоминания.';

  @override
  String get riskStayArea =>
      'при таком размере уход с места будет замечен позже.';

  @override
  String get riskSpeed => 'медленный транспорт может быть принят за ходьбу.';

  @override
  String get riskWalking =>
      'напоминание после поездки придёт позже чем через минуту.';

  @override
  String get saveAnyway => 'Всё равно сохранить';

  @override
  String get changeValues => 'Изменить';

  @override
  String get stayCustomNote =>
      'Сейчас действуют свои значения. Выбор варианта заменит время и размер места.';

  @override
  String get reminderPlaces => 'Места с напоминанием';

  @override
  String get reminderPlacesHelp =>
      'Напомним при уходе отсюда, даже после короткого визита (от 1 минуты).';

  @override
  String get noReminderPlaces => 'Мест пока нет.';

  @override
  String get markReminderPlace => 'Отметить это место';

  @override
  String get reminderPlaceName => 'Название';

  @override
  String get reminderPlaceNameHint => 'Например, бассейн';

  @override
  String get reminderPlaceMessage => 'Сообщение';

  @override
  String get reminderPlaceMessageHint => 'Например, возьмите полотенце';

  @override
  String get reminderPlaceNeedsText => 'Сначала введите название и сообщение.';

  @override
  String get reminderPlaceNoFix =>
      'Не удалось определить, где вы. Место не сохранено. Выйдите на улицу и попробуйте снова.';

  @override
  String get alreadyReminderPlace => 'Это место уже отмечено.';

  @override
  String get reminderPlaceSaved => 'Место сохранено';

  @override
  String get reminderPlaceRemoved => 'Место удалено';

  @override
  String get removeReminderPlaceQuestion =>
      'Удалить это место? Напоминаний с этим сообщением больше не будет.';

  @override
  String removeNamed(String name) {
    return 'Удалить: $name';
  }

  @override
  String get clashIsQuiet =>
      'Это место уже отмечено как тихое. Одно место не может быть и тихим, и с напоминанием. Что оставить?';

  @override
  String get keepQuiet => 'Оставить тихим';

  @override
  String get makeReminderPlace => 'Сделать местом с напоминанием';

  @override
  String get keptQuiet => 'Оставили тихим местом';

  @override
  String get clashIsReminderPlace =>
      'Здесь уже есть место с напоминанием. Одно место не может быть и тихим, и с напоминанием. Что оставить?';

  @override
  String get keepReminderPlace => 'Оставить с напоминанием';

  @override
  String get makeQuiet => 'Сделать тихим';

  @override
  String get keptReminderPlace => 'Оставили место с напоминанием';

  @override
  String get homeWifi => 'Домашний Wi-Fi';

  @override
  String get homeWifiHelp =>
      'Напоминает проверить вещи, когда человек выходит из дома и телефон теряет домашний Wi-Fi.';

  @override
  String get homeWifiNone => 'Домашний Wi-Fi не выбран.';

  @override
  String homeWifiCurrent(String name) {
    return 'Домашний Wi-Fi: $name';
  }

  @override
  String get homeWifiSet => 'Это домашний Wi-Fi';

  @override
  String get homeWifiRemove => 'Убрать домашний Wi-Fi';

  @override
  String get homeWifiNotConnected =>
      'Сначала подключите телефон к домашнему Wi-Fi и попробуйте снова.';

  @override
  String get homeWifiNoFix =>
      'Не удалось определить место, ничего не сохранено. Встаньте у окна и попробуйте снова.';

  @override
  String get homeWifiSaved => 'Домашний Wi-Fi сохранён';

  @override
  String get homeWifiRemoved => 'Домашний Wi-Fi убран';

  @override
  String get setupHomeTitle => 'Отметьте домашний Wi-Fi';

  @override
  String get setupHomeText =>
      'Дома, когда телефон подключён к домашнему Wi-Fi, отметьте его. Тогда при выходе из дома будет напоминание.';

  @override
  String get setupOpenHome => 'Выбрать домашний Wi-Fi';

  @override
  String get statusAllGood => 'Всё хорошо';

  @override
  String get statusAllGoodText =>
      'Когда вы выйдете из дома, будет напоминание.';

  @override
  String get statusNotSet => 'Не настроено';

  @override
  String get statusNotSetText => 'Отметьте домашний Wi-Fi, чтобы начать.';

  @override
  String get statusNeedsAttention => 'Нужно внимание';

  @override
  String get lastReminder => 'Последнее напоминание';

  @override
  String get checkLeftHome => 'Вы вышли из дома';

  @override
  String get checkYes => 'Да';

  @override
  String get checkNoGoBack => 'Нет, вернуться';

  @override
  String get checkSkip => 'Пропустить всё';

  @override
  String get checkAllDone => 'Всё проверено';

  @override
  String get checkGoodTrip => 'Хорошей дороги!';

  @override
  String get checkClose => 'Закрыть';

  @override
  String get checkHaveEverything => 'Всё взяли?';

  @override
  String get itemKeys => 'Ключи';

  @override
  String get itemWallet => 'Кошелёк';

  @override
  String get itemPhone => 'Телефон';

  @override
  String get itemGlasses => 'Очки';

  @override
  String get itemGas => 'Газ выключен';

  @override
  String get itemDoor => 'Дверь заперта';

  @override
  String get whatToCheck => 'Что проверить';

  @override
  String get addItem => 'Добавить';

  @override
  String get addItemHint => 'Например, зонт';

  @override
  String get removeItem => 'Убрать';

  @override
  String itemsOn(int count) {
    return 'Включено: $count';
  }

  @override
  String get howToRemind => 'Как напоминать';

  @override
  String get notSet => 'Не выбран';
}
