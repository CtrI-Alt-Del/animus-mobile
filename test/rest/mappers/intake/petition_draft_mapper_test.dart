import 'package:animus/rest/mappers/intake/petition_draft_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PetitionDraftMapper', () {
    test('should map petition draft payload', () {
      final dto = PetitionDraftMapper.toDto(<String, dynamic>{
        'analysis_id': 'analysis-1',
        'content': 'Minuta da peticao',
      });

      expect(dto.analysisId, 'analysis-1');
      expect(dto.content, 'Minuta da peticao');
    });

    test('should fallback to empty strings when payload is incomplete', () {
      final dto = PetitionDraftMapper.toDto(<String, dynamic>{});

      expect(dto.analysisId, '');
      expect(dto.content, '');
    });
  });
}
