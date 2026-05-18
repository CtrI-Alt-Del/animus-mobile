import 'package:animus/rest/mappers/intake/judgment_draft_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JudgmentDraftMapper', () {
    test('should map judgment draft payload', () {
      final dto = JudgmentDraftMapper.toDto(<String, dynamic>{
        'content': 'Minuta do julgamento',
      });

      expect(dto.content, 'Minuta do julgamento');
    });

    test('should fallback to empty string when content is absent', () {
      final dto = JudgmentDraftMapper.toDto(<String, dynamic>{});

      expect(dto.content, '');
    });
  });
}
