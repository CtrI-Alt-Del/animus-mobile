String formatPrecedentStatus(String value) {
  final String normalized = value.trim();
  if (normalized.isEmpty) {
    return 'Trânsito em julgado';
  }

  final String sanitized = normalized.replaceAll('_', ' ').toLowerCase();
  final List<String> parts = sanitized
      .split(RegExp(r'\s+'))
      .where((String part) => part.isNotEmpty)
      .toList();

  return parts
      .map((String part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
