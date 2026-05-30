import 'dart:typed_data';

import 'package:animus/core/intake/dtos/case_assessment_analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/first_instance_analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_analysis_report_dto.dart';

abstract class PdfDriver {
  Future<Uint8List> generateCaseAssessmentAnalysisReport({
    required CaseAssessmentAnalysisReportDto report,
  });

  Future<Uint8List> generateFirstInstanceAnalysisReport({
    required FirstInstanceAnalysisReportDto report,
  });

  Future<Uint8List> generateSecondInstanceAnalysisReport({
    required SecondInstanceAnalysisReportDto report,
  });

  Future<void> sharePdf({required Uint8List bytes, required String filename});
}
