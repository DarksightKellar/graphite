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
   cd graphite
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
├── core/                     # Shared app layers
│   ├── data/                 # Platform abstractions (database, file system)
│   ├── design/               # Theme and shared UI primitives
│   ├── di/                   # Dependency injection
│   ├── models/               # Core data: Note, Tag, Link
│   ├── repository/           # Business logic (NoteRepository)
│   └── router/               # Route definitions (app_router.dart)
├── features/                 # Feature modules
│   ├── editor/               # Editor screen, widgets, and use cases
│   ├── graph/                # Graph placeholder
│   ├── home/                 # Home screen, widgets, and use cases
│   └── tags/                 # Tag browser
└── main.dart                 # App entry point
```

## Architecture Principles
- **Clean Architecture** — separation of concerns from day one
- **Local-first** — all data lives on device, no cloud dependency
- **Flutter-native** — single codebase for iOS, Android, macOS, Windows

## Offline-First Design

Graphite is designed to work **fully offline** — no network connection is ever required.

**Guarantees:**
- All CRUD operations (create, read, update, delete) work in airplane mode
- SQLite database is created and migrated entirely locally via FFI backend
- No `http`, `dio`, `cloud_firestore`, or any network-dependent package in `pubspec.yaml`
- Zero network calls in any Dart import across the entire codebase
- File system vault is created and managed locally via `path_provider`

**Verification:**
- `test/offline_integration_test.dart` — canonical integration test proving the full note
  lifecycle (create → read → update → search → tag-filter → link navigation → delete)
  works without network, using the FFI-backed SQLite database factory

**Audit results (Phase 2.4):**
- ✅ 0 network-requiring Dart imports found
- ✅ 0 cloud/HTTP dependencies in pubspec.yaml
- ✅ 8/8 offline integration tests pass
- ✅ Full CRUD + search + tags + links verified offline

## Next Steps (Post-MVP)
- [ ] Cross-platform file picker (open files outside app vault)
- [ ] Undo/redo system with conflict resolution
- [ ] Interactive graph view with node/edge navigation
- [ ] Advanced graph filters (show only recent links, hide dead ends)
- [ ] Full syntax highlighting in editor pane
- [x] Dark mode theme
- [ ] Template library

## Technical Debt Tracker
- Add real markdown rendering — **High priority**
- Implement proper line numbers with syntax tokens — **Medium priority**
- Graph view needs fl_chart integration — **High priority**
- Tag filtering state management (Bloc) — **Medium priority**

## License
MIT — Open source, free to use and modify.
