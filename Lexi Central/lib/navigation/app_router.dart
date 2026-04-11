import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/gallery/presentation/gallery_screen.dart';
import '../features/vault/presentation/vault_screen.dart';
import '../features/discord_feed/presentation/discord_screen.dart';
import '../features/notes_links/presentation/notes_screen.dart';
import '../features/customization/presentation/screens/customization_screen.dart';
import '../core/screens/home_screen.dart';

class AppRouter {
  static const String home = '/';
  static const String gallery = '/gallery';
  static const String vault = '/vault';
  static const String discord = '/discord';
  static const String notes = '/notes';
  static const String customization = '/customization';

  static final router = GoRouter(
    initialLocation: home,
    routes: [
      // Shell route for main layout
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          // Home route
          GoRoute(
            path: home,
            builder: (context, state) => const HomeScreen(),
          ),
          
          // Feature routes
          GoRoute(
            path: gallery,
            builder: (context, state) => const GalleryScreen(),
          ),
          
          GoRoute(
            path: vault,
            builder: (context, state) => const VaultScreen(),
          ),
          
          GoRoute(
            path: discord,
            builder: (context, state) => const DiscordScreen(),
          ),
          
          GoRoute(
            path: notes,
            builder: (context, state) => const NotesScreen(),
          ),
          
          GoRoute(
            path: customization,
            builder: (context, state) => const CustomizationScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The requested page could not be found.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
