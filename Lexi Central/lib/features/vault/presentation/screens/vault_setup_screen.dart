import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../../domain/providers/vault_provider.dart';

class VaultSetupScreen extends ConsumerStatefulWidget {
  const VaultSetupScreen({super.key});

  @override
  ConsumerState<VaultSetupScreen> createState() => _VaultSetupScreenState();
}

class _VaultSetupScreenState extends ConsumerState<VaultSetupScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);
    final vaultNotifier = ref.read(vaultProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Vault'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon and title
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ).animate().scale(delay: 200.ms, duration: 600.ms).then().shake(),
              
              const SizedBox(height: 24),
              
              Text(
                'Create Your Vault',
                style: Theme.of(context).textTheme.displayMedium,
              ).animate().fadeIn(delay: 400.ms),
              
              const SizedBox(height: 8),
              
              Text(
                'Zero-knowledge encryption - only you can access your files',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 600.ms),
              
              const SizedBox(height: 48),
              
              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Create a strong password',
                  prefixIcon: const Icon(Icons.lock),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 800.ms),
              
              const SizedBox(height: 16),
              
              // Confirm password field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 900.ms),
              
              const SizedBox(height: 32),
              
              // Warning message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '⚠️ This password cannot be recovered if lost. Store it safely.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 1000.ms),
              
              const SizedBox(height: 32),
              
              // Setup button
              if (vaultState.isLoading)
                const CircularProgressIndicator(
                  color: Color(0xFFFFB7C5),
                ).animate().fadeIn(delay: 1100.ms)
              else
                BouncyButton(
                  onTap: _setupVault,
                  child: ElevatedButton(
                    onPressed: _setupVault,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Create Vault'),
                  ),
                ).animate().fadeIn(delay: 1100.ms),
              
              const SizedBox(height: 16),
              
              // Error message
              if (vaultState.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          vaultState.error!,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                        ),
                      ),
                      IconButton(
                        onPressed: vaultNotifier.clearError,
                        icon: Icon(Icons.close, color: Colors.red.shade700, size: 20),
                      ),
                    ],
                  ),
                ).animate().slideY(begin: -1, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }

  void _setupVault() {
    if (_formKey.currentState!.validate()) {
      ref.read(vaultProvider.notifier).setupVault(_passwordController.text);
    }
  }
}
