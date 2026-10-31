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

  /// Adds the date when it isn't today, so yesterday's time can't mislead.
  static String whenText(DateTime time, DateTime now) {
    final t = time.toLocal();
    final n = now.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    final clock = '${two(t.hour)}:${two(t.minute)}';
    final today = t.year == n.year && t.month == n.month && t.day == n.day;
    return today
        ? 'Вы были здесь до $clock'
        : 'Вы были здесь до $clock, ${t.day} ${_months[t.month - 1]}';
  }
}
