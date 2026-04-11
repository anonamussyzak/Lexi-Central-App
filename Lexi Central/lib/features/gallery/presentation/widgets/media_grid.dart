import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/media_item.dart';
import '../../domain/providers/gallery_provider.dart';
import 'media_thumbnail.dart';

class MediaGrid extends ConsumerStatefulWidget {
  const MediaGrid({super.key});

  @override
  ConsumerState<MediaGrid> createState() => _MediaGridState();
}

class _MediaGridState extends ConsumerState<MediaGrid> {
  @override
  Widget build(BuildContext context) {
    final mediaItems = ref.watch(mediaItemsProvider);
    final galleryState = ref.watch(galleryProvider);

    if (galleryState.isLoading && mediaItems.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFFB7C5),
        ),
      );
    }

    if (galleryState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading media',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              galleryState.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(galleryProvider.notifier).clearError(),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
    }

    if (mediaItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ).animate().scale(delay: 200.ms, duration: 600.ms).then().shake(),
            const SizedBox(height: 24),
            Text(
              'No media yet',
              style: Theme.of(context).textTheme.displayMedium,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 16),
            Text(
              'Import some photos and videos to get started',
              style: Theme.of(context).textTheme.bodyLarge,
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: mediaItems.length,
      itemBuilder: (context, index) {
        final mediaItem = mediaItems[index];
        return _MediaCard(
          mediaItem: mediaItem,
          onTap: () => _openMediaViewer(context, mediaItem),
          onDelete: () => _deleteMediaItem(mediaItem),
          index: index,
        );
      },
    );
  }

  void _openMediaViewer(BuildContext context, MediaItem mediaItem) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MediaViewerScreen(mediaItem: mediaItem),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(0, 1), end: Offset.zero),
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _deleteMediaItem(MediaItem mediaItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: Text('Are you sure you want to delete "${mediaItem.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(galleryProvider.notifier).deleteMediaItem(mediaItem);
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

class _MediaCard extends StatelessWidget {
  final MediaItem mediaItem;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final int index;

  const _MediaCard({
    required this.mediaItem,
    required this.onTap,
    required this.onDelete,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            MediaThumbnail(
              mediaItem: mediaItem,
              fit: BoxFit.cover,
            ),
            
            // Video indicator
            if (mediaItem.type == MediaType.video)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            
            // Duration for videos
            if (mediaItem.type == MediaType.video && mediaItem.duration != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(mediaItem.duration!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            
            // File type indicator
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: mediaItem.type == MediaType.image 
                      ? const Color(0xFFFFB7C5).withOpacity(0.9)
                      : const Color(0xFFB8F2E6).withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  mediaItem.type == MediaType.image 
                      ? Icons.image
                      : Icons.video_file,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(delay: (index * 50).ms, duration: 300.ms).fadeIn();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}
