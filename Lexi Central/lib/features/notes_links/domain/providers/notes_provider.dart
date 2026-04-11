import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/notes_models.dart';
import '../../data/services/notes_storage_service.dart';
import '../../data/services/link_preview_service.dart';

class NotesState {
  final List<Note> notes;
  final List<Link> links;
  final List<Category> categories;
  final SearchFilters filters;
  final List<Note> filteredNotes;
  final List<Link> filteredLinks;
  final bool isLoading;
  final String? error;
  final ContentType currentView;

  const NotesState({
    this.notes = const [],
    this.links = const [],
    this.categories = const [],
    this.filters = const SearchFilters(),
    this.filteredNotes = const [],
    this.filteredLinks = const [],
    this.isLoading = false,
    this.error,
    this.currentView = ContentType.all,
  });

  NotesState copyWith({
    List<Note>? notes,
    List<Link>? links,
    List<Category>? categories,
    SearchFilters? filters,
    List<Note>? filteredNotes,
    List<Link>? filteredLinks,
    bool? isLoading,
    String? error,
    ContentType? currentView,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      links: links ?? this.links,
      categories: categories ?? this.categories,
      filters: filters ?? this.filters,
      filteredNotes: filteredNotes ?? this.filteredNotes,
      filteredLinks: filteredLinks ?? this.filteredLinks,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentView: currentView ?? this.currentView,
    );
  }
}

class NotesNotifier extends StateNotifier<NotesState> {
  final NotesStorageService _storageService;
  final LinkPreviewService _previewService;

  NotesNotifier(this._storageService, this._previewService) : super(const NotesState()) {
    _initializeData();
  }

  Future<void> _initializeData() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _storageService.initialize();
      
      final notes = await _storageService.getAllNotes();
      final links = await _storageService.getAllLinks();
      final categories = await _storageService.getAllCategories();
      
      state = state.copyWith(
        notes: notes,
        links: links,
        categories: categories,
        isLoading: false,
      );
      
