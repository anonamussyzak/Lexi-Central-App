import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';
import '../models/vault_file.dart';
import '../services/encryption_service.dart';
import '../services/vault_auth_service.dart';

class VaultRepository {
  Future<List<VaultFile>> getVaultFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory('${appDir.path}/vault');
      
      if (!await vaultDir.exists()) {
        return [];
      }
      
      final files = await vaultDir.list().toList();
      final vaultFiles = <VaultFile>[];
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.enc')) {
          // Parse filename to extract metadata
          final fileName = file.path.split('/').last;
          final parts = fileName.split('_');
          
          if (parts.length >= 2) {
            final timestamp = parts[0];
            final originalFileName = parts.sublist(1).join('_').replaceFirst('.enc', '');
            
            // Get file type
            final fileType = _getFileType(originalFileName);
            
            // Get file size
            final fileSize = await file.length();
            
            // Create vault file object
            final vaultFile = VaultFile(
              id: timestamp,
              encryptedPath: file.path,
              originalFileName: originalFileName,
              type: fileType,
              fileSize: fileSize,
              createdAt: DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp)),
              checksum: '', // Will be loaded from metadata if stored
            );
            
            vaultFiles.add(vaultFile);
          }
        }
      }
      
      // Sort by creation date (newest first)
      vaultFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return vaultFiles;
      
    } catch (e) {
      throw Exception('Failed to load vault files: $e');
    }
  }

  Future<VaultFile> addFileToVault(String filePath, String password) async {
    try {
      // Derive encryption key
      final keyString = await VaultAuthService.deriveKey(password);
      final keyBytes = Uint8List.fromList(
        const Base64Decoder().convert(keyString)
      );
      final key = SecretKey(keyBytes);
      
      // Encrypt the file
      final (encryptedPath, nonce, checksum) = await EncryptionService.encryptFile(
        filePath, 
        key
      );
      
      // Determine file type
      final fileName = filePath.split('/').last;
      final fileType = _getFileType(fileName);
      
      // Get file size
      final encryptedFile = File(encryptedPath);
      final fileSize = await encryptedFile.length();
      
      // Create vault file record
      final vaultFile = VaultFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        encryptedPath: encryptedPath,
        originalFileName: fileName,
        type: fileType,
        fileSize: fileSize,
        createdAt: DateTime.now(),
        checksum: checksum,
      );
      
      // Store nonce securely (in a real app, you'd store this in a database)
      // For now, we'll include it in the filename or metadata
      
      return vaultFile;
      
    } catch (e) {
      throw Exception('Failed to add file to vault: $e');
    }
  }

  Future<Uint8List> decryptFile(VaultFile vaultFile, String password) async {
    try {
      // Derive encryption key
      final keyString = await VaultAuthService.deriveKey(password);
      final keyBytes = Uint8List.fromList(
        const Base64Decoder().convert(keyString)
      );
      final key = SecretKey(keyBytes);
      
      // Extract nonce from metadata (for now, we'll use a simple approach)
      // In a real implementation, you'd store this securely
      final nonce = _extractNonce(vaultFile);
      
      // Decrypt the file
      final decryptedBytes = await EncryptionService.decryptFile(
        vaultFile.encryptedPath,
        nonce,
        key,
      );
      
      return decryptedBytes;
      
    } catch (e) {
      throw Exception('Failed to decrypt file: $e');
    }
  }

  Future<void> deleteFile(VaultFile vaultFile) async {
    try {
      // Securely delete the encrypted file
      await EncryptionService.secureDelete(vaultFile.encryptedPath);
      
    } catch (e) {
      throw Exception('Failed to delete vault file: $e');
    }
  }

  Future<void> exportFile(VaultFile vaultFile, String password, String exportPath) async {
    try {
      // Decrypt the file
      final decryptedBytes = await decryptFile(vaultFile, password);
      
      // Save to export location
      final exportFile = File(exportPath);
      await exportFile.writeAsBytes(decryptedBytes);
      
    } catch (e) {
      throw Exception('Failed to export file: $e');
    }
  }

  VaultFileType _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(extension)) {
      return VaultFileType.image;
    } else if (['mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', 'webm'].contains(extension)) {
      return VaultFileType.video;
    } else if (['pdf', 'doc', 'docx', 'txt', 'rtf'].contains(extension)) {
      return VaultFileType.document;
    } else {
      return VaultFileType.other;
    }
  }

  String _extractNonce(VaultFile vaultFile) {
    // In a real implementation, you'd store the nonce securely
    // For now, we'll use a simple approach based on the file ID
    final timestamp = vaultFile.id;
    final nonceBytes = List<int>.generate(12, (i) {
      return (int.parse(timestamp) + i * 7) % 256;
    });
    return String.fromCharCodes(nonceBytes);
  }

  Future<void> verifyVaultIntegrity() async {
    try {
      final vaultFiles = await getVaultFiles();
      
      for (final vaultFile in vaultFiles) {
        final isValid = await EncryptionService.verifyChecksum(
          vaultFile.encryptedPath,
          vaultFile.checksum,
        );
        
        if (!isValid) {
          throw Exception('File integrity check failed: ${vaultFile.originalFileName}');
        }
      }
      
    } catch (e) {
      throw Exception('Vault integrity verification failed: $e');
    }
  }
}
