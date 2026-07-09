class SpaceUploadResult {
  const SpaceUploadResult({
    this.index,
    this.originalFileName,
    this.fileId,
    this.ossUrl,
    this.success = false,
    this.errorMsg,
    this.watermarkId,
    this.watermarkContent,
    this.fileSha256,
  });

  final int? index;
  final String? originalFileName;
  final String? fileId;
  final String? ossUrl;
  final bool success;
  final String? errorMsg;
  final int? watermarkId;
  final Map<String, dynamic>? watermarkContent;
  final String? fileSha256;

  factory SpaceUploadResult.fromJson(Map<String, dynamic> json) {
    final rawContent = json['watermarkContent'];
    return SpaceUploadResult(
      index: json['index'] as int?,
      originalFileName: json['originalFileName'] as String?,
      fileId: json['fileId']?.toString(),
      ossUrl: json['ossUrl'] as String?,
      success: json['success'] as bool? ?? false,
      errorMsg: json['errorMsg'] as String?,
      watermarkId: json['watermarkId'] as int?,
      watermarkContent: rawContent is Map
          ? Map<String, dynamic>.from(rawContent)
          : null,
      fileSha256: json['fileSha256'] as String?,
    );
  }
}
