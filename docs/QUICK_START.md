# Graphite — Quick Start Guide

A modern Obsidian-inspired note-taking app built with Flutter + SQLite, local-first.

## Get Running (2 minutes)

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Run
```bash
flutter run -d <your-device-id>
```

To find your device ID: `flutter devices`

---

## First Notes

| Action | How |
|---|---|
| **Create a note** | Tap the **+** FAB → type title + content → Save |
| **Edit a note** | Tap any note in the list |
| **Write markdown** | `# Headings`, `**bold**`, `*italic*`, `- lists`, `1. ordered` |
| **Link notes** | `[[Another Note]]` — builds the knowledge graph |
| **Tag notes** | `#personal #ideas` — filterable, browseable |
| **Search** | Type in the search bar (searches content + titles) |
| **Pin a note** | Swipe right on a note card |
| **Delete a note** | Swipe left on a note card → confirm |

---

## Editor Tips

- **Live preview** — your markdown renders in real-time on the right pane
- **Auto-save** — saves 2 seconds after you stop typing, or when you background the app
- **Wiki-link navigation** — tap `[[links]]` in preview to jump to that note (or create it)
- **Unsaved changes warning** — the editor prompts before navigating away

---

## Key Features

- Fully offline — SQLite database, zero network calls
- Dark mode — follows system preference
- Tag browser — view all tags and filter notes by tag
- File import — import `.md` files from your device
- Bulk selection — long-press to select multiple notes for deletion

---

## Build for Release

```bash
# Android APK
flutter build apk --release

# iOS (macOS only)
flutter build ios --release

# macOS native
flutter build macos --release
```

---

## License
MIT
