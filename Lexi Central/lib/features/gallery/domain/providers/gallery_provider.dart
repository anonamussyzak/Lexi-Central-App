import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_item.dart';
import '../../data/repositories/gallery_repository.dart';

class GalleryState {
  final List<MediaItem> mediaItems;
  final bool isLoading;
  final String? error;

  const GalleryState({
    this.mediaItems = const [],
    this.isLoading = false,
    this.error,
  });

  GalleryState copyWith({
    List<MediaItem>? mediaItems,
    bool? isLoading,
    String? error,
  }) {
    return GalleryState(
      mediaItems: mediaItems ?? this.mediaItems,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class GalleryNotifier extends StateNotifier<GalleryState> {
  final GalleryRepository _repository;

  GalleryNotifier(this._repository) : super(const GalleryState());

  Future<void> importMedia() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final mediaItems = await _repository.importMediaFiles();
      state = state.copyWith(
        mediaItems: [...state.mediaItems, ...mediaItems],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to import media: ${e.toString()}',
      );
    }
  }

  Future<void> loadLocalMedia() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final mediaItems = await _repository.getLocalMediaFiles();
      state = state.copyWith(
        mediaItems: mediaItems,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load media: ${e.toString()}',
      );
    }
  }

  Future<void> deleteMediaItem(MediaItem item) async {
    state = state.copyWith(
      mediaItems: state.mediaItems.where((i) => i.id != item.id).toList(),
    );
    
    try {
      await _repository.deleteMediaItem(item);
    } catch (e) {
      // Rollback on error
      state = state.copyWith(
        mediaItems: [...state.mediaItems, item],
        error: 'Failed to delete media: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final galleryRepositoryProvider = Provider<GalleryRepository>((ref) {
  return GalleryRepository();
});

final galleryProvider = StateNotifierProvider<GalleryNotifier, GalleryState>((ref) {
  final repository = ref.watch(galleryRepositoryProvider);
  return GalleryNotifier(repository);
});

final mediaItemsProvider = Provider<List<MediaItem>>((ref) {
  return ref.watch(galleryProvider).mediaItems;
});
