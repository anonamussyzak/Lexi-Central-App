import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/media_item.dart';

class MediaThumbnail extends StatelessWidget {
  final MediaItem mediaItem;
  final BoxFit fit;
  final double? width;
  final double? height;

  const MediaThumbnail({
    required this.mediaItem,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaItem.thumbnailPath == null) {
      return _buildPlaceholder();
    }

    final thumbnailFile = File(mediaItem.thumbnailPath!);
    
    if (!thumbnailFile.existsSync()) {
      return _buildPlaceholder();
    }

    return Image.file(
      thumbnailFile,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder();
      },
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFB7C5).withOpacity(0.3),
            const Color(0xFFB8F2E6).withOpacity(0.3),
          ],
        ),
      ),
      child: Icon(
        mediaItem.type == MediaType.image 
            ? Icons.image_outlined
            : Icons.video_file_outlined,
        size: 48,
        color: const Color(0xFFFFB7C5),
      ),
    );
  }
}
