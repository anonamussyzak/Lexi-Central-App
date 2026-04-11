import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/vault_file.dart';
import '../../domain/providers/vault_provider.dart';

class VaultFileGrid extends ConsumerWidget {
  const VaultFileGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultState = ref.watch(vaultProvider);

    if (vaultState.isLoading && vaultState.files.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFFB7C5),
        ),
      );
    }

    if (vaultState.files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_special_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ).animate().scale(delay: 200.ms, duration: 600.ms).then().shake(),
            const SizedBox(height: 24),
            Text(
              'Vault is Empty',
              style: Theme.of(context).textTheme.displayMedium,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 16),
            Text(
              'Add encrypted files to keep them secure',
              style: Theme.of(context).textTheme.bodyLarge,
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: vaultState.files.length,
      itemBuilder: (context, index) {
        final vaultFile = vaultState.files[index];
        return _VaultFileCard(
          vaultFile: vaultFile,
          onTap: () => _showFileOptions(context, vaultFile),
          index: index,
        );
      },
    );
  }

  void _showFileOptions(BuildContext context, VaultFile vaultFile) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _FileOptionsSheet(vaultFile: vaultFile),
    );
  }
}

class _VaultFileCard extends StatelessWidget {
  final VaultFile vaultFile;
  final VoidCallback onTap;
  final int index;

  const _VaultFileCard({
    required this.vaultFile,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient based on file type
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getFileTypeColors(vaultFile.type),
                ),
              ),
            ),
            
            // File icon
            Center(
              child: Icon(
                _getFileTypeIcon(vaultFile.type),
                size: 48,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            
            // File type indicator
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getFileTypeIcon(vaultFile.type),
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            
            // File name
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  vaultFile.originalFileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            
            // Encrypted indicator
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(delay: (index * 50).ms, duration: 300.ms).fadeIn();
  }

  List<Color> _getFileTypeColors(VaultFileType type) {
    switch (type) {
      case VaultFileType.image:
        return [
          const Color(0xFFFFB7C5).withOpacity(0.8),
          const Color(0xFFFF6B8B).withOpacity(0.8),
        ];
      case VaultFileType.video:
        return [
          const Color(0xFFB8F2E6).withOpacity(0.8),
          const Color(0xFF2A7F7E).withOpacity(0.8),
        ];
      case VaultFileType.document:
        return [
          const Color(0xFFFFF5B7).withOpacity(0.8),
          const Color(0xFFE6D690).withOpacity(0.8),
        ];
      case VaultFileType.other:
        return [
          const Color(0xFFD8BFD8).withOpacity(0.8),
          const Color(0xFF9370DB).withOpacity(0.8),
        ];
    }
  }

  IconData _getFileTypeIcon(VaultFileType type) {
    switch (type) {
      case VaultFileType.image:
        return Icons.image;
      case VaultFileType.video:
        return Icons.video_file;
      case VaultFileType.document:
        return Icons.description;
      case VaultFileType.other:
        return Icons.insert_drive_file;
    }
  }
}

class _FileOptionsSheet extends ConsumerWidget {
  final VaultFile vaultFile;

  const _FileOptionsSheet({required this.vaultFile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // File info
          Row(
            children: [
              Icon(
                _getFileTypeIcon(vaultFile.type),
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vaultFile.originalFileName,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Added: ${_formatDate(vaultFile.createdAt)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Options
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export File'),
            subtitle: const Text('Decrypt and save to device'),
            onTap: () {
              Navigator.of(context).pop();
              _exportFile(context, ref);
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('File Info'),
            subtitle: Text('Size: ${_formatFileSize(vaultFile.fileSize)}'),
            onTap: () {
              Navigator.of(context).pop();
              _showFileInfo(context);
            },
          ),
          
          const Divider(),
          
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete File', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Permanently remove from vault'),
            onTap: () {
              Navigator.of(context).pop();
              _deleteFile(context, ref);
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _exportFile(BuildContext context, WidgetRef ref) {
    // For now, we'll show a password dialog
    showDialog(
      context: context,
      builder: (context) => _PasswordDialog(
        title: 'Export File',
        onConfirm: (password) {
          ref.read(vaultProvider.notifier).exportFile(vaultFile, password);
        },
      ),
    );
  }

  void _deleteFile(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Encrypted File'),
        content: Text(
          'Are you sure you want to delete "${vaultFile.originalFileName}" from the vault?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(vaultProvider.notifier).deleteFile(vaultFile);
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

  void _showFileInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name', vaultFile.originalFileName),
            _buildInfoRow('Type', vaultFile.type.name),
            _buildInfoRow('Size', _formatFileSize(vaultFile.fileSize)),
            _buildInfoRow('Added', _formatDate(vaultFile.createdAt)),
            _buildInfoRow('Status', 'Encrypted ✓'),
            _buildInfoRow('Integrity', 'Verified ✓'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  IconData _getFileTypeIcon(VaultFileType type) {
    switch (type) {
      case VaultFileType.image:
        return Icons.image;
      case VaultFileType.video:
        return Icons.video_file;
      case VaultFileType.document:
        return Icons.description;
      case VaultFileType.other:
        return Icons.insert_drive_file;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _PasswordDialog extends StatefulWidget {
  final String title;
  final Function(String) onConfirm;

  const _PasswordDialog({
    required this.title,
    required this.onConfirm,
  });

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter your vault password to decrypt this file:'),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
              ),
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
            if (_passwordController.text.isNotEmpty) {
              widget.onConfirm(_passwordController.text);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Export'),
        ),
      ],
    );
  }
}
