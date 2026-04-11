import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import '../models/notes_models.dart';

class NotesStorageService {
  static const String _notesBoxName = 'notes';
  static const String _linksBoxName = 'links';
  static const String _categoriesBoxName = 'categories';
  
  late Box<Note> _notesBox;
  late Box<Link> _linksBox;
  late Box<Category> _categoriesBox;

  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDir.path);
    
    // Register adapters
    Hive.registerAdapter(NoteAdapter());
    Hive.registerAdapter(LinkAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(ContentTypeAdapter());
    Hive.registerAdapter(SortOptionAdapter());
    
    // Open boxes
    _notesBox = await Hive.openBox<Note>(_notesBoxName);
    _linksBox = await Hive.openBox<Link>(_linksBoxName);
    _categoriesBox = await Hive.openBox<Category>(_categoriesBoxName);
    
    // Create default categories if none exist
    await _createDefaultCategories();
  }

  // Notes operations
  Future<List<Note>> getAllNotes() async {
    return _notesBox.values.toList();
  }

  Future<Note?> getNoteById(String id) async {
    return _notesBox.get(id);
  }

  Future<void> saveNote(Note note) async {
    await _notesBox.put(note.id, note);
  }

  Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }

  Future<List<Note>> searchNotes(SearchFilters filters) async {
    var notes = _notesBox.values.toList();
    
    // Apply filters
    if (filters.contentType == ContentType.notes || filters.contentType == ContentType.all) {
      notes = _applyNoteFilters(notes, filters);
    } else {
      notes = [];
    }
    
    return notes;
  }

  List<Note> _applyNoteFilters(List<Note> notes, SearchFilters filters) {
    var filteredNotes = notes;
    
    // Text search
    if (filters.query.isNotEmpty) {
      final query = filters.query.toLowerCase();
      filteredNotes = filteredNotes.where((note) =>
          note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query) ||
          note.tags.any((tag) => tag.toLowerCase().contains(query))
      ).toList();
    }
    
    // Tags filter
    if (filters.tags.isNotEmpty) {
      filteredNotes = filteredNotes.where((note) =>
          filters.tags.any((tag) => note.tags.contains(tag))
      ).toList();
    }
    
    // Category filter
    if (filters.categoryId != null) {
      filteredNotes = filteredNotes.where((note) =>
          note.categoryId == filters.categoryId
      ).toList();
    }
    
    // Favorites filter
    if (filters.showFavoritesOnly) {
      filteredNotes = filteredNotes.where((note) => note.isPinned).toList();
    }
    
    // Sort
    filteredNotes = _sortNotes(filteredNotes, filters.sortBy);
    
    return filteredNotes;
  }

  List<Note> _sortNotes(List<Note> notes, SortOption sortBy) {
    switch (sortBy) {
      case SortOption.newestFirst:
        return notes..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case SortOption.oldestFirst:
        return notes..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case SortOption.titleAZ:
        return notes..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case SortOption.titleZA:
        return notes..sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
      case SortOption.lastModified:
        return notes..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case SortOption.mostVisited:
        return notes; // Notes don't have visit count, keep original order
    }
  }

  // Links operations
  Future<List<Link>> getAllLinks() async {
    return _linksBox.values.toList();
  }

  Future<Link?> getLinkById(String id) async {
    return _linksBox.get(id);
  }

  Future<void> saveLink(Link link) async {
    await _linksBox.put(link.id, link);
  }

  Future<void> deleteLink(String id) async {
    await _linksBox.delete(id);
  }

  Future<List<Link>> searchLinks(SearchFilters filters) async {
    var links = _linksBox.values.toList();
    
    // Apply filters
    if (filters.contentType == ContentType.links || filters.contentType == ContentType.all) {
      links = _applyLinkFilters(links, filters);
    } else {
      links = [];
    }
    
    return links;
  }

  List<Link> _applyLinkFilters(List<Link> links, SearchFilters filters) {
    var filteredLinks = links;
    
    // Text search
    if (filters.query.isNotEmpty) {
      final query = filters.query.toLowerCase();
      filteredLinks = filteredLinks.where((link) =>
          link.title.toLowerCase().contains(query) ||
          link.description?.toLowerCase().contains(query) == true ||
          link.url.toLowerCase().contains(query) ||
          link.displayDomain.toLowerCase().contains(query) ||
          link.tags.any((tag) => tag.toLowerCase().contains(query))
      ).toList();
    }
    
    // Tags filter
    if (filters.tags.isNotEmpty) {
      filteredLinks = filteredLinks.where((link) =>
          filters.tags.any((tag) => link.tags.contains(tag))
      ).toList();
    }
    
    // Category filter
    if (filters.categoryId != null) {
      filteredLinks = filteredLinks.where((link) =>
          link.categoryId == filters.categoryId
      ).toList();
    }
    
    // Favorites filter
    if (filters.showFavoritesOnly) {
      filteredLinks = filteredLinks.where((link) => link.isFavorite).toList();
    }
    
    // Sort
    filteredLinks = _sortLinks(filteredLinks, filters.sortBy);
    
    return filteredLinks;
  }

  List<Link> _sortLinks(List<Link> links, SortOption sortBy) {
    switch (sortBy) {
      case SortOption.newestFirst:
        return links..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortOption.oldestFirst:
        return links..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case SortOption.titleAZ:
        return links..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case SortOption.titleZA:
        return links..sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
      case SortOption.lastModified:
        return links..sort((a, b) => 
            (b.lastVisited ?? b.createdAt).compareTo(a.lastVisited ?? a.createdAt));
      case SortOption.mostVisited:
        return links; // Sort by last visited as proxy for most visited
    }
  }

  // Categories operations
  Future<List<Category>> getAllCategories() async {
    return _categoriesBox.values.toList();
  }

  Future<Category?> getCategoryById(String id) async {
    return _categoriesBox.get(id);
  }

  Future<void> saveCategory(Category category) async {
    await _categoriesBox.put(category.id, category);
  }

  Future<void> deleteCategory(String id) async {
    // Remove category from notes and links
    for (final note in _notesBox.values) {
      if (note.categoryId == id) {
        final updatedNote = note.copyWith(categoryId: null);
        await _notesBox.put(note.id, updatedNote);
      }
    }
    
    for (final link in _linksBox.values) {
      if (link.categoryId == id) {
        final updatedLink = link.copyWith(categoryId: null);
        await _linksBox.put(link.id, updatedLink);
      }
    }
    
    await _categoriesBox.delete(id);
  }

  Future<void> _createDefaultCategories() async {
    final categories = await getAllCategories();
    
    if (categories.isEmpty) {
      final defaultCategories = [
        Category(
          id: 'personal',
          name: 'Personal',
          color: '#FFB7C5',
          icon: 'person',
          createdAt: DateTime.now(),
        ),
        Category(
          id: 'work',
          name: 'Work',
          color: '#B8F2E6',
          icon: 'work',
          createdAt: DateTime.now(),
        ),
        Category(
          id: 'ideas',
          name: 'Ideas',
          color: '#FFF5B7',
          icon: 'lightbulb',
          createdAt: DateTime.now(),
        ),
        Category(
          id: 'resources',
          name: 'Resources',
          color: '#D8BFD8',
          icon: 'bookmark',
          createdAt: DateTime.now(),
        ),
      ];
      
      for (final category in defaultCategories) {
        await saveCategory(category);
      }
    }
  }

  // Statistics
  Future<Map<String, int>> getStatistics() async {
    final notesCount = _notesBox.length;
    final linksCount = _linksBox.length;
    final categoriesCount = _categoriesBox.length;
    
    return {
      'notes': notesCount,
      'links': linksCount,
      'categories': categoriesCount,
    };
  }

  // Export/Import
  Future<void> exportData(String filePath) async {
    final exportData = {
      'notes': _notesBox.values.map((note) => note.toJson()).toList(),
      'links': _linksBox.values.map((link) => link.toJson()).toList(),
      'categories': _categoriesBox.values.map((category) => category.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
    
    final file = File(filePath);
    await file.writeAsString(jsonEncode(exportData));
  }

  Future<void> importData(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Import file does not exist');
    }
    
    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;
    
    // Clear existing data
    await _notesBox.clear();
    await _linksBox.clear();
    await _categoriesBox.clear();
    
    // Import categories first
    final categoriesData = data['categories'] as List;
    for (final categoryData in categoriesData) {
      final category = Category.fromJson(categoryData);
      await saveCategory(category);
    }
    
    // Import notes
    final notesData = data['notes'] as List;
    for (final noteData in notesData) {
      final note = Note.fromJson(noteData);
      await saveNote(note);
    }
    
    // Import links
    final linksData = data['links'] as List;
    for (final linkData in linksData) {
      final link = Link.fromJson(linkData);
      await saveLink(link);
    }
  }

  Future<void> close() async {
    await _notesBox.close();
    await _linksBox.close();
    await _categoriesBox.close();
  }
}

