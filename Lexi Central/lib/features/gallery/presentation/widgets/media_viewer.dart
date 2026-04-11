import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/media_item.dart';
import '../../domain/providers/gallery_provider.dart';

class MediaViewerScreen extends ConsumerStatefulWidget {
  final MediaItem mediaItem;

  const MediaViewerScreen({required this.mediaItem, super.key});

  @override
  ConsumerState<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends ConsumerState<MediaViewerScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.mediaItem.type == MediaType.video) {
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      final file = File(widget.mediaItem.path);
      if (await file.exists()) {
        _videoController = VideoPlayerController.file(file);
        await _videoController!.initialize();
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaItems = ref.watch(mediaItemsProvider);
    final initialIndex = mediaItems.indexOf(widget.mediaItem);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        foregroundColor: Colors.white,
        title: Text(
          widget.mediaItem.fileName,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => _deleteCurrentMedia(),
            icon: const Icon(Icons.delete, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: PhotoViewGallery.builder(
          scrollDirection: Axis.horizontal,
          itemCount: mediaItems.length,
          builder: (context, index) {
            final mediaItem = mediaItems[index];
            return PhotoViewGalleryPageOptions(
              imageProvider: _getImageProvider(mediaItem),
              initialScale: PhotoViewComputedScale.contained,
              heroAttributes: PhotoViewHeroAttributes(tag: mediaItem.id),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 4.0,
              errorBuilder: (context, error, stackTrace) => _buildErrorWidget(mediaItem),
            );
          },
          backgroundDecoration: const BoxDecoration(
            color: Colors.black,
          ),
          pageController: PageController(initialPage: initialIndex),
          onPageChanged: (index) {
            final newMediaItem = mediaItems[index];
            if (newMediaItem.type == MediaType.video && _videoController == null) {
              _initializeVideoForMedia(newMediaItem);
            }
          },
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(MediaItem mediaItem) {
    if (mediaItem.type == MediaType.image) {
      final file = File(mediaItem.path);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } else if (mediaItem.type == MediaType.video && mediaItem.thumbnailPath != null) {
      final thumbnailFile = File(mediaItem.thumbnailPath!);
      if (thumbnailFile.existsSync()) {
        return FileImage(thumbnailFile);
      }
    }
    
    // Fallback to asset
    return const AssetImage('assets/kirby_bg.png');
  }

  Widget _buildErrorWidget(MediaItem mediaItem) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mediaItem.type == MediaType.image 
                  ? Icons.broken_image
                  : Icons.video_file_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load ${mediaItem.type.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeVideoForMedia(MediaItem mediaItem) async {
    try {
      final file = File(mediaItem.path);
      if (await file.exists()) {
        _videoController?.dispose();
        _videoController = VideoPlayerController.file(file);
        await _videoController!.initialize();
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _deleteCurrentMedia() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: Text('Are you sure you want to delete "${widget.mediaItem.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(galleryProvider.notifier).deleteMediaItem(widget.mediaItem);
              Navigator.of(context).pop(); // Close viewer
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

class VideoPlayerWidget extends StatelessWidget {
  final VideoPlayerController controller;

  const VideoPlayerWidget({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: VideoPlayer(controller),
    );
  }
}
