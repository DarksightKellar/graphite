# Graphite — Setup Guide

## Quick Start (5 minutes)

```bash
cd /home/kel/projects/graphite
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
- Android: Install Android Studio (or use existing)
- iOS/MacOS: Xcode must be installed on macOS
- Windows: WSL2 + Flutter CLI is sufficient for mobile development

### Step 2: Clean and Install Dependencies
```bash
cd /home/kel/projects/graphite
flutter clean
flutter pub get
```

This installs all packages from `pubspec.yaml` including:
- **sqflite** — Local SQLite database (Obsidian's core DNA)
- **path_provider** — Platform-specific data directory handling
- **markdown** & **highlighter** — Markdown parsing and syntax highlighting
- **flutter_bloc** — State management for clean architecture
- **go_router** — Declarative routing with URL parameters
- **fl_chart** — Graph visualization library

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

1. **Home Screen** → File explorer with breadcrumbs and search bar
2. **Tap "Create Note" (+)** → Opens editor with blank markdown canvas
3. **Try it out:**
   - Type `# Hello Graphite`
   - Add a link: `[[Another Note]]` (this builds the graph!) 
   - Tag something: `#personal #ideas`
4. **Tap the paintbrush icon** → Toggle preview mode
5. **Navigate to /graph** → Visualize your note connections

---

## Troubleshooting

### "No devices found" or "Device not connected"
- Android: Check USB debugging is enabled (Developer Options)
- iOS Simulator: Open Xcode → Products → Scheme → Select a device, then `flutter run`
- macOS/Windows native: Close and reopen VS Code's DevTools window

### "This app requires platform channels"
- This is normal on first launch — Flutter is initializing the bridge.
- Wait 10 seconds for the splash screen to disappear.

### Freezed generation errors in logs
- These are expected during development. The `.freezed.dart` file gets generated automatically when you run tests or build.
- No action needed unless you see persistent compilation errors after running.

---

## Next Steps (After First Launch)

1. **Create your first note** → Tap the + button, type some markdown
2. **Explore the graph** → Go to `/graph`, create a few more notes with links
3. **Try tag filtering** → Browse all tags and click to filter
4. **Read the code** → All Dart files are in `lib/` — inspect the architecture

---

## Project Roadmap

| Feature | Status | Next Milestone |
|---------|--------|----------------|
| Local SQLite storage | ✅ Scaffolded | Full CRUD with conflict resolution |
| Markdown live preview | ⏳ In progress | Syntax highlighting + table of contents |
| Graph view (fl_chart) | ⏳ Planned | Node/edge rendering with zoom/pan |
| Cross-device sync | ❌ Out of scope v1 | Multi-tab undo stack first |

For more details, see `README.md` and the architecture doc in `/docs/ARCHITECTURE.md`.
