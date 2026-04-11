# 🌸 Lexi Central - PC Setup Guide

## 🚀 Quick Start (Windows)

### Prerequisites
- Windows 10/11
- Visual Studio 2022 with C++ development tools
- Git (optional, for version control)

### Step 1: Install Flutter
```powershell
# Download Flutter SDK
# Visit: https://flutter.dev/docs/get-started/install/windows

# Extract to C:\flutter
# Add to PATH: C:\flutter\bin
```

### Step 2: Install Visual Studio
```powershell
# Install Visual Studio 2022 Community (Free)
# Select "Desktop development with C++" workload
# Include Windows 10/11 SDK
```

### Step 3: Setup Development Environment
```powershell
# Open PowerShell as Administrator
flutter doctor --verbose
flutter config --enable-windows-desktop
```

### Step 4: Run Lexi Central
```powershell
cd "c:\Users\zborg\Desktop\Lexi Central"
flutter pub get
flutter run -d windows
```

## 🎨 Theme Customization Guide

### Theme Location
All theme settings are in: `lib/core/theme/app_theme.dart`

### Current Kirby Color Palette
```dart
// Primary Colors
primary: Color(0xFFFFB7C5),     // Pastel Pink
secondary: Color(0xFFB8F2E6),   // Mint Green  
tertiary: Color(0xFFFFF5B7),    // Pastel Yellow
background: Color(0xFFFFF5F7),  // Soft White
```

### How to Customize Colors

#### 1. Edit Main Theme Colors
```dart
// In lib/core/theme/app_theme.dart
static final kirbyTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFFFB7C5), // Change your primary here
    primary: const Color(0xFFFFB7C5),     // Main accent color
    secondary: const Color(0xFFB8F2E6),   // Secondary accent
    tertiary: const Color(0xFFFFF5B7),     // Tertiary accent
    surface: Colors.white,
    background: const Color(0xFFFFF5F7), // Background color
  ),
);
```

#### 2. Update Component Colors
```dart
// Button colors
elevatedButtonTheme: ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFFFB7C5), // Change button color
    foregroundColor: Colors.white,
  ),
),

// Card colors
cardTheme: CardTheme(
  color: Colors.white,
  elevation: 6,
  shadowColor: const Color(0xFFFFB7C5).withOpacity(0.3),
),
```

#### 3. Navigation Colors
```dart
// Bottom navigation
bottomNavigationBarTheme: BottomNavigationBarThemeData(
  selectedItemColor: const Color(0xFFFFB7C5), // Selected item color
  unselectedItemColor: const Color(0xFFB8B8B8), // Unselected color
),

// Side navigation (PC)
navigationRailTheme: NavigationRailThemeData(
  selectedIconColor: const Color(0xFFFFB7C5),
  unselectedIconColor: const Color(0xFFB8B8B8),
),
```

## 🎭 Popular Theme Variations

### 🌙 Dark Kirby Theme
```dart
// Replace background colors
scaffoldBackgroundColor: const Color(0xFF2D2D2D),
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFFFF6B8B),
  primary: const Color(0xFFFF6B8B),
  secondary: const Color(0xFF4ECDC4),
  tertiary: const Color(0xFFFFE66D),
  surface: const Color(0xFF3D3D3D),
  background: const Color(0xFF2D2D2D),
),
```

### 🌸 Cherry Blossom Theme
```dart
// Pink-focused palette
primary: const Color(0xFFFFB7C5),    // Light Pink
secondary: const Color(0xFFFF6B9D),  // Hot Pink
tertiary: const Color(0xFFFFC3D8),  // Baby Pink
background: const Color(0xFFFFF0F5), // Lavender Blush
```

### 🌊 Ocean Theme
```dart
// Blue-green palette
primary: const Color(0xFF4ECDC4),    // Turquoise
secondary: const Color(0xFF44A3AA),  // Ocean Blue
tertiary: const Color(0xFF95E1D3),  // Mint
background: const Color(0xFFF0FFFF), // Alice Blue
```

### 🌻 Sunshine Theme
```dart
// Yellow-orange palette
primary: const Color(0xFFFFD93D),    // Golden Yellow
secondary: const Color(0xFFFF6B35),  // Orange
tertiary: const Color(0xFFFFE66D),  // Light Yellow
background: const Color(0xFFFFFEF7), // Lemon Chiffon
```

