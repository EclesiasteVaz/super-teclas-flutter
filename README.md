<div align="center">

# Super Teclas

**A fast-paced typing game against the clock.**

Challenge yourself to type words accurately before time runs out. Compete on the global online ranking, improve your speed and precision, and master words in both **Portuguese** and **English**.

[![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platforms-Android%20|%20iOS%20|%20Web%20|%20Linux%20|%20Windows-lightgrey)]()

</div>

---

## Features

- **Dual Language** — Full support for Portuguese and English with automatic locale detection
- **500+ Words per Language** — Curated word banks across 3 difficulty levels (easy, medium, hard)
- **Real-time Feedback** — Character-by-character coloring as you type (green = correct, red = wrong)
- **Countdown Timer** — Color-coded urgency: green (>5s), orange (>3s), red (≤3s)
- **Online Ranking** — Supabase-powered global leaderboard with encrypted local username storage
- **Score & Stats** — Tracks score, accuracy, words per minute, and words completed
- **Background Music** — Immersive audio with victory/defeat sound effects
- **Pause & Mute** — Full game controls with keyboard shortcuts (ESC to pause)
- **Confetti Animation** — Custom-built celebration with 60-particle `CustomPainter` effect
- **PWA Ready** — Installable as a Progressive Web App with offline capabilities
- **Responsive Design** — Adapts to different screen sizes across all platforms

---

## Screenshots

<!-- Add your screenshots here -->

