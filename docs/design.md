# Geo Alert: Design

The chosen UX is Variant A, "one big status" (`prototypes/variant-a.html`). The prototype holds mock logic only and is never imported by production code. Terms follow `GLOSSARY.md`, and all app text is in Russian.

## Layout

```text
Main screen, protecting        Main screen, not protecting
+----------------------+       +----------------------+
|       (green)        |       |        (red)         |
|          ✓           |       |          !           |
|   Защита работает    |       |  Защита не работает  |
|   Ничего нажимать    |       | Геолокация выключена |
|      не нужно        |       |    [ Исправить ]     |
+----------------------+       +----------------------+
| [ Я что-то забыл ]   |       | [ Я что-то забыл ]   |
|  Вы были здесь до…   |       |  Вы были здесь до…   |
| Для близких: удерж.  |       | Для близких: удерж.  |
+----------------------+       +----------------------+

Reminder (notification)        "Я что-то забыл"
+----------------------+       +----------------------+
| Папа, ваша сумка     |       | Не волнуйтесь        |
| с вами?              |       | Вы были здесь до 14:32|
| Вы ушли с места.     |       | Предыдущее: до 11:05 |
| Проверьте вещи.      |       | Вернитесь или        |
| [ Всё при мне ]      |       | позвоните туда.      |
| [ Я что-то забыл ]   |       | [ Открыть на карте ] |
+----------------------+       | [ На главный экран ] |
                               +----------------------+
```

The real Reminder is a standard Android high-priority notification with two action buttons. The prototype's lock screen card overstates its size. Its look is limited by Android, and it is confirmed in S6.

The previous place was built in S12, with its own map button below its time ("Предыдущее место на карте"). It is not in the prototype.

## Screens and components

```text
App
├─ SetupFlow: one question per screen, 9 steps
│  ├─ Welcome
│  ├─ PermissionStep ×4: location, notifications, activity, battery
│  ├─ PhoneOnBodyAdvice
│  ├─ MarkQuietPlace
│  ├─ ReminderOptions
│  └─ Done
├─ MainScreen
│  ├─ StatusPanel: protecting or not protecting, with Fix
│  ├─ LowBatteryNote (Should)
│  ├─ ForgotButton: shown when a Last Place exists
│  └─ HelperEntry: long press
├─ ForgotScreen: time, advice for Stay or Ride, Open on map, missing-map message
├─ HelperSettings
│  ├─ ReminderOptions: text, sound, vibration, silent choice, record voice, test
│  ├─ StaySetting (Should)
│  └─ QuietPlacesList: mark and remove
└─ ReminderNotification: text, actions, repeat
```

## Design tokens

| Token | Value | Use |
|---|---|---|
| `ink` | `#111111` | Main text |
| `background` | `#FFFFFF` | Screens |
| `ok` | `#0B6B2E` | Protecting panel, with white text |
| `bad` | `#B3141C` | Not protecting panel and "Я что-то забыл" on the Reminder, with white text |
| `primary` | `#0B3D91` | Main buttons |
| `warning` | `#FFF3C4` with `#7A5C00` border | Notes |
| `muted` | `#3D3D3D` | Secondary text |
| `focus` | `#E07B00` | Focus outline |
| Text sizes | body 20, headings 30, status 36, status icon 88 | Logical pixels, and should grow with the phone's text setting |
| Touch targets | main 64 high, secondary 48 high | Logical pixels |
| Corners and spacing | radius 14, screen padding 20, gap 16 | |

## Interaction rules

- **Status:** colour is never the only signal. The icon and words always change too.
- **Nothing to do:** when protecting, the main screen asks for nothing.
- **Setup:** one question per screen, with Back available. Next is blocked until a required permission is granted, and a note says why. A blocked button still responds with an announcement.
- **Quiet Places:** marked only while standing there. With no location fix, nothing is saved and a note says why.
- **Reminder:** both actions and the return to the place stop the repeats. When tries run out, the Reminder stops and the Last Place stays on the main screen.
- **Forgotten item:** the screen is calm in tone. It shows the time prominently and opens the map app on request. If no map app exists, it shows the time and coordinates.
- **Helper settings:** opened by a 2-second long press, with an accessibility action as the equivalent. The prototype uses the keyboard's Enter for this.
- **Wording:** short and plain, addressed to the Wearer. The Helper-only screens are written to the Helper.

