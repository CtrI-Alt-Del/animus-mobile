import 'package:animus/core/shared/responses/cursor_pagination_response.dart';
import 'package:animus/core/shared/types/json.dart';

final class CursorPaginationMapper {
  const CursorPaginationMapper._();

  static CursorPaginationResponse<T> toDto<T>(
    Json json,
    T Function(Json item) itemMapper,
  ) {
    final dynamic itemsValue = json['items'] ?? json['data'];
    final List<T> items = _toItems(itemsValue, itemMapper);
    final String? nextCursor = _toNextCursor(json);

    return CursorPaginationResponse<T>(items: items, nextCursor: nextCursor);
  }

  static List<T> _toItems<T>(dynamic value, T Function(Json item) itemMapper) {
    if (value is! List<dynamic>) {
      return <T>[];
    }

    return value.whereType<Json>().map(itemMapper).toList();
  }

  static String? _toNextCursor(Json json) {
    final dynamic nextCursor = json['next_cursor'] ?? json['nextCursor'];
    if (nextCursor is String && nextCursor.trim().isNotEmpty) {
      return nextCursor;
    }

    return null;
  }
}
