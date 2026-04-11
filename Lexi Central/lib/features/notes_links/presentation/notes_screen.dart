import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/providers/notes_provider.dart';
import '../data/models/notes_models.dart';
import 'widgets/markdown_editor.dart';
import 'widgets/note_card.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  ContentType _currentView = ContentType.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final filters = ref.read(notesProvider).filters;
    ref.read(notesProvider.notifier).updateFilters(
      filters.copyWith(query: _searchController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(notesProvider);
    final filteredNotes = ref.watch(filteredNotesProvider);
    final filteredLinks = ref.watch(filteredLinksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.note_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('Notes & Links'),
          ],
        ),
        centerTitle: false,
        actions: [
          // View toggle
          PopupMenuButton<ContentType>(
            icon: Icon(
              Icons.view_list,
              color: Theme.of(context).colorScheme.primary,
            ),
            onSelected: (view) {
              setState(() {
                _currentView = view;
              });
              _updateFilters(view);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ContentType.all,
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive),
                    SizedBox(width: 8),
                    Text('All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ContentType.notes,
                child: Row(
                  children: [
                    Icon(Icons.note),
                    SizedBox(width: 8),
                    Text('Notes'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ContentType.links,
                child: Row(
                  children: [
                    Icon(Icons.link),
                    SizedBox(width: 8),
                    Text('Links'),
                  ],
                ),
              ),
            ],
          ),
          
          // More options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_note',
                child: Row(
                  children: [
                    Icon(Icons.note_add),
                    SizedBox(width: 8),
                    Text('New Note'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_link',
                child: Row(
                  children: [
                    Icon(Icons.link),
                    SizedBox(width: 8),
                    Text('Add Link'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'categories',
                child: Row(
                  children: [
                    Icon(Icons.category),
                    SizedBox(width: 8),
                    Text('Categories'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes and links...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: notesState.filters.hasActiveFilters
                    ? IconButton(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: Stack(
              children: [
                // Notes and links grid
                _buildContentGrid(filteredNotes, filteredLinks),
                
                // Loading indicator
                if (notesState.isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFF5B7),
                    ),
                  ),
                
                // Error message
                if (notesState.error != null)
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
                                notesState.error!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                            IconButton(
                              onPressed: () => ref.read(notesProvider.notifier).clearError(),
                              icon: Icon(Icons.close, color: Colors.red.shade700),
                            ),
                          ],
                        ),
                      ),
                    ).animate().slideY(begin: -1, duration: 300.ms),
                  ),
                
                // Floating action buttons
                _buildFloatingActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentGrid(List<Note> notes, List<Link> links) {
    List<Widget> items = [];
    
    // Add notes based on current view
    if (_currentView == ContentType.all || _currentView == ContentType.notes) {
      items.addAll(notes.map((note) => NoteCard(
        note: note,
        onTap: () => _openNote(note),
        onEdit: () => _editNote(note),
        onDelete: () => _deleteNote(note),
        onTogglePin: () => _toggleNotePin(note),
      )));
    }
    
    // Add links based on current view
    if (_currentView == ContentType.all || _currentView == ContentType.links) {
      items.addAll(links.map((link) => _buildLinkCard(link)));
    }
    
    if (items.isEmpty) {
      return _buildEmptyState();
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return items[index];
      },
    );
  }

  Widget _buildLinkCard(Link link) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openLink(link),
        onLongPress: () => _editLink(link),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                const Color(0xFFF5F7FF),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with favicon and title
                Row(
                  children: [
                    if (link.faviconUrl != null)
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.network(
                            link.faviconUrl!,
                            width: 16,
                            height: 16,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.link,
                                size: 12,
                                color: Theme.of(context).colorScheme.primary,
                              );
                            },
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.link,
                        size: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    
                    const SizedBox(width: 6),
                    
                    Expanded(
                      child: Text(
                        link.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    if (link.isFavorite)
                      Icon(
                        Icons.favorite,
                        size: 12,
                        color: Colors.red,
                      ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                if (link.description != null && link.description!.isNotEmpty)
                  Text(
                    link.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                const Spacer(),
                
                // Domain
                Text(
                  link.displayDomain,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().scale(delay: 50.ms, duration: 300.ms).fadeIn(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _currentView == ContentType.links ? Icons.link_outlined : Icons.note_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ).animate().scale(delay: 200.ms, duration: 600.ms).then().shake(),
          
          const SizedBox(height: 24),
          
          Text(
            _getEmptyTitle(),
            style: Theme.of(context).textTheme.displayMedium,
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 16),
          
          Text(
            _getEmptyMessage(),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add note button
          FloatingActionButton(
            onPressed: _createNote,
            backgroundColor: const Color(0xFFFFF5B7),
            foregroundColor: const Color(0xFFE6D690),
            heroTag: 'add_note',
            child: const Icon(Icons.note_add),
          ).animate().scale(delay: 500.ms, duration: 400.ms),
          
          const SizedBox(height: 12),
          
          // Add link button
          FloatingActionButton(
            onPressed: _createLink,
            backgroundColor: const Color(0xFFB8F2E6),
            foregroundColor: const Color(0xFF2A7F7E),
            heroTag: 'add_link',
            child: const Icon(Icons.link),
          ).animate().scale(delay: 600.ms, duration: 400.ms),
        ],
      ),
    );
  }

  String _getEmptyTitle() {
    switch (_currentView) {
      case ContentType.notes:
        return 'No Notes Yet';
      case ContentType.links:
        return 'No Links Yet';
      case ContentType.all:
        return 'Nothing Yet';
    }
  }

  String _getEmptyMessage() {
    switch (_currentView) {
      case ContentType.notes:
        return 'Create your first note to get started';
      case ContentType.links:
        return 'Add your first link to get started';
      case ContentType.all:
        return 'Create notes and add links to get started';
    }
  }

  void _updateFilters(ContentType view) {
    final filters = ref.read(notesProvider).filters;
    ref.read(notesProvider.notifier).updateFilters(
      filters.copyWith(contentType: view),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(notesProvider.notifier).updateFilters(const SearchFilters());
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'add_note':
        _createNote();
        break;
      case 'add_link':
        _createLink();
        break;
      case 'categories':
        _showCategories();
        break;
      case 'export':
        ref.read(notesProvider.notifier).exportData();
        break;
    }
  }

  void _createNote() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          onSave: (title, content, tags, categoryId) {
            ref.read(notesProvider.notifier).createNote(
              title: title,
              content: content,
              tags: tags,
              categoryId: categoryId,
            );
          },
        ),
      ),
    );
  }

  void _createLink() {
    showDialog(
      context: context,
      builder: (context) => AddLinkDialog(
        onSave: (url, tags, categoryId) {
          ref.read(notesProvider.notifier).createLink(
            url,
            tags: tags,
            categoryId: categoryId,
          );
        },
      ),
    );
  }

  void _openNote(Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteViewerScreen(note: note),
      ),
    );
  }

  void _editNote(Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          initialNote: note,
          onSave: (title, content, tags, categoryId) {
            final updatedNote = note.copyWith(
              title: title,
              content: content,
              tags: tags,
              categoryId: categoryId,
            );
            ref.read(notesProvider.notifier).updateNote(updatedNote);
          },
        ),
      ),
    );
  }

  void _deleteNote(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(notesProvider.notifier).deleteNote(note.id);
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

  void _toggleNotePin(Note note) {
    ref.read(notesProvider.notifier).toggleNotePin(note);
  }

  void _openLink(Link link) {
    ref.read(notesProvider.notifier).updateLinkLastVisited(link.id);
    // In a real app, you would open the URL in a browser
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${link.title}...')),
    );
  }

  void _editLink(Link link) {
    showDialog(
      context: context,
      builder: (context) => EditLinkDialog(
        link: link,
        onSave: (updatedLink) {
          ref.read(notesProvider.notifier).updateLink(updatedLink);
        },
      ),
    );
  }

  void _showCategories() {
    showDialog(
      context: context,
      builder: (context) => const CategoriesDialog(),
    );
  }
}

// Placeholder screens - these would be implemented in separate files
class NoteEditorScreen extends StatelessWidget {
  final Note? initialNote;
  final Function(String, String, List<String>, String?) onSave;

  const NoteEditorScreen({
    this.initialNote,
    required this.onSave,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    String title = initialNote?.title ?? '';
    String content = initialNote?.content ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(initialNote == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            onPressed: () {
              onSave(title, content, [], null);
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              initialValue: title,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => title = value,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MarkdownEditor(
                initialContent: content,
                onChanged: (value) => content = value,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoteViewerScreen extends StatelessWidget {
  final Note note;

  const NoteViewerScreen({required this.note, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(note.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: MarkdownBody(
          data: note.content,
        ),
      ),
    );
  }
}

class AddLinkDialog extends StatefulWidget {
  final Function(String, List<String>, String?) onSave;

  const AddLinkDialog({required this.onSave, super.key});

  @override
  State<AddLinkDialog> createState() => _AddLinkDialogState();
}

class _AddLinkDialogState extends State<AddLinkDialog> {
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Link'),
      content: TextField(
        controller: _urlController,
        decoration: const InputDecoration(
          labelText: 'URL',
          hintText: 'https://example.com',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_urlController.text.isNotEmpty) {
              widget.onSave(_urlController.text, [], null);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class EditLinkDialog extends StatefulWidget {
  final Link link;
  final Function(Link) onSave;

  const EditLinkDialog({
    required this.link,
    required this.onSave,
    super.key,
  });

  @override
  State<EditLinkDialog> createState() => _EditLinkDialogState();
}

class _EditLinkDialogState extends State<EditLinkDialog> {
  late final TextEditingController _urlController;
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.link.url);
    _titleController = TextEditingController(text: widget.link.title);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Link'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedLink = widget.link.copyWith(
              title: _titleController.text,
              url: _urlController.text,
            );
            widget.onSave(updatedLink);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class CategoriesDialog extends StatelessWidget {
  const CategoriesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Categories'),
      content: const Text('Categories management coming soon!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
