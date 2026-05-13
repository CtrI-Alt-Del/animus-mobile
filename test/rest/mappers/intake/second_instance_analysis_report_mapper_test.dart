import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/rest/mappers/intake/second_instance_analysis_report_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecondInstanceAnalysisReportMapper', () {
    test(
      'should map second instance analysis report with chosen precedent',
      () {
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
          'chosen_precedent': <String, dynamic>{
            'analysis_id': 'analysis-1',
            'is_chosen': true,
            'synthesis': 'Sintese escolhida',
            'similarity_score': 91,
            'final_rank': 1,
            'applicability_level': 2,
            'precedent': <String, dynamic>{
              'id': 'precedent-1',
              'identifier': <String, dynamic>{
                'court': 'TRT7',
                'kind': 'NT',
                'number': 456,
              },
              'synthesis': 'Sintese',
              'status': 'AVAILABLE',
              'enunciation': 'Enunciado',
              'thesis': 'Tese',
              'last_updated_in_pangea_at': '2026-05-12T10:00:00.000Z',
            },
          },
        });

        expect(dto.analysis.type, AnalysisTypeDto.secondInstance);
        expect(dto.analysis.status, AnalysisStatusDto.generatingJudgmentDraft);
        expect(dto.chosenPrecedent, isNotNull);
        expect(dto.chosenPrecedent!.precedent.identifier.number, 456);
      },
    );

    test('should ignore invalid chosen precedent payload', () {
      final dto = SecondInstanceAnalysisReportMapper.toDto(<String, dynamic>{
        'analysis': <String, dynamic>{
          'type': 'SECOND_INSTANCE',
          'status': 'DONE',
        },
        'document': <String, dynamic>{},
        'case_summary': <String, dynamic>{},
        'precedents': 'invalid',
        'chosen_precedent': <String, dynamic>{
          'precedent': <String, dynamic>{
            'identifier': <String, dynamic>{'court': 'TRT7'},
          },
        },
      });

      expect(dto.precedents, isEmpty);
      expect(dto.chosenPrecedent, isNull);
      expect(dto.analysis.status, AnalysisStatusDto.done);
    });
  });
}
