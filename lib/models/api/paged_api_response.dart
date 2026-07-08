class PagedApiResponse<T> {
  const PagedApiResponse({
    required this.code,
    this.msg,
    required this.total,
    required this.rows,
  });

  final int code;
  final String? msg;
  final int total;
  final List<T> rows;

  bool get isSuccess => code == 200;

  factory PagedApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) {
    final rawRows = json['rows'];
    final rows = rawRows is List
        ? rawRows
            .whereType<Map<String, dynamic>>()
            .map(fromJsonT)
            .toList()
        : <T>[];

    return PagedApiResponse(
      code: json['code'] as int? ?? -1,
      msg: json['msg'] as String?,
      total: json['total'] as int? ?? rows.length,
      rows: rows,
    );
  }
}