## Accessibility

- Text and button colours are chosen to meet AA contrast. Check them again in Flutter, including with enlarged system text.
- Screens must work with Android TalkBack: status changes and errors are announced, and focus moves to the heading on a new screen.
- Large text must reflow without clipping at 360 dp wide.
- Sound, vibration and on-screen text all carry the Reminder, so it isn't lost if one fails.
- The prototype's layout, keyboard use and announcements have only been checked by a scripted logic run and the user's viewing. Test the real app on a phone, ideally with elderly people.

## Release additions: Helper settings

The chosen UX is Variant A, "separate screens" (`prototypes/release-variant-a.html`). It holds mock logic only and is never imported by production code. These screens sit behind the existing long press or code. Text is a draft until the native-speaker check.

```text
Helper settings menu           Reminder Places
+----------------------+       +----------------------+
| Настройки для близких|       | ← Назад              |
| [Места с напоминанием|       | Места с напоминанием |
|   Отмечено: 1       ]|       | Напомним при уходе…  |
| [Точные значения     |       | Бассейн              |
|   Сейчас: Обычно    ]|       | «Возьмите полотенце» |
| [Язык                |       | [Удалить: Бассейн]   |
|   Как на телефоне   ]|       | Название [         ] |
+----------------------+       | Сообщение [        ] |
                               | [Отметить это место] |
                               +----------------------+

Exact values                   Language
+----------------------+       +----------------------+
| ← Назад              |       | ← Назад              |
| Точные значения      |       | Язык                 |
| Сейчас: Обычно       |       | (•) Как на телефоне  |
| [Чаще][Обычно][Реже] |       | ( ) Русский          |
| Сколько пробыть, мин |       | ( ) English          |
| [−]    [ 5 ]    [+]  |       | Следующее напоминание|
| от 1 до 30, реком. 5 |       | Ваши вещи с вами?    |
| … 3 more values …    |       +----------------------+
| [Сохранить]          |
| [Вернуть рекомендуемые]
+----------------------+
```

### Components

```text
HelperSettings: menu, each row showing its current state
├─ ReminderPlacesScreen
│  ├─ PlaceCard ×n: name, message, remove with confirmation
│  ├─ AddPlaceForm: name, message, mark
│  └─ QuietPlaceClashDialog
├─ AdvancedSettingsScreen
│  ├─ CurrentChoice: preset name or "Свои значения"
│  ├─ PresetButtons
│  ├─ ValueField ×4: label with unit, − and +, typed number, limits, recommended
│  ├─ RiskWarning: save anyway or change
│  └─ Save, Reset to recommended
└─ LanguageScreen: phone, Русский, English, with a Reminder preview
```

### Interaction rules

- **Mark a place:** an empty name or message, or no location fix, saves nothing and says why. The buttons stay enabled, so the explanation is always reachable.
- **Quiet Place clash:** the dialog asks which to keep. Keeping it quiet saves no Reminder Place. The same question applies when marking a Reminder Place as a Quiet Place.
- **Values:** − and + step by 1, except Stay area and walking time, which step by 5, and they stop at the limits. Typed values are checked on save; if any is out of limits, nothing is saved and the limits are shown.
- **Risk warning:** Stay time over 15 min, Stay area over 150 m, speed over 20 km/h or walking time over 60 s. These thresholds are starting points. Nothing is saved until "Save anyway".
- **Presets:** save at once and replace only Stay time and area. If speed or walking time are custom, the state stays "Свои значения".
- **Language:** applies at once, including to the next Reminder. "Как на телефоне" follows the phone. A recording or custom message stays as the Helper made it.

### Tokens and accessibility

Uses the existing tokens above, with buttons at least 56 px high and body text at 20 px. Every result appears on screen and is announced to screen readers. Moving to a screen puts focus on its title, and dialogs take focus and close with Back. − and + have labels naming their value. The real screens need checking with TalkBack, since the prototype wasn't tried with a screen reader or walked through by keyboard.
