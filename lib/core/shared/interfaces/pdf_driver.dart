import 'dart:typed_data';

import 'package:animus/core/intake/dtos/analysis_report_dto.dart';

abstract class PdfDriver {
  Future<Uint8List> generateAnalysisReport({required AnalysisReportDto report});

  Future<void> sharePdf({required Uint8List bytes, required String filename});
}
