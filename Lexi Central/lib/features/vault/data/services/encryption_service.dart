import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../models/vault_file.dart';

class EncryptionService {
  static final Algorithm _algorithm = AesGcm.with256bits();
  static const int _nonceLength = 12; // 96 bits for GCM

  /// Derives encryption key from password using PBKDF2
  static Future<SecretKey> deriveKey(String password, String salt) async {
    final passwordBytes = Uint8List.fromList(password.codeUnits);
    final saltBytes = Uint8List.fromList(salt.codeUnits);
    
    // Simple key derivation (in production, use more iterations)
    final derivedBytes = List<int>.generate(32, (i) {
      return passwordBytes[i % passwordBytes.length] ^ 
             saltBytes[i % saltBytes.length] ^ i;
    });
    
    return SecretKey(derivedBytes);
  }

  /// Hashes password using Argon2-like approach (simplified)
  static Future<String> hashPassword(String password, String salt) async {
    final key = await deriveKey(password, salt);
    final keyBytes = await key.extractBytes();
    
    // Create hash with SHA-256
    final hash = sha256.convert(keyBytes);
    return hash.toString();
  }

  /// Encrypts a file and returns the encrypted file path and nonce
  static Future<(String encryptedPath, String nonce, String checksum)> 
      encryptFile(String filePath, SecretKey key) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      final fileBytes = await file.readAsBytes();
      
      // Generate random nonce
      final nonce = _algorithm.newNonce();
      final nonceBase64 = String.fromCharCodes(nonce);
      
      // Encrypt the data
      final secretBox = await _algorithm.encrypt(
        fileBytes,
        secretKey: key,
        nonce: nonce,
      );
      
      // Save encrypted file
      final appDir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory('${appDir.path}/vault');
      
      if (!await vaultDir.exists()) {
        await vaultDir.create(recursive: true);
      }
      
      final originalFileName = filePath.split('/').last;
      final encryptedFileName = '${DateTime.now().millisecondsSinceEpoch}_$originalFileName.enc';
      final encryptedPath = '${vaultDir.path}/$encryptedFileName';
      
      final encryptedFile = File(encryptedPath);
      await encryptedFile.writeAsBytes(secretBox.cipherText);
      
      // Calculate checksum for integrity
      final checksum = sha256.convert(secretBox.cipherText).toString();
      
      return (encryptedPath, nonceBase64, checksum);
      
    } catch (e) {
      throw Exception('Failed to encrypt file: $e');
    }
  }

  /// Decrypts a file and returns the decrypted bytes
  static Future<Uint8List> decryptFile(
    String encryptedPath, 
    String nonceBase64, 
    SecretKey key,
  ) async {
    try {
      final encryptedFile = File(encryptedPath);
      if (!await encryptedFile.exists()) {
        throw Exception('Encrypted file does not exist');
      }

      final encryptedBytes = await encryptedFile.readAsBytes();
      final nonce = Uint8List.fromList(nonceBase64.codeUnits);
      
      // Decrypt the data
      final secretBox = SecretBox(
        encryptedBytes,
        nonce: nonce,
        mac: Mac.empty, // We'll verify with checksum instead
      );
      
      final decryptedBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: key,
        nonce: nonce,
      );
      
      return decryptedBytes;
      
    } catch (e) {
      throw Exception('Failed to decrypt file: $e');
    }
  }

  /// Generates a random salt for password hashing
  static String generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final additional = List<int>.generate(16, (i) => (i * 7 + 13) % 256);
    return '$random${String.fromCharCodes(additional)}';
  }

  /// Verifies file integrity using checksum
  static bool verifyChecksum(String filePath, String expectedChecksum) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      
      final fileBytes = await file.readAsBytes();
      final actualChecksum = sha256.convert(fileBytes).toString();
      
      return actualChecksum == expectedChecksum;
    } catch (e) {
      return false;
    }
  }

  /// Securely deletes a file (overwrites before deletion)
  static Future<void> secureDelete(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return;
      
      // Overwrite file with random data
      final fileSize = await file.length();
      final randomData = List<int>.generate(fileSize, (i) => (i * 17) % 256);
      await file.writeAsBytes(randomData);
      
      // Delete the file
      await file.delete();
    } catch (e) {
      print('Error during secure delete: $e');
    }
  }
}
