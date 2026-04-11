# 🎨 Lexi Central - Theme Customization Quick Reference

## 🎯 Current Theme Location
**File**: `lib/core/theme/app_theme.dart`

## 🌈 Quick Color Changes

### Primary Palette (Main Colors)
```dart
// Find these lines in app_theme.dart
primary: const Color(0xFFFFB7C5),     // 🔸 Change main pink
secondary: const Color(0xFFB8F2E6),   // 🔸 Change mint green  
tertiary: const Color(0xFFFFF5B7),    // 🔸 Change yellow
background: const Color(0xFFFFF5F7),  // 🔸 Change background
```

### Feature Accent Colors
```dart
// Gallery - Floating button (line ~65)
const Color(0xFFFFB7C5),  // 🔸 Gallery accent

// Vault - Floating button (vault_screen.dart ~425)  
const Color(0xFFB8F2E6),  // 🔸 Vault accent

// Notes - Floating button (notes_screen.dart ~425)
const Color(0xFFFFF5B7),  // 🔸 Notes accent
```

## 🎭 Pre-made Themes

### 🌙 Dark Mode
Replace background colors with:
```dart
scaffoldBackgroundColor: const Color(0xFF2D2D2D),
primary: const Color(0xFFFF6B8B),
secondary: const Color(0xFF4ECDC4),
surface: const Color(0xFF3D3D3D),
```

### 🌸 Cherry Blossom
```dart
primary: const Color(0xFFFFB7C5),
secondary: const Color(0xFFFF6B9D),
tertiary: const Color(0xFFFFC3D8),
background: const Color(0xFFFFF0F5),
```

### 🌊 Ocean Breeze
```dart
primary: const Color(0xFF4ECDC4),
secondary: const Color(0xFF44A3AA),
tertiary: const Color(0xFF95E1D3),
background: const Color(0xFFF0FFFF),
```

### 🌻 Sunshine
```dart
primary: const Color(0xFFFFD93D),
secondary: const Color(0xFFFF6B35),
tertiary: const Color(0xFFFFE66D),
background: const Color(0xFFFFFEF7),
```

## 🔧 Quick Steps

1. **Open**: `lib/core/theme/app_theme.dart`
2. **Find**: Color codes you want to change
3. **Replace**: With new hex colors
4. **Save**: the file
5. **Run**: Double-click `RUN_WINDOWS.bat`
6. **Hot Reload**: Press 'r' in terminal to see changes

## 🎯 Popular Color Codes

### Pink Shades
- `#FFB7C5` - Light Pink (current)
- `#FF6B9D` - Hot Pink
- `#FFC3D8` - Baby Pink
- `#FF69B4` - Medium Pink

### Blue Shades  
- `#B8F2E6` - Mint (current)
- `#4ECDC4` - Turquoise
- `#44A3AA` - Ocean Blue
- `#87CEEB` - Sky Blue

### Yellow Shades
- `#FFF5B7` - Light Yellow (current)
- `#FFD93D` - Golden Yellow
- `#FFE66D` - Pastel Yellow
- `#FFA500` - Orange

### Background Shades
- `#FFF5F7` - Soft White (current)
- `#F0FFFF` - Alice Blue
- `#FFF0F5` - Lavender Blush
- `#2D2D2D` - Dark Gray

## 🎨 Border Radius Customization

### More Rounded (Bubbly)
```dart
BorderRadius.circular(30),  // Instead of 24
```

### Less Rounded (Clean)
```dart
BorderRadius.circular(16),  // Instead of 24
```

### Square (Modern)
```dart
BorderRadius.circular(8),   // Instead of 24
```

## 🌟 Animation Speed

### Faster
```dart
duration: const Duration(milliseconds: 100),  // Instead of 150
```

### Slower
```dart
duration: const Duration(milliseconds: 200),  // Instead of 150
```

### More Bouncy
```dart
curve: Curves.bounceOut,  // Instead of elasticOut
```

## 🚀 Test Your Changes

1. **Run**: `RUN_WINDOWS.bat`
2. **Make**: color changes in `app_theme.dart`
3. **Save**: the file
4. **Press**: 'r' for hot reload
5. **See**: your changes instantly!

## 📱 Feature-Specific Customization

### Gallery Feature
- File: `lib/features/gallery/presentation/widgets/floating_import_button.dart`
- Change: Gradient colors on import button

### Vault Feature  
- File: `lib/features/vault/presentation/widgets/floating_add_button.dart`
- Change: Gradient colors on vault add button

### Notes Feature
- File: `lib/features/notes_links/presentation/notes_screen.dart`
- Change: Floating action button colors

### Discord Feature
- File: `lib/features/discord_feed/presentation/discord_screen.dart`
- Change: Discord purple accent color

## 🎯 Tips

1. **Start Small**: Change one color at a time
2. **Test Often**: Use hot reload frequently
3. **Contrast**: Ensure text is readable on backgrounds
4. **Consistency**: Keep related features similar
5. **Backup**: Save original colors before major changes

Happy customizing! 🌸✨
