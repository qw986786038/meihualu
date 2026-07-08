class ApiResponse<T> {
  const ApiResponse({
    required this.code,
    this.msg,
    this.data,
  });

  final int code;
  final String? msg;
  final T? data;

  bool get isSuccess => code == 200;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json)? fromJsonT,
  ) {
    final rawData = json['data'];
    T? data;
    if (rawData is Map<String, dynamic> && fromJsonT != null) {
      data = fromJsonT(rawData);
    } else if (rawData != null && fromJsonT == null) {
      data = rawData as T?;
    }

    return ApiResponse(
      code: json['code'] as int? ?? -1,
      msg: json['msg'] as String?,
      data: data,
    );
  }
}
