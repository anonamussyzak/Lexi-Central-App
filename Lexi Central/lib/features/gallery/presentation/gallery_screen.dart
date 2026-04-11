import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/providers/gallery_provider.dart';
import 'widgets/media_grid.dart';
import 'widgets/floating_import_button.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  @override
  void initState() {
    super.initState();
    // Load any existing media when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(galleryProvider.notifier).loadLocalMedia();
    });
  }

  @override
  Widget build(BuildContext context) {
    final galleryState = ref.watch(galleryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.photo_library_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('Gallery'),
          ],
        ),
        centerTitle: false,
        actions: [
          if (galleryState.mediaItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Chip(
                label: Text(
                  '${galleryState.mediaItems.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                deleteIcon: null,
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          const MediaGrid(),
          
          // Floating import button
          const FloatingImportButton(),
          
          // Error snackbar
          if (galleryState.error != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          galleryState.error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => ref.read(galleryProvider.notifier).clearError(),
                        icon: Icon(Icons.close, color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ),
              ).animate().slideY(begin: -1, duration: 300.ms),
            ),
        ],
      ),
    );
  }
}
