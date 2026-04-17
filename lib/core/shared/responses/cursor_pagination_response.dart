class CursorPaginationResponse<Item> {
  final List<Item> items;
  final String? nextCursor;

  const CursorPaginationResponse({required this.items, this.nextCursor});
}
