class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  
  ApiException(this.message, [this.statusCode, this.data]);
  
  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException() : super('Unauthorized', 401);
}

class ValidationException extends ApiException {
  ValidationException(String message, [dynamic data]) : super(message, 422, data);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message, 404);
}

class ConflictException extends ApiException {
  ConflictException(String message) : super(message, 409);
}