## 🎯 Feature-Specific Colors

### Gallery Feature
```dart
// In lib/features/gallery/presentation/widgets/floating_import_button.dart
decoration: BoxDecoration(
  gradient: LinearGradient(
    colors: [
      const Color(0xFFFFB7C5),  // Change gallery accent
      const Color(0xFFFF6B8B),
    ],
  ),
),
```

### Vault Feature  
```dart
// In lib/features/vault/presentation/widgets/floating_add_button.dart
decoration: BoxDecoration(
  gradient: LinearGradient(
    colors: [
      const Color(0xFFB8F2E6),  // Change vault accent
      const Color(0xFF2A7F7E),
    ],
  ),
),
```

### Notes Feature
```dart
// In lib/features/notes_links/presentation/notes_screen.dart
backgroundColor: const Color(0xFFFFF5B7),  // Change notes accent
foregroundColor: const Color(0xFFE6D690),
```

## 🖼️ Custom Assets

### Add Custom Background
1. Add your image to `assets/` folder
2. Update `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/kirby.gif
    - assets/custom_background.png  # Add your custom asset
```

3. Update background widget:
```dart
// In lib/core/widgets/kirby_background.dart
Image.asset(
  'assets/custom_background.png',  // Change to your asset
  fit: BoxFit.cover,
),
```

### Add Custom Fonts
1. Add font files to `assets/fonts/`
2. Update `pubspec.yaml`:
```yaml
flutter:
  fonts:
    - family: CustomFont
      fonts:
        - asset: assets/fonts/custom_font.ttf
```

3. Update theme:
```dart
// In lib/core/theme/app_theme.dart
textTheme: GoogleFonts.customFont().copyWith(
  displayLarge: GoogleFonts.customFont(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: const Color(0xFFFF6B8B),
  ),
),
```

## 🔧 Advanced Customization

### Custom Animations
```dart
// In lib/core/widgets/bouncy_button.dart
// Adjust animation duration and curve
duration: const Duration(milliseconds: 150),  // Change speed
curve: Curves.elasticOut,  // Change bounce effect
```

### Custom Border Radius
```dart
// Throughout the app, find BorderRadius.circular(24)
// Adjust for more/less rounded corners
BorderRadius.circular(30),  // More rounded
BorderRadius.circular(16),  // Less rounded
```

### Custom Shadows
```dart
// In theme definitions
shadowColor: const Color(0xFFFFB7C5).withOpacity(0.4),  // Change shadow color
blurRadius: 12,  // Change shadow blur
offset: const Offset(0, 4),  // Change shadow position
```

## 🚀 Running Your Customized App

### After Making Changes
```powershell
# Stop current app (Ctrl+C in terminal)
# Apply your theme changes
flutter run -d windows
```

### Hot Reload
```powershell
# In the running app terminal, press:
r  # Hot reload
R  # Hot restart
```

## 🎨 Theme Testing Checklist

- [ ] Background color looks good
- [ ] Button colors are visible and accessible
- [ ] Text contrast is sufficient for readability
- [ ] Navigation colors are consistent
- [ ] Feature-specific accents match theme
- [ ] Dark mode works (if implemented)
- [ ] Animations feel smooth and appropriate

## 🐛 Common Issues & Solutions

### Colors Not Updating
```powershell
# Try hot restart instead of hot reload
# Press 'R' in terminal
```

### Build Errors After Theme Changes
```powershell
flutter clean
flutter pub get
flutter run -d windows
```

### Asset Loading Issues
```powershell
# Check pubspec.yaml indentation
# Ensure assets are in correct folder
# Run flutter clean
```

## 🎯 Next Steps

1. **Choose Your Theme**: Pick one of the variations or create your own
2. **Update Colors**: Modify `lib/core/theme/app_theme.dart`
3. **Test Changes**: Run the app and use hot reload
4. **Fine-tune**: Adjust shadows, animations, and borders
5. **Add Assets**: Include custom backgrounds or fonts if desired

## 📞 Need Help?

- Check Flutter documentation: https://flutter.dev/docs
- Theme customization: https://flutter.dev/docs/cookbook/design/themes
- Color picker tools: https://colorhunt.co, https://coolors.co

Happy customizing! 🌸✨
