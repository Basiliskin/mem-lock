/// All Russian app text, kept in one place so it can be translated later.
abstract final class Strings {
  static const appName = 'Geo Alert';
  static const protecting = 'Защита работает';
  static const notProtecting = 'Защита не работает';
  static const nothingToDo = 'Ничего нажимать не нужно';
  static const enable = 'Включить защиту';
  static const startFailed =
      'Не удалось включить. Проверьте разрешения в настройках.';
  static const serviceTitle = 'Защита работает';
  static const serviceText = 'Напомним о вещах, когда вы уйдёте';
  static const reminderChannel = 'Напоминания';
  static const reminderTitle = 'Ваши вещи с вами?';
  static const actionHaveEverything = 'Всё при мне';
  static const actionForgot = 'Я что-то забыл';
  static const reminderBody = 'Вы ушли с места. Проверьте вещи.';
  static const dontWorry = 'Не волнуйтесь';
  static const goBackAdvice = 'Вернитесь на это место или позвоните туда.';
  static const openMap = 'Открыть на карте';
  static const toMain = 'На главный экран';
  static const noMapApp = 'Не найдено приложение карт.';
  static const coordinates = 'Координаты';

  static const helperEntry = 'Для близких: удерживайте 2 секунды';
  static const quietPlaces = 'Тихие места';
  static const noQuietPlaces = 'Тихих мест пока нет.';
  static const markQuietPlace = 'Отметить место, где я сейчас';
  static const noFixToMark =
      'Место не сохранено: не удалось точно определить, где вы. '
      'Проверьте, что геолокация включена, выйдите ближе к окну или на улицу '
      'и попробуйте снова.';
  static const alreadyQuiet = 'Это место уже отмечено.';
  static const saveFailed = 'Не удалось сохранить. Попробуйте снова.';
  static const remove = 'Удалить';
  static const removeQuestion =
      'Удалить это место? Снова отметить его можно будет, только находясь там.';
  static const confirmRemove = 'Да, удалить';
  static const cancel = 'Отмена';

  static const helperSettings = 'Настройки для близких';
  static const reminderOptions = 'Напоминание';
  static const reminderChannelNoVibration = 'Напоминания без вибрации';
  static const reminderChannelStrong = 'Напоминания с сильной вибрацией';
  static const testReminder = 'Проверить напоминание';
  static const stopTest = 'Остановить проверку';
  static const testFailed = 'Не удалось запустить проверку.';
  static const soundHeading = 'Звук';
  static const toneRising = 'Два сигнала';
  static const toneBell = 'Колокольчик';
  static const tonePulse = 'Частые сигналы';
  static const recordVoice = 'Записать голос';
  static const stopRecording = 'Закончить запись';
  static const voiceInUse = 'Сейчас звучит записанный голос.';
  static const micRefused =
      'Нет доступа к микрофону. Разрешите его в настройках телефона.';
  static const recordFailed = 'Запись не удалась. Попробуйте снова.';
  static const vibrationHeading = 'Вибрация';
  static const vibrationOff = 'Без вибрации';
  static const vibrationNormal = 'Обычная';
  static const vibrationStrong = 'Сильная';
  static const silentHeading = 'Когда телефон без звука';
  static const silentAloud = 'Всё равно звучать';
  static const silentVibrate = 'Только вибрация';
  static const nothingOnSilent =
      'На беззвучном напоминание не будет ни слышно, ни ощутимо.';
  static const textHeading = 'Текст';
  static const reminderTitleLabel = 'Заголовок: «$reminderTitle»';
  static const reminderBodyLabel = 'Сообщение: «$reminderBody»';

