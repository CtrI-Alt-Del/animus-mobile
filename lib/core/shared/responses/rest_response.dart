import 'dart:io';

import 'package:animus_mobile/core/shared/types/json.dart';

class RestResponse<Body> {
  final Body? _body;
  final int _statusCode;
  final String? _errorMessage;
  final Json? _errorBody;

  RestResponse({
    Body? body,
    int? statusCode,
    String? errorMessage,
    Json? errorBody,
  }) : _body = body,
       _statusCode = statusCode ?? HttpStatus.ok,
       _errorMessage = errorMessage,
       _errorBody = errorBody;

  Body get body {
    if (isFailure || _body == null) {
      throw Exception('Rest Response failed: $statusCode');
    }
    return _body;
  }

  Never throwError() {
    throw Exception('Rest Response failed: $statusCode');
  }

  RestResponse<NewBody> mapBody<NewBody>(NewBody Function(Body body) mapper) {
    if (isFailure) {
      return RestResponse<NewBody>(
        statusCode: _statusCode,
        errorMessage: _errorMessage,
        errorBody: _errorBody,
      );
    }

    if (_body == null) {
      return RestResponse<NewBody>(
        statusCode: _statusCode,
        errorMessage: 'Rest Response failed. Body is null',
        errorBody: _errorBody,
      );
    }

    return RestResponse<NewBody>(
      body: mapper(_body),
      statusCode: _statusCode,
      errorBody: _errorBody,
    );
  }

  bool get isSuccessful {
    return _statusCode < HttpStatus.badRequest && _errorMessage == null;
  }

  bool get isFailure {
    return !isSuccessful;
  }

  String get errorMessage {
    if (_errorMessage != null) {
      return _errorMessage;
    }
    throw Exception('Rest Response failed: $statusCode');
  }

  Json? get errorBody => _errorBody;

  int get statusCode => _statusCode;
}
