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
