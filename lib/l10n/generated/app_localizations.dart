import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In ru, this message translates to:
  /// **'LeaveCheck'**
  String get appName;

  /// No description provided for @protecting.
  ///
  /// In ru, this message translates to:
  /// **'Защита работает'**
  String get protecting;

  /// No description provided for @notProtecting.
  ///
  /// In ru, this message translates to:
  /// **'Защита не работает'**
  String get notProtecting;

  /// No description provided for @nothingToDo.
  ///
  /// In ru, this message translates to:
  /// **'Ничего нажимать не нужно'**
  String get nothingToDo;

  /// No description provided for @enable.
  ///
  /// In ru, this message translates to:
  /// **'Включить защиту'**
  String get enable;

  /// No description provided for @startFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось включить. Проверьте разрешения в настройках.'**
  String get startFailed;

  /// No description provided for @serviceTitle.
  ///
  /// In ru, this message translates to:
  /// **'Защита работает'**
  String get serviceTitle;

  /// No description provided for @serviceText.
  ///
  /// In ru, this message translates to:
  /// **'Напомним о вещах, когда вы уйдёте'**
  String get serviceText;

  /// No description provided for @reminderChannel.
  ///
  /// In ru, this message translates to:
  /// **'Напоминания'**
  String get reminderChannel;

  /// No description provided for @reminderTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ваши вещи с вами?'**
  String get reminderTitle;

  /// No description provided for @actionHaveEverything.
  ///
  /// In ru, this message translates to:
  /// **'Всё при мне'**
  String get actionHaveEverything;

  /// No description provided for @actionForgot.
  ///
  /// In ru, this message translates to:
  /// **'Я что-то забыл'**
  String get actionForgot;

  /// No description provided for @reminderBody.
  ///
  /// In ru, this message translates to:
  /// **'Вы ушли с места. Проверьте вещи.'**
  String get reminderBody;

  /// No description provided for @dontWorry.
  ///
  /// In ru, this message translates to:
  /// **'Не волнуйтесь'**
  String get dontWorry;

  /// No description provided for @goBackAdvice.
  ///
  /// In ru, this message translates to:
  /// **'Вернитесь на это место или позвоните туда.'**
  String get goBackAdvice;

  /// No description provided for @openMap.
  ///
  /// In ru, this message translates to:
  /// **'Открыть на карте'**
  String get openMap;

  /// No description provided for @toMain.
  ///
  /// In ru, this message translates to:
  /// **'На главный экран'**
  String get toMain;

  /// No description provided for @noMapApp.
  ///
  /// In ru, this message translates to:
  /// **'Не найдено приложение карт.'**
  String get noMapApp;

  /// No description provided for @coordinates.
  ///
  /// In ru, this message translates to:
  /// **'Координаты'**
  String get coordinates;

  /// No description provided for @helperEntry.
  ///
  /// In ru, this message translates to:
  /// **'Для близких: удерживайте 2 секунды'**
  String get helperEntry;

  /// No description provided for @quietPlaces.
  ///
  /// In ru, this message translates to:
  /// **'Тихие места'**
  String get quietPlaces;

  /// No description provided for @noQuietPlaces.
  ///
  /// In ru, this message translates to:
  /// **'Тихих мест пока нет.'**
  String get noQuietPlaces;

  /// No description provided for @markQuietPlace.
  ///
  /// In ru, this message translates to:
  /// **'Отметить место, где я сейчас'**
  String get markQuietPlace;

  /// No description provided for @noFixToMark.
  ///
  /// In ru, this message translates to:
  /// **'Место не сохранено: не удалось точно определить, где вы. Проверьте, что геолокация включена, выйдите ближе к окну или на улицу и попробуйте снова.'**
  String get noFixToMark;

  /// No description provided for @alreadyQuiet.
  ///
  /// In ru, this message translates to:
  /// **'Это место уже отмечено.'**
  String get alreadyQuiet;

  /// No description provided for @saveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить. Попробуйте снова.'**
  String get saveFailed;

  /// No description provided for @remove.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get remove;

  /// No description provided for @removeQuestion.
  ///
  /// In ru, this message translates to:
  /// **'Удалить это место? Снова отметить его можно будет, только находясь там.'**
  String get removeQuestion;

  /// No description provided for @confirmRemove.
  ///
  /// In ru, this message translates to:
  /// **'Да, удалить'**
  String get confirmRemove;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @helperSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки для близких'**
  String get helperSettings;

  /// No description provided for @reminderOptions.
  ///
  /// In ru, this message translates to:
  /// **'Напоминание'**
  String get reminderOptions;

  /// No description provided for @reminderChannelNoVibration.
  ///
  /// In ru, this message translates to:
  /// **'Напоминания без вибрации'**
  String get reminderChannelNoVibration;

  /// No description provided for @reminderChannelStrong.
  ///
  /// In ru, this message translates to:
  /// **'Напоминания с сильной вибрацией'**
  String get reminderChannelStrong;

  /// No description provided for @testReminder.
  ///
  /// In ru, this message translates to:
  /// **'Проверить напоминание'**
  String get testReminder;

  /// No description provided for @stopTest.
  ///
  /// In ru, this message translates to:
  /// **'Остановить проверку'**
  String get stopTest;

  /// No description provided for @testFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось запустить проверку.'**
  String get testFailed;

  /// No description provided for @soundHeading.
  ///
  /// In ru, this message translates to:
  /// **'Звук'**
  String get soundHeading;

  /// No description provided for @toneRising.
  ///
  /// In ru, this message translates to:
  /// **'Два сигнала'**
  String get toneRising;

  /// No description provided for @toneBell.
  ///
  /// In ru, this message translates to:
  /// **'Колокольчик'**
  String get toneBell;

  /// No description provided for @tonePulse.
  ///
  /// In ru, this message translates to:
  /// **'Частые сигналы'**
  String get tonePulse;

  /// No description provided for @recordVoice.
  ///
  /// In ru, this message translates to:
  /// **'Записать голос'**
  String get recordVoice;

  /// No description provided for @stopRecording.
  ///
  /// In ru, this message translates to:
  /// **'Закончить запись'**
  String get stopRecording;

  /// No description provided for @voiceInUse.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас звучит записанный голос.'**
  String get voiceInUse;

  /// No description provided for @micRefused.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа к микрофону. Разрешите его в настройках телефона.'**
  String get micRefused;

  /// No description provided for @recordFailed.
  ///
  /// In ru, this message translates to:
  /// **'Запись не удалась. Попробуйте снова.'**
  String get recordFailed;

  /// No description provided for @vibrationHeading.
  ///
  /// In ru, this message translates to:
  /// **'Вибрация'**
  String get vibrationHeading;

  /// No description provided for @vibrationOff.
  ///
  /// In ru, this message translates to:
  /// **'Без вибрации'**
  String get vibrationOff;

  /// No description provided for @vibrationNormal.
  ///
  /// In ru, this message translates to:
  /// **'Обычная'**
  String get vibrationNormal;

  /// No description provided for @vibrationStrong.
  ///
  /// In ru, this message translates to:
  /// **'Сильная'**
  String get vibrationStrong;

  /// No description provided for @silentHeading.
  ///
  /// In ru, this message translates to:
  /// **'Когда телефон без звука'**
  String get silentHeading;

  /// No description provided for @silentAloud.
  ///
  /// In ru, this message translates to:
  /// **'Всё равно звучать'**
  String get silentAloud;

  /// No description provided for @silentVibrate.
  ///
  /// In ru, this message translates to:
  /// **'Только вибрация'**
  String get silentVibrate;

  /// No description provided for @nothingOnSilent.
  ///
  /// In ru, this message translates to:
  /// **'На беззвучном напоминание не будет ни слышно, ни ощутимо.'**
  String get nothingOnSilent;

  /// No description provided for @textHeading.
  ///
  /// In ru, this message translates to:
  /// **'Текст'**
  String get textHeading;

  /// No description provided for @setupNext.
  ///
  /// In ru, this message translates to:
  /// **'Дальше'**
  String get setupNext;

  /// No description provided for @setupBack.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get setupBack;

  /// No description provided for @setupStart.
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get setupStart;

  /// No description provided for @setupAllow.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить'**
  String get setupAllow;

  /// No description provided for @setupAllowed.
  ///
  /// In ru, this message translates to:
  /// **'Разрешено ✓'**
  String get setupAllowed;

  /// No description provided for @setupOpenSettings.
  ///
  /// In ru, this message translates to:
  /// **'Открыть настройки телефона'**
  String get setupOpenSettings;

  /// No description provided for @setupBlocked.
  ///
  /// In ru, this message translates to:
  /// **'Сначала разрешите, чтобы продолжить.'**
  String get setupBlocked;

  /// No description provided for @setupWelcomeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройка для близкого'**
  String get setupWelcomeTitle;

  /// No description provided for @setupWelcomeText.
  ///
  /// In ru, this message translates to:
  /// **'Настройте приложение на телефоне близкого человека. Это займёт несколько минут.'**
  String get setupWelcomeText;

  /// No description provided for @setupLocationTitle.
  ///
  /// In ru, this message translates to:
  /// **'Разрешите геолокацию'**
  String get setupLocationTitle;

  /// No description provided for @setupLocationText.
  ///
  /// In ru, this message translates to:
  /// **'LeaveCheck использует геолокацию, чтобы напоминать о вещах, когда вы уходите с места, и показывать последнее место, даже когда приложение закрыто или не используется. Данные о местоположении остаются на этом телефоне. На следующем экране выберите «Разрешить всегда».'**
  String get setupLocationText;

  /// No description provided for @setupWhyLocation.
  ///
  /// In ru, this message translates to:
  /// **'Без этого приложение не заметит, что человек ушёл.'**
  String get setupWhyLocation;

  /// No description provided for @setupNotificationsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Разрешите уведомления'**
  String get setupNotificationsTitle;

  /// No description provided for @setupNotificationsText.
  ///
  /// In ru, this message translates to:
  /// **'Так напоминание появится на экране.'**
  String get setupNotificationsText;

  /// No description provided for @setupWhyNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Без этого напоминание не появится на экране.'**
  String get setupWhyNotifications;

  /// No description provided for @setupActivityTitle.
  ///
  /// In ru, this message translates to:
  /// **'Разрешите данные о движении'**
  String get setupActivityTitle;

  /// No description provided for @setupActivityText.
  ///
  /// In ru, this message translates to:
  /// **'Так приложение сможет распознавать движение человека.'**
  String get setupActivityText;

  /// No description provided for @setupWhyActivity.
  ///
  /// In ru, this message translates to:
  /// **'Это разрешение нужно, чтобы продолжить настройку.'**
  String get setupWhyActivity;

  /// No description provided for @setupNoRideDetection.
  ///
  /// In ru, this message translates to:
  /// **'На этом телефоне нет нужных сервисов Google, поэтому напоминания после поездки на поезде или автобусе работать не будут. Напоминания при уходе с места будут работать.'**
  String get setupNoRideDetection;

  /// No description provided for @setupBatteryTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отключите экономию заряда'**
  String get setupBatteryTitle;

  /// No description provided for @setupBatteryText.
  ///
  /// In ru, this message translates to:
  /// **'Разрешите приложению работать без ограничений.'**
  String get setupBatteryText;

  /// No description provided for @setupWhyBattery.
  ///
  /// In ru, this message translates to:
  /// **'Иначе телефон может закрыть приложение.'**
  String get setupWhyBattery;

  /// No description provided for @setupPhoneTitle.
  ///
  /// In ru, this message translates to:
  /// **'Телефон должен быть при себе'**
  String get setupPhoneTitle;

  /// No description provided for @setupPhoneText.
  ///
  /// In ru, this message translates to:
  /// **'Если телефон останется в забытой сумке, приложение ничего не заметит. Носите его в кармане или в чехле на шее.'**
  String get setupPhoneText;

  /// No description provided for @setupQuietTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отметьте дом'**
  String get setupQuietTitle;

  /// No description provided for @setupQuietText.
  ///
  /// In ru, this message translates to:
  /// **'Уходя из тихого места, человек не получит напоминания. Отметить можно, только находясь там.'**
  String get setupQuietText;

  /// No description provided for @setupOpenQuiet.
  ///
  /// In ru, this message translates to:
  /// **'Отметить место'**
  String get setupOpenQuiet;

  /// No description provided for @setupOptionsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Напоминание'**
  String get setupOptionsTitle;

  /// No description provided for @setupSilentText.
  ///
  /// In ru, this message translates to:
  /// **'Когда телефон без звука, напоминание всё равно звучит вслух, с громкостью будильника. Можно выбрать «Только вибрация». Здесь же можно изменить звук, текст и записать голос.'**
  String get setupSilentText;

  /// No description provided for @setupChangeOptions.
  ///
  /// In ru, this message translates to:
  /// **'Настроить напоминание'**
  String get setupChangeOptions;

  /// No description provided for @setupDoneTitle.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get setupDoneTitle;

  /// No description provided for @setupDoneText.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите «Начать», и приложение заработает. Больше ничего нажимать не нужно.'**
  String get setupDoneText;

  /// No description provided for @tapToFix.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите, чтобы исправить'**
  String get tapToFix;

  /// No description provided for @fix.
  ///
  /// In ru, this message translates to:
  /// **'Исправить'**
  String get fix;

  /// No description provided for @problemLocationOff.
  ///
  /// In ru, this message translates to:
  /// **'Геолокация выключена'**
  String get problemLocationOff;

  /// No description provided for @problemLocationNotStarting.
  ///
  /// In ru, this message translates to:
  /// **'Геолокация не запускается. Проверьте настройки геолокации.'**
  String get problemLocationNotStarting;

  /// No description provided for @problemActivityPermission.
  ///
  /// In ru, this message translates to:
  /// **'Нет разрешения на данные о движении, поэтому напоминания после поездки не появятся.'**
  String get problemActivityPermission;

  /// No description provided for @problemLocationPermission.
  ///
  /// In ru, this message translates to:
  /// **'Нет разрешения на геолокацию. Выберите «Разрешить всегда».'**
  String get problemLocationPermission;

  /// No description provided for @problemNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления запрещены'**
  String get problemNotifications;

  /// No description provided for @openPreviousMap.
  ///
  /// In ru, this message translates to:
  /// **'Предыдущее место на карте'**
  String get openPreviousMap;

  /// No description provided for @lowBattery.
  ///
  /// In ru, this message translates to:
  /// **'Телефон скоро разрядится'**
  String get lowBattery;

  /// No description provided for @lowBatteryWhy.
  ///
  /// In ru, this message translates to:
  /// **'Поставьте его на зарядку, иначе защита отключится.'**
  String get lowBatteryWhy;

  /// No description provided for @lowBatteryChannel.
  ///
  /// In ru, this message translates to:
  /// **'Низкий заряд'**
  String get lowBatteryChannel;

  /// No description provided for @staySetting.
  ///
  /// In ru, this message translates to:
  /// **'Как часто напоминать'**
  String get staySetting;

  /// No description provided for @stayMoreOften.
  ///
  /// In ru, this message translates to:
  /// **'Чаще'**
  String get stayMoreOften;

  /// No description provided for @stayNormal.
  ///
  /// In ru, this message translates to:
  /// **'Обычно'**
  String get stayNormal;

  /// No description provided for @stayLessOften.
  ///
  /// In ru, this message translates to:
  /// **'Реже'**
  String get stayLessOften;

  /// No description provided for @reminderTitleLabel.
  ///
  /// In ru, this message translates to:
  /// **'Заголовок: «Ваши вещи с вами?»'**
  String get reminderTitleLabel;

  /// No description provided for @reminderBodyLabel.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение: «Вы ушли с места. Проверьте вещи.»'**
  String get reminderBodyLabel;

  /// No description provided for @setupProgress.
  ///
  /// In ru, this message translates to:
  /// **'Шаг {step} из {total}'**
  String setupProgress(int step, int total);

  /// No description provided for @stayHint.
  ///
  /// In ru, this message translates to:
  /// **'Если человек пробыл на месте {minutes} мин.'**
  String stayHint(int minutes);

  /// No description provided for @monthDay.
  ///
  /// In ru, this message translates to:
  /// **'{day} {month, select, m1{января} m2{февраля} m3{марта} m4{апреля} m5{мая} m6{июня} m7{июля} m8{августа} m9{сентября} m10{октября} m11{ноября} m12{декабря} other{}}'**
  String monthDay(String day, String month);

  /// No description provided for @whenToday.
  ///
  /// In ru, this message translates to:
  /// **'Вы были здесь до {clock}'**
  String whenToday(String clock);

  /// No description provided for @whenOtherDay.
  ///
  /// In ru, this message translates to:
  /// **'Вы были здесь до {clock}, {date}'**
  String whenOtherDay(String clock, String date);

  /// No description provided for @previousToday.
  ///
  /// In ru, this message translates to:
  /// **'Предыдущее: до {clock}'**
  String previousToday(String clock);

  /// No description provided for @previousOtherDay.
  ///
  /// In ru, this message translates to:
  /// **'Предыдущее: до {clock}, {date}'**
  String previousOtherDay(String clock, String date);

  /// No description provided for @markedAt.
  ///
  /// In ru, this message translates to:
  /// **'Отмечено {date} в {clock}'**
  String markedAt(String date, String clock);

  /// No description provided for @languageSetting.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get languageSetting;

  /// No description provided for @languagePhone.
  ///
  /// In ru, this message translates to:
  /// **'Как на телефоне'**
  String get languagePhone;

  /// No description provided for @languageRussian.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @languageEnglish.
  ///
  /// In ru, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languagePreview.
  ///
  /// In ru, this message translates to:
  /// **'Следующее напоминание'**
  String get languagePreview;

  /// No description provided for @advancedSettings.
  ///
  /// In ru, this message translates to:
  /// **'Точные значения'**
  String get advancedSettings;

  /// No description provided for @advancedNow.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас: {name}'**
  String advancedNow(String name);

  /// No description provided for @advancedCustom.
  ///
  /// In ru, this message translates to:
  /// **'Свои значения'**
  String get advancedCustom;

  /// No description provided for @advancedPresetHelp.
  ///
  /// In ru, this message translates to:
  /// **'Выбор варианта заменит время и размер места.'**
  String get advancedPresetHelp;

  /// No description provided for @advancedStayTime.
  ///
  /// In ru, this message translates to:
  /// **'Сколько пробыть на месте'**
  String get advancedStayTime;

  /// No description provided for @advancedStayArea.
  ///
  /// In ru, this message translates to:
  /// **'Размер места'**
  String get advancedStayArea;

  /// No description provided for @advancedSpeed.
  ///
  /// In ru, this message translates to:
  /// **'Скорость транспорта'**
  String get advancedSpeed;

  /// No description provided for @advancedWalking.
  ///
  /// In ru, this message translates to:
  /// **'Сколько идти после поездки'**
  String get advancedWalking;

  /// No description provided for @unitMinutes.
  ///
  /// In ru, this message translates to:
  /// **'мин'**
  String get unitMinutes;

  /// No description provided for @unitMeters.
  ///
  /// In ru, this message translates to:
  /// **'м'**
  String get unitMeters;

  /// No description provided for @unitKmh.
  ///
  /// In ru, this message translates to:
  /// **'км/ч'**
  String get unitKmh;

  /// No description provided for @unitSeconds.
  ///
  /// In ru, this message translates to:
  /// **'сек'**
  String get unitSeconds;

  /// No description provided for @advancedRange.
  ///
  /// In ru, this message translates to:
  /// **'от {min} до {max} {unit}, рекомендуем {recommended}'**
  String advancedRange(String min, String max, String unit, String recommended);

  /// No description provided for @advancedLimit.
  ///
  /// In ru, this message translates to:
  /// **'{label}: можно от {min} до {max} {unit}. Не сохранено.'**
  String advancedLimit(String label, String min, String max, String unit);

  /// No description provided for @increaseValue.
  ///
  /// In ru, this message translates to:
  /// **'Больше: {label}'**
  String increaseValue(String label);

  /// No description provided for @decreaseValue.
  ///
  /// In ru, this message translates to:
  /// **'Меньше: {label}'**
  String decreaseValue(String label);

  /// No description provided for @saveValues.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get saveValues;

  /// No description provided for @resetToRecommended.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть рекомендуемые'**
  String get resetToRecommended;

  /// No description provided for @valuesSaved.
  ///
  /// In ru, this message translates to:
  /// **'Значения сохранены'**
  String get valuesSaved;

  /// No description provided for @valuesReset.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендуемые значения возвращены'**
  String get valuesReset;

  /// No description provided for @riskTitle.
  ///
  /// In ru, this message translates to:
  /// **'Напоминания могут не прийти:'**
  String get riskTitle;

  /// No description provided for @riskStayTime.
  ///
  /// In ru, this message translates to:
  /// **'при таком времени короткие остановки останутся без напоминания.'**
  String get riskStayTime;

  /// No description provided for @riskStayArea.
  ///
  /// In ru, this message translates to:
  /// **'при таком размере уход с места будет замечен позже.'**
  String get riskStayArea;

  /// No description provided for @riskSpeed.
  ///
  /// In ru, this message translates to:
  /// **'медленный транспорт может быть принят за ходьбу.'**
  String get riskSpeed;

  /// No description provided for @riskWalking.
  ///
  /// In ru, this message translates to:
  /// **'напоминание после поездки придёт позже чем через минуту.'**
  String get riskWalking;

  /// No description provided for @saveAnyway.
  ///
  /// In ru, this message translates to:
  /// **'Всё равно сохранить'**
  String get saveAnyway;

  /// No description provided for @changeValues.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get changeValues;

  /// No description provided for @stayCustomNote.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас действуют свои значения. Выбор варианта заменит время и размер места.'**
  String get stayCustomNote;

  /// No description provided for @reminderPlaces.
  ///
  /// In ru, this message translates to:
  /// **'Места с напоминанием'**
  String get reminderPlaces;

  /// No description provided for @reminderPlacesHelp.
  ///
  /// In ru, this message translates to:
  /// **'Напомним при уходе отсюда, даже после короткого визита (от 1 минуты).'**
  String get reminderPlacesHelp;

  /// No description provided for @noReminderPlaces.
  ///
  /// In ru, this message translates to:
  /// **'Мест пока нет.'**
  String get noReminderPlaces;

  /// No description provided for @markReminderPlace.
  ///
  /// In ru, this message translates to:
  /// **'Отметить это место'**
  String get markReminderPlace;

  /// No description provided for @reminderPlaceName.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get reminderPlaceName;

  /// No description provided for @reminderPlaceNameHint.
  ///
  /// In ru, this message translates to:
  /// **'Например, бассейн'**
  String get reminderPlaceNameHint;

  /// No description provided for @reminderPlaceMessage.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get reminderPlaceMessage;

  /// No description provided for @reminderPlaceMessageHint.
  ///
  /// In ru, this message translates to:
  /// **'Например, возьмите полотенце'**
  String get reminderPlaceMessageHint;

  /// No description provided for @reminderPlaceNeedsText.
  ///
  /// In ru, this message translates to:
  /// **'Сначала введите название и сообщение.'**
  String get reminderPlaceNeedsText;

  /// No description provided for @reminderPlaceNoFix.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось определить, где вы. Место не сохранено. Выйдите на улицу и попробуйте снова.'**
  String get reminderPlaceNoFix;

  /// No description provided for @alreadyReminderPlace.
  ///
  /// In ru, this message translates to:
  /// **'Это место уже отмечено.'**
  String get alreadyReminderPlace;

  /// No description provided for @reminderPlaceSaved.
  ///
  /// In ru, this message translates to:
  /// **'Место сохранено'**
  String get reminderPlaceSaved;

  /// No description provided for @reminderPlaceRemoved.
  ///
  /// In ru, this message translates to:
  /// **'Место удалено'**
  String get reminderPlaceRemoved;

  /// No description provided for @removeReminderPlaceQuestion.
  ///
  /// In ru, this message translates to:
  /// **'Удалить это место? Напоминаний с этим сообщением больше не будет.'**
  String get removeReminderPlaceQuestion;

  /// No description provided for @removeNamed.
  ///
  /// In ru, this message translates to:
  /// **'Удалить: {name}'**
  String removeNamed(String name);

  /// No description provided for @clashIsQuiet.
  ///
  /// In ru, this message translates to:
  /// **'Это место уже отмечено как тихое. Одно место не может быть и тихим, и с напоминанием. Что оставить?'**
  String get clashIsQuiet;

  /// No description provided for @keepQuiet.
  ///
  /// In ru, this message translates to:
  /// **'Оставить тихим'**
  String get keepQuiet;

  /// No description provided for @makeReminderPlace.
  ///
  /// In ru, this message translates to:
  /// **'Сделать местом с напоминанием'**
  String get makeReminderPlace;

  /// No description provided for @keptQuiet.
  ///
  /// In ru, this message translates to:
  /// **'Оставили тихим местом'**
  String get keptQuiet;

  /// No description provided for @clashIsReminderPlace.
  ///
  /// In ru, this message translates to:
  /// **'Здесь уже есть место с напоминанием. Одно место не может быть и тихим, и с напоминанием. Что оставить?'**
  String get clashIsReminderPlace;

  /// No description provided for @keepReminderPlace.
  ///
  /// In ru, this message translates to:
  /// **'Оставить с напоминанием'**
  String get keepReminderPlace;

  /// No description provided for @makeQuiet.
  ///
  /// In ru, this message translates to:
  /// **'Сделать тихим'**
  String get makeQuiet;

  /// No description provided for @keptReminderPlace.
  ///
  /// In ru, this message translates to:
  /// **'Оставили место с напоминанием'**
  String get keptReminderPlace;

  /// No description provided for @homeWifi.
  ///
  /// In ru, this message translates to:
  /// **'Домашний Wi-Fi'**
  String get homeWifi;

  /// No description provided for @homeWifiHelp.
  ///
  /// In ru, this message translates to:
  /// **'Напоминает проверить вещи, когда человек выходит из дома и телефон теряет домашний Wi-Fi.'**
  String get homeWifiHelp;

  /// No description provided for @homeWifiNone.
  ///
  /// In ru, this message translates to:
  /// **'Домашний Wi-Fi не выбран.'**
  String get homeWifiNone;

  /// No description provided for @homeWifiCurrent.
  ///
  /// In ru, this message translates to:
  /// **'Домашний Wi-Fi: {name}'**
  String homeWifiCurrent(String name);

  /// No description provided for @homeWifiSet.
  ///
  /// In ru, this message translates to:
  /// **'Это домашний Wi-Fi'**
  String get homeWifiSet;

  /// No description provided for @homeWifiRemove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать домашний Wi-Fi'**
  String get homeWifiRemove;

  /// No description provided for @homeWifiNotConnected.
  ///
  /// In ru, this message translates to:
  /// **'Сначала подключите телефон к домашнему Wi-Fi и попробуйте снова.'**
  String get homeWifiNotConnected;

  /// No description provided for @homeWifiNoFix.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось определить место, ничего не сохранено. Встаньте у окна и попробуйте снова.'**
  String get homeWifiNoFix;

  /// No description provided for @homeWifiSaved.
  ///
  /// In ru, this message translates to:
  /// **'Домашний Wi-Fi сохранён'**
  String get homeWifiSaved;

  /// No description provided for @homeWifiRemoved.
  ///
  /// In ru, this message translates to:
  /// **'Домашний Wi-Fi убран'**
  String get homeWifiRemoved;

  /// No description provided for @setupHomeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отметьте домашний Wi-Fi'**
  String get setupHomeTitle;

  /// No description provided for @setupHomeText.
  ///
  /// In ru, this message translates to:
  /// **'Дома, когда телефон подключён к домашнему Wi-Fi, отметьте его. Тогда при выходе из дома будет напоминание.'**
  String get setupHomeText;

  /// No description provided for @setupOpenHome.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать домашний Wi-Fi'**
  String get setupOpenHome;

  /// No description provided for @statusAllGood.
  ///
  /// In ru, this message translates to:
  /// **'Всё хорошо'**
  String get statusAllGood;

  /// No description provided for @statusAllGoodText.
  ///
  /// In ru, this message translates to:
  /// **'Когда вы выйдете из дома, будет напоминание.'**
  String get statusAllGoodText;

  /// No description provided for @statusNotSet.
  ///
  /// In ru, this message translates to:
  /// **'Не настроено'**
  String get statusNotSet;

  /// No description provided for @statusNotSetText.
  ///
  /// In ru, this message translates to:
  /// **'Отметьте домашний Wi-Fi, чтобы начать.'**
  String get statusNotSetText;

  /// No description provided for @statusNeedsAttention.
  ///
  /// In ru, this message translates to:
  /// **'Нужно внимание'**
  String get statusNeedsAttention;

  /// No description provided for @lastReminder.
  ///
  /// In ru, this message translates to:
  /// **'Последнее напоминание'**
  String get lastReminder;

  /// No description provided for @checkLeftHome.
  ///
  /// In ru, this message translates to:
  /// **'Вы вышли из дома'**
  String get checkLeftHome;

  /// No description provided for @checkYes.
  ///
  /// In ru, this message translates to:
  /// **'Да'**
  String get checkYes;

  /// No description provided for @checkNoGoBack.
  ///
  /// In ru, this message translates to:
  /// **'Нет, вернуться'**
  String get checkNoGoBack;

  /// No description provided for @checkSkip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить всё'**
  String get checkSkip;

  /// No description provided for @checkAllDone.
  ///
  /// In ru, this message translates to:
  /// **'Всё проверено'**
  String get checkAllDone;

  /// No description provided for @checkGoodTrip.
  ///
  /// In ru, this message translates to:
  /// **'Хорошей дороги!'**
  String get checkGoodTrip;

  /// No description provided for @checkClose.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get checkClose;

  /// No description provided for @checkHaveEverything.
  ///
  /// In ru, this message translates to:
  /// **'Всё взяли?'**
  String get checkHaveEverything;

  /// No description provided for @itemKeys.
  ///
  /// In ru, this message translates to:
  /// **'Ключи'**
  String get itemKeys;

  /// No description provided for @itemWallet.
  ///
  /// In ru, this message translates to:
  /// **'Кошелёк'**
  String get itemWallet;

  /// No description provided for @itemPhone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get itemPhone;

  /// No description provided for @itemGlasses.
  ///
  /// In ru, this message translates to:
  /// **'Очки'**
  String get itemGlasses;

  /// No description provided for @itemGas.
  ///
  /// In ru, this message translates to:
  /// **'Газ выключен'**
  String get itemGas;

  /// No description provided for @itemDoor.
  ///
  /// In ru, this message translates to:
  /// **'Дверь заперта'**
  String get itemDoor;

  /// No description provided for @whatToCheck.
  ///
  /// In ru, this message translates to:
  /// **'Что проверить'**
  String get whatToCheck;

  /// No description provided for @addItem.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get addItem;

  /// No description provided for @addItemHint.
  ///
  /// In ru, this message translates to:
  /// **'Например, зонт'**
  String get addItemHint;

  /// No description provided for @removeItem.
  ///
  /// In ru, this message translates to:
  /// **'Убрать'**
  String get removeItem;

  /// No description provided for @itemsOn.
  ///
  /// In ru, this message translates to:
  /// **'Включено: {count}'**
  String itemsOn(int count);

  /// No description provided for @howToRemind.
  ///
  /// In ru, this message translates to:
  /// **'Как напоминать'**
  String get howToRemind;

  /// No description provided for @notSet.
  ///
  /// In ru, this message translates to:
  /// **'Не выбран'**
  String get notSet;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
