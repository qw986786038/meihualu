import 'package:watermark_camera/models/api/space_upload_result.dart';

class SpaceBatchUploadData {
  const SpaceBatchUploadData({
    required this.totalCount,
    required this.successCount,
    required this.failCount,
    this.results = const [],
    this.failures = const [],
  });

  final int totalCount;
  final int successCount;
  final int failCount;
  final List<SpaceUploadResult> results;
  final List<SpaceUploadResult> failures;

  factory SpaceBatchUploadData.fromJson(Map<String, dynamic> json) {
    return SpaceBatchUploadData(
      totalCount: json['totalCount'] as int? ?? 0,
      successCount: json['successCount'] as int? ?? 0,
      failCount: json['failCount'] as int? ?? 0,
      results: _parseResults(json['results']),
      failures: _parseResults(json['failures']),
    );
  }

  static List<SpaceUploadResult> _parseResults(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(SpaceUploadResult.fromJson)
        .toList();
  }
}

class SpaceBatchUploadItem {
  const SpaceBatchUploadItem({
    required this.filePath,
    required this.sha256Hash,
    required this.exifData,
    required this.watermarkId,
    required this.watermarkContent,
    this.antiFakeCode = '',
  });

  final String filePath;
  final String sha256Hash;
  final String exifData;
  final int watermarkId;
  final String watermarkContent;
  final String antiFakeCode;
}
