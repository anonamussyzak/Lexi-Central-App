# Lexi Central 🌸

A cute, Kirby-themed media management app with secure vault and Discord integration.

## Features

- 🖼️ **Media Gallery** - Local file explorer for images and videos
- 🔐 **The Vault** - Zero-knowledge encrypted storage for sensitive files
- 💬 **Discord Feed** - Connect to Discord server channels
- 📝 **Notes & Links** - Personal knowledge base with markdown support

## Architecture

Built with Flutter using clean architecture principles:
- **Cross-platform**: Android APK + Windows EXE
- **Feature-based structure** for scalability
- **Kirby-core design** with pastel aesthetics
- **Bouncy animations** for playful UX

## Tech Stack

- **Framework**: Flutter 3.10+
- **State Management**: Riverpod
- **Navigation**: Go Router
- **UI**: Material 3 + Custom Kirby Theme
- **File System**: file_picker, path_provider
- **Video**: ffmpeg_kit_flutter, video_thumbnail
- **Security**: flutter_secure_storage, cryptography
- **Networking**: dio for Discord API

## Getting Started

### Prerequisites
- Flutter SDK 3.10 or higher
- For Android: Android Studio + Android SDK
- For Windows: Visual Studio 2022 with C++ tools

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Add assets:
   - Place `kirby.gif` in `assets/` folder
   - Add any custom fonts to `assets/fonts/`

### Running the App

```bash
# Development
flutter run

# Android APK
flutter build apk

# Windows EXE
flutter build windows
```

## Project Structure

```
lib/
├── core/                  # Shared utilities
│   ├── theme/            # Kirby theme system
│   ├── widgets/          # Reusable UI components
│   ├── services/         # Global services
│   └── utils/            # Helper functions
├── features/             # Feature modules
│   ├── gallery/          # Media gallery
│   ├── vault/            # Secure vault
│   ├── discord_feed/     # Discord integration
│   └── notes_links/      # Notes & links
├── navigation/           # App routing
└── main.dart            # Entry point
```

## Security Notes

- **Vault**: Zero-knowledge encryption with local password hashing
- **No recovery**: By design - passwords cannot be recovered
- **Local storage**: All sensitive data stays on device

## Contributing

1. Follow the existing code style
2. Use feature-based architecture
3. Maintain the Kirby-core aesthetic
4. Test on both Android and Windows

## License

© 2026 Lexi Central - All Rights Reserved
