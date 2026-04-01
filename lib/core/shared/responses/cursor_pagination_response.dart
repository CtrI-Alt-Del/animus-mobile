class CursorPaginationResponse<T> {
  final List<T> items;
  final String? nextCursor;

  const CursorPaginationResponse({required this.items, this.nextCursor});
}
