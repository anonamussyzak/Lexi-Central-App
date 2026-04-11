import 'package:equatable/equatable.dart';

class ThemePreset extends Equatable {
  final String id;
  final String name;
  final String description;
  final ThemeColors colors;
  final String? backgroundImage;
  final String icon;
  final bool isDefault;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.colors,
    this.backgroundImage,
    required this.icon,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        colors,
        backgroundImage,
        icon,
        isDefault,
      ];
}

class ThemeColors extends Equatable {
  final String primary;
  final String secondary;
  final String tertiary;
  final String background;
  final String surface;
  final String cardBackground;
  final String textPrimary;
  final String textSecondary;
  final String shadowColor;

  const ThemeColors({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.background,
    required this.surface,
    required this.cardBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.shadowColor,
  });

  @override
  List<Object?> get props => [
        primary,
        secondary,
        tertiary,
        background,
        surface,
        cardBackground,
        textPrimary,
        textSecondary,
        shadowColor,
      ];
}

class ModuleLayout extends Equatable {
  final String moduleId;
  final String name;
  final int position;
  final double x;
  final double y;
  final double width;
  final double height;
  final bool isVisible;

  const ModuleLayout({
    required this.moduleId,
    required this.name,
    required this.position,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.isVisible = true,
  });

  ModuleLayout copyWith({
    String? moduleId,
    String? name,
    int? position,
    double? x,
    double? y,
    double? width,
    double? height,
    bool? isVisible,
  }) {
    return ModuleLayout(
      moduleId: moduleId ?? this.moduleId,
      name: name ?? this.name,
      position: position ?? this.position,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  @override
  List<Object?> get props => [
        moduleId,
        name,
        position,
        x,
        y,
        width,
        height,
        isVisible,
      ];
}

class CustomBackground extends Equatable {
  final String id;
  final String name;
  final String imagePath;
  final double opacity;
  final BoxFit fit;
  final bool isDefault;

  const CustomBackground({
    required this.id,
    required this.name,
    required this.imagePath,
    this.opacity = 0.1,
    this.fit = BoxFit.cover,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        imagePath,
        opacity,
        fit,
        isDefault,
      ];
}

enum ModuleType {
  gallery,
  vault,
  discord,
  notes,
  links,
}

class CustomizationSettings extends Equatable {
  final ThemePreset currentTheme;
  final List<ThemePreset> customPresets;
  final List<CustomBackground> customBackgrounds;
  final List<ModuleLayout> moduleLayouts;
  final CustomBackground? currentBackground;
  final bool showCustomBackground;

  const CustomizationSettings({
    required this.currentTheme,
    this.customPresets = const [],
    this.customBackgrounds = const [],
    this.moduleLayouts = const [],
    this.currentBackground,
    this.showCustomBackground = false,
  });

  CustomizationSettings copyWith({
    ThemePreset? currentTheme,
    List<ThemePreset>? customPresets,
    List<CustomBackground>? customBackgrounds,
    List<ModuleLayout>? moduleLayouts,
    CustomBackground? currentBackground,
    bool? showCustomBackground,
  }) {
    return CustomizationSettings(
      currentTheme: currentTheme ?? this.currentTheme,
      customPresets: customPresets ?? this.customPresets,
      customBackgrounds: customBackgrounds ?? this.customBackgrounds,
      moduleLayouts: moduleLayouts ?? this.moduleLayouts,
      currentBackground: currentBackground ?? this.currentBackground,
      showCustomBackground: showCustomBackground ?? this.showCustomBackground,
    );
  }

  @override
  List<Object?> get props => [
        currentTheme,
        customPresets,
        customBackgrounds,
        moduleLayouts,
        currentBackground,
        showCustomBackground,
      ];
}
