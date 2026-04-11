import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/customization_models.dart';

class ThemePresetCard extends StatelessWidget {
  final ThemePreset preset;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const ThemePresetCard({
    required this.preset,
    required this.onTap,
    this.onDelete,
    this.onEdit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onEdit,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _colorFromHex(preset.colors.primary),
                _colorFromHex(preset.colors.secondary),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and actions
                Row(
                  children: [
                    Text(
                      preset.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const Spacer(),
                    if (onDelete != null)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                        onSelected: (value) {
                          if (value == 'delete') onDelete!();
                          if (value == 'edit') onEdit!();
                        },
                        itemBuilder: (context) => [
                          if (onEdit != null)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                          if (onDelete != null)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 16),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Theme name
                Text(
                  preset.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // Description
                Text(
                  preset.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const Spacer(),
                
                // Color preview dots
                Row(
                  children: [
                    _buildColorDot(preset.colors.primary),
                    const SizedBox(width: 4),
                    _buildColorDot(preset.colors.secondary),
                    const SizedBox(width: 4),
                    _buildColorDot(preset.colors.tertiary),
                    const Spacer(),
                    if (preset.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().scale(delay: 50.ms, duration: 300.ms).fadeIn();
  }

  Widget _buildColorDot(String color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _colorFromHex(color),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
    );
  }

  Color _colorFromHex(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}
