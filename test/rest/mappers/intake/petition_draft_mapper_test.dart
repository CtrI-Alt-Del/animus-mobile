import 'package:animus/rest/mappers/intake/petition_draft_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PetitionDraftMapper', () {
    test('should map petition draft payload', () {
      final dto = PetitionDraftMapper.toDto(<String, dynamic>{
        'analysis_id': 'analysis-1',
        'structured_facts': 'Fatos estruturados',
        'legal_grounds': 'Fundamentos juridicos',
        'central_thesis': 'Tese central',
        'requests': <dynamic>['Pedido 1'],
        'precedent_citations': <dynamic>['Precedente 1'],
      });

      expect(dto.analysisId, 'analysis-1');
      expect(dto.structuredFacts, 'Fatos estruturados');
      expect(dto.legalGrounds, 'Fundamentos juridicos');
      expect(dto.centralThesis, 'Tese central');
      expect(dto.requests, <String>['Pedido 1']);
      expect(dto.precedentCitations, <String>['Precedente 1']);
    });

    test('should fallback to empty strings when payload is incomplete', () {
      final dto = PetitionDraftMapper.toDto(<String, dynamic>{});

      expect(dto.analysisId, '');
      expect(dto.structuredFacts, '');
      expect(dto.legalGrounds, '');
      expect(dto.centralThesis, '');
      expect(dto.requests, isEmpty);
      expect(dto.precedentCitations, isEmpty);
    });
  });
}
