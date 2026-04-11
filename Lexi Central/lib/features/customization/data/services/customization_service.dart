import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import '../models/customization_models.dart';

class CustomizationService {
  static const String _settingsBoxName = 'customization_settings';
  static const String _presetsBoxName = 'theme_presets';
  static const String _backgroundsBoxName = 'custom_backgrounds';
  static const String _layoutsBoxName = 'module_layouts';

  late Box<CustomizationSettings> _settingsBox;
  late Box<ThemePreset> _presetsBox;
  late Box<CustomBackground> _backgroundsBox;
  late Box<ModuleLayout> _layoutsBox;

  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDir.path);
    
    // Register adapters
    Hive.registerAdapter(ThemePresetAdapter());
    Hive.registerAdapter(ThemeColorsAdapter());
    Hive.registerAdapter(ModuleLayoutAdapter());
    Hive.registerAdapter(CustomBackgroundAdapter());
    Hive.registerAdapter(CustomizationSettingsAdapter());
    Hive.registerAdapter(ModuleTypeAdapter());
    
    // Open boxes
    _settingsBox = await Hive.openBox<CustomizationSettings>(_settingsBoxName);
    _presetsBox = await Hive.openBox<ThemePreset>(_presetsBoxName);
    _backgroundsBox = await Hive.openBox<CustomBackground>(_backgroundsBoxName);
    _layoutsBox = await Hive.openBox<ModuleLayout>(_layoutsBoxName);
    
    // Initialize default data if empty
    await _initializeDefaultData();
  }

  Future<void> _initializeDefaultData() async {
    // Create default theme presets
    if (_presetsBox.isEmpty) {
      final defaultPresets = [
        ThemePreset(
          id: 'kirby_original',
          name: 'Kirby Original',
          description: 'The original pastel Kirby theme',
          colors: const ThemeColors(
            primary: '#FFB7C5',
            secondary: '#B8F2E6',
            tertiary: '#FFF5B7',
            background: '#FFF5F7',
            surface: '#FFFFFF',
            cardBackground: '#FFFFFF',
            textPrimary: '#4A4A4A',
            textSecondary: '#6A6A6A',
            shadowColor: '#FFB7C5',
          ),
          icon: '🌸',
          isDefault: true,
        ),
        ThemePreset(
          id: 'dark_kirby',
          name: 'Dark Kirby',
          description: 'Dark mode with Kirby colors',
          colors: const ThemeColors(
            primary: '#FF6B8B',
            secondary: '#4ECDC4',
            tertiary: '#FFE66D',
            background: '#2D2D2D',
            surface: '#3D3D3D',
            cardBackground: '#454545',
            textPrimary: '#FFFFFF',
            textSecondary: '#B8B8B8',
            shadowColor: '#FF6B8B',
          ),
          icon: '🌙',
        ),
        ThemePreset(
          id: 'cherry_blossom',
          name: 'Cherry Blossom',
          description: 'Pink cherry blossom theme',
          colors: const ThemeColors(
            primary: '#FFB7C5',
            secondary: '#FF6B9D',
            tertiary: '#FFC3D8',
            background: '#FFF0F5',
            surface: '#FFFFFF',
            cardBackground: '#FFFFFF',
            textPrimary: '#4A4A4A',
            textSecondary: '#6A6A6A',
            shadowColor: '#FF6B9D',
          ),
          icon: '🌸',
        ),
        ThemePreset(
          id: 'ocean_breeze',
          name: 'Ocean Breeze',
          description: 'Cool ocean blue theme',
          colors: const ThemeColors(
            primary: '#4ECDC4',
            secondary: '#44A3AA',
            tertiary: '#95E1D3',
            background: '#F0FFFF',
            surface: '#FFFFFF',
            cardBackground: '#FFFFFF',
            textPrimary: '#4A4A4A',
            textSecondary: '#6A6A6A',
            shadowColor: '#4ECDC4',
          ),
          icon: '🌊',
        ),
        ThemePreset(
          id: 'sunshine',
          name: 'Sunshine',
          description: 'Bright yellow sunshine theme',
          colors: const ThemeColors(
            primary: '#FFD93D',
            secondary: '#FF6B35',
            tertiary: '#FFE66D',
            background: '#FFFEF7',
            surface: '#FFFFFF',
            cardBackground: '#FFFFFF',
            textPrimary: '#4A4A4A',
            textSecondary: '#6A6A6A',
            shadowColor: '#FFD93D',
          ),
          icon: '🌻',
        ),
      ];
      
      for (final preset in defaultPresets) {
        await _presetsBox.put(preset.id, preset);
      }
    }

    // Create default module layouts
    if (_layoutsBox.isEmpty) {
      final defaultLayouts = [
        ModuleLayout(
          moduleId: 'gallery',
          name: 'Gallery',
          position: 0,
          x: 0.0,
          y: 0.0,
          width: 0.5,
          height: 0.5,
        ),
        ModuleLayout(
          moduleId: 'vault',
          name: 'Vault',
          position: 1,
          x: 0.5,
          y: 0.0,
          width: 0.5,
          height: 0.5,
        ),
        ModuleLayout(
          moduleId: 'discord',
          name: 'Discord',
          position: 2,
          x: 0.0,
          y: 0.5,
          width: 0.5,
          height: 0.5,
        ),
        ModuleLayout(
          moduleId: 'notes',
          name: 'Notes',
          position: 3,
          x: 0.5,
          y: 0.5,
          width: 0.25,
          height: 0.5,
        ),
        ModuleLayout(
          moduleId: 'links',
          name: 'Links',
          position: 4,
          x: 0.75,
          y: 0.5,
          width: 0.25,
          height: 0.5,
        ),
      ];
      
      for (final layout in defaultLayouts) {
        await _layoutsBox.put(layout.moduleId, layout);
      }
    }

    // Create default settings
    if (_settingsBox.isEmpty) {
      final kirbyPreset = _presetsBox.get('kirby_original')!;
      final settings = CustomizationSettings(
        currentTheme: kirbyPreset,
        moduleLayouts: _layoutsBox.values.toList(),
      );
      await _settingsBox.put('main_settings', settings);
    }
  }

  Future<CustomizationSettings> getSettings() async {
    final settings = _settingsBox.get('main_settings');
    if (settings != null) {
      return settings.copyWith(
        customPresets: _presetsBox.values.where((p) => !p.isDefault).toList(),
        customBackgrounds: _backgroundsBox.values.toList(),
        moduleLayouts: _layoutsBox.values.toList(),
      );
    }
    throw Exception('Settings not initialized');
  }

  Future<void> updateSettings(CustomizationSettings settings) async {
    await _settingsBox.put('main_settings', settings);
  }

  Future<void> saveThemePreset(ThemePreset preset) async {
    await _presetsBox.put(preset.id, preset);
  }

  Future<void> deleteThemePreset(String presetId) async {
    await _presetsBox.delete(presetId);
  }

  Future<void> saveCustomBackground(CustomBackground background) async {
    await _backgroundsBox.put(background.id, background);
  }

  Future<void> deleteCustomBackground(String backgroundId) async {
    await _backgroundsBox.delete(backgroundId);
    
    // Delete the actual image file
    final backgrounds = _backgroundsBox.values.toList();
    final background = backgrounds.where((b) => b.id == backgroundId).firstOrNull;
    if (background != null) {
      final file = File(background.imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> updateModuleLayouts(List<ModuleLayout> layouts) async {
    for (final layout in layouts) {
      await _layoutsBox.put(layout.moduleId, layout);
    }
  }

  Future<String> saveCustomImage(String fileName, List<int> bytes) async {
    final appDir = await getApplicationDocumentsDirectory();
    final customImagesDir = Directory('${appDir.path}/custom_images');
    
    if (!await customImagesDir.exists()) {
      await customImagesDir.create(recursive: true);
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final savedFileName = '${timestamp}_$fileName';
    final savedPath = '${customImagesDir.path}/$savedFileName';
    
    final file = File(savedPath);
    await file.writeAsBytes(bytes);
    
    return savedPath;
  }

  Future<List<ThemePreset>> getAllPresets() async {
    return _presetsBox.values.toList();
  }

  Future<List<CustomBackground>> getAllBackgrounds() async {
    return _backgroundsBox.values.toList();
  }

  Future<List<ModuleLayout>> getAllModuleLayouts() async {
    return _layoutsBox.values.toList();
  }

  Future<void> close() async {
    await _settingsBox.close();
    await _presetsBox.close();
    await _backgroundsBox.close();
    await _layoutsBox.close();
  }
}

// Hive Type Adapters
class ThemePresetAdapter extends TypeAdapter<ThemePreset> {
  @override
  final typeId = 10;

  @override
  ThemePreset read(BinaryReader reader) {
    return ThemePreset.fromJson(reader.read());
  }

  @override
  void write(BinaryWriter writer, ThemePreset obj) {
    writer.write(obj.toJson());
  }
}

class ThemeColorsAdapter extends TypeAdapter<ThemeColors> {
  @override
  final typeId = 11;

  @override
  ThemeColors read(BinaryReader reader) {
    return ThemeColors.fromJson(reader.read());
  }

  @override
  void write(BinaryWriter writer, ThemeColors obj) {
    writer.write(obj.toJson());
  }
}

class ModuleLayoutAdapter extends TypeAdapter<ModuleLayout> {
  @override
  final typeId = 12;

  @override
  ModuleLayout read(BinaryReader reader) {
    return ModuleLayout.fromJson(reader.read());
  }

  @override
  void write(BinaryWriter writer, ModuleLayout obj) {
    writer.write(obj.toJson());
  }
}

class CustomBackgroundAdapter extends TypeAdapter<CustomBackground> {
  @override
  final typeId = 13;

  @override
  CustomBackground read(BinaryReader reader) {
    return CustomBackground.fromJson(reader.read());
  }

  @override
  void write(BinaryWriter writer, CustomBackground obj) {
    writer.write(obj.toJson());
  }
}

class CustomizationSettingsAdapter extends TypeAdapter<CustomizationSettings> {
  @override
  final typeId = 14;

  @override
  CustomizationSettings read(BinaryReader reader) {
    return CustomizationSettings.fromJson(reader.read());
  }

  @override
  void write(BinaryWriter writer, CustomizationSettings obj) {
    writer.write(obj.toJson());
  }
}

class ModuleTypeAdapter extends TypeAdapter<ModuleType> {
  @override
  final typeId = 15;

  @override
  ModuleType read(BinaryReader reader) {
    return ModuleType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, ModuleType obj) {
    writer.writeByte(obj.index);
  }
}

// Extension methods for JSON serialization
extension ThemePresetExtension on ThemePreset {
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'colors': colors.toJson(),
        'backgroundImage': backgroundImage,
        'icon': icon,
        'isDefault': isDefault,
      };

  static ThemePreset fromJson(Map<String, dynamic> json) => ThemePreset(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        colors: ThemeColorsExtension.fromJson(json['colors'] as Map<String, dynamic>),
        backgroundImage: json['backgroundImage'] as String?,
        icon: json['icon'] as String,
        isDefault: json['isDefault'] as bool? ?? false,
      );
}

extension ThemeColorsExtension on ThemeColors {
  Map<String, dynamic> toJson() => {
        'primary': primary,
        'secondary': secondary,
        'tertiary': tertiary,
        'background': background,
        'surface': surface,
        'cardBackground': cardBackground,
        'textPrimary': textPrimary,
        'textSecondary': textSecondary,
        'shadowColor': shadowColor,
      };

  static ThemeColors fromJson(Map<String, dynamic> json) => ThemeColors(
        primary: json['primary'] as String,
        secondary: json['secondary'] as String,
        tertiary: json['tertiary'] as String,
        background: json['background'] as String,
        surface: json['surface'] as String,
        cardBackground: json['cardBackground'] as String,
        textPrimary: json['textPrimary'] as String,
        textSecondary: json['textSecondary'] as String,
        shadowColor: json['shadowColor'] as String,
      );
}

extension ModuleLayoutExtension on ModuleLayout {
  Map<String, dynamic> toJson() => {
        'moduleId': moduleId,
        'name': name,
        'position': position,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'isVisible': isVisible,
      };

  static ModuleLayout fromJson(Map<String, dynamic> json) => ModuleLayout(
        moduleId: json['moduleId'] as String,
        name: json['name'] as String,
        position: json['position'] as int,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
        isVisible: json['isVisible'] as bool? ?? true,
      );
}

extension CustomBackgroundExtension on CustomBackground {
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imagePath': imagePath,
        'opacity': opacity,
        'fit': fit.toString(),
        'isDefault': isDefault,
      };

  static CustomBackground fromJson(Map<String, dynamic> json) => CustomBackground(
        id: json['id'] as String,
        name: json['name'] as String,
        imagePath: json['imagePath'] as String,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 0.1,
        fit: BoxFit.values.firstWhere((e) => e.toString() == json['fit'] as String, orElse: () => BoxFit.cover),
        isDefault: json['isDefault'] as bool? ?? false,
      );
}

extension CustomizationSettingsExtension on CustomizationSettings {
  Map<String, dynamic> toJson() => {
        'currentTheme': currentTheme.toJson(),
        'customPresets': customPresets.map((p) => p.toJson()).toList(),
        'customBackgrounds': customBackgrounds.map((b) => b.toJson()).toList(),
        'moduleLayouts': moduleLayouts.map((m) => m.toJson()).toList(),
        'currentBackground': currentBackground?.toJson(),
        'showCustomBackground': showCustomBackground,
      };

  static CustomizationSettings fromJson(Map<String, dynamic> json) => CustomizationSettings(
        currentTheme: ThemePresetExtension.fromJson(json['currentTheme'] as Map<String, dynamic>),
        customPresets: (json['customPresets'] as List).map((p) => ThemePresetExtension.fromJson(p as Map<String, dynamic>)).toList(),
        customBackgrounds: (json['customBackgrounds'] as List).map((b) => CustomBackgroundExtension.fromJson(b as Map<String, dynamic>)).toList(),
        moduleLayouts: (json['moduleLayouts'] as List).map((m) => ModuleLayoutExtension.fromJson(m as Map<String, dynamic>)).toList(),
        currentBackground: json['currentBackground'] != null ? CustomBackgroundExtension.fromJson(json['currentBackground'] as Map<String, dynamic>) : null,
        showCustomBackground: json['showCustomBackground'] as bool? ?? false,
      );
}
