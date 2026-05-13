import 'package:animus/core/intake/dtos/analysis_status_dto.dart';
import 'package:animus/core/intake/dtos/analysis_type_dto.dart';
import 'package:animus/rest/mappers/intake/analysis_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalysisMapper', () {
    test('should map case assessment type and status', () {
      final dto = AnalysisMapper.toDto(<String, dynamic>{
        'id': 'analysis-1',
        'name': 'Analise',
        'account_id': 'account-1',
        'type': 'CASE_ASSESSMENT',
        'status': 'GENERATING_PETITION_DRAFT',
        'summary': 'Resumo',
        'created_at': '2026-05-12T10:00:00.000Z',
      });

      expect(dto.type, AnalysisTypeDto.caseAssessment);
      expect(dto.status, AnalysisStatusDto.generatingPetitionDraft);
    });

    test('should keep legacy compatibility for first instance alias', () {
      final dto = AnalysisMapper.toDto(<String, dynamic>{
        'id': 'analysis-1',
        'name': 'Analise',
        'account_id': 'account-1',
        'type': 'LAWYER',
        'status': 'DONE',
        'summary': 'Resumo',
        'createdAt': '2026-05-12T10:00:00.000Z',
      });

      expect(dto.type, AnalysisTypeDto.firstInstance);
      expect(dto.status, AnalysisStatusDto.precedentChosen);
      expect(dto.createdAt, '2026-05-12T10:00:00.000Z');
    });

    test('should keep legacy compatibility for second instance alias', () {
      final dto = AnalysisMapper.toDto(<String, dynamic>{
        'id': 'analysis-1',
        'name': 'Analise',
        'account_id': 'account-1',
        'type': 'JUDGE',
        'status': 'GENERATING_JUDGMENT_DRAFT',
        'summary': 'Resumo',
        'created_at': '2026-05-12T10:00:00.000Z',
        'folder_id': 'folder-1',
        'is_archived': true,
      });

      expect(dto.type, AnalysisTypeDto.secondInstance);
      expect(dto.status, AnalysisStatusDto.generatingJudgmentDraft);
      expect(dto.folderId, 'folder-1');
      expect(dto.isArchived, isTrue);
    });

    test('should fallback to first instance defaults on unknown values', () {
      final dto = AnalysisMapper.toDto(<String, dynamic>{
        'type': 'UNKNOWN',
        'status': 'UNKNOWN',
      });

      expect(dto.type, AnalysisTypeDto.firstInstance);
      expect(dto.status, AnalysisStatusDto.waitingPetition);
      expect(dto.name, '');
      expect(dto.accountId, '');
      expect(dto.summary, '');
      expect(dto.createdAt, '');
      expect(dto.isArchived, isFalse);
    });
  });
}
