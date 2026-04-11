import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import '../models/media_item.dart';

class GalleryRepository {
  static const List<String> imageExtensions = [
    'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'
  ];
  
  static const List<String> videoExtensions = [
    'mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', 'webm'
  ];

  Future<List<MediaItem>> importMediaFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: [...imageExtensions, ...videoExtensions],
    );

    if (result == null || result.files.isEmpty) return [];

    final mediaItems = <MediaItem>[];
    final appDir = await getApplicationDocumentsDirectory();
    final thumbnailsDir = Directory('${appDir.path}/thumbnails');
    
    if (!await thumbnailsDir.exists()) {
      await thumbnailsDir.create(recursive: true);
    }

    for (final file in result.files) {
      if (file.path == null) continue;

      final path = file.path!;
      final fileName = path.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();
      
      // Determine media type
      final isImage = imageExtensions.contains(extension);
      final isVideo = videoExtensions.contains(extension);
      
      if (!isImage && !isVideo) continue;

      // Generate thumbnail
      String? thumbnailPath;
      Duration? videoDuration;

      if (isVideo) {
        thumbnailPath = await _generateVideoThumbnail(path, thumbnailsDir.path);
        videoDuration = await _getVideoDuration(path);
      } else {
        thumbnailPath = path; // For images, use the original file as thumbnail
      }

      final mediaItem = MediaItem.fromFile(
        path,
        thumbnailPath: thumbnailPath,
        type: isImage ? MediaType.image : MediaType.video,
        duration: videoDuration,
      );

      mediaItems.add(mediaItem);
    }

    return mediaItems;
  }

  Future<String?> _generateVideoThumbnail(String videoPath, String outputDir) async {
    try {
      final fileName = videoPath.split('/').last;
      final thumbnailName = '${fileName.split('.')[0]}_thumb.jpg';
      final thumbnailPath = '$outputDir/$thumbnailName';

      // First try with video_thumbnail package
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.jpeg,
        maxHeight: 200,
        quality: 75,
      );

      if (thumbnail != null) {
        return thumbnail;
      }

      // Fallback to ffmpeg for MKV files
      if (videoPath.toLowerCase().endsWith('.mkv')) {
        final session = await FFmpegKit.execute(
          '-i "$videoPath" -ss 00:00:01.000 -vframes 1 "$thumbnailPath"'
        );

        final returnCode = await session.getReturnCode();
        if (returnCode?.isValueSuccess() == true) {
          return thumbnailPath;
        }
      }

      return null;
    } catch (e) {
      print('Error generating thumbnail: $e');
      return null;
    }
  }

  Future<Duration?> _getVideoDuration(String videoPath) async {
    try {
      final session = await FFmpegKit.execute(
        '-i "$videoPath" -show_entries format=duration -v quiet -of csv=p=0'
      );

      final returnCode = await session.getReturnCode();
      if (returnCode?.isValueSuccess() == true) {
        final output = await session.getOutput();
        if (output != null) {
          final durationStr = output.trim();
          final duration = double.tryParse(durationStr);
          if (duration != null) {
            return Duration(seconds: duration.toInt());
          }
        }
      }
    } catch (e) {
      print('Error getting video duration: $e');
    }
    return null;
  }

  Future<List<MediaItem>> getLocalMediaFiles() async {
    // This would load previously imported media from local storage
    // For now, return empty list
    return [];
  }

  Future<void> deleteMediaItem(MediaItem item) async {
    try {
      // Delete thumbnail if it exists and is different from main file
      if (item.thumbnailPath != null && 
          item.thumbnailPath != item.path &&
          item.thumbnailPath!.isNotEmpty) {
        final thumbnailFile = File(item.thumbnailPath!);
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }
      }
      
      // Note: We don't delete the original file as it might be user's personal file
      // In a real app, you might want to manage this differently
      
    } catch (e) {
      print('Error deleting media item: $e');
    }
  }
}
