class BindError<T> extends Error {
  /// The type of the class the user tried to retrieve
  final T controller;
  final String? tag;

  /// Creates a [BindError]
  BindError({required this.controller, required this.tag});

  @override
  String toString() {
    return '''Error: No Bind<$controller> ancestor found. To fix this, please add a Bind<$controller> widget ancestor to the current context.
      ''';
  }
}
