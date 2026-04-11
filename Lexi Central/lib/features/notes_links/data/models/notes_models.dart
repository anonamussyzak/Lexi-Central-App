import 'package:equatable/equatable.dart';

class Note extends Equatable {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final bool isPinned;
  final String? categoryId;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.isPinned = false,
    this.categoryId,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    bool? isPinned,
    String? categoryId,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  String get excerpt {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  int get wordCount {
    return content.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        createdAt,
        updatedAt,
        tags,
        isPinned,
        categoryId,
      ];
}

class Link extends Equatable {
  final String id;
  final String url;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? faviconUrl;
  final String? domain;
  final DateTime createdAt;
  final DateTime? lastVisited;
  final List<String> tags;
  final String? categoryId;
  final bool isFavorite;

  const Link({
    required this.id,
    required this.url,
    required this.title,
    this.description,
    this.imageUrl,
    this.faviconUrl,
    this.domain,
    required this.createdAt,
    this.lastVisited,
    this.tags = const [],
    this.categoryId,
    this.isFavorite = false,
  });

  Link copyWith({
    String? id,
    String? url,
    String? title,
    String? description,
    String? imageUrl,
    String? faviconUrl,
    String? domain,
    DateTime? createdAt,
    DateTime? lastVisited,
    List<String>? tags,
    String? categoryId,
    bool? isFavorite,
  }) {
    return Link(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      domain: domain ?? this.domain,
      createdAt: createdAt ?? this.createdAt,
      lastVisited: lastVisited ?? this.lastVisited,
      tags: tags ?? this.tags,
      categoryId: categoryId ?? this.categoryId,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  String get displayDomain {
    if (domain != null) return domain!;
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return url;
    }
  }

  @override
  List<Object?> get props => [
        id,
        url,
        title,
        description,
        imageUrl,
        faviconUrl,
        domain,
        createdAt,
        lastVisited,
        tags,
        categoryId,
        isFavorite,
      ];
}

class Category extends Equatable {
  final String id;
  final String name;
  final String color;
  final String icon;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.createdAt,
  });

  Category copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, color, icon, createdAt];
}

class LinkPreview {
  final String title;
  final String? description;
  final String? imageUrl;
  final String? faviconUrl;
  final String domain;
  final bool isValid;

  const LinkPreview({
    required this.title,
    this.description,
    this.imageUrl,
    this.faviconUrl,
    required this.domain,
    required this.isValid,
  });
}

enum ContentType { notes, links, all }

enum SortOption {
  newestFirst,
  oldestFirst,
  titleAZ,
  titleZA,
  lastModified,
  mostVisited,
}

class SearchFilters {
  final String query;
  final List<String> tags;
  final String? categoryId;
  final ContentType contentType;
  final SortOption sortBy;
  final bool showFavoritesOnly;

  const SearchFilters({
    this.query = '',
    this.tags = const [],
    this.categoryId,
    this.contentType = ContentType.all,
    this.sortBy = SortOption.newestFirst,
    this.showFavoritesOnly = false,
  });

  SearchFilters copyWith({
    String? query,
    List<String>? tags,
    String? categoryId,
    ContentType? contentType,
    SortOption? sortBy,
    bool? showFavoritesOnly,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      tags: tags ?? this.tags,
      categoryId: categoryId ?? this.categoryId,
      contentType: contentType ?? this.contentType,
      sortBy: sortBy ?? this.sortBy,
      showFavoritesOnly: showFavoritesOnly ?? this.showFavoritesOnly,
    );
  }

  bool get hasActiveFilters => 
      query.isNotEmpty || 
      tags.isNotEmpty || 
      categoryId != null || 
      contentType != ContentType.all ||
      showFavoritesOnly;
}