// Hive Type Adapters
class NoteAdapter extends TypeAdapter<Note> {
  @override
  final typeId = 0;

  @override
  Note read(BinaryReader reader) {
    return Note.fromJson(reader.read());
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer.write(obj.toJson());
  }
}

class LinkAdapter extends TypeAdapter<Link> {
  @override
  final typeId = 1;

  @override
  Link read(BinaryReader reader) {
    return Link.fromJson(reader.read());
  }

  @override
  void write(BinaryWriter writer, Link obj) {
    writer.write(obj.toJson());
  }
}

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final typeId = 2;

  @override
  Category read(BinaryReader reader) {
    return Category.fromJson(reader.read());
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer.write(obj.toJson());
  }
}

class ContentTypeAdapter extends TypeAdapter<ContentType> {
  @override
  final typeId = 3;

  @override
  ContentType read(BinaryReader reader) {
    return ContentType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, ContentType obj) {
    writer.writeByte(obj.index);
  }
}

class SortOptionAdapter extends TypeAdapter<SortOption> {
  @override
  final typeId = 4;

  @override
  SortOption read(BinaryReader reader) {
    return SortOption.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, SortOption obj) {
    writer.writeByte(obj.index);
  }
}

// Extension methods for JSON serialization
extension NoteExtension on Note {
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'tags': tags,
        'isPinned': isPinned,
        'categoryId': categoryId,
      };

  static Note fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        tags: List<String>.from(json['tags'] ?? []),
        isPinned: json['isPinned'] ?? false,
        categoryId: json['categoryId'],
      );
}

extension LinkExtension on Link {
  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'faviconUrl': faviconUrl,
        'domain': domain,
        'createdAt': createdAt.toIso8601String(),
        'lastVisited': lastVisited?.toIso8601String(),
        'tags': tags,
        'categoryId': categoryId,
        'isFavorite': isFavorite,
      };

  static Link fromJson(Map<String, dynamic> json) => Link(
        id: json['id'],
        url: json['url'],
        title: json['title'],
        description: json['description'],
        imageUrl: json['imageUrl'],
        faviconUrl: json['faviconUrl'],
        domain: json['domain'],
        createdAt: DateTime.parse(json['createdAt']),
        lastVisited: json['lastVisited'] != null 
            ? DateTime.parse(json['lastVisited'])
            : null,
        tags: List<String>.from(json['tags'] ?? []),
        categoryId: json['categoryId'],
        isFavorite: json['isFavorite'] ?? false,
      );
}

extension CategoryExtension on Category {
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'icon': icon,
        'createdAt': createdAt.toIso8601String(),
      };

  static Category fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        name: json['name'],
        color: json['color'],
        icon: json['icon'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}