  static const setupNext = 'Дальше';
  static const setupBack = 'Назад';
  static const setupStart = 'Начать';
  static const setupAllow = 'Разрешить';
  static const setupAllowed = 'Разрешено ✓';
  static const setupOpenSettings = 'Открыть настройки телефона';
  static const setupBlocked = 'Сначала разрешите, чтобы продолжить.';
  static const setupWelcomeTitle = 'Настройка для близкого';
  static const setupWelcomeText =
      'Настройте приложение на телефоне близкого человека. '
      'Это займёт несколько минут.';
  static const setupLocationTitle = 'Разрешите геолокацию';
  static const setupLocationText = 'Выберите «Разрешить всегда».';
  static const setupWhyLocation =
      'Без этого приложение не заметит, что человек ушёл.';
  static const setupNotificationsTitle = 'Разрешите уведомления';
  static const setupNotificationsText = 'Так напоминание появится на экране.';
  static const setupWhyNotifications =
      'Без этого напоминание не появится на экране.';
  static const setupActivityTitle = 'Разрешите данные о движении';
  static const setupActivityText =
      'Так приложение сможет распознавать движение человека.';
  static const setupWhyActivity =
      'Это разрешение нужно, чтобы продолжить настройку.';
  static const setupBatteryTitle = 'Отключите экономию заряда';
  static const setupBatteryText =
      'Разрешите приложению работать без ограничений.';
  static const setupWhyBattery = 'Иначе телефон может закрыть приложение.';
  static const setupPhoneTitle = 'Телефон должен быть при себе';
  static const setupPhoneText =
      'Если телефон останется в забытой сумке, приложение ничего не заметит. '
      'Носите его в кармане или в чехле на шее.';
  static const setupQuietTitle = 'Отметьте дом';
  static const setupQuietText =
      'Уходя из тихого места, человек не получит напоминания. '
      'Отметить можно, только находясь там.';
  static const setupOpenQuiet = 'Отметить место';
  static const setupOptionsTitle = 'Напоминание';
  static const setupSilentText =
      'Когда телефон без звука, напоминание всё равно звучит вслух, с '
      'громкостью будильника. Можно выбрать «Только вибрация». Здесь же можно '
      'изменить звук, текст и записать голос.';
  static const setupChangeOptions = 'Настроить напоминание';
  static const setupDoneTitle = 'Готово';
  static const setupDoneText =
      'Нажмите «Начать», и приложение заработает. '
      'Больше ничего нажимать не нужно.';

  static String setupProgress(int step, int total) => 'Шаг $step из $total';

  static const tapToFix = 'Нажмите, чтобы исправить';
  static const fix = 'Исправить';
  static const problemLocationOff = 'Геолокация выключена';
  static const problemLocationPermission =
      'Нет разрешения на геолокацию. Выберите «Разрешить всегда».';
  static const problemNotifications = 'Уведомления запрещены';

  static const openPreviousMap = 'Предыдущее место на карте';
  static String previousWhen(DateTime time, DateTime now) =>
      'Предыдущее: ${whenText(time, now).replaceFirst('Вы были здесь ', '')}';

  static const lowBattery = 'Телефон скоро разрядится';
  static const lowBatteryWhy =
      'Поставьте его на зарядку, иначе защита отключится.';
  static const lowBatteryChannel = 'Низкий заряд';

  static const staySetting = 'Как часто напоминать';
  static const stayMoreOften = 'Чаще';
  static const stayNormal = 'Обычно';
  static const stayLessOften = 'Реже';
  static String stayHint(int minutes) =>
      'Если человек пробыл на месте $minutes мин.';

  static const _months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  static String _clock(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  static String quietMarkedAt(DateTime time) {
    final t = time.toLocal();
    return 'Отмечено ${t.day} ${_months[t.month - 1]} в ${_clock(t)}';
  }

  /// Adds the date when it isn't today, so yesterday's time can't mislead.
  static String whenText(DateTime time, DateTime now) {
    final t = time.toLocal();
    final n = now.toLocal();
    final clock = _clock(t);
    final today = t.year == n.year && t.month == n.month && t.day == n.day;
    return today
        ? 'Вы были здесь до $clock'
        : 'Вы были здесь до $clock, ${t.day} ${_months[t.month - 1]}';
  }
}
