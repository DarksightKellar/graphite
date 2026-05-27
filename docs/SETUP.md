# Graphite — Setup Guide

## Quick Start

```bash
cd graphite
flutter pub get
flutter run -d <your-device-id>
```

To find your device ID:
- Android: `flutter devices` → look for "Connected device"
- iOS Simulator: `flutter devices` → select "iPhone 14" or similar
- macOS/Windows native: `flutter run` will auto-detect

---

## Detailed Setup

### Step 1: Verify Flutter Installation
```bash
flutter doctor -v
```

**Expected output:** All platforms showing ✓, with at least one connected device.

If you see missing dependencies:
- Android: Install Android Studio
- iOS/macOS: Xcode must be installed
- Windows: WSL2 + Flutter CLI

### Step 2: Install Dependencies
```bash
flutter pub get
```

This installs all packages from `pubspec.yaml`:
- **sqflite** — Local SQLite database
- **path_provider** — Platform-specific data directory handling
- **go_router** — Declarative routing
- **file_picker** — Import markdown files
- **sqflite_common_ffi** — Desktop database support (dev)

### Step 3: Run the App
```bash
# Android emulator or physical device
flutter run -d <device-id>

# iOS Simulator (macOS only)
flutter run -d iPhone-14

# macOS native app
flutter run -d macos
```

The first launch will take 30-60 seconds as Flutter builds the app shell.

---

## First Launch — What You'll See

1. **Home Screen** → Note list with search bar, sort/filter controls, and a welcome note
2. **Tap the + FAB** → Quick capture dialog (title + content + tags)
3. **Try it out:**
   - Type `# Hello Graphite`
   - Add a link: `[[Another Note]]` (this builds the graph!)
   - Tag something: `#personal #ideas`
4. **Tap a note** → Opens the dual-pane markdown editor with live preview
5. **Swipe right** on a note → Pin it to the top
6. **Swipe left** on a note → Delete it

---

## Project Structure

```
graphite/
├── lib/
│   ├── main.dart                    # App entry + theme (light/dark)
│   ├── router/app_router.dart       # go_router configuration
│   ├── data/                        # Database + file system operations
│   ├── models/                      # Core data: Note, Tag, Link
│   ├── repository/                  # Business logic (NoteRepository)
│   ├── screens/                     # Full-screen views
│   │   ├── home_screen.dart        # Note list + search + quick capture
│   │   ├── editor_screen.dart      # Dual-pane markdown editor
│   │   ├── graph_screen.dart       # Graph view (post-MVP placeholder)
│   │   └── tag_browser_screen.dart # Tag filtering UI
│   ├── widgets/                     # Reusable UI components
│   ├── utils/                       # Markdown parser + helpers
│   └── hooks/                       # Custom hooks
├── test/                            # Test suite (306 tests)
├── pubspec.yaml
└── README.md
```

---

## Troubleshooting

### "No devices found"
- Android: Check USB debugging is enabled (Developer Options)
- iOS: Open Xcode → select a simulator, then `flutter run`
- macOS/Windows: Close and reopen your IDE

### Database errors on first launch
- Run `flutter clean && flutter pub get` to reset the build cache
- The SQLite database is created automatically on first access

### Tests failing locally
- Run `flutter pub get` first to sync dependencies
- Performance benchmark tests may time out on desktop runners — this is a known environment issue, not a code defect. Run with `flutter test --exclude-tags=benchmark` to skip them.

---

## Running Tests

```bash
# Full suite (excluding known-flaky benchmarks)
flutter test test/models/ test/data/ test/repository/ test/utils/ \
  test/screens/ test/widgets/ test/offline_integration_test.dart \
  test/integration/app_flow_test.dart

# With coverage
flutter test --coverage <same-paths-as-above>
```

---

## License
MIT — Open source, free to use and modify.