| Home | Gameplay | End Game |
|:----:|:--------:|:--------:|
| ![Home](docs/screenshots/home.png) | ![Game](docs/screenshots/game.png) | ![End](docs/screenshots/end.png) |

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | [Flutter](https://flutter.dev) (stable) |
| Language | [Dart](https://dart.dev) 3.5+ |
| State Management | `ChangeNotifier` + `ListenableBuilder` (no external packages) |
| Backend | [Supabase](https://supabase.com) (online ranking) |
| Local Storage | [SharedPreferences](https://pub.dev/packages/shared_preferences) |
| Audio | [audioplayers](https://pub.dev/packages/audioplayers) 5.2.1 |
| Encryption | [encrypt](https://pub.dev/packages/encrypt) 5.0.3 (AES-256) |
| i18n | Custom `InheritedWidget` + `AppStrings` (PT/EN) |
| Deployment | [Vercel](https://vercel.com) (web) |

---

## Getting Started

### Prerequisites

- **Flutter SDK** — [Install Flutter](https://docs.flutter.dev/get-started/install) (stable channel, ≥3.38.4)
- **Dart SDK** — Comes bundled with Flutter (≥3.5.0)
- **IDE** — [VS Code](https://code.visualstudio.com/) with Flutter extension, or [Android Studio](https://developer.android.com/studio)
- **Supabase Account** — Free tier works fine at [supabase.com](https://supabase.com) (for online ranking)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/your-username/super-teclas-flutter.git
   cd super-teclas-flutter
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables** (optional — game works offline without Supabase)

   Copy the `.env.example` template:

   ```bash
   cp .env.example .env
   ```

   Fill in your Supabase project credentials in `.env`:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```

   See [COMPETITION.md](COMPETITION.md) for detailed Supabase setup including table creation and RLS policies.

4. **Run the app**

   **Option A: Web (Chrome with `--dart-define`)**
   ```bash
   flutter run -d chrome \
     --dart-define=SUPABASE_URL=https://vstopwdfkoizsbveeicn.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=sb_publishable_QTy4SSQFlj7L9WIK3HabvQ_KP3EFXSN
   ```

   **Option B: Mobile / Desktop (using `.env`)**
   ```bash
   # Android
   flutter run -d android

   # iOS
   flutter run -d ios

   # macOS / Linux / Windows
   flutter run -d macos
   flutter run -d linux
   flutter run -d windows
   ```

   **Option C: Offline Mode (no ranking backend)**
   ```bash
   flutter run -d chrome
   ```

---

## Project Structure

```
super-teclas-flutter/
├── lib/
│   ├── main.dart                              # Entry point, locale, theme, Supabase init
│   ├── utils/
│   │   ├── game_color_status.dart             # Color mapping utility
│   │   └── game_time.dart                     # Time formatting utility
│   └── src/
│       ├── data/
│       │   ├── i18n/
│       │   │   └── app_strings.dart           # 43+ translated strings (PT/EN)
│       │   ├── models/
│       │   │   └── word_model.dart            # WordModel with difficulty
│       │   └── words/
│       │       └── word_bank.dart             # JSON word loader with fallback
│       ├── services/
│       │   ├── game_service.dart              # Core game logic (ChangeNotifier)
│       │   ├── ranking_service.dart           # Supabase ranking CRUD
│       │   └── storage_service.dart           # Encrypted local username storage
│       └── ui/
│           ├── pages/
│           │   ├── home_page.dart             # Home screen with ranking
│           │   ├── game_page.dart             # Main gameplay screen
│           │   └── end_game_page.dart         # Results with confetti
│           └── widgets/
│               ├── button_costum_widget.dart   # Reusable styled button
│               └── title_game_widget.dart     # Two-tone title widget
├── test/
│   ├── game_service_test.dart                 # Unit tests for game logic
│   ├── word_model_test.dart                   # Unit tests for word model
│   ├── widget_test.dart                       # Widget tests for HomePage
│   ├── game_page_test.dart                    # Widget tests for GamePage
│   └── end_game_page_test.dart               # Widget tests for EndGamePage
├── assets/
│   ├── audios/                                # Background music + SFX
│   ├── images/                                # App icon
│   └── words/
│       ├── pt.json                            # 200 Portuguese words
│       └── en.json                            # 204 English words
├── web/                                       # Web config, PWA manifest, icons
├── android/                                   # Android platform config
├── ios/                                       # iOS platform config
├── linux/                                     # Linux platform config
├── windows/                                   # Windows platform config
├── pubspec.yaml
├── vercel.json
├── AGENTS.md                                  # Agent instructions for AI assistants
└── COMPETITION.md                             # Online ranking system documentation
```

---

## Architecture

### State Management

The game uses Flutter's built-in `ChangeNotifier` pattern — no external state management packages:

- **`GameService`** — Core game state (words, score, accuracy, timer). Extends `ChangeNotifier` and notifies listeners on every mutation.
- **`ListenableBuilder`** — UI subscribes to `GameService` changes for reactive updates.
- **`LocaleProvider`** — `InheritedWidget` that injects locale into the widget tree.

### Data Flow

```
User Input (onChanged)
    │
    ├── recordKeystroke()        → totalKeystrokes++
    ├── addCorrectKeystroke()    → correctKeystrokes++ (if matches)
    └── writing(word)            → validate → advance word → check win
                                         │
                                         └── notifyListeners() → UI rebuilds
```

### Game Mechanics

| Metric | Formula |
|--------|---------|
| Score | `(wordsCompleted / totalWords) × 100` |
| Accuracy | `(correctKeystrokes / totalKeystrokes) × 100` |
| Words/min | `(wordsCompleted / elapsedSeconds) × 60` |
| Timer | `word.length.clamp(8, 15)` seconds per word |

### Navigation

All navigation uses `Navigator.pushReplacement` — each screen replaces the previous one (no back stack):

```
HomePage → GamePage → EndGamePage → (restart or home)
```

---

## Configuration

### Supabase (Online Ranking)

1. Create a project at [supabase.com](https://supabase.com)
2. Run the SQL from [COMPETITION.md](COMPETITION.md) to create the `rankings` table
3. Copy your **Project URL** and **anon key** into `lib/main.dart`
4. Enable RLS with the provided policies

The game works fully offline — ranking features gracefully degrade when Supabase is unavailable.

### Adding Words

Edit the JSON files in `assets/words/`:

```json
[
  {"word": "YourWord", "difficulty": "easy|medium|hard"}
]
```

Each language needs ~200 words for a good experience. The `WordBank` includes a hardcoded fallback of 16 words per language if JSON loading fails.

---

## Testing

### Run All Tests

```bash
flutter test
```

### Run Specific Test Files

```bash
flutter test test/game_service_test.dart       # Unit tests
flutter test test/word_model_test.dart         # Model tests
flutter test test/widget_test.dart             # HomePage widget tests
flutter test test/game_page_test.dart          # GamePage widget tests
flutter test test/end_game_page_test.dart      # EndGamePage widget tests
```

### Test Coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Test Approach

- **Unit tests** — Game logic, word model validation, scoring
- **Widget tests** — UI rendering, navigation, audio mocking
- Audio channels are always mocked (`setMockMethodCallHandler`) — no real audio in tests
- Each test file has its own `_buildApp()` helper with localization delegates

---

## Deployment

### Web (Vercel)

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=https://vstopwdfkoizsbveeicn.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_QTy4SSQFlj7L9WIK3HabvQ_KP3EFXSN

vercel --prod
```

The `vercel.json` is pre-configured to serve from `build/web`.

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

### Desktop

```bash
flutter build linux --release
flutter build windows --release
```

---

## Contributing

Contributions are welcome! Here's how to get started:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feat/my-feature`)
3. **Commit** your changes (`git commit -m 'feat: add my feature'`)
4. **Push** to the branch (`git push origin feat/my-feature`)
5. **Open** a Pull Request

### Development Guidelines

- Follow the code conventions in [AGENTS.md](AGENTS.md)
- Run `flutter analyze` before submitting
- Run `flutter test` to ensure all tests pass
- No external state management packages (keep it pure Flutter)
- No comments in code unless explicitly requested
- Use `package:` imports (absolute), never relative imports
- Add tests for new features

---

## Roadmap

- [ ] Edge Function for server-side score validation
- [ ] Supabase Auth integration (Google, GitHub, Email)
- [ ] Dedicated ranking page with pagination
- [ ] Difficulty selection (easy/medium/hard)
- [ ] Language-specific ranking filters
- [ ] High score persistence across sessions
- [ ] Custom word lists
- [ ] Sound toggle persistence

---

## Known Issues

- High score is stored in memory only — lost on app restart
- Background music (5MB) may slow initial web load
- Username cannot be changed after first save
- No server-side score validation (anon key is public by design in Supabase)

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- [Flutter](https://flutter.dev) — Beautiful, fast UI framework
- [Supabase](https://supabase.com) — Open source backend for the ranking system
- [audioplayers](https://pub.dev/packages/audioplayers) — Cross-platform audio playback
- Word audio credits: [Freesound](https://freesound.org) for sound effects

---

<div align="center">

**Built with Flutter**

</div>
