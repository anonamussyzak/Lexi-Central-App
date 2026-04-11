import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../navigation/app_router.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  
  const MainLayout({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          // Side navigation rail (desktop)
          if (MediaQuery.of(context).size.width > 800)
            _buildNavigationRail(context),
          
          // Main content
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 800
          ? _buildBottomNavigationBar(context)
          : null,
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    return NavigationRail(
      selectedIndex: _getSelectedIndex(context),
      onDestinationSelected: (index) {
        _navigateToDestination(context, index);
      },
      extended: MediaQuery.of(context).size.width > 1200,
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: const Text('Home'),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.photo_library_outlined),
          selectedIcon: const Icon(Icons.photo_library),
          label: const Text('Gallery'),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.lock_outlined),
          selectedIcon: const Icon(Icons.lock),
          label: const Text('Vault'),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.discord_outlined),
          selectedIcon: const Icon(Icons.discord),
          label: const Text('Discord'),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.note_outlined),
          selectedIcon: const Icon(Icons.note),
          label: const Text('Notes'),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.palette_outlined),
          selectedIcon: const Icon(Icons.palette),
          label: const Text('Customize'),
        ),
      ],
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedIconColor: Theme.of(context).colorScheme.primary,
      selectedLabelTextStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _getSelectedIndex(context),
      onTap: (index) {
        _navigateToDestination(context, index);
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey.shade600,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.photo_library_outlined),
          activeIcon: Icon(Icons.photo_library),
          label: 'Gallery',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.lock_outlined),
          activeIcon: Icon(Icons.lock),
          label: 'Vault',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.discord_outlined),
          activeIcon: Icon(Icons.discord),
          label: 'Discord',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.note_outlined),
          activeIcon: Icon(Icons.note),
          label: 'Notes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.palette_outlined),
          activeIcon: Icon(Icons.palette),
          label: 'Customize',
        ),
      ],
    );
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouter.of(context).location;
    
    switch (location) {
      case AppRouter.home:
        return 0;
      case AppRouter.gallery:
        return 1;
      case AppRouter.vault:
        return 2;
      case AppRouter.discord:
        return 3;
      case AppRouter.notes:
        return 4;
      case AppRouter.customization:
        return 5;
      default:
        return 0;
    }
  }

  void _navigateToDestination(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRouter.home);
        break;
      case 1:
        context.go(AppRouter.gallery);
        break;
      case 2:
        context.go(AppRouter.vault);
        break;
      case 3:
        context.go(AppRouter.discord);
        break;
      case 4:
        context.go(AppRouter.notes);
        break;
      case 5:
        context.go(AppRouter.customization);
        break;
    }
  }
}
