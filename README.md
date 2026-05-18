# Graphite — Obsidian Clone in Flutter

A modern, local-first note-taking app built with Flutter. Clean architecture from day one.

## Features (MVP)
- **Local SQLite database** — no server, fully offline
- **File explorer with breadcrumbs** — navigate like a real filesystem
- **Markdown editor with live preview** — syntax highlighting ready
- **Graph view** — visualize connections via `[[ ]]` links
- **Tagging system** — discover notes by tags
- **Quick note capture** — create in seconds

## Getting Started

### Prerequisites
- Flutter SDK (3.16+ recommended)
- IDE: VS Code or Android Studio
- Platform-specific tools:
  - Android Studio/Android SDK for Android testing
  - Xcode/iOS Simulator for iOS/Mac testing
  - Windows Subsystem for Linux (if on Windows) for mobile development

### Installation

1. **Clone the repository**
   ```bash
   cd /home/kel/projects/graphite
   flutter pub get
   ```

2. **Verify dependencies installed correctly**
   ```bash
   flutter doctor -v
   ```

3. **Run on a device or simulator** (choose one):
   ```bash
   # Android emulator / physical device  
   flutter run -d <device-id>
   
   # iOS Simulator
   flutter run -d iPhone-14
   
   # macOS native app
   flutter run -d macos
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point + router
├── models/                   # Core data: Note, Tag, Link
├── data/                     # Platform abstractions (FileRepository)
├── repository/               # Business logic (NoteRepository)
├── utils/                    # Helpers (MarkdownParser)
└── screens/                  # UI widgets (HomeScreen, EditorScreen...)
```

## Architecture Principles
- **Clean Architecture** — separation of concerns from day one
- **Local-first** — all data lives on device, no cloud dependency
- **Flutter-native** — single codebase for iOS, Android, macOS, Windows

## Next Steps (Post-MVP)
- [ ] Cross-platform file picker (open files outside app vault)
- [ ] Undo/redo system with conflict resolution
- [ ] Advanced graph filters (show only recent links, hide dead ends)
- [ ] Full syntax highlighting in editor pane
- [ ] Dark mode theme
- [ ] Template library

## Technical Debt Tracker
| Issue | Status | Priority |
|-------|--------|----------|
| Add real markdown rendering | TODO | High |
| Implement proper line numbers with syntax tokens | TODO | Medium |
| Graph view needs fl_chart integration | TODO | High |
| Tag filtering state management (Bloc) | TODO | Medium |

## License
MIT — Open source, free to use and modify.
