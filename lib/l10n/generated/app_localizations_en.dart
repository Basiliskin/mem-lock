// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'LeaveCheck';

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
  String get setupLocationText =>
      'LeaveCheck uses your location to give a Reminder when you leave a place, and to show the last place, even when the app is closed or not in use. Location stays on this phone. On the next screen, choose \"Allow all the time\".';

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

  @override
  String get advancedSettings => 'Exact values';

  @override
  String advancedNow(String name) {
    return 'Now: $name';
  }

  @override
  String get advancedCustom => 'Custom values';

  @override
  String get advancedPresetHelp =>
      'Choosing one replaces the time and place size.';

  @override
  String get advancedStayTime => 'Time to count as a stay';

  @override
  String get advancedStayArea => 'Size of the place';

  @override
  String get advancedSpeed => 'Vehicle speed';

  @override
  String get advancedWalking => 'Walking time after a ride';

  @override
  String get unitMinutes => 'min';

  @override
  String get unitMeters => 'm';

  @override
  String get unitKmh => 'km/h';

  @override
  String get unitSeconds => 'sec';

  @override
  String advancedRange(
    String min,
    String max,
    String unit,
    String recommended,
  ) {
    return 'from $min to $max $unit, recommended $recommended';
  }

  @override
  String advancedLimit(String label, String min, String max, String unit) {
    return '$label: must be $min to $max $unit. Not saved.';
  }

  @override
  String increaseValue(String label) {
    return 'Increase: $label';
  }

  @override
  String decreaseValue(String label) {
    return 'Decrease: $label';
  }

  @override
  String get saveValues => 'Save';

  @override
  String get resetToRecommended => 'Reset to recommended';

  @override
  String get valuesSaved => 'Values saved';

  @override
  String get valuesReset => 'Recommended values restored';

  @override
  String get riskTitle => 'Reminders may be missed:';

  @override
  String get riskStayTime => 'short stops will give no Reminder.';

  @override
  String get riskStayArea => 'leaving will be noticed later.';

  @override
  String get riskSpeed => 'a slow vehicle could be mistaken for walking.';

  @override
  String get riskWalking =>
      'the Reminder after a ride will take over a minute.';

  @override
  String get saveAnyway => 'Save anyway';

  @override
  String get changeValues => 'Change';

  @override
  String get stayCustomNote =>
      'Custom values are in use. Choosing one replaces the time and place size.';

  @override
  String get reminderPlaces => 'Reminder Places';

  @override
  String get reminderPlacesHelp =>
      'Reminds on leaving, even after a short visit (1 minute or more).';

  @override
  String get noReminderPlaces => 'No places yet.';

  @override
  String get markReminderPlace => 'Mark this place';

  @override
  String get reminderPlaceName => 'Name';

  @override
  String get reminderPlaceNameHint => 'For example, pool';

  @override
  String get reminderPlaceMessage => 'Message';

  @override
  String get reminderPlaceMessageHint => 'For example, take your towel';

  @override
  String get reminderPlaceNeedsText => 'Enter a name and message first.';

  @override
  String get reminderPlaceNoFix =>
      'Could not find your location, so nothing was saved. Go outside and try again.';

  @override
  String get alreadyReminderPlace => 'This place is already marked.';

  @override
  String get reminderPlaceSaved => 'Place saved';

  @override
  String get reminderPlaceRemoved => 'Place removed';

  @override
  String get removeReminderPlaceQuestion =>
      'Remove this place? Its Reminders will stop.';

  @override
  String removeNamed(String name) {
    return 'Remove: $name';
  }

  @override
  String get clashIsQuiet =>
      'This place is already a Quiet Place. A place cannot be both. Which should it be?';

  @override
  String get keepQuiet => 'Keep it quiet';

  @override
  String get makeReminderPlace => 'Make it a Reminder Place';

  @override
  String get keptQuiet => 'Kept as a Quiet Place';

  @override
  String get clashIsReminderPlace =>
      'This place is already a Reminder Place. A place cannot be both. Which should it be?';

  @override
  String get keepReminderPlace => 'Keep the Reminder Place';

  @override
  String get makeQuiet => 'Make it quiet';

  @override
  String get keptReminderPlace => 'Kept as a Reminder Place';

  @override
  String get homeWifi => 'Home Wi-Fi';

  @override
  String get homeWifiHelp =>
      'Reminds the person to check their belongings when they walk out of home and the phone loses the home Wi-Fi.';

  @override
  String get homeWifiNone => 'No home Wi-Fi is set.';

  @override
  String homeWifiCurrent(String name) {
    return 'Home Wi-Fi: $name';
  }

  @override
  String get homeWifiSet => 'This is the home Wi-Fi';

  @override
  String get homeWifiRemove => 'Remove home Wi-Fi';

  @override
  String get homeWifiNotConnected =>
      'Connect this phone to the home Wi-Fi first, then try again.';

  @override
  String get homeWifiNoFix =>
      'Could not find your location, so nothing was saved. Stand near a window and try again.';

  @override
  String get homeWifiSaved => 'Home Wi-Fi saved';

  @override
  String get homeWifiRemoved => 'Home Wi-Fi removed';

  @override
  String get setupHomeTitle => 'Mark home Wi-Fi';

  @override
  String get setupHomeText =>
      'At home, with this phone connected to the home Wi-Fi, mark it. Walking out of home then gives a Reminder.';

  @override
  String get setupOpenHome => 'Set home Wi-Fi';

  @override
  String get statusAllGood => 'All good';

  @override
  String get statusAllGoodText =>
      'You\'ll get a reminder when you walk out of home.';

  @override
  String get statusNotSet => 'Not set up';

  @override
  String get statusNotSetText => 'Mark the home Wi-Fi to start.';

  @override
  String get statusNeedsAttention => 'Needs attention';

  @override
  String get lastReminder => 'Last reminder';

  @override
  String get checkLeftHome => 'You left home';

  @override
  String get checkYes => 'Yes';

  @override
  String get checkNoGoBack => 'No, go back';

  @override
  String get checkSkip => 'Skip all';

  @override
  String get checkAllDone => 'All checked';

  @override
  String get checkGoodTrip => 'Have a good trip!';

  @override
  String get checkClose => 'Close';

  @override
  String get checkHaveEverything => 'Do you have everything?';

  @override
  String get itemKeys => 'Keys';

  @override
  String get itemWallet => 'Wallet';

  @override
  String get itemPhone => 'Phone';

  @override
  String get itemGlasses => 'Glasses';

  @override
  String get itemGas => 'Gas off';

  @override
  String get itemDoor => 'Door locked';

  @override
  String get whatToCheck => 'What to check';

  @override
  String get addItem => 'Add item';

  @override
  String get addItemHint => 'For example, umbrella';

  @override
  String get removeItem => 'Remove';

  @override
  String itemsOn(int count) {
    return '$count on';
  }

  @override
  String get howToRemind => 'How to remind';

  @override
  String get notSet => 'Not set';

  @override
  String get reminderBodyHome => 'You left home. Check your things.';
}
