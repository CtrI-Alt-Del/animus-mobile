import 'package:animus/rest/mappers/intake/analysis_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalysisMapper', () {
    test('should map analysis fields from api payload', () {
      final dto = AnalysisMapper.toDto(<String, dynamic>{
        'id': 'analysis-1',
        'name': 'Analise 1',
        'account_id': 'account-1',
        'status': 'processing',
        'summary': 'Resumo',
        'created_at': '2026-03-31T12:30:00Z',
        'folder_id': 'folder-1',
        'is_archived': true,
      });

      expect(dto.id, 'analysis-1');
      expect(dto.name, 'Analise 1');
      expect(dto.accountId, 'account-1');
      expect(dto.status, 'processing');
      expect(dto.summary, 'Resumo');
      expect(dto.createdAt, '2026-03-31T12:30:00Z');
      expect(dto.folderId, 'folder-1');
      expect(dto.isArchived, isTrue);
    });

    test('should apply fallbacks when optional fields are absent', () {
      final dto = AnalysisMapper.toDto(<String, dynamic>{
        'createdAt': '2026-04-01T08:00:00Z',
      });

      expect(dto.id, isNull);
      expect(dto.name, '');
      expect(dto.accountId, '');
      expect(dto.status, '');
      expect(dto.summary, '');
      expect(dto.createdAt, '2026-04-01T08:00:00Z');
      expect(dto.folderId, isNull);
      expect(dto.isArchived, isFalse);
    });
  });
}
