import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../../domain/providers/vault_provider.dart';

class VaultAuthScreen extends ConsumerStatefulWidget {
  const VaultAuthScreen({super.key});

  @override
  ConsumerState<VaultAuthScreen> createState() => _VaultAuthScreenState();
}

class _VaultAuthScreenState extends ConsumerState<VaultAuthScreen> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);
    final vaultNotifier = ref.read(vaultProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Vault'),
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
                Icons.lock,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ).animate().scale(delay: 200.ms, duration: 600.ms).then().shake(),
              
              const SizedBox(height: 24),
              
              Text(
                'Enter Vault Password',
                style: Theme.of(context).textTheme.displayMedium,
              ).animate().fadeIn(delay: 400.ms),
              
              const SizedBox(height: 8),
              
              Text(
                'Access your secure encrypted files',
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
                  hintText: 'Enter your vault password',
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
                    return 'Please enter your password';
                  }
                  return null;
                },
                onSubmitted: (_) => _authenticate(),
              ).animate().fadeIn(delay: 800.ms),
              
              const SizedBox(height: 32),
              
              // Biometric authentication button
              if (vaultState.biometricAvailable && vaultState.biometricEnabled)
                Column(
                  children: [
                    const Text(
                      'OR',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ).animate().fadeIn(delay: 900.ms),
                    
                    const SizedBox(height: 16),
                    
                    BouncyButton(
                      onTap: vaultNotifier.authenticateWithBiometrics,
                      child: OutlinedButton.icon(
                        onPressed: vaultNotifier.authenticateWithBiometrics,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Use Biometrics'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ).animate().fadeIn(delay: 1000.ms),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              
              // Unlock button
              if (vaultState.isLoading)
                const CircularProgressIndicator(
                  color: Color(0xFFFFB7C5),
                ).animate().fadeIn(delay: 1100.ms)
              else
                BouncyButton(
                  onTap: _authenticate,
                  child: ElevatedButton(
                    onPressed: _authenticate,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Unlock Vault'),
                  ),
                ).animate().fadeIn(delay: 1100.ms),
              
              const SizedBox(height: 24),
              
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
              
              // Forgot password hint
              const SizedBox(height: 16),
              
              Text(
                '🔐 For security, passwords cannot be recovered if forgotten.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 1200.ms),
            ],
          ),
        ),
      ),
    );
  }

  void _authenticate() {
    if (_formKey.currentState!.validate()) {
      ref.read(vaultProvider.notifier).authenticate(_passwordController.text);
    }
  }
}
