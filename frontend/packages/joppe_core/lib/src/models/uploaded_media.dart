class UploadedMedia {
  final String? id;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String contentType;
  final String folder;
  final DateTime? createdAt;

  const UploadedMedia({
    this.id,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.contentType,
    this.folder = 'general',
    this.createdAt,
  });

  factory UploadedMedia.fromJson(Map<String, dynamic> json) {
    return UploadedMedia(
      id: json['id'] as String?,
      fileUrl: json['fileUrl'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      contentType: json['contentType'] as String? ?? '',
      folder: json['folder'] as String? ?? 'general',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'contentType': contentType,
        'folder': folder,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}
