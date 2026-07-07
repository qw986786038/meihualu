String? parseUploadPath(dynamic data) {
  if (data == null) return null;
  if (data is String) {
    final value = data.trim();
    return value.isEmpty ? null : value;
  }
  if (data is Map) {
    for (final key in ['url', 'fileName', 'avatarUrl', 'path', 'logo']) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
  }
  return null;
}
