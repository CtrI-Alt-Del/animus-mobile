import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/rest/mappers/intake/first_instance_analysis_report_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirstInstanceAnalysisReportMapper', () {
    test('should map first instance analysis report', () {
      final dto = FirstInstanceAnalysisReportMapper.toDto(<String, dynamic>{
        'analysis': <String, dynamic>{
          'id': 'analysis-1',
          'name': 'Analise',
          'account_id': 'account-1',
          'type': 'FIRST_INSTANCE',
          'status': 'DONE',
          'summary': 'Resumo',
          'created_at': '2026-05-12T10:00:00.000Z',
        },
        'document': <String, dynamic>{
          'analysis_id': 'analysis-1',
          'uploaded_at': '2026-05-12T10:00:00.000Z',
          'file_path': 'uploads/documento.pdf',
          'name': 'documento.pdf',
        },
        'case_summary': <String, dynamic>{
          'case_summary': 'Resumo do caso',
          'legal_issue': 'Questao juridica',
          'central_question': 'Pergunta central',
          'relevant_laws': <dynamic>['Art. 5'],
          'key_facts': <dynamic>['Fato 1'],
          'search_terms': <dynamic>['termo 1'],
        },
        'precedents': <dynamic>[
          <String, dynamic>{
            'analysis_id': 'analysis-1',
            'is_chosen': false,
            'synthesis': 'Sintese do precedente',
            'similarity_score': 80,
            'final_rank': 2,
            'applicability_level': 1,
            'precedent': <String, dynamic>{
              'id': 'precedent-1',
              'identifier': <String, dynamic>{
                'court': 'TRT7',
                'kind': 'NT',
                'number': 123,
              },
              'synthesis': 'Sintese',
              'status': 'AVAILABLE',
              'enunciation': 'Enunciado',
              'thesis': 'Tese',
              'last_updated_in_pangea_at': '2026-05-12T10:00:00.000Z',
            },
          },
        ],
        'judgment_draft': <String, dynamic>{'content': 'Minuta do julgamento'},
      });

      expect(dto.analysis.type, AnalysisTypeDto.firstInstance);
      expect(dto.analysis.status, AnalysisStatusDto.precedentChosen);
      expect(dto.document.analysisId, 'analysis-1');
      expect(dto.caseSummary.legalIssue, 'Questao juridica');
      expect(dto.precedents.single.precedent.identifier.number, 123);
      expect(dto.judgmentDraft.content, 'Minuta do julgamento');
    });
  });
}
