import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customization_models.dart';
import '../../data/services/customization_service.dart';

class CustomizationState {
  final ThemePreset currentTheme;
  final List<ThemePreset> customPresets;
  final List<CustomBackground> customBackgrounds;
  final List<ModuleLayout> moduleLayouts;
  final CustomBackground? currentBackground;
  final bool showCustomBackground;
  final bool isLoading;
  final String? error;

  const CustomizationState({
    required this.currentTheme,
    this.customPresets = const [],
    this.customBackgrounds = const [],
    this.moduleLayouts = const [],
    this.currentBackground,
    this.showCustomBackground = false,
    this.isLoading = false,
    this.error,
  });

  CustomizationState copyWith({
    ThemePreset? currentTheme,
    List<ThemePreset>? customPresets,
    List<CustomBackground>? customBackgrounds,
    List<ModuleLayout>? moduleLayouts,
    CustomBackground? currentBackground,
    bool? showCustomBackground,
    bool? isLoading,
    String? error,
  }) {
    return CustomizationState(
      currentTheme: currentTheme ?? this.currentTheme,
      customPresets: customPresets ?? this.customPresets,
      customBackgrounds: customBackgrounds ?? this.customBackgrounds,
      moduleLayouts: moduleLayouts ?? this.moduleLayouts,
      currentBackground: currentBackground ?? this.currentBackground,
      showCustomBackground: showCustomBackground ?? this.showCustomBackground,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class CustomizationNotifier extends StateNotifier<CustomizationState> {
  final CustomizationService _service;

  CustomizationNotifier(this._service) : super(const CustomizationState(
    currentTheme: ThemePreset(
      id: 'default',
      name: 'Default',
      description: 'Default theme',
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
    ),
  )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final settings = await _service.getSettings();
      state = state.copyWith(
        currentTheme: settings.currentTheme,
        customPresets: settings.customPresets,
        customBackgrounds: settings.customBackgrounds,
        moduleLayouts: settings.moduleLayouts,
        currentBackground: settings.currentBackground,
        showCustomBackground: settings.showCustomBackground,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load settings: ${e.toString()}',
      );
    }
  }

  Future<void> setCurrentTheme(ThemePreset theme) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final settings = await _service.getSettings();
      final updatedSettings = settings.copyWith(currentTheme: theme);
      await _service.updateSettings(updatedSettings);
      
      state = state.copyWith(
        currentTheme: theme,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to set theme: ${e.toString()}',
      );
    }
  }

  Future<void> addCustomBackground(String name, List<int> bytes) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final imagePath = await _service.saveCustomImage(name, bytes);
      
      final background = CustomBackground(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        imagePath: imagePath,
      );
      
      await _service.saveCustomBackground(background);
      await _loadSettings();
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add background: ${e.toString()}',
      );
    }
  }

  Future<void> deleteCustomBackground(String backgroundId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _service.deleteCustomBackground(backgroundId);
      
      // Clear current background if it was deleted
      if (state.currentBackground?.id == backgroundId) {
        final settings = await _service.getSettings();
        final updatedSettings = settings.copyWith(currentBackground: null);
        await _service.updateSettings(updatedSettings);
      }
      
      await _loadSettings();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete background: ${e.toString()}',
      );
    }
  }

  Future<void> setCurrentBackground(CustomBackground? background) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final settings = await _service.getSettings();
      final updatedSettings = settings.copyWith(currentBackground: background);
      await _service.updateSettings(updatedSettings);
      
      state = state.copyWith(
        currentBackground: background,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to set background: ${e.toString()}',
      );
    }
  }

  Future<void> toggleCustomBackground(bool show) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final settings = await _service.getSettings();
      final updatedSettings = settings.copyWith(showCustomBackground: show);
      await _service.updateSettings(updatedSettings);
      
      state = state.copyWith(
        showCustomBackground: show,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to toggle background: ${e.toString()}',
      );
    }
  }

  Future<void> updateModuleLayouts(List<ModuleLayout> layouts) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _service.updateModuleLayouts(layouts);
      await _loadSettings();
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update layouts: ${e.toString()}',
      );
    }
  }

  Future<void> saveThemePreset(ThemePreset preset) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _service.saveThemePreset(preset);
      await _loadSettings();
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save preset: ${e.toString()}',
      );
    }
  }

  Future<void> deleteThemePreset(String presetId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _service.deleteThemePreset(presetId);
      await _loadSettings();
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete preset: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final customizationServiceProvider = Provider<CustomizationService>((ref) {
  return CustomizationService();
});

final customizationProvider = StateNotifierProvider<CustomizationNotifier, CustomizationState>((ref) {
  final service = ref.watch(customizationServiceProvider);
  return CustomizationNotifier(service);
});

final currentThemeProvider = Provider<ThemePreset>((ref) {
  return ref.watch(customizationProvider).currentTheme;
});

final customBackgroundsProvider = Provider<List<CustomBackground>>((ref) {
  return ref.watch(customizationProvider).customBackgrounds;
});

final moduleLayoutsProvider = Provider<List<ModuleLayout>>((ref) {
  return ref.watch(customizationProvider).moduleLayouts;
});
