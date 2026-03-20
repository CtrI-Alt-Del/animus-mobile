import 'dart:io';

class RestResponse<Body> {
  final Body? _body;
  final int _statusCode;
  final String? _errorMessage;

  RestResponse({Body? body, int? statusCode, String? errorMessage})
    : _body = body,
      _statusCode = statusCode ?? HttpStatus.ok,
      _errorMessage = errorMessage;

  Body get body {
    if (isFailure || _errorMessage != null) {
      throw Exception('Rest Response failed: $statusCode');
    }
    return _body!;
  }

  Never throwError() {
    throw Exception('Rest Response failed: $statusCode');
  }

  RestResponse<NewBody> mapBody<NewBody>(NewBody? Function(Body) mapper) {
    if (_errorMessage != null) {
      throw Exception('Rest Response failed. Error message: $_errorMessage');
    }
    if (_body == null) {
      throw Exception('Rest Response failed. Body is null');
    }
    return RestResponse(body: mapper(_body), statusCode: _statusCode);
  }

  bool get isSuccessful {
    return _statusCode <= HttpStatus.badRequest;
  }

  bool get isFailure {
    return _statusCode >= HttpStatus.badRequest || _errorMessage != null;
  }

  String get errorMessage {
    if (_errorMessage != null) {
      return _errorMessage;
    }
    throw Exception('Rest Response failed: $statusCode');
  }

  int get statusCode => _statusCode;
}
