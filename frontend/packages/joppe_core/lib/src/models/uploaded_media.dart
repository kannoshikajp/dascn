class UploadedMedia {
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String contentType;

  const UploadedMedia({
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.contentType,
  });

  factory UploadedMedia.fromJson(Map<String, dynamic> json) {
    return UploadedMedia(
      fileUrl: json['fileUrl'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      contentType: json['contentType'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'contentType': contentType,
      };
}
