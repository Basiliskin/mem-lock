// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Geo Alert';

  @override
  String get protecting => 'Protection is on';

  @override
  String get notProtecting => 'Protection is off';

  @override
  String get nothingToDo => 'There is nothing you need to press';

  @override
  String get enable => 'Turn on protection';

  @override
  String get startFailed =>
      'Couldn\'t turn on. Check the permissions in settings.';

  @override
  String get serviceTitle => 'Protection is on';

  @override
  String get serviceText =>
      'We\'ll remind you about your things when you leave';

  @override
  String get reminderChannel => 'Reminders';

  @override
  String get reminderTitle => 'Do you have your things?';

  @override
  String get actionHaveEverything => 'I have everything';

  @override
  String get actionForgot => 'I forgot something';

  @override
  String get reminderBody => 'You have left a place. Check your things.';

  @override
  String get dontWorry => 'Don\'t worry';

  @override
  String get goBackAdvice => 'Go back to this place or call them.';

  @override
  String get openMap => 'Open on map';

  @override
  String get toMain => 'To main screen';

  @override
  String get noMapApp => 'No map app found.';

  @override
  String get coordinates => 'Coordinates';

  @override
  String get helperEntry => 'For family: hold for 2 seconds';

  @override
  String get quietPlaces => 'Quiet Places';

  @override
  String get noQuietPlaces => 'No Quiet Places yet.';

  @override
  String get markQuietPlace => 'Mark where I am now';

  @override
  String get noFixToMark =>
      'Place not saved: couldn\'t tell exactly where you are. Check that location is on, move closer to a window or go outside, and try again.';

  @override
  String get alreadyQuiet => 'This place is already marked.';

  @override
  String get saveFailed => 'Couldn\'t save. Try again.';

  @override
  String get remove => 'Remove';

  @override
  String get removeQuestion =>
      'Remove this place? You can only mark it again while you are there.';

  @override
  String get confirmRemove => 'Yes, remove';

  @override
  String get cancel => 'Cancel';

  @override
  String get helperSettings => 'Settings for family';

  @override
  String get reminderOptions => 'Reminder';

  @override
  String get reminderChannelNoVibration => 'Reminders without vibration';

  @override
  String get reminderChannelStrong => 'Reminders with strong vibration';

  @override
  String get testReminder => 'Test the Reminder';

  @override
  String get stopTest => 'Stop the test';

  @override
  String get testFailed => 'Couldn\'t start the test.';

  @override
  String get soundHeading => 'Sound';

  @override
  String get toneRising => 'Two tones';

  @override
  String get toneBell => 'Bell';

  @override
  String get tonePulse => 'Rapid tones';

  @override
  String get recordVoice => 'Record a voice';

  @override
  String get stopRecording => 'Finish recording';

  @override
  String get voiceInUse => 'The recorded voice is playing now.';

  @override
  String get micRefused =>
      'No access to the microphone. Allow it in the phone settings.';

  @override
  String get recordFailed => 'Recording didn\'t work. Try again.';

  @override
  String get vibrationHeading => 'Vibration';

  @override
  String get vibrationOff => 'No vibration';

  @override
  String get vibrationNormal => 'Normal';

  @override
  String get vibrationStrong => 'Strong';

  @override
  String get silentHeading => 'When the phone is on silent';

  @override
  String get silentAloud => 'Play aloud anyway';

  @override
  String get silentVibrate => 'Vibrate only';

  @override
  String get nothingOnSilent =>
      'On silent, the Reminder can\'t be heard or felt.';

  @override
  String get textHeading => 'Text';

  @override
  String get setupNext => 'Next';

  @override
  String get setupBack => 'Back';

  @override
  String get setupStart => 'Start';

  @override
  String get setupAllow => 'Allow';

  @override
  String get setupAllowed => 'Allowed ✓';

  @override
  String get setupOpenSettings => 'Open phone settings';

  @override
  String get setupBlocked => 'Allow this first to continue.';

  @override
  String get setupWelcomeTitle => 'Setup for your family member';

  @override
  String get setupWelcomeText =>
      'Set up the app on your family member\'s phone. It takes a few minutes.';

  @override
  String get setupLocationTitle => 'Allow location';

  @override
  String get setupLocationText => 'Choose \"Allow all the time\".';

  @override
  String get setupWhyLocation =>
      'Without this, the app won\'t notice that the person has left.';

  @override
  String get setupNotificationsTitle => 'Allow notifications';

  @override
  String get setupNotificationsText =>
      'This lets the Reminder appear on the screen.';

  @override
  String get setupWhyNotifications =>
      'Without this, the Reminder won\'t appear on the screen.';

  @override
  String get setupActivityTitle => 'Allow physical activity data';

  @override
  String get setupActivityText =>
      'This lets the app recognize the person\'s movement.';

  @override
  String get setupWhyActivity => 'This permission is needed to continue setup.';

  @override
  String get setupNoRideDetection =>
      'This phone doesn\'t have the Google services needed, so Reminders after a train or bus ride won\'t work. Reminders when leaving a place will work.';

  @override
  String get setupBatteryTitle => 'Turn off battery saving';

  @override
  String get setupBatteryText => 'Let the app run without restrictions.';

  @override
  String get setupWhyBattery => 'Otherwise the phone may close the app.';

  @override
  String get setupPhoneTitle => 'Keep the phone with you';

  @override
  String get setupPhoneText =>
      'If the phone stays in a forgotten bag, the app won\'t notice anything. Carry it in a pocket or a neck case.';

  @override
  String get setupQuietTitle => 'Mark home';

  @override
  String get setupQuietText =>
      'Leaving a Quiet Place gives no Reminder. You can only mark it while you are there.';

  @override
  String get setupOpenQuiet => 'Mark a place';

  @override
  String get setupOptionsTitle => 'Reminder';

  @override
  String get setupSilentText =>
      'When the phone is on silent, the Reminder still plays aloud at alarm volume. You can choose \"Vibrate only\". You can also change the sound and text, and record a voice, here.';

  @override
  String get setupChangeOptions => 'Set up the Reminder';

  @override
  String get setupDoneTitle => 'All done';

  @override
  String get setupDoneText =>
      'Press \"Start\" and the app will begin working. There is nothing else to press.';

  @override
  String get tapToFix => 'Tap to fix';

  @override
  String get fix => 'Fix';

  @override
  String get problemLocationOff => 'Location is off';

  @override
  String get problemLocationNotStarting =>
      'Location isn\'t starting. Check the location settings.';

  @override
  String get problemActivityPermission =>
      'No permission for physical activity data, so Reminders after a ride won\'t appear.';

  @override
  String get problemLocationPermission =>
      'No location permission. Choose \"Allow all the time\".';

  @override
  String get problemNotifications => 'Notifications are blocked';

  @override
  String get openPreviousMap => 'Previous place on map';

  @override
  String get lowBattery => 'The phone will run out of battery soon';

  @override
  String get lowBatteryWhy => 'Put it on charge, or protection will turn off.';

  @override
  String get lowBatteryChannel => 'Low battery';

  @override
  String get staySetting => 'How often to remind';

  @override
  String get stayMoreOften => 'More often';

  @override
  String get stayNormal => 'Normal';

  @override
  String get stayLessOften => 'Less often';

  @override
  String get reminderTitleLabel => 'Title: \"Do you have your things?\"';

  @override
  String get reminderBodyLabel =>
      'Message: \"You have left a place. Check your things.\"';

  @override
  String setupProgress(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String stayHint(int minutes) {
    return 'If the person stayed in a place for $minutes min.';
  }

  @override
  String monthDay(String day, String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'm1': 'January',
      'm2': 'February',
      'm3': 'March',
      'm4': 'April',
      'm5': 'May',
      'm6': 'June',
      'm7': 'July',
      'm8': 'August',
      'm9': 'September',
      'm10': 'October',
      'm11': 'November',
      'm12': 'December',
      'other': '',
    });
    return '$_temp0 $day';
  }

  @override
  String whenToday(String clock) {
    return 'You were here until $clock';
  }

  @override
  String whenOtherDay(String clock, String date) {
    return 'You were here until $clock, $date';
  }

  @override
  String previousToday(String clock) {
    return 'Previous: until $clock';
  }

  @override
  String previousOtherDay(String clock, String date) {
    return 'Previous: until $clock, $date';
  }

  @override
  String markedAt(String date, String clock) {
    return 'Marked $date at $clock';
  }

  @override
  String get languageSetting => 'Language';

  @override
  String get languagePhone => 'Same as the phone';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePreview => 'Next Reminder';
}
