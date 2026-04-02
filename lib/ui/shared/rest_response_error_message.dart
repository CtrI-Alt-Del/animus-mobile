import 'dart:io';

import 'package:animus/core/shared/responses/rest_response.dart';

String resolveRestResponseErrorMessage(
  RestResponse<dynamic> response, {
  required String fallback,
}) {
  final String? bodyMessage = response.errorBody?['message'] as String?;
  if (bodyMessage != null && bodyMessage.trim().isNotEmpty) {
    return bodyMessage;
  }

  try {
    final String message = response.errorMessage;
    if (message.trim().isNotEmpty && !_isTechnicalTransportMessage(message)) {
      return message;
    }
  } catch (_) {}

  return fallback;
}

bool _isTechnicalTransportMessage(String message) {
  return message.contains('RequestOptions.validateStatus') ||
      message.contains('This exception was thrown because the response') ||
      message.contains('developer.mozilla.org/en-US/docs/Web/HTTP/Status') ||
      message.contains('status code of ${HttpStatus.notFound}');
}
