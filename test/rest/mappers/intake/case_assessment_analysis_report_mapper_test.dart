import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/rest/mappers/intake/case_assessment_analysis_report_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaseAssessmentAnalysisReportMapper', () {
    test('should map case assessment analysis report', () {
      final dto = CaseAssessmentAnalysisReportMapper.toDto(
        _reportJson(
          type: 'CASE_ASSESSMENT',
          status: 'GENERATING_PETITION_DRAFT',
          draft: <String, dynamic>{
            'analysis_id': 'analysis-1',
            'content': 'Minuta da peticao',
          },
          draftKey: 'petition_draft',
        ),
      );

      expect(dto.analysis.type, AnalysisTypeDto.caseAssessment);
      expect(dto.analysis.status, AnalysisStatusDto.generatingPetitionDraft);
      expect(dto.document.name, 'documento.pdf');
      expect(dto.caseSummary.caseSummary, 'Resumo do caso');
      expect(dto.precedents.single.analysisId, 'analysis-1');
      expect(dto.petitionDraft.analysisId, 'analysis-1');
      expect(dto.petitionDraft.content, 'Minuta da peticao');
    });
  });
}

Map<String, dynamic> _reportJson({
  required String type,
  required String status,
  required Map<String, dynamic> draft,
  required String draftKey,
}) {
  return <String, dynamic>{
    'analysis': <String, dynamic>{
      'id': 'analysis-1',
      'name': 'Analise',
      'account_id': 'account-1',
      'type': type,
      'status': status,
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
        'is_chosen': true,
        'synthesis': 'Sintese do precedente',
        'similarity_score': 90,
        'final_rank': 1,
        'applicability_level': 2,
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
    draftKey: draft,
  };
}
