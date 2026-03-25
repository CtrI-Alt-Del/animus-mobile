class CursorPaginationResponse<Item> {
  final List<Item> items;
  final String? nextCursor;

  CursorPaginationResponse({required this.items, this.nextCursor});
}
