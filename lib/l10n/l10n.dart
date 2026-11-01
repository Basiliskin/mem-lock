import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

extension ContextText on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Times and dates, built without date libraries so the service needs no setup.
extension DateText on AppLocalizations {
  static String _clock(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  String _date(DateTime t) => monthDay('${t.day}', 'm${t.month}');

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String quietMarkedAt(DateTime time) {
    final t = time.toLocal();
    return markedAt(_date(t), _clock(t));
  }

  /// Adds the date when it isn't today, so yesterday's time can't mislead.
  String whenText(DateTime time, DateTime now) {
    final t = time.toLocal();
    return _sameDay(t, now.toLocal())
        ? whenToday(_clock(t))
        : whenOtherDay(_clock(t), _date(t));
  }

  String previousWhen(DateTime time, DateTime now) {
    final t = time.toLocal();
    return _sameDay(t, now.toLocal())
        ? previousToday(_clock(t))
        : previousOtherDay(_clock(t), _date(t));
  }
}
