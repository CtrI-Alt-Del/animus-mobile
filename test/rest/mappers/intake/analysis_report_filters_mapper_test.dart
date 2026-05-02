import 'package:animus/core/intake/dtos/court_dto.dart';
import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';
import 'package:animus/rest/mappers/intake/analysis_report_filters_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalysisReportFiltersMapper.toDto', () {
    test('maps limit courts and precedent kinds ignoring unknown values', () {
      final dto = AnalysisReportFiltersMapper.toDto(<String, dynamic>{
        'limit': '5',
        'courts': <String>['STJ', 'UNKNOWN', 'TRT7'],
        'precedent_kinds': <String>['SUM', 'INVALID', 'IRDR'],
      });

      expect(dto.limit, 5);
      expect(dto.courts, <CourtDto>[CourtDto.stj, CourtDto.trt7]);
      expect(dto.precedentKinds, <PrecedentKindDto>[
        PrecedentKindDto.sum,
        PrecedentKindDto.irdr,
      ]);
    });

    test('throws FormatException when limit is missing', () {
      expect(
        () => AnalysisReportFiltersMapper.toDto(<String, dynamic>{
          'courts': <String>['STF'],
          'precedent_kinds': <String>['SUM'],
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when limit is zero or negative', () {
      expect(
        () => AnalysisReportFiltersMapper.toDto(<String, dynamic>{
          'limit': 0,
          'courts': <String>[],
          'precedent_kinds': <String>[],
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
