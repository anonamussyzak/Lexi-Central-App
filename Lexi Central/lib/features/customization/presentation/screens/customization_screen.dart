import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/customization_models.dart';
import '../../domain/providers/customization_provider.dart';
import '../widgets/theme_preset_card.dart';
import '../widgets/module_layout_editor.dart';
import '../widgets/background_selector.dart';

class CustomizationScreen extends ConsumerStatefulWidget {
  const CustomizationScreen({super.key});

  @override
  ConsumerState<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends ConsumerState<CustomizationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customizationState = ref.watch(customizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.palette_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('Customization'),
          ],
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.palette),
              text: 'Themes',
            ),
            Tab(
              icon: Icons.dashboard_customize,
              text: 'Layout',
            ),
            Tab(
              icon: Icons.image,
              text: 'Background',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildThemesTab(customizationState),
          _buildLayoutTab(customizationState),
          _buildBackgroundTab(customizationState),
        ],
      ),
    );
  }

  Widget _buildThemesTab(CustomizationState state) {
    return Column(
      children: [
        // Current theme display
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _colorFromHex(state.currentTheme.colors.primary),
                _colorFromHex(state.currentTheme.colors.secondary),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Text(
                state.currentTheme.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.currentTheme.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      state.currentTheme.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().scale(delay: 200.ms),

        // Theme presets
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: state.customPresets.length + 1, // +1 for "Create New"
            itemBuilder: (context, index) {
              if (index == state.customPresets.length) {
                return _buildCreatePresetCard().animate().scale(delay: (index * 100).ms);
              }
              
              final preset = state.customPresets[index];
              return ThemePresetCard(
                preset: preset,
                onTap: () => _applyTheme(preset),
                onDelete: preset.isDefault ? null : () => _deletePreset(preset.id),
                onEdit: () => _editPreset(preset),
              ).animate().scale(delay: (index * 100).ms);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLayoutTab(CustomizationState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Layout instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Drag and drop modules to rearrange them. Long press to resize.',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ).animate().slideX(begin: -1, duration: 400.ms),

          const SizedBox(height: 16),

          // Module layout editor
          Expanded(
            child: ModuleLayoutEditor(
              layouts: state.moduleLayouts,
              onLayoutChanged: (layouts) {
                ref.read(customizationProvider.notifier).updateModuleLayouts(layouts);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundTab(CustomizationState state) {
    return Column(
      children: [
        // Background toggle
        Container(
          margin: const EdgeInsets.all(16),
          child: SwitchListTile(
            title: const Text('Show Custom Background'),
            subtitle: const Text('Display your uploaded background image'),
            value: state.showCustomBackground,
            onChanged: (value) {
              ref.read(customizationProvider.notifier).toggleCustomBackground(value);
            },
            secondary: Icon(
              state.showCustomBackground ? Icons.image : Icons.image_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ).animate().slideX(begin: -1, duration: 400.ms),

        // Background selector
        Expanded(
          child: BackgroundSelector(
            backgrounds: state.customBackgrounds,
            currentBackground: state.currentBackground,
            showCustomBackground: state.showCustomBackground,
            onBackgroundSelected: (background) {
              ref.read(customizationProvider.notifier).setCurrentBackground(background);
            },
            onAddBackground: _addCustomBackground,
            onDeleteBackground: _deleteBackground,
          ),
        ),
      ],
    );
  }

  Widget _buildCreatePresetCard() {
    return InkWell(
      onTap: _createNewPreset,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 48,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              'Create Theme',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFromHex(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  void _applyTheme(ThemePreset preset) {
    ref.read(customizationProvider.notifier).setCurrentTheme(preset);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied ${preset.name} theme'),
        backgroundColor: _colorFromHex(preset.colors.primary),
      ),
    );
  }

  void _deletePreset(String presetId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Theme'),
        content: const Text('Are you sure you want to delete this theme preset?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(customizationProvider.notifier).deleteThemePreset(presetId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editPreset(ThemePreset preset) {
    // TODO: Navigate to theme editor screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Theme editor coming soon!')),
    );
  }

  void _createNewPreset() {
    // TODO: Navigate to theme creation screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Theme creator coming soon!')),
    );
  }

  Future<void> _addCustomBackground() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          await ref.read(customizationProvider.notifier).addCustomBackground(
            file.name,
            file.bytes!,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding background: $e')),
      );
    }
  }

  void _deleteBackground(String backgroundId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Background'),
        content: const Text('Are you sure you want to delete this background image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(customizationProvider.notifier).deleteCustomBackground(backgroundId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
