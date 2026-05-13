import 'package:animus/constants/cache_keys.dart';
import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/core/shared/interfaces/cache_driver.dart';
import 'package:animus/core/shared/interfaces/navigation_driver.dart';
import 'package:animus/core/shared/interfaces/rest_client.dart';
import 'package:animus/core/shared/responses/rest_response.dart';
import 'package:animus/core/shared/types/json.dart';
import 'package:animus/rest/services/intake_rest_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRestClient extends Mock implements RestClient {}

class MockCacheDriver extends Mock implements CacheDriver {}

class MockNavigationDriver extends Mock implements NavigationDriver {}

void main() {
  late MockRestClient restClient;
  late MockCacheDriver cacheDriver;
  late MockNavigationDriver navigationDriver;
  late IntakeRestService service;

  setUp(() {
    restClient = MockRestClient();
    cacheDriver = MockCacheDriver();
    navigationDriver = MockNavigationDriver();
    service = IntakeRestService(
      restClient: restClient,
      cacheDriver: cacheDriver,
      navigationDriver: navigationDriver,
    );

    when(() => cacheDriver.get(CacheKeys.accessToken)).thenReturn('access');
    when(() => cacheDriver.get(CacheKeys.refreshToken)).thenReturn('refresh');
  });

  test('createAnalysis envia type e folder_id trimado', () async {
    when(
      () => restClient.post(any(), body: any(named: 'body')),
    ).thenAnswer((_) async => RestResponse<Json>(body: _analysisJson()));

    final response = await service.createAnalysis(
      type: AnalysisTypeDto.secondInstance,
      folderId: '  folder-1  ',
    );

    expect(response.isSuccessful, isTrue);
    expect(response.body.type, AnalysisTypeDto.secondInstance);

    final verification = verify(
      () => restClient.post(captureAny(), body: captureAny(named: 'body')),
    );
    final captured = verification.captured;
    expect(captured.first, '/intake/analyses');
    expect(captured.last, <String, dynamic>{
      'type': AnalysisTypeDto.secondInstance.value,
      'folder_id': 'folder-1',
    });
    verify(() => restClient.setHeader('Authorization', 'Bearer access'));
  });

  test('getCaseSummary usa endpoint por analysis e mapeia summary', () async {
    when(() => restClient.get(any())).thenAnswer(
      (_) async => RestResponse<Json>(
        body: <String, dynamic>{
          'case_summary': 'Resumo do caso',
          'legal_issue': 'Questao juridica',
          'central_question': 'Pergunta central',
          'relevant_laws': <dynamic>['Art. 5'],
          'key_facts': <dynamic>['Fato 1'],
          'search_terms': <dynamic>['termo 1'],
          'excluded_or_acessory_topics': <dynamic>['Topico legado'],
        },
      ),
    );

    final response = await service.getCaseSummary(analysisId: 'analysis-1');

    expect(response.isSuccessful, isTrue);
    expect(response.body.caseSummary, 'Resumo do caso');
    expect(response.body.excludedOrAccessoryTopics, <String>['Topico legado']);
    verify(
      () => restClient.get('/intake/analyses/analysis-1/summary'),
    ).called(1);
  });

  test('getPetitionDraft usa endpoint novo e mapeia draft', () async {
    when(() => restClient.get(any())).thenAnswer(
      (_) async => RestResponse<Json>(
        body: <String, dynamic>{
          'analysis_id': 'analysis-1',
          'content': 'Minuta da peticao',
        },
      ),
    );

    final response = await service.getPetitionDraft(analysisId: 'analysis-1');

    expect(response.isSuccessful, isTrue);
    expect(response.body.analysisId, 'analysis-1');
    expect(response.body.content, 'Minuta da peticao');
    verify(
      () => restClient.get('/intake/analyses/analysis-1/petition-draft'),
    ).called(1);
  });

  test('getJudgmentDraft usa endpoint novo e mapeia draft', () async {
    when(() => restClient.get(any())).thenAnswer(
      (_) async => RestResponse<Json>(
        body: <String, dynamic>{'content': 'Minuta do julgamento'},
      ),
    );

    final response = await service.getJudgmentDraft(analysisId: 'analysis-1');

    expect(response.isSuccessful, isTrue);
    expect(response.body.content, 'Minuta do julgamento');
    verify(
      () => restClient.get('/intake/analyses/analysis-1/judgment-draft'),
    ).called(1);
  });

  test(
    'getFirstInstanceAnalysisReport usa endpoint e mapper corretos',
    () async {
      when(() => restClient.get(any())).thenAnswer(
        (_) async => RestResponse<Json>(
          body: _reportJson(
            type: 'FIRST_INSTANCE',
            status: 'DONE',
            extra: <String, dynamic>{
              'judgment_draft': <String, dynamic>{
                'content': 'Minuta do julgamento',
              },
            },
          ),
        ),
      );

      final response = await service.getFirstInstanceAnalysisReport(
        analysisId: 'analysis-1',
      );

      expect(response.isSuccessful, isTrue);
      expect(response.body.analysis.type, AnalysisTypeDto.firstInstance);
      expect(response.body.analysis.status, AnalysisStatusDto.precedentChosen);
      expect(response.body.judgmentDraft.content, 'Minuta do julgamento');
      verify(
        () => restClient.get(
          '/intake/analyses/analysis-1/first-instance-analysis-report',
        ),
      ).called(1);
    },
  );

  test(
    'getCaseAssessmentAnalysisReport usa endpoint e mapper corretos',
    () async {
      when(() => restClient.get(any())).thenAnswer(
        (_) async => RestResponse<Json>(
          body: _reportJson(
            type: 'CASE_ASSESSMENT',
            status: 'GENERATING_PETITION_DRAFT',
            extra: <String, dynamic>{
              'petition_draft': <String, dynamic>{
                'analysis_id': 'analysis-1',
                'content': 'Minuta da peticao',
              },
            },
          ),
        ),
      );

      final response = await service.getCaseAssessmentAnalysisReport(
        analysisId: 'analysis-1',
      );

      expect(response.isSuccessful, isTrue);
      expect(response.body.analysis.type, AnalysisTypeDto.caseAssessment);
      expect(
        response.body.analysis.status,
        AnalysisStatusDto.generatingPetitionDraft,
      );
      expect(response.body.petitionDraft.content, 'Minuta da peticao');
      verify(
        () => restClient.get(
          '/intake/analyses/analysis-1/case-assessment-analysis-report',
        ),
      ).called(1);
    },
  );

  test(
    'getSecondInstanceAnalysisReport usa endpoint e mapper corretos',
    () async {
      when(() => restClient.get(any())).thenAnswer(
        (_) async => RestResponse<Json>(
          body: _reportJson(
            type: 'SECOND_INSTANCE',
            status: 'GENERATING_JUDGMENT_DRAFT',
            extra: <String, dynamic>{
              'chosen_precedent': <String, dynamic>{
                'analysis_id': 'analysis-1',
                'is_chosen': true,
                'synthesis': 'Sintese escolhida',
                'similarity_score': 90,
                'final_rank': 1,
                'applicability_level': 2,
                'precedent': <String, dynamic>{
                  'id': 'precedent-1',
                  'identifier': <String, dynamic>{
                    'court': 'TRT7',
                    'kind': 'NT',
                    'number': 987,
                  },
                  'synthesis': 'Sintese',
                  'status': 'AVAILABLE',
                  'enunciation': 'Enunciado',
                  'thesis': 'Tese',
                  'last_updated_in_pangea_at': '2026-05-12T10:00:00.000Z',
                },
              },
            },
          ),
        ),
      );

      final response = await service.getSecondInstanceAnalysisReport(
        analysisId: 'analysis-1',
      );

      expect(response.isSuccessful, isTrue);
      expect(response.body.analysis.type, AnalysisTypeDto.secondInstance);
      expect(
        response.body.analysis.status,
        AnalysisStatusDto.generatingJudgmentDraft,
      );
      expect(response.body.chosenPrecedent, isNotNull);
      expect(response.body.chosenPrecedent!.precedent.identifier.number, 987);
      verify(
        () => restClient.get(
          '/intake/analyses/analysis-1/second-instance-analysis-report',
        ),
      ).called(1);
    },
  );

  test(
    'unarchiveAnalysis usa endpoint novo e retorna analysis atualizada',
    () async {
      when(() => restClient.patch(any())).thenAnswer(
        (_) async => RestResponse<Json>(
          body: _analysisJson(isArchived: false, status: 'DONE'),
        ),
      );

      final response = await service.unarchiveAnalysis(
        analysisId: 'analysis-1',
      );

      expect(response.isSuccessful, isTrue);
      expect(response.body.type, AnalysisTypeDto.secondInstance);
      expect(response.body.isArchived, isFalse);
      expect(response.body.status, AnalysisStatusDto.done);
      verify(
        () => restClient.patch('/intake/analyses/analysis-1/unarchive'),
      ).called(1);
    },
  );
}

Map<String, dynamic> _analysisJson({
  String type = 'SECOND_INSTANCE',
  String status = 'GENERATING_JUDGMENT_DRAFT',
  bool isArchived = false,
}) {
  return <String, dynamic>{
    'id': 'analysis-1',
    'name': 'Analise',
    'account_id': 'account-1',
    'type': type,
    'status': status,
    'summary': 'Resumo',
    'created_at': '2026-05-12T10:00:00.000Z',
    'folder_id': 'folder-1',
    'is_archived': isArchived,
  };
}

Map<String, dynamic> _reportJson({
  required String type,
  required String status,
  required Map<String, dynamic> extra,
}) {
  return <String, dynamic>{
    'analysis': _analysisJson(type: type, status: status),
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
        'similarity_score': 88,
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
    ...extra,
  };
}
