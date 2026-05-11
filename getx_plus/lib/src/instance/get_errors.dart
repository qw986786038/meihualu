/// Thrown when [Get.find] cannot resolve a registered dependency.
final class GetDependencyNotFound implements Exception {
  const GetDependencyNotFound(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown for other GetX / reactive usage errors (e.g. missing [toJson]).
final class GetXException implements Exception {
  const GetXException(this.message);

  final String message;

  @override
  String toString() => message;
}
