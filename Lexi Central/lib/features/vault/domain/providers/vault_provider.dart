import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vault_file.dart';
import '../../data/repositories/vault_repository.dart';
import '../../data/services/vault_auth_service.dart';

class VaultState {
  final bool isAuthenticated;
  final bool isSetup;
  final List<VaultFile> files;
  final bool isLoading;
  final String? error;
  final bool biometricAvailable;
  final bool biometricEnabled;

  const VaultState({
    this.isAuthenticated = false,
    this.isSetup = false,
    this.files = const [],
    this.isLoading = false,
    this.error,
    this.biometricAvailable = false,
    this.biometricEnabled = false,
  });

  VaultState copyWith({
    bool? isAuthenticated,
    bool? isSetup,
    List<VaultFile>? files,
    bool? isLoading,
    String? error,
    bool? biometricAvailable,
    bool? biometricEnabled,
  }) {
    return VaultState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isSetup: isSetup ?? this.isSetup,
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }
}

class VaultNotifier extends StateNotifier<VaultState> {
  final VaultRepository _repository;

  VaultNotifier(this._repository) : super(const VaultState()) {
    _initializeVault();
  }

  Future<void> _initializeVault() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final isSetup = await VaultAuthService.isVaultSetup();
      final biometricAvailable = await VaultAuthService.isBiometricAvailable();
      final biometricEnabled = biometricAvailable ? await VaultAuthService.isBiometricEnabled() : false;
      
      state = state.copyWith(
        isSetup: isSetup,
        biometricAvailable: biometricAvailable,
        biometricEnabled: biometricEnabled,
        isLoading: false,
      );
      
      if (isSetup) {
        await loadVaultFiles();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize vault: ${e.toString()}',
      );
    }
  }

  Future<void> setupVault(String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await VaultAuthService.setupVault(password);
      
      final biometricAvailable = await VaultAuthService.isBiometricAvailable();
      
      state = state.copyWith(
        isSetup: true,
        isAuthenticated: true,
        biometricAvailable: biometricAvailable,
        isLoading: false,
      );
      
      await loadVaultFiles();
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to setup vault: ${e.toString()}',
      );
    }
  }

  Future<void> authenticate(String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final isAuthenticated = await VaultAuthService.authenticate(password);
      
      if (isAuthenticated) {
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
        );
        await loadVaultFiles();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid password',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Authentication failed: ${e.toString()}',
      );
    }
  }

  Future<void> authenticateWithBiometrics() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final isAuthenticated = await VaultAuthService.authenticateWithBiometrics();
      
      if (isAuthenticated) {
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
        );
        await loadVaultFiles();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Biometric authentication failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Biometric authentication failed: ${e.toString()}',
      );
    }
  }

  Future<void> loadVaultFiles() async {
    if (!state.isAuthenticated) return;
    
    try {
      final files = await _repository.getVaultFiles();
      state = state.copyWith(files: files);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load files: ${e.toString()}');
    }
  }

  Future<void> addFile(String filePath, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final vaultFile = await _repository.addFileToVault(filePath, password);
      
      state = state.copyWith(
        files: [vaultFile, ...state.files],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add file: ${e.toString()}',
      );
    }
  }

  Future<void> deleteFile(VaultFile vaultFile) async {
    state = state.copyWith(
      files: state.files.where((f) => f.id != vaultFile.id).toList(),
    );
    
    try {
      await _repository.deleteFile(vaultFile);
    } catch (e) {
      // Rollback on error
      await loadVaultFiles();
      state = state.copyWith(error: 'Failed to delete file: ${e.toString()}');
    }
  }

  Future<void> exportFile(VaultFile vaultFile, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // For now, we'll export to downloads directory
      // In a real app, you'd let user choose location
      final fileName = vaultFile.originalFileName;
      
      await _repository.exportFile(vaultFile, password, fileName);
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to export file: ${e.toString()}',
      );
    }
  }

  Future<void> enableBiometrics() async {
    try {
      await VaultAuthService.enableBiometrics();
      state = state.copyWith(biometricEnabled: true);
    } catch (e) {
      state = state.copyWith(error: 'Failed to enable biometrics: ${e.toString()}');
    }
  }

  Future<void> disableBiometrics() async {
    try {
      await VaultAuthService.disableBiometrics();
      state = state.copyWith(biometricEnabled: false);
    } catch (e) {
      state = state.copyWith(error: 'Failed to disable biometrics: ${e.toString()}');
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await VaultAuthService.changePassword(oldPassword, newPassword);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to change password: ${e.toString()}',
      );
    }
  }

  void logout() {
    state = state.copyWith(isAuthenticated: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  return VaultRepository();
});

final vaultProvider = StateNotifierProvider<VaultNotifier, VaultState>((ref) {
  final repository = ref.watch(vaultRepositoryProvider);
  return VaultNotifier(repository);
});
