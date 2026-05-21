import 'package:animus/rest/mappers/intake/analysis_petition_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalysisPetitionMapper', () {
    test(
      'should map case summary from summary and preserve typed petition',
      () {
        final dto = AnalysisPetitionMapper.toDto(<String, dynamic>{
          'petition': <String, dynamic>{
            'id': 'petition-1',
            'analysis_id': 'analysis-1',
            'uploaded_at': '2026-05-12T10:00:00.000Z',
            'document': <String, dynamic>{
              'file_path': 'uploads/petitions/petition-1.pdf',
              'name': 'petition-1.pdf',
            },
          },
          'summary': <String, dynamic>{'case_summary': 'Resumo atual'},
        });

        expect(dto.petition.id, 'petition-1');
        expect(dto.petition.analysisId, 'analysis-1');
        expect(dto.petition.uploadedAt, '2026-05-12T10:00:00.000Z');
        expect(
          dto.petition.document.filePath,
          'uploads/petitions/petition-1.pdf',
        );
        expect(dto.petition.document.name, 'petition-1.pdf');
        expect(dto.caseSummary?.caseSummary, 'Resumo atual');
      },
    );

    test('should keep legacy compatibility with petition_summary', () {
      final dto = AnalysisPetitionMapper.toDto(<String, dynamic>{
        'petition': <String, dynamic>{
          'id': 'petition-legacy',
          'analysis_id': 'analysis-legacy',
          'uploaded_at': '2026-05-12T10:00:00.000Z',
          'document': <String, dynamic>{
            'file_path': 'uploads/petitions/petition-legacy.pdf',
            'name': 'petition-legacy.pdf',
          },
        },
        'petition_summary': <String, dynamic>{'case_summary': 'Resumo legado'},
      });

      expect(dto.petition.id, 'petition-legacy');
      expect(dto.caseSummary?.caseSummary, 'Resumo legado');
    });

    test('should return null case summary when payload has no summary', () {
      final dto = AnalysisPetitionMapper.toDto(<String, dynamic>{
        'petition': <String, dynamic>{
          'id': 'petition-1',
          'analysis_id': 'analysis-1',
          'uploaded_at': '2026-05-12T10:00:00.000Z',
          'document': <String, dynamic>{
            'file_path': 'uploads/petitions/petition-1.pdf',
            'name': 'petition-1.pdf',
          },
        },
      });

      expect(dto.petition.id, 'petition-1');
      expect(dto.caseSummary, isNull);
    });
  });
}