      await _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize data: ${e.toString()}',
      );
    }
  }

  // Note operations
  Future<void> createNote({String? title, String? content, List<String>? tags, String? categoryId}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final now = DateTime.now();
      final note = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title ?? 'New Note',
        content: content ?? '',
        createdAt: now,
        updatedAt: now,
        tags: tags ?? [],
        categoryId: categoryId,
      );
      
      await _storageService.saveNote(note);
      
      final updatedNotes = [...state.notes, note];
      state = state.copyWith(
        notes: updatedNotes,
        isLoading: false,
      );
      
      await _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create note: ${e.toString()}',
      );
    }
  }

  Future<void> updateNote(Note note) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final updatedNote = note.copyWith(updatedAt: DateTime.now());
      await _storageService.saveNote(updatedNote);
      
      final updatedNotes = state.notes.map((n) => n.id == note.id ? updatedNote : n).toList();
      state = state.copyWith(
        notes: updatedNotes,
        isLoading: false,
      );
      
      await _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update note: ${e.toString()}',
      );
    }
  }

  Future<void> deleteNote(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _storageService.deleteNote(id);
      
      final updatedNotes = state.notes.where((n) => n.id != id).toList();
      state = state.copyWith(
        notes: updatedNotes,
        isLoading: false,
      );
      
      await _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete note: ${e.toString()}',
      );
    }
  }

  Future<void> toggleNotePin(Note note) async {
    final updatedNote = note.copyWith(isPinned: !note.isPinned);
    await updateNote(updatedNote);
  }

  // Link operations
  Future<void> createLink(String url, {List<String>? tags, String? categoryId}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Generate preview
      final preview = await _previewService.getCachedPreview(url);
      
      final link = Link(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: url,
        title: preview.title,
        description: preview.description,
        imageUrl: preview.imageUrl,
        faviconUrl: preview.faviconUrl,
        domain: preview.domain,
        createdAt: DateTime.now(),
        tags: tags ?? [],
        categoryId: categoryId,
      );
      
      await _storageService.saveLink(link);
      
      final updatedLinks = [...state.links, link];
      state = state.copyWith(
        links: updatedLinks,
        isLoading: false,
      );
      
      await _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create link: ${e.toString()}',
      );
    }
  }

  Future<void> updateLink(Link link) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _storageService.saveLink(link);
      
      final updatedLinks = state.links.map((l) => l.id == link.id ? link : l).toList();
      state = state.copyWith(
        links: updatedLinks,
        isLoading: false,
      );
      
      await _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update link: ${e.toString()}',
      );
    }
  }

  Future<void> deleteLink(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _storageService.deleteLink(id);
      
      final updatedLinks = state.links.where((l) => l.id != id).toList();
      state = state.copyWith(
        links: updatedLinks,
        isLoading: false,
      );
      
      await _applyFilters();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete link: ${e.toString()}',
      );
    }
  }

  Future<void> toggleLinkFavorite(Link link) async {
    final updatedLink = link.copyWith(isFavorite: !link.isFavorite);
    await updateLink(updatedLink);
  }

  Future<void> updateLinkLastVisited(String id) async {
    final link = state.links.firstWhere((l) => l.id == id);
    final updatedLink = link.copyWith(lastVisited: DateTime.now());
    await updateLink(updatedLink);
  }

  // Category operations
  Future<void> createCategory(String name, String color, String icon) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final category = Category(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        color: color,
        icon: icon,
        createdAt: DateTime.now(),
      );
      
      await _storageService.saveCategory(category);
      
      final updatedCategories = [...state.categories, category];
      state = state.copyWith(
        categories: updatedCategories,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create category: ${e.toString()}',
      );
    }
  }

  Future<void> updateCategory(Category category) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _storageService.saveCategory(category);
      
      final updatedCategories = state.categories.map((c) => c.id == category.id ? category : c).toList();
      state = state.copyWith(
        categories: updatedCategories,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update category: ${e.toString()}',
      );
    }
  }

  Future<void> deleteCategory(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _storageService.deleteCategory(id);
      
      final updatedCategories = state.categories.where((c) => c.id != id).toList();
      state = state.copyWith(
        categories: updatedCategories,
        isLoading: false,
      );
      
      await _initializeData(); // Reload data to update note/link categories
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete category: ${e.toString()}',
      );
    }
  }

  // Search and filtering
  Future<void> updateFilters(SearchFilters filters) async {
    state = state.copyWith(filters: filters);
    await _applyFilters();
  }

  Future<void> _applyFilters() async {
    try {
      final filteredNotes = await _storageService.searchNotes(state.filters);
      final filteredLinks = await _storageService.searchLinks(state.filters);
      
      state = state.copyWith(
        filteredNotes: filteredNotes,
        filteredLinks: filteredLinks,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to apply filters: ${e.toString()}',
      );
    }
  }

  void setCurrentView(ContentType view) {
    state = state.copyWith(currentView: view);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Export/Import
  Future<void> exportData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final directory = await _getApplicationDocumentsDirectory();
      final exportPath = '${directory.path}/lexi_central_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      await _storageService.exportData(exportPath);
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to export data: ${e.toString()}',
      );
    }
  }

  Future<void> importData(String filePath) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _storageService.importData(filePath);
      await _initializeData(); // Reload all data
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to import data: ${e.toString()}',
      );
    }
  }

  Future<void> _getApplicationDocumentsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory;
  }

  // Statistics
  Future<Map<String, int>> getStatistics() async {
    return await _storageService.getStatistics();
  }
}

// Providers
final notesStorageServiceProvider = Provider<NotesStorageService>((ref) {
  return NotesStorageService();
});

final linkPreviewServiceProvider = Provider<LinkPreviewService>((ref) {
  return LinkPreviewService();
});

final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  final storageService = ref.watch(notesStorageServiceProvider);
  final previewService = ref.watch(linkPreviewServiceProvider);
  return NotesNotifier(storageService, previewService);
});

final filteredNotesProvider = Provider<List<Note>>((ref) {
  return ref.watch(notesProvider).filteredNotes;
});

final filteredLinksProvider = Provider<List<Link>>((ref) {
  return ref.watch(notesProvider).filteredLinks;
});

final categoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(notesProvider).categories;
});
