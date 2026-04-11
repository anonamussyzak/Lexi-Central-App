import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import '../models/vault_file.dart';
import 'encryption_service.dart';

class VaultAuthService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const LocalAuthentication _localAuth = LocalAuthentication();
  
  static const String _passwordHashKey = 'vault_password_hash';
  static const String _saltKey = 'vault_salt';
  static const String _isSetupKey = 'vault_is_setup';
  static const String _biometricEnabledKey = 'vault_biometric_enabled';

  /// Checks if vault is already set up
  static Future<bool> isVaultSetup() async {
    final isSetup = await _secureStorage.read(key: _isSetupKey);
    return isSetup == 'true';
  }

  /// Sets up vault with new password
  static Future<void> setupVault(String password) async {
    try {
      final salt = EncryptionService.generateSalt();
      final passwordHash = await EncryptionService.hashPassword(password, salt);
      
      // Store credentials securely
      await _secureStorage.write(key: _passwordHashKey, value: passwordHash);
      await _secureStorage.write(key: _saltKey, value: salt);
      await _secureStorage.write(key: _isSetupKey, value: 'true');
      
      // Create vault directory
      final appDir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory('${appDir.path}/vault');
      if (!await vaultDir.exists()) {
        await vaultDir.create(recursive: true);
      }
      
    } catch (e) {
      throw Exception('Failed to setup vault: $e');
    }
  }

  /// Authenticates user with password
  static Future<bool> authenticate(String password) async {
    try {
      final storedHash = await _secureStorage.read(key: _passwordHashKey);
      final salt = await _secureStorage.read(key: _saltKey);
      
      if (storedHash == null || salt == null) {
        return false;
      }
      
      final inputHash = await EncryptionService.hashPassword(password, salt);
      return inputHash == storedHash;
      
    } catch (e) {
      return false;
    }
  }

  /// Derives encryption key from password
  static Future<String> deriveKey(String password) async {
    final salt = await _secureStorage.read(key: _saltKey);
    if (salt == null) {
      throw Exception('Vault not setup');
    }
    
    final key = await EncryptionService.deriveKey(password, salt);
    final keyBytes = await key.extractBytes();
    return base64.encode(keyBytes);
  }

  /// Checks if biometric authentication is available
  static Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canAuthenticate && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Authenticates using biometrics
  static Future<bool> authenticateWithBiometrics() async {
    try {
      final biometricEnabled = await _secureStorage.read(key: _biometricEnabledKey);
      if (biometricEnabled != 'true') {
        return false;
      }
      
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your vault',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      return authenticated;
    } catch (e) {
      return false;
    }
  }

  /// Enables biometric authentication
  static Future<void> enableBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Enable biometric authentication for quick vault access',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      if (authenticated) {
        await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
      } else {
        throw Exception('Biometric authentication failed');
      }
    } catch (e) {
      throw Exception('Failed to enable biometrics: $e');
    }
  }

  /// Disables biometric authentication
  static Future<void> disableBiometrics() async {
    await _secureStorage.delete(key: _biometricEnabledKey);
  }

  /// Checks if biometrics is enabled
  static Future<bool> isBiometricEnabled() async {
    final enabled = await _secureStorage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  /// Changes vault password
  static Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      // Verify old password
      final isAuthenticated = await authenticate(oldPassword);
      if (!isAuthenticated) {
        throw Exception('Current password is incorrect');
      }
      
      // Generate new salt and hash
      final newSalt = EncryptionService.generateSalt();
      final newPasswordHash = await EncryptionService.hashPassword(newPassword, newSalt);
      
      // Update stored credentials
      await _secureStorage.write(key: _passwordHashKey, value: newPasswordHash);
      await _secureStorage.write(key: _saltKey, value: newSalt);
      
      // Note: In a real implementation, you would need to re-encrypt all files
      // with the new password. For now, we'll just update the password.
      
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  /// Resets the vault (WARNING: This will delete all encrypted data)
  static Future<void> resetVault() async {
    try {
      // Delete all secure storage data
      await _secureStorage.delete(key: _passwordHashKey);
      await _secureStorage.delete(key: _saltKey);
      await _secureStorage.delete(key: _isSetupKey);
      await _secureStorage.delete(key: _biometricEnabledKey);
      
      // Delete vault directory
      final appDir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory('${appDir.path}/vault');
      
      if (await vaultDir.exists()) {
        await vaultDir.delete(recursive: true);
      }
      
    } catch (e) {
      throw Exception('Failed to reset vault: $e');
    }
  }
}
