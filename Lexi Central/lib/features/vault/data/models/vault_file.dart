import 'package:equatable/equatable.dart';

enum VaultFileType { image, video, document, other }

class VaultFile extends Equatable {
  final String id;
  final String encryptedPath;
  final String originalFileName;
  final VaultFileType type;
  final int fileSize;
  final DateTime createdAt;
  final String checksum; // For integrity verification

  const VaultFile({
    required this.id,
    required this.encryptedPath,
    required this.originalFileName,
    required this.type,
    required this.fileSize,
    required this.createdAt,
    required this.checksum,
  });

  VaultFile copyWith({
    String? id,
    String? encryptedPath,
    String? originalFileName,
    VaultFileType? type,
    int? fileSize,
    DateTime? createdAt,
    String? checksum,
  }) {
    return VaultFile(
      id: id ?? this.id,
      encryptedPath: encryptedPath ?? this.encryptedPath,
      originalFileName: originalFileName ?? this.originalFileName,
      type: type ?? this.type,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      checksum: checksum ?? this.checksum,
    );
  }

  @override
  List<Object?> get props => [
        id,
        encryptedPath,
        originalFileName,
        type,
        fileSize,
        createdAt,
        checksum,
      ];
}
