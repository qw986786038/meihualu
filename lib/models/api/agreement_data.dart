class AgreementData {
  const AgreementData({
    required this.type,
    required this.title,
    required this.content,
  });

  final String type;
  final String title;
  final String content;

  factory AgreementData.fromJson(Map<String, dynamic> json) {
    return AgreementData(
      type: (json['type'] as String?)?.trim() ?? '',
      title: (json['title'] as String?)?.trim() ?? '',
      content: (json['content'] as String?) ?? '',
    );
  }
}

/// 协议类型：对应 GET agreement/{type}
abstract final class AgreementType {
  static const String service = 'service';
  static const String privacy = 'privacy';
}
