import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownEditor extends StatefulWidget {
  final String initialContent;
  final Function(String) onChanged;
  final String? hintText;
  final bool showPreview;
  final int? maxLines;

  const MarkdownEditor({
    required this.onChanged,
    this.initialContent = '',
    this.hintText,
    this.showPreview = true,
    this.maxLines,
    super.key,
  });

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late TextEditingController _controller;
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
    _controller.addListener(() {
      widget.onChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPreviewMode) {
      return _buildPreview();
    }

    return Column(
      children: [
        // Toolbar
        _buildToolbar(),
        
        const SizedBox(height: 8),
        
        // Editor
        _buildEditor(),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Formatting buttons
          _buildToolbarButton(
            icon: Icons.format_bold,
            tooltip: 'Bold',
            onPressed: () => _insertText('**', '**'),
          ),
          
          _buildToolbarButton(
            icon: Icons.format_italic,
            tooltip: 'Italic',
            onPressed: () => _insertText('*', '*'),
          ),
          
          _buildToolbarButton(
            icon: Icons.format_strikethrough,
            tooltip: 'Strikethrough',
            onPressed: () => _insertText('~~', '~~'),
          ),
          
          const VerticalDivider(width: 16),
          
          _buildToolbarButton(
            icon: Icons.title,
            tooltip: 'Heading',
            onPressed: () => _insertText('## ', ''),
          ),
          
          _buildToolbarButton(
            icon: Icons.format_quote,
            tooltip: 'Quote',
            onPressed: () => _insertText('> ', ''),
          ),
          
          const VerticalDivider(width: 16),
          
          _buildToolbarButton(
            icon: Icons.code,
            tooltip: 'Inline Code',
            onPressed: () => _insertText('`', '`'),
          ),
          
          _buildToolbarButton(
            icon: Icons.code_off,
            tooltip: 'Code Block',
            onPressed: () => _insertText('```\n', '\n```'),
          ),
          
          const VerticalDivider(width: 16),
          
          _buildToolbarButton(
            icon: Icons.link,
            tooltip: 'Link',
            onPressed: () => _insertText('[', '](url)'),
          ),
          
          _buildToolbarButton(
            icon: Icons.image,
            tooltip: 'Image',
            onPressed: () => _insertText('![', '](url)'),
          ),
          
          const VerticalDivider(width: 16),
          
          _buildToolbarButton(
            icon: Icons.format_list_bulleted,
            tooltip: 'Bullet List',
            onPressed: () => _insertText('- ', ''),
          ),
          
          _buildToolbarButton(
            icon: Icons.format_list_numbered,
            tooltip: 'Numbered List',
            onPressed: () => _insertText('1. ', ''),
          ),
          
          const Spacer(),
          
          // Preview toggle
          if (widget.showPreview)
            IconButton(
              onPressed: () {
                setState(() {
                  _isPreviewMode = !_isPreviewMode;
                });
              },
              icon: Icon(
                _isPreviewMode ? Icons.edit : Icons.visibility,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: _isPreviewMode ? 'Edit' : 'Preview',
            ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        splashRadius: 20,
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _controller,
        maxLines: widget.maxLines ?? 15,
        expands: widget.maxLines == null,
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Start writing in markdown...',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontFamily: 'monospace',
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Preview header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.visibility,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Preview',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isPreviewMode = !_isPreviewMode;
                    });
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  tooltip: 'Edit',
                ),
              ],
            ),
          ),
          
          // Preview content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: _controller.text.isEmpty
                  ? Center(
                      child: Text(
                        'Nothing to preview yet...',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : MarkdownBody(
                      data: _controller.text,
                      styleSheet: MarkdownStyleSheet(
                        p: Theme.of(context).textTheme.bodyMedium,
                        h1: Theme.of(context).textTheme.headlineLarge,
                        h2: Theme.of(context).textTheme.headlineMedium,
                        h3: Theme.of(context).textTheme.headlineSmall,
                        h4: Theme.of(context).textTheme.titleLarge,
                        h5: Theme.of(context).textTheme.titleMedium,
                        h6: Theme.of(context).textTheme.titleSmall,
                        code: TextStyle(
                          backgroundColor: Colors.grey.shade200,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        blockquote: TextStyle(
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 4,
                            ),
                          ),
        ),
        listBullet: TextStyle(
          color: Theme.of(context).colorScheme.primary,
        ),
        a: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        tableHead: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        tableBody: TextStyle(
          color: Colors.grey.shade700,
        ),
        tableBorder: TableBorder.all(
          color: Colors.grey.shade300,
        ),
      ),
    ),
            ),
          ),
        ],
      ),
    );
  }

  void _insertText(String prefix, String suffix) {
    final text = _controller.text;
    final selection = _controller.selection;
    
    if (selection.isValid) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );
      
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + prefix.length + selectedText.length + suffix.length,
        ),
      );
    } else {
      final cursorPos = selection.baseOffset;
      final newText = text.replaceRange(
        cursorPos,
        cursorPos,
        '$prefix$suffix',
      );
      
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: cursorPos + prefix.length,
        ),
      );
    }
  }

  void _insertListMarker(String marker) {
    final text = _controller.text;
    final selection = _controller.selection;
    
    if (selection.isValid) {
      final lineStart = text.lastIndexOf('\n', selection.start - 1) + 1;
      final lineEnd = text.indexOf('\n', selection.end);
      final endPos = lineEnd == -1 ? text.length : lineEnd;
      
      final line = text.substring(lineStart, endPos);
      if (!line.startsWith(marker)) {
        final newText = text.replaceRange(
          lineStart,
          lineStart,
          marker,
        );
        
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: selection.baseOffset + marker.length,
          ),
        );
      }
    } else {
      final cursorPos = selection.baseOffset;
      final lineStart = text.lastIndexOf('\n', cursorPos - 1) + 1;
      
      final line = text.substring(lineStart);
      if (!line.startsWith(marker)) {
        final newText = text.replaceRange(
          lineStart,
          lineStart,
          marker,
        );
        
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: cursorPos + marker.length,
          ),
        );
      }
    }
  }
}
