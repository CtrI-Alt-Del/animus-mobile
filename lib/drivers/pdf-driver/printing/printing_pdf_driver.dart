import 'dart:typed_data';

import 'package:printing/printing.dart';

import 'package:animus/core/intake/dtos/first_instance_analysis_report_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_analysis_report_dto.dart';
import 'package:animus/core/shared/interfaces/pdf_driver.dart';
import 'package:animus/drivers/pdf-driver/printing/animus_pdf_theme.dart';
import 'package:animus/drivers/pdf-driver/printing/first_instance_pdf_generator.dart';
import 'package:animus/drivers/pdf-driver/printing/second_instance_pdf_generator.dart';

class PrintingPdfDriver implements PdfDriver {
  final FirstInstancePdfGenerator _firstInstancePdfGenerator;
  final SecondInstancePdfGenerator _secondInstancePdfGenerator;

  PrintingPdfDriver({required AnimusPdfTheme theme})
    : _firstInstancePdfGenerator = FirstInstancePdfGenerator(theme: theme),
      _secondInstancePdfGenerator = SecondInstancePdfGenerator(theme: theme);

  @override
  Future<Uint8List> generateAnalysisReport({
    required FirstInstanceAnalysisReportDto report,
  }) {
    return _firstInstancePdfGenerator.generate(report: report);
  }

  @override
  Future<Uint8List> generateSecondInstanceAnalysisReport({
    required SecondInstanceAnalysisReportDto report,
  }) {
    return _secondInstancePdfGenerator.generate(report: report);
  }

  @override
  Future<void> sharePdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
