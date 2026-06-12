class CommerceException implements Exception {
  const CommerceException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() =>
      'CommerceException(statusCode: $statusCode, message: $message)';
}
