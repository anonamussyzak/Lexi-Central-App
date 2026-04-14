# Lexi Central - Architecture Details, Logic Refinements, and Build Pipeline

## 1. Project Overview: "Lexi Central"

- **Root Structure**: Hybrid project consisting of a Native Android (Kotlin/Compose) application and a Jetpack Compose/React Native (Expo) application (located in the `/project` directory).
- **Target SDK**: Android 35 (latest).
- **Storage Architecture**:
  - **Remote**: Supabase (Postgrest & Realtime) for cross-device note syncing.
  - **Local**: AsyncStorage for user preferences and persistent metadata.
  - **Filesystem**: Atomic file moves using Android's Storage Access Framework (SAF) for the Private Vault.

## 2. Summarized Prompts & Goals

Throughout this session, your requirements focused on moving from a "broken and weird" template state to a polished, high-performance visual tool:

1. **Reactive Settings**: Fix Supabase credentials so the client reloads instantly upon saving without an app restart.
2. **Vault Security**: Ensure mass-vaulting is reliable (no file loss) and that vaulted items are physically hidden from the rest of the phone.
3. **YouTube-Style Media Player**: Overhaul the UI to include dynamic centering, double-tap seeking (10s), and a swipe-to-hide info sheet.
4. **Gallery/Notes Isolation**: Separate visual media (Gallery) from text/voice media (Notes). Ensure notes are strictly persistent to their tabs.
5. **Build Pipeline**: Move from EAS Cloud Build (limit hit) to Local Build (Windows path bypass) and finally to GitHub Actions for standalone release APKs.
6. **Minimalist Branding**: "Zak" branding in the footer and a clean, standalone user experience.

## 3. Major Changes & Fixed Mistakes

### Media & Gallery Logic
- **Scanning Engine**: Rewrote the scanner to verify SAF permissions. It now strips system junk (`primary:`) from tab names, resulting in clean labels like "Vacation" or "Daily."
- **Dynamic Player Physics**: Fixed the "stuck at top" bug. The video player now uses an animation engine to glide into the vertical center of the screen when the metadata is hidden.
- **Hitbox Precision**: Re-layered the player UI to ensure the Play/Pause button is on top of seek zones, fixing the "Play button doesn't work" issue.
- **Type-Strict Navigation**: Fixed navigation arrows so they only cycle through the same media type (Video stays with Video, Image with Image).

### Security & Persistence
- **Atomic Move Sequence**: Updated the vault to follow a Copy -> Verify -> Delete cycle. This prevents the "disappearing files" bug by confirming the vault copy is healthy before removing the public one.
- **Ghost Zone**: Vaulted items are moved to private app storage, making them invisible to external gallery apps and skipping them in arrow navigation.
- **Auto-Save Engine**: Every setting change (Theme, PIN, Scan Paths) is instantly synced to disk using a background side-effect.

### Build & Infrastructure
- **Virtual Drive Hack**: Created `kirby_build.ps1` which uses a temporary `K:` drive to bypass Windows folder path character limits.
- **GitHub Magic Build**: Created a `.github/workflows/build-apk.yml` configuration that builds a Standalone Release APK using a debug signature for easy installation.

## 4. Current Build Path

To get your master copy, you no longer need local setup. Just use the GitHub pipeline:

1. **Push**: `git push origin main`
2. **Monitor**: GitHub Actions Tab -> "Build Android APK."
3. **Result**: Download the standalone `kirby-app-release` artifact.

The app is now logic-perfect, professionally branded ("Zak"), and ready for standalone deployment.
