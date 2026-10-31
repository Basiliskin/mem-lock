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

The previous place appears only once the Should item for two Last Places is built (S12). It is not in the prototype.

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
