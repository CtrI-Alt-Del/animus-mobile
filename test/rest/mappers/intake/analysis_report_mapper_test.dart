import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';
import 'package:animus/rest/mappers/intake/analysis_report_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalysisReportMapper.toDto', () {
    test('maps report and applied filters from payload', () {
      final dto = AnalysisReportMapper.toDto(_validPayload());

      expect(dto.analysis.id, 'analysis-1');
      expect(dto.analysis.name, 'Analise final');
      expect(dto.filters.limit, 7);
      expect(dto.filters.courts, <CourtDto>[CourtDto.stf, CourtDto.stj]);
      expect(dto.filters.precedentKinds, <PrecedentKindDto>[
        PrecedentKindDto.sum,
        PrecedentKindDto.irdr,
      ]);
      expect(dto.precedents, hasLength(1));
      expect(dto.chosenPrecedent.isChosen, isTrue);
    });

    test('throws FormatException when filters block is missing', () {
      final payload = _validPayload()..remove('filters');

      expect(
        () => AnalysisReportMapper.toDto(payload),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Map<String, dynamic> _validPayload() {
  return <String, dynamic>{
    'analysis': <String, dynamic>{
      'id': 'analysis-1',
      'name': 'Analise final',
      'account_id': 'account-1',
      'status': 'PRECEDENT_CHOSED',
      'summary': 'Resumo',
      'created_at': '2026-05-02T10:00:00Z',
      'is_archived': false,
    },
    'petition': <String, dynamic>{
      'id': 'petition-1',
      'analysis_id': 'analysis-1',
      'uploaded_at': '2026-05-02T10:00:00Z',
      'document': <String, dynamic>{
        'file_path': 'uploads/petition.pdf',
        'name': 'petition.pdf',
      },
    },
    'summary': <String, dynamic>{
      'case_summary': 'Resumo do caso',
      'legal_issue': 'Questao juridica',
      'central_question': 'Pergunta central',
      'relevant_laws': <String>['Lei 1'],
      'key_facts': <String>['Fato 1'],
      'search_terms': <String>['termo'],
    },
    'filters': <String, dynamic>{
      'limit': 7,
      'courts': <String>['STF', 'STJ'],
      'precedent_kinds': <String>['SUM', 'IRDR'],
    },
    'precedents': <Map<String, dynamic>>[
      _analysisPrecedentJson(isChosen: false),
    ],
    'chosen_precedent': _analysisPrecedentJson(isChosen: true),
  };
}

Map<String, dynamic> _analysisPrecedentJson({required bool isChosen}) {
  return <String, dynamic>{
    'analysis_id': 'analysis-1',
    'is_chosen': isChosen,
    'applicability_percentage': 91,
    'classification_level': 'APPLICABLE',
    'synthesis': 'Sintese explicativa',
    'precedent': <String, dynamic>{
      'identifier': <String, dynamic>{
        'court': 'STF',
        'kind': 'SUM',
        'number': 123,
      },
      'synthesis': 'Sintese do precedente',
      'status': 'ACTIVE',
      'enunciation': 'Enunciado',
      'thesis': 'Tese',
      'last_updated_in_pangea_at': '2026-05-02T10:00:00Z',
      'id': 'precedent-1',
    },
  };
}
