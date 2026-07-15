class MediaVerifyResult {
  const MediaVerifyResult({
    required this.verdict,
    this.stepResults = const {},
    this.details = const {},
  });

  final String verdict;
  final Map<String, bool> stepResults;
  final Map<String, String> details;

  bool get isTrusted {
    final value = verdict.trim();
    return value == '可信' || value.toLowerCase() == 'trusted';
  }

  factory MediaVerifyResult.fromJson(Map<String, dynamic> json) {
    final stepRaw = json['stepResults'];
    final stepResults = <String, bool>{};
    if (stepRaw is Map) {
      for (final entry in stepRaw.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is bool) {
          stepResults[key] = value;
        } else if (value != null) {
          final text = value.toString().toLowerCase();
          stepResults[key] = text == 'true' || text == '1';
        }
      }
    }

    final detailRaw = json['details'];
    final details = <String, String>{};
    if (detailRaw is Map) {
      for (final entry in detailRaw.entries) {
        details[entry.key.toString()] = entry.value?.toString() ?? '';
      }
    }

    return MediaVerifyResult(
      verdict: json['verdict']?.toString() ?? '',
      stepResults: stepResults,
      details: details,
    );
  }
}
