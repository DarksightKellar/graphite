# Graphite — Quick Start Guide

A modern Obsidian clone in Flutter with local-first SQLite storage.

## 🚀 Get Running (3 minutes)

### Step 1: Verify Flutter Installation
```bash
cd /home/kel/projects/graphite
flutter doctor -v
```
**Expected:** All platforms showing ✓, at least one connected device.

If you see missing dependencies:
- **Android:** Install Android Studio (or use existing)
- **iOS/MacOS:** Xcode must be installed on macOS
- **Windows:** WSL2 + Flutter CLI is sufficient for mobile development

### Step 2: Clean and Install Dependencies
```bash
flutter clean && flutter pub get
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

**To find your device ID:**
```bash
flutter devices
```
Look for "Connected device" or list all available simulators.

---

## 🎯 First Launch — What You'll See

1. **Home Screen** → File explorer with search bar, folder navigation, and note cards
2. **Tap the + menu (top right)** → Options to create new notes or view graph
3. **Create a quick note:**
   - Tap the **+** button in app bar
   - Type your title
   - Automatically opens editor screen
4. **Try markdown editing:**
   - Type `# Heading` → renders as H1 in preview
   - Add a link: `[[Another Note]]` (this builds the graph!)
   - Tag something: `#personal #ideas`
5. **Toggle preview mode** → Tap paintbrush icon to see rendered markdown
6. **Navigate to Graph** → Go to `/graph` tab to visualize note connections

---

## 📁 Project Structure (Clean Architecture)

```
graphite/
├── lib/
│   ├── main.dart                          # App entry + theme
│   ├── router/app_router.dart             # go_router configuration
│   ├── data/                              # Database operations
│   │   └── database.dart                  # SQLite CRUD (notes, tags, links)
│   ├── models/                            # Core data: Note, Tag, Link
│   ├── screens/                           # UI components
│   │   ├── home_screen.dart              # File explorer + quick capture
│   │   ├── editor_screen.dart            # Dual-pane markdown editor
│   │   ├── graph_screen.dart             # Graph visualization canvas
│   │   └── tag_browser_screen.dart       # Tag filtering UI
│   └── widgets/                           # Reusable UI elements
├── pubspec.yaml                          # Flutter dependencies
├── README.md                             # Project overview
└── scripts/build.sh                      # Automated setup script
```

---

## 🔮 Next Steps (Post-MVP)

| Feature | Status | Priority |
|---------|--------|----------|
| Cross-platform file picker (open files outside vault) | ⏳ Planned | High |
| Full syntax highlighting with highlighter package | ⏳ Planned | High |
| Advanced graph filters (show recent links, hide dead ends) | ❌ Out of scope v1 | Medium |
| Undo/redo system with conflict resolution | ❌ Out of scope v1 | Low |

---

## 💻 Platform-Specific Build Commands

### Android APK
```bash
flutter build apk --debug  # Debug build for testing
flutter build apk --release # Production release (APK larger)
```

### iOS App (macOS only)
```bash
flutter build ios --debug --no-codesign   # No signing required for simulator
```

### macOS Native App
```bash
flutter build macos --debug               # Build DMG installer
```

---

## 🐛 Troubleshooting

### "No devices found" or "Device not connected"
- **Android:** Enable USB debugging (Developer Options → USB Debugging)
- **iOS Simulator:** Open Xcode → Products → Scheme → Select device, then rerun
- **macOS/Windows native:** Close and reopen VS Code's DevTools window

### Freezed generation errors in logs
These are expected during development. The `.freezed.dart` file gets generated automatically when you run tests or build.

---

## 📖 License
MIT — Open source, free to use and modify.
