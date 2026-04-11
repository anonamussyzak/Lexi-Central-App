import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../navigation/app_router.dart';

class HomeScreen extends StatelessWidget {
  final Widget? child;
  
  const HomeScreen({
    this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // If child is provided, show it directly (for navigation)
    if (child != null) {
      return child!;
    }
    
    // Otherwise show the home dashboard
    return const HomeDashboard();
  }
}

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFF5F7),
              const Color(0xFFB8F2E6).withOpacity(0.1),
              const Color(0xFFFFB7C5).withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome header
                Row(
                  children: [
                    Text(
                      '🌸',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Welcome to Lexi Central!',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFF6B8B),
                      ),
                    ),
                  ],
                ).animate().slideX(begin: -1, duration: 600.ms),
                
                const SizedBox(height: 32),
                
                // Module grid
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: 5, // Number of main features
                    itemBuilder: (context, index) {
                      return _buildModuleCard(context, index);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, int index) {
    final modules = [
      {
        'title': 'Gallery',
        'subtitle': 'Your media collection',
        'icon': Icons.photo_library,
        'color': const Color(0xFFFFB7C5),
        'route': AppRouter.gallery,
      },
      {
        'title': 'Vault',
        'subtitle': 'Secure encrypted storage',
        'icon': Icons.lock,
        'color': const Color(0xFFB8F2E6),
        'route': AppRouter.vault,
      },
      {
        'title': 'Discord',
        'subtitle': 'Server messages feed',
        'icon': Icons.discord,
        'color': const Color(0xFF5865F2),
        'route': AppRouter.discord,
      },
      {
        'title': 'Notes',
        'subtitle': 'Markdown notes',
        'icon': Icons.note,
        'color': const Color(0xFFFFF5B7),
        'route': AppRouter.notes,
      },
      {
        'title': 'Customize',
        'subtitle': 'Themes & layout',
        'icon': Icons.palette,
        'color': const Color(0xFFD8BFD8),
        'route': AppRouter.customization,
      },
    ];
    
    final module = modules[index];
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(module['route'] as String),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                module['color'] as Color,
                (module['color'] as Color).withOpacity(0.7),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  module['icon'] as IconData,
                  size: 32,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  module['title'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  module['subtitle'] as String,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().scale(delay: (index * 150).ms, duration: 400.ms).fadeIn();
  }
}
