import 'package:animus/rest/mappers/intake/case_summary_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaseSummaryMapper', () {
    test('should map fields and prefer canonical excluded topics key', () {
      final dto = CaseSummaryMapper.toDto(<String, dynamic>{
        'case_summary': '  Resumo do caso  ',
        'legal_issue': '  Questao juridica  ',
        'central_question': '  Pergunta central  ',
        'relevant_laws': <dynamic>[' Art. 5 ', ' ', 10],
        'key_facts': <dynamic>[' Fato 1 ', null, 'Fato 2'],
        'search_terms': <dynamic>[' termo 1 ', 'termo 2'],
        'type_of_action': '  Acao civil  ',
        'jurisdiction_issue': '  Competencia  ',
        'standing_issue': '  Legitimidade  ',
        'secondary_legal_issues': <dynamic>[' Tema 1 '],
        'alternative_questions': <dynamic>[' Alternativa 1 '],
        'requested_relief': <dynamic>[' Pedido 1 '],
        'procedural_issues': <dynamic>[' Procedimento 1 '],
        'excluded_or_accessory_topics': <dynamic>[' Topico novo ', ' '],
        'excluded_or_acessory_topics': <dynamic>[' Topico legado '],
      });

      expect(dto.caseSummary, 'Resumo do caso');
      expect(dto.legalIssue, 'Questao juridica');
      expect(dto.centralQuestion, 'Pergunta central');
      expect(dto.relevantLaws, <String>['Art. 5']);
      expect(dto.keyFacts, <String>['Fato 1', 'Fato 2']);
      expect(dto.searchTerms, <String>['termo 1', 'termo 2']);
      expect(dto.typeOfAction, 'Acao civil');
      expect(dto.jurisdictionIssue, 'Competencia');
      expect(dto.standingIssue, 'Legitimidade');
      expect(dto.secondaryLegalIssues, <String>['Tema 1']);
      expect(dto.alternativeQuestions, <String>['Alternativa 1']);
      expect(dto.requestedRelief, <String>['Pedido 1']);
      expect(dto.proceduralIssues, <String>['Procedimento 1']);
      expect(dto.excludedOrAccessoryTopics, <String>['Topico novo']);
    });

    test(
      'should use defensive fallbacks and support legacy excluded topics key',
      () {
        final dto = CaseSummaryMapper.toDto(<String, dynamic>{
          'case_summary': null,
          'legal_issue': 1,
          'central_question': true,
          'relevant_laws': 'invalid',
          'key_facts': null,
          'search_terms': <dynamic>[' ', ' termo valido '],
          'type_of_action': ' ',
          'jurisdiction_issue': '',
          'standing_issue': null,
          'secondary_legal_issues': <dynamic>[1, ' Tema valido '],
          'alternative_questions': const <dynamic>[],
          'requested_relief': const <dynamic>[],
          'procedural_issues': const <dynamic>[],
          'excluded_or_acessory_topics': <dynamic>[' Legado 1 ', '', 2],
        });

        expect(dto.caseSummary, '');
        expect(dto.legalIssue, '');
        expect(dto.centralQuestion, '');
        expect(dto.relevantLaws, isEmpty);
        expect(dto.keyFacts, isEmpty);
        expect(dto.searchTerms, <String>['termo valido']);
        expect(dto.typeOfAction, isNull);
        expect(dto.jurisdictionIssue, isNull);
        expect(dto.standingIssue, isNull);
        expect(dto.secondaryLegalIssues, <String>['Tema valido']);
        expect(dto.excludedOrAccessoryTopics, <String>['Legado 1']);
      },
    );
  });
}
