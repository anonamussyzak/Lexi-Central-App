import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/customization_models.dart';

class ModuleLayoutEditor extends StatefulWidget {
  final List<ModuleLayout> layouts;
  final Function(List<ModuleLayout>) onLayoutChanged;

  const ModuleLayoutEditor({
    required this.layouts,
    required this.onLayoutChanged,
    super.key,
  });

  @override
  State<ModuleLayoutEditor> createState() => _ModuleLayoutEditorState();
}

class _ModuleLayoutEditorState extends State<ModuleLayoutEditor> {
  List<ModuleLayout> _layouts = [];
  ModuleLayout? _draggedModule;
  int? _draggedIndex;
  
  @override
  void initState() {
    super.initState();
    _layouts = List.from(widget.layouts);
    _layouts.sort((a, b) => a.position.compareTo(b.position));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.dashboard_customize,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Module Layout',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _resetLayout,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Layout grid
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DragTarget<String>(
                  onAccept: (moduleId) {
                    _handleDrop(moduleId);
                  },
                  builder: (context, candidateData, rejectedData) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: _layouts.length + 1, // +1 for empty slot
                      itemBuilder: (context, index) {
                        if (index < _layouts.length) {
                          final layout = _layouts[index];
                          return _buildModuleCard(layout, index);
                        } else {
                          return _buildEmptySlot(index);
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(ModuleLayout layout, int index) {
    final isDragged = _draggedIndex == index;
    
    return LongPressDraggable<String>(
      data: layout.moduleId,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 150,
          height: 100,
          decoration: BoxDecoration(
            gradient: _getModuleGradient(layout.moduleId),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _getModuleIcon(layout.moduleId),
                  color: Colors.white,
                  size: 24,
                ),
                const Spacer(),
                Text(
                  layout.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
        ),
        child: const Center(
          child: Icon(Icons.swap_vert, color: Colors.grey),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: _getModuleGradient(layout.moduleId),
          borderRadius: BorderRadius.circular(12),
          opacity: isDragged ? 0.5 : 1.0,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _getModuleIcon(layout.moduleId),
                color: Colors.white,
                size: 24,
              ),
              const Spacer(),
              Text(
                layout.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(delay: (index * 100).ms, duration: 300.ms);
  }

  Widget _buildEmptySlot(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 32,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              'Drop Module',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(delay: (index * 100).ms, duration: 300.ms);
  }

  LinearGradient _getModuleGradient(String moduleId) {
    switch (moduleId) {
      case 'gallery':
        return const LinearGradient(
          colors: [Color(0xFFFFB7C5), Color(0xFFFF6B8B)],
        );
      case 'vault':
        return const LinearGradient(
          colors: [Color(0xFFB8F2E6), Color(0xFF2A7F7E)],
        );
      case 'discord':
        return const LinearGradient(
          colors: [Color(0xFF5865F2), Color(0xFF4752C4)],
        );
      case 'notes':
        return const LinearGradient(
          colors: [Color(0xFFFFF5B7), Color(0xFFE6D690)],
        );
      case 'links':
        return const LinearGradient(
          colors: [Color(0xFFD8BFD8), Color(0xFF9370DB)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFFB8B8B8), Color(0xFF6A6A6A)],
        );
    }
  }

  IconData _getModuleIcon(String moduleId) {
    switch (moduleId) {
      case 'gallery':
        return Icons.photo_library;
      case 'vault':
        return Icons.lock;
      case 'discord':
        return Icons.discord;
      case 'notes':
        return Icons.note;
      case 'links':
        return Icons.link;
      default:
        return Icons.apps;
    }
  }

  void _handleDrop(String moduleId) {
    if (_draggedModule != null && _draggedIndex != null) {
      // Remove from original position
      _layouts.removeWhere((layout) => layout.moduleId == moduleId);
      
      // Add to new position (empty slot)
      final newLayout = _draggedModule!.copyWith(position: _draggedIndex!);
      _layouts.insert(_draggedIndex!, newLayout);
      
      // Update positions
      for (int i = 0; i < _layouts.length; i++) {
        _layouts[i] = _layouts[i].copyWith(position: i);
      }
      
      widget.onLayoutChanged(_layouts);
    }
    
    setState(() {
      _draggedModule = null;
      _draggedIndex = null;
    });
  }

  void _resetLayout() {
    setState(() {
      _layouts = [
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
    });
    
    widget.onLayoutChanged(_layouts);
  }
}
