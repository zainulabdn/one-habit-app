# One‑Tap Habit

A tiny, delightful micro‑habit tracker with **premium animations**, a clean **offline data model**, and a fast **Flutter** stack (Riverpod + GoRouter + Hive).

 
------

## ✨ Features

* **One‑tap check‑ins** with streaks and celebratory micro‑animations
* **Animated UI**: progress ring, sheen progress bar, staggered list, glowing FAB
* **Filters**: All / Done / To‑do
* **Stats**: 7‑day bar chart
* **Offline storage** with Hive
* **Routing** with GoRouter
* **State** with Riverpod
* **Settings**: Theme mode (System/Light/Dark), Accent color, Haptics toggle
* **Data**: Export to clipboard (JSON) • Import from pasted JSON

> The app intentionally keeps habits tiny so you can succeed every day.

---

## 🛠️ Tech Stack

* **Flutter** (Material 3)
* **Riverpod** for state management
* **GoRouter** for navigation
* **Hive** (+ adapters) for local persistence
* **FlexColorScheme** for themed palettes (seeded by user accent)
* **fl\_chart** for stats (bar chart)

---

## 🚀 Getting Started

### Prerequisites

* Flutter SDK (stable)
* Xcode (iOS) / Android Studio (Android)

### Install deps & run

```bash
flutter pub get
flutter run
```

If you changed generated adapters in the past, prefer manual adapters (included) or add:

```yaml
dev_dependencies:
  build_runner: any
```

…and run `dart run build_runner build` only if you are using codegen.

---

## 📁 Project Structure (high‑level)

```
lib/
  features/
    add_habit/
    home/
    settings/
    stats/
    welcome/
  data/
    habit_repo.dart
  models/
    habit.dart          # Hive model + manual adapter
  utils/
    date.dart
  widgets/
    habit_tile.dart
```

---

## 🎨 Theming

Theme is controlled by Riverpod providers:

* `themeModeProvider` → `ThemeMode.system | light | dark`
* `accentColorProvider` → seeds the entire app palette

In `main.dart`, build themes dynamically:

```dart
class OneTapHabitApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final seed = ref.watch(accentColorProvider);
    return MaterialApp.router(
      theme: buildLightTheme(seed),
      darkTheme: buildDarkTheme(seed),
      themeMode: mode,
      routerConfig: createRouter(),
    );
  }
}
```

---

## 💾 Data: Export / Import

* **Export**: Settings → *Export to clipboard* → copies JSON array
* **Import**: Settings → *Import from JSON* → paste JSON → (optionally) *Replace existing*

JSON shape:

```json
[
  {
    "id": "uuid",
    "name": "Drink Water",
    "colorValue": 4281558682,
    "emoji": "💧",
    "createdAt": "2025-01-01T00:00:00.000Z",
    "checkins": ["2025-08-01", "2025-08-02"]
  }
]
```

---

## 📊 Stats

* Last‑7‑days aggregated counts with **fl\_chart**
* Chips (Total / Best / Avg) wrap on small screens

---

## 🔔 Haptics

Toggle via Settings. Read `hapticsProvider` before triggering tactile feedback.

---

## 🧩 Assets

If you use illustrations/animations, ensure `pubspec.yaml` paths and **case** match your files exactly, e.g.:

```yaml
flutter:
  assets:
    - assets/svg/Jogging-pana.svg
```

---

## 🏗️ Build

**Android**

```bash
flutter build apk --release
```

**iOS**

```bash
flutter build ipa --release
```

---

## 🧰 Troubleshooting

* **A RenderFlex overflowed…** → Use `Wrap` instead of `Row`, or make chips scrollable.
* **Could not find package build\_runner** → Add to `dev_dependencies` *only* if you use codegen. This repo uses manual Hive adapters.
* **iOS: CardTheme type mismatch** → Ensure `flex_color_scheme` is up‑to‑date (`^8.x`), run `flutter clean && flutter pub get`.
* **Assets not loading** → Verify *exact* path + filename case in `pubspec.yaml`.

---

## 🖼️ Screenshots

Place PNGs here and commit:
<p align="center">
  <img src="/ss1.png" width="220" />
  <img src="/ss2.png" width="220" />
  <img src="/ss3.png" width="220" />
</p>



Reference them above in the README (already wired).

---

## 📄 License

MIT — do what you love. Attribution appreciated.
