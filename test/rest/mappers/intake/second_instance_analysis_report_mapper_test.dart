import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/rest/mappers/intake/second_instance_analysis_report_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecondInstanceAnalysisReportMapper', () {
    test('should map second instance analysis report with judgment draft', () {
      final dto = SecondInstanceAnalysisReportMapper.toDto(<String, dynamic>{
        'analysis': <String, dynamic>{
          'id': 'analysis-1',
          'name': 'Analise',
          'account_id': 'account-1',
          'type': 'SECOND_INSTANCE',
          'status': 'GENERATING_JUDGMENT_DRAFT',
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
        'judgment_draft': <String, dynamic>{
          'analysis_id': 'analysis-1',
          'report': 'Relatorio da minuta',
          'merit_analysis': 'Analise de merito',
          'precedent_adherence_analysis': 'Analise de aderencia',
          'ruling': <dynamic>['Dar provimento'],
          'preliminary_issues': 'Preliminares',
          'no_applicable_precedent_notice': 'Sem precedente aplicavel',
        },
      });

      expect(dto.analysis.type, AnalysisTypeDto.secondInstance);
      expect(dto.analysis.status, AnalysisStatusDto.generatingJudgmentDraft);
      expect(dto.document.analysisId, 'analysis-1');
      expect(dto.caseSummary.caseSummary, 'Resumo do caso');
      expect(dto.precedents, hasLength(1));
      expect(dto.precedents.single.precedent.id, 'precedent-1');
      expect(dto.judgmentDraft.report, 'Relatorio da minuta');
      expect(dto.judgmentDraft.ruling, <String>['Dar provimento']);
    });

    test('should map empty judgment draft payload with defaults', () {
      final dto = SecondInstanceAnalysisReportMapper.toDto(<String, dynamic>{
        'analysis': <String, dynamic>{
          'type': 'SECOND_INSTANCE',
          'status': 'DONE',
        },
        'document': <String, dynamic>{},
        'case_summary': <String, dynamic>{},
        'precedents': 'invalid',
        'judgment_draft': 'invalid',
      });

      expect(dto.precedents, isEmpty);
      expect(dto.judgmentDraft.analysisId, isEmpty);
      expect(dto.judgmentDraft.ruling, isEmpty);
      expect(dto.analysis.status, AnalysisStatusDto.done);
    });

    test('should map camelCase judgment draft payload', () {
      final dto = SecondInstanceAnalysisReportMapper.toDto(<String, dynamic>{
        'analysis': <String, dynamic>{
          'type': 'SECOND_INSTANCE',
          'status': 'DONE',
        },
        'document': <String, dynamic>{},
        'case_summary': <String, dynamic>{},
        'precedents': <dynamic>[],
        'judgment_draft': <String, dynamic>{
          'analysisId': 'analysis-2',
          'report': 'Relatorio',
          'meritAnalysis': 'Merito',
          'precedentAdherenceAnalysis': 'Aderencia',
          'ruling': 'Dar parcial provimento',
          'preliminaryIssues': 'Preliminares',
          'noApplicablePrecedentNotice': 'Sem precedente',
        },
      });

      expect(dto.judgmentDraft.analysisId, 'analysis-2');
      expect(dto.judgmentDraft.report, 'Relatorio');
      expect(dto.judgmentDraft.meritAnalysis, 'Merito');
      expect(dto.judgmentDraft.precedentAdherenceAnalysis, 'Aderencia');
      expect(dto.judgmentDraft.ruling, <String>['Dar parcial provimento']);
      expect(dto.judgmentDraft.preliminaryIssues, 'Preliminares');
      expect(dto.judgmentDraft.noApplicablePrecedentNotice, 'Sem precedente');
    });
  });
}
