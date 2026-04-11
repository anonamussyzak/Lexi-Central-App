import 'package:equatable/equatable.dart';

enum MediaType { image, video }

class MediaItem extends Equatable {
  final String id;
  final String path;
  final String? thumbnailPath;
  final MediaType type;
  final String fileName;
  final int fileSize;
  final DateTime createdAt;
  final Duration? duration; // For videos

  const MediaItem({
    required this.id,
    required this.path,
    this.thumbnailPath,
    required this.type,
    required this.fileName,
    required this.fileSize,
    required this.createdAt,
    this.duration,
  });

  factory MediaItem.fromFile(
    String path, {
    String? thumbnailPath,
    MediaType? type,
    Duration? duration,
  }) {
    final fileName = path.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();
    
    final mediaType = type ?? (['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(extension) 
        ? MediaType.image 
        : MediaType.video);
    
    return MediaItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: path,
      thumbnailPath: thumbnailPath,
      type: mediaType,
      fileName: fileName,
      fileSize: 0, // Will be set when file is accessed
      createdAt: DateTime.now(),
      duration: duration,
    );
  }

  MediaItem copyWith({
    String? id,
    String? path,
    String? thumbnailPath,
    MediaType? type,
    String? fileName,
    int? fileSize,
    DateTime? createdAt,
    Duration? duration,
  }) {
    return MediaItem(
      id: id ?? this.id,
      path: path ?? this.path,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      type: type ?? this.type,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      duration: duration ?? this.duration,
    );
  }

  @override
  List<Object?> get props => [
        id,
        path,
        thumbnailPath,
        type,
        fileName,
        fileSize,
        createdAt,
        duration,
      ];
}
