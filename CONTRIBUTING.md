# Contributing to Super Teclas 🚀

Thank you for your interest in contributing to **Super Teclas**! This is an open-source project focused on high performance, clean architecture, and rapid typing against the clock in Flutter.

All contributions — whether reporting a bug, proposing new vocabulary, improving the UI/UX, or optimizing code — are warmly welcomed.

---

## 📋 Golden Rules of the Project

To maintain consistency and technical excellence across the codebase, all contributions must strictly adhere to the project conventions (also detailed in [`AGENTS.md`](AGENTS.md)):

1. **No Comments in Dart Code:** Code must be self-documenting through clear, descriptive names for classes, methods, and variables.
2. **Absolute Package Imports:** Always use absolute imports with the `package:super_teclas/...` prefix. Never use relative imports (`../`).
3. **No External State Managers:** The project natively uses `ChangeNotifier` + `ListenableBuilder` + `setState`. Do not introduce Provider, Riverpod, BLoC, GetX, or MobX.
4. **New Dependencies:** Do not add new third-party packages to `pubspec.yaml` without opening an issue first to discuss the necessity with maintainers.
5. **Zero Secrets:** Never commit `.env` files, API keys, service account credentials, or build artifacts to the repository.

---

## 🛠️ How to Contribute

### 1. Setting Up the Environment

1. Fork the repository on GitHub.
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/super-teclas-flutter.git
   cd super-teclas-flutter
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```

### 2. Creating a Branch

Create a descriptive branch off `develop` (or `master`):
```bash
git checkout -b feature/my-improvement
# or
git checkout -b fix/bug-fix
```

### 3. Running Lints and Automated Tests

Before submitting your Pull Request, ensure that the static analyzer and all automated tests pass with zero issues:

```bash
# Verify formatting and lints
flutter analyze

# Run the complete automated test suite
flutter test
```

### 4. Commits

Write concise, clear commit messages in the imperative mood:
- ✅ `Fix accuracy calculation on end game page`
- ✅ `Add keyboard shortcut support for mute toggle`
- ❌ `fixed stuff`

### 5. Submitting a Pull Request

1. Push the changes to your fork:
   ```bash
   git push origin feature/my-improvement
   ```
2. Open a Pull Request on the main repository clearly detailing:
   - What problem this PR solves.
   - What was changed.
   - Confirmation that `flutter analyze` and `flutter test` pass with 0 errors.

---

## 💬 Questions or Suggestions?

Feel free to open an [Issue on GitHub](https://github.com/eclesiastes-vaz/super-teclas-flutter/issues) to discuss ideas, feedback, or technical questions about the architecture.
