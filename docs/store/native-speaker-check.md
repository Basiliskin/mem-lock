# Native-speaker check (AC-13.5)

**Status: not done.** Each language needs a native speaker to check every line, especially Reminders and warnings. Generated from `lib/l10n/app_ru.arb` and `app_en.arb`; edit those files, not this one. Mark who checked and when:

- Russian: not checked
- English: not checked

Also check `fastlane/metadata/android/*/` (store text).

| Key | Russian | English |
|---|---|---|
| `appName` | LeaveCheck | LeaveCheck |
| `protecting` | Защита работает | Protection is on |
| `notProtecting` | Защита не работает | Protection is off |
| `nothingToDo` | Ничего нажимать не нужно | There is nothing you need to press |
| `enable` | Включить защиту | Turn on protection |
| `startFailed` | Не удалось включить. Проверьте разрешения в настройках. | Couldn't turn on. Check the permissions in settings. |
| `serviceTitle` | Защита работает | Protection is on |
| `serviceText` | Напомним о вещах, когда вы уйдёте | We'll remind you about your things when you leave |
| `reminderChannel` | Напоминания | Reminders |
| `reminderTitle` | Ваши вещи с вами? | Do you have your things? |
| `actionHaveEverything` | Всё при мне | I have everything |
| `actionForgot` | Я что-то забыл | I forgot something |
| `reminderBody` | Вы ушли с места. Проверьте вещи. | You have left a place. Check your things. |
| `dontWorry` | Не волнуйтесь | Don't worry |
| `goBackAdvice` | Вернитесь на это место или позвоните туда. | Go back to this place or call them. |
| `openMap` | Открыть на карте | Open on map |
| `toMain` | На главный экран | To main screen |
| `noMapApp` | Не найдено приложение карт. | No map app found. |
| `coordinates` | Координаты | Coordinates |
| `helperEntry` | Для близких: удерживайте 2 секунды | For family: hold for 2 seconds |
| `quietPlaces` | Тихие места | Quiet Places |
| `noQuietPlaces` | Тихих мест пока нет. | No Quiet Places yet. |
| `markQuietPlace` | Отметить место, где я сейчас | Mark where I am now |
| `noFixToMark` | Место не сохранено: не удалось точно определить, где вы. Проверьте, что геолокация включена, выйдите ближе к окну или на улицу и попробуйте снова. | Place not saved: couldn't tell exactly where you are. Check that location is on, move closer to a window or go outside, and try again. |
| `alreadyQuiet` | Это место уже отмечено. | This place is already marked. |
| `saveFailed` | Не удалось сохранить. Попробуйте снова. | Couldn't save. Try again. |
| `remove` | Удалить | Remove |
| `removeQuestion` | Удалить это место? Снова отметить его можно будет, только находясь там. | Remove this place? You can only mark it again while you are there. |
| `confirmRemove` | Да, удалить | Yes, remove |
| `cancel` | Отмена | Cancel |
| `helperSettings` | Настройки для близких | Settings for family |
| `reminderOptions` | Напоминание | Reminder |
| `reminderChannelNoVibration` | Напоминания без вибрации | Reminders without vibration |
| `reminderChannelStrong` | Напоминания с сильной вибрацией | Reminders with strong vibration |
| `testReminder` | Проверить напоминание | Test the Reminder |
| `stopTest` | Остановить проверку | Stop the test |
| `testFailed` | Не удалось запустить проверку. | Couldn't start the test. |
| `soundHeading` | Звук | Sound |
| `toneRising` | Два сигнала | Two tones |
| `toneBell` | Колокольчик | Bell |
| `tonePulse` | Частые сигналы | Rapid tones |
| `recordVoice` | Записать голос | Record a voice |
| `stopRecording` | Закончить запись | Finish recording |
| `voiceInUse` | Сейчас звучит записанный голос. | The recorded voice is playing now. |
| `micRefused` | Нет доступа к микрофону. Разрешите его в настройках телефона. | No access to the microphone. Allow it in the phone settings. |
| `recordFailed` | Запись не удалась. Попробуйте снова. | Recording didn't work. Try again. |
| `vibrationHeading` | Вибрация | Vibration |
| `vibrationOff` | Без вибрации | No vibration |
| `vibrationNormal` | Обычная | Normal |
| `vibrationStrong` | Сильная | Strong |
| `silentHeading` | Когда телефон без звука | When the phone is on silent |
| `silentAloud` | Всё равно звучать | Play aloud anyway |
| `silentVibrate` | Только вибрация | Vibrate only |
| `nothingOnSilent` | На беззвучном напоминание не будет ни слышно, ни ощутимо. | On silent, the Reminder can't be heard or felt. |
| `textHeading` | Текст | Text |
| `setupNext` | Дальше | Next |
| `setupBack` | Назад | Back |
| `setupStart` | Начать | Start |
| `setupAllow` | Разрешить | Allow |
| `setupAllowed` | Разрешено ✓ | Allowed ✓ |
| `setupOpenSettings` | Открыть настройки телефона | Open phone settings |
| `setupBlocked` | Сначала разрешите, чтобы продолжить. | Allow this first to continue. |
| `setupWelcomeTitle` | Настройка для близкого | Setup for your family member |
| `setupWelcomeText` | Настройте приложение на телефоне близкого человека. Это займёт несколько минут. | Set up the app on your family member's phone. It takes a few minutes. |
| `setupLocationTitle` | Разрешите геолокацию | Allow location |
| `setupLocationText` | LeaveCheck использует геолокацию, чтобы напоминать о вещах, когда вы уходите с места, и показывать последнее место, даже когда приложение закрыто или не используется. Данные о местоположении остаются на этом телефоне. На следующем экране выберите «Разрешить всегда». | LeaveCheck uses your location to give a Reminder when you leave a place, and to show the last place, even when the app is closed or not in use. Location stays on this phone. On the next screen, choose "Allow all the time". |
| `setupWhyLocation` | Без этого приложение не заметит, что человек ушёл. | Without this, the app won't notice that the person has left. |
| `setupNotificationsTitle` | Разрешите уведомления | Allow notifications |
| `setupNotificationsText` | Так напоминание появится на экране. | This lets the Reminder appear on the screen. |
| `setupWhyNotifications` | Без этого напоминание не появится на экране. | Without this, the Reminder won't appear on the screen. |
| `setupActivityTitle` | Разрешите данные о движении | Allow physical activity data |
| `setupActivityText` | Так приложение сможет распознавать движение человека. | This lets the app recognize the person's movement. |
| `setupWhyActivity` | Это разрешение нужно, чтобы продолжить настройку. | This permission is needed to continue setup. |
| `setupNoRideDetection` | На этом телефоне нет нужных сервисов Google, поэтому напоминания после поездки на поезде или автобусе работать не будут. Напоминания при уходе с места будут работать. | This phone doesn't have the Google services needed, so Reminders after a train or bus ride won't work. Reminders when leaving a place will work. |
| `setupBatteryTitle` | Отключите экономию заряда | Turn off battery saving |
| `setupBatteryText` | Разрешите приложению работать без ограничений. | Let the app run without restrictions. |
| `setupWhyBattery` | Иначе телефон может закрыть приложение. | Otherwise the phone may close the app. |
| `setupPhoneTitle` | Телефон должен быть при себе | Keep the phone with you |
| `setupPhoneText` | Если телефон останется в забытой сумке, приложение ничего не заметит. Носите его в кармане или в чехле на шее. | If the phone stays in a forgotten bag, the app won't notice anything. Carry it in a pocket or a neck case. |
| `setupQuietTitle` | Отметьте дом | Mark home |
| `setupQuietText` | Уходя из тихого места, человек не получит напоминания. Отметить можно, только находясь там. | Leaving a Quiet Place gives no Reminder. You can only mark it while you are there. |
| `setupOpenQuiet` | Отметить место | Mark a place |
| `setupOptionsTitle` | Напоминание | Reminder |
| `setupSilentText` | Когда телефон без звука, напоминание всё равно звучит вслух, с громкостью будильника. Можно выбрать «Только вибрация». Здесь же можно изменить звук, текст и записать голос. | When the phone is on silent, the Reminder still plays aloud at alarm volume. You can choose "Vibrate only". You can also change the sound and text, and record a voice, here. |
| `setupChangeOptions` | Настроить напоминание | Set up the Reminder |
| `setupDoneTitle` | Готово | All done |
| `setupDoneText` | Нажмите «Начать», и приложение заработает. Больше ничего нажимать не нужно. | Press "Start" and the app will begin working. There is nothing else to press. |
| `tapToFix` | Нажмите, чтобы исправить | Tap to fix |
| `fix` | Исправить | Fix |
| `problemLocationOff` | Геолокация выключена | Location is off |
| `problemLocationNotStarting` | Геолокация не запускается. Проверьте настройки геолокации. | Location isn't starting. Check the location settings. |
| `problemActivityPermission` | Нет разрешения на данные о движении, поэтому напоминания после поездки не появятся. | No permission for physical activity data, so Reminders after a ride won't appear. |
| `problemLocationPermission` | Нет разрешения на геолокацию. Выберите «Разрешить всегда». | No location permission. Choose "Allow all the time". |
| `problemNotifications` | Уведомления запрещены | Notifications are blocked |
| `openPreviousMap` | Предыдущее место на карте | Previous place on map |
| `lowBattery` | Телефон скоро разрядится | The phone will run out of battery soon |
| `lowBatteryWhy` | Поставьте его на зарядку, иначе защита отключится. | Put it on charge, or protection will turn off. |
| `lowBatteryChannel` | Низкий заряд | Low battery |
| `staySetting` | Как часто напоминать | How often to remind |
| `stayMoreOften` | Чаще | More often |
| `stayNormal` | Обычно | Normal |
| `stayLessOften` | Реже | Less often |
| `reminderTitleLabel` | Заголовок: «Ваши вещи с вами?» | Title: "Do you have your things?" |
| `reminderBodyLabel` | Сообщение: «Вы ушли с места. Проверьте вещи.» | Message: "You have left a place. Check your things." |
| `setupProgress` | Шаг {step} из {total} | Step {step} of {total} |
| `stayHint` | Если человек пробыл на месте {minutes} мин. | If the person stayed in a place for {minutes} min. |
| `monthDay` | {day} {month, select, m1{января} m2{февраля} m3{марта} m4{апреля} m5{мая} m6{июня} m7{июля} m8{августа} m9{сентября} m10{октября} m11{ноября} m12{декабря} other{}} | {month, select, m1{January} m2{February} m3{March} m4{April} m5{May} m6{June} m7{July} m8{August} m9{September} m10{October} m11{November} m12{December} other{}} {day} |
| `whenToday` | Вы были здесь до {clock} | You were here until {clock} |
| `whenOtherDay` | Вы были здесь до {clock}, {date} | You were here until {clock}, {date} |
| `previousToday` | Предыдущее: до {clock} | Previous: until {clock} |
| `previousOtherDay` | Предыдущее: до {clock}, {date} | Previous: until {clock}, {date} |
| `markedAt` | Отмечено {date} в {clock} | Marked {date} at {clock} |
| `languageSetting` | Язык | Language |
| `languagePhone` | Как на телефоне | Same as the phone |
| `languageRussian` | Русский | Русский |
| `languageEnglish` | English | English |
| `languagePreview` | Следующее напоминание | Next Reminder |
| `advancedSettings` | Точные значения | Exact values |
| `advancedNow` | Сейчас: {name} | Now: {name} |
| `advancedCustom` | Свои значения | Custom values |
| `advancedPresetHelp` | Выбор варианта заменит время и размер места. | Choosing one replaces the time and place size. |
| `advancedStayTime` | Сколько пробыть на месте | Time to count as a stay |
| `advancedStayArea` | Размер места | Size of the place |
| `advancedSpeed` | Скорость транспорта | Vehicle speed |
| `advancedWalking` | Сколько идти после поездки | Walking time after a ride |
| `unitMinutes` | мин | min |
| `unitMeters` | м | m |
| `unitKmh` | км/ч | km/h |
| `unitSeconds` | сек | sec |
| `advancedRange` | от {min} до {max} {unit}, рекомендуем {recommended} | from {min} to {max} {unit}, recommended {recommended} |
| `advancedLimit` | {label}: можно от {min} до {max} {unit}. Не сохранено. | {label}: must be {min} to {max} {unit}. Not saved. |
| `increaseValue` | Больше: {label} | Increase: {label} |
| `decreaseValue` | Меньше: {label} | Decrease: {label} |
| `saveValues` | Сохранить | Save |
| `resetToRecommended` | Вернуть рекомендуемые | Reset to recommended |
| `valuesSaved` | Значения сохранены | Values saved |
| `valuesReset` | Рекомендуемые значения возвращены | Recommended values restored |
| `riskTitle` | Напоминания могут не прийти: | Reminders may be missed: |
| `riskStayTime` | при таком времени короткие остановки останутся без напоминания. | short stops will give no Reminder. |
| `riskStayArea` | при таком размере уход с места будет замечен позже. | leaving will be noticed later. |
| `riskSpeed` | медленный транспорт может быть принят за ходьбу. | a slow vehicle could be mistaken for walking. |
| `riskWalking` | напоминание после поездки придёт позже чем через минуту. | the Reminder after a ride will take over a minute. |
| `saveAnyway` | Всё равно сохранить | Save anyway |
| `changeValues` | Изменить | Change |
| `stayCustomNote` | Сейчас действуют свои значения. Выбор варианта заменит время и размер места. | Custom values are in use. Choosing one replaces the time and place size. |
| `reminderPlaces` | Места с напоминанием | Reminder Places |
| `reminderPlacesHelp` | Напомним при уходе отсюда, даже после короткого визита (от 1 минуты). | Reminds on leaving, even after a short visit (1 minute or more). |
| `noReminderPlaces` | Мест пока нет. | No places yet. |
| `markReminderPlace` | Отметить это место | Mark this place |
| `reminderPlaceName` | Название | Name |
| `reminderPlaceNameHint` | Например, бассейн | For example, pool |
| `reminderPlaceMessage` | Сообщение | Message |
| `reminderPlaceMessageHint` | Например, возьмите полотенце | For example, take your towel |
| `reminderPlaceNeedsText` | Сначала введите название и сообщение. | Enter a name and message first. |
| `reminderPlaceNoFix` | Не удалось определить, где вы. Место не сохранено. Выйдите на улицу и попробуйте снова. | Could not find your location, so nothing was saved. Go outside and try again. |
| `alreadyReminderPlace` | Это место уже отмечено. | This place is already marked. |
| `reminderPlaceSaved` | Место сохранено | Place saved |
| `reminderPlaceRemoved` | Место удалено | Place removed |
| `removeReminderPlaceQuestion` | Удалить это место? Напоминаний с этим сообщением больше не будет. | Remove this place? Its Reminders will stop. |
| `removeNamed` | Удалить: {name} | Remove: {name} |
| `clashIsQuiet` | Это место уже отмечено как тихое. Одно место не может быть и тихим, и с напоминанием. Что оставить? | This place is already a Quiet Place. A place cannot be both. Which should it be? |
| `keepQuiet` | Оставить тихим | Keep it quiet |
| `makeReminderPlace` | Сделать местом с напоминанием | Make it a Reminder Place |
| `keptQuiet` | Оставили тихим местом | Kept as a Quiet Place |
| `clashIsReminderPlace` | Здесь уже есть место с напоминанием. Одно место не может быть и тихим, и с напоминанием. Что оставить? | This place is already a Reminder Place. A place cannot be both. Which should it be? |
| `keepReminderPlace` | Оставить с напоминанием | Keep the Reminder Place |
| `makeQuiet` | Сделать тихим | Make it quiet |
| `keptReminderPlace` | Оставили место с напоминанием | Kept as a Reminder Place |
