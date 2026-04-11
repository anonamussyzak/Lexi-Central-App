import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/providers/vault_provider.dart';
import 'screens/vault_setup_screen.dart';
import 'screens/vault_auth_screen.dart';
import 'widgets/vault_file_grid.dart';
import 'widgets/floating_add_button.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);

    // Show appropriate screen based on vault state
    if (!vaultState.isSetup) {
      return const VaultSetupScreen();
    }

    if (!vaultState.isAuthenticated) {
      return const VaultAuthScreen();
    }

    // Main vault interface
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.lock,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('The Vault'),
          ],
        ),
        centerTitle: false,
        actions: [
          if (vaultState.files.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Chip(
                label: Text(
                  '${vaultState.files.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                deleteIcon: null,
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, ref),
            itemBuilder: (context) => [
              if (vaultState.biometricAvailable && !vaultState.biometricEnabled)
                const PopupMenuItem(
                  value: 'enable_biometrics',
                  child: Row(
                    children: [
                      Icon(Icons.fingerprint),
                      SizedBox(width: 8),
                      Text('Enable Biometrics'),
                    ],
                  ),
                ),
              if (vaultState.biometricAvailable && vaultState.biometricEnabled)
                const PopupMenuItem(
                  value: 'disable_biometrics',
                  child: Row(
                    children: [
                      Icon(Icons.fingerprint_off),
                      SizedBox(width: 8),
                      Text('Disable Biometrics'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                      value: 'change_password',
                      child: Row(
                        children: [
                          Icon(Icons.password),
                          SizedBox(width: 8),
                          Text('Change Password'),
                        ],
                      ),
                    ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Lock Vault'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          const VaultFileGrid(),
          
          // Floating add button
          const FloatingAddButton(),
          
          // Error snackbar
          if (vaultState.error != null)
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
                          vaultState.error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => ref.read(vaultProvider.notifier).clearError(),
                        icon: Icon(Icons.close, color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ),
              ).animate().slideY(begin: -1, duration: 300.ms),
            ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, WidgetRef ref) {
    switch (action) {
      case 'enable_biometrics':
        ref.read(vaultProvider.notifier).enableBiometrics();
        break;
      case 'disable_biometrics':
        ref.read(vaultProvider.notifier).disableBiometrics();
        break;
      case 'change_password':
        _showChangePasswordDialog(ref);
        break;
      case 'logout':
        ref.read(vaultProvider.notifier).logout();
        break;
    }
  }

  void _showChangePasswordDialog(WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _ChangePasswordDialog(
        onConfirm: (oldPassword, newPassword) {
          ref.read(vaultProvider.notifier).changePassword(oldPassword, newPassword);
        },
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final Function(String, String) onConfirm;

  const _ChangePasswordDialog({required this.onConfirm});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Vault Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _oldPasswordController,
            obscureText: _obscureOld,
            decoration: InputDecoration(
              labelText: 'Current Password',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureOld = !_obscureOld),
                icon: Icon(_obscureOld ? Icons.visibility : Icons.visibility_off),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newPasswordController,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              labelText: 'New Password',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
                icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
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
            if (_newPasswordController.text == _confirmPasswordController.text &&
                _newPasswordController.text.length >= 8) {
              widget.onConfirm(
                _oldPasswordController.text,
                _newPasswordController.text,
              );
              Navigator.of(context).pop();
            }
          },
          child: const Text('Change Password'),
        ),
      ],
    );
  }
}
