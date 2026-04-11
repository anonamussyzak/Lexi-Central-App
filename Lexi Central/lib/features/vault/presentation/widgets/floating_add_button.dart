import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../../domain/providers/vault_provider.dart';

class FloatingAddButton extends ConsumerWidget {
  const FloatingAddButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultState = ref.watch(vaultProvider);

    return Positioned(
      bottom: 24,
      right: 24,
      child: BouncyButton(
        onTap: () => _addFileToVault(context, ref),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFB8F2E6),
                const Color(0xFF2A7F7E),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB8F2E6).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: vaultState.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
        ),
      ).animate().scale(delay: 500.ms, duration: 400.ms).then().shimmer(),
    );
  }

  Future<void> _addFileToVault(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      // Show password dialog
      await showDialog(
        context: context,
        builder: (context) => _PasswordDialog(
          title: 'Add to Vault',
          fileName: file.name,
          onConfirm: (password) {
            ref.read(vaultProvider.notifier).addFile(file.path!, password);
          },
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _PasswordDialog extends StatefulWidget {
  final String title;
  final String fileName;
  final Function(String) onConfirm;

  const _PasswordDialog({
    required this.title,
    required this.fileName,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('File: ${widget.fileName}'),
          const SizedBox(height: 16),
          const Text('Enter your vault password to encrypt this file:'),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter vault password',
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
          const SizedBox(height: 8),
          Text(
            '🔒 This file will be encrypted with zero-knowledge security',
            style: Theme.of(context).textTheme.bodySmall,
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
          child: const Text('Encrypt & Add'),
        ),
      ],
    );
  }
}
