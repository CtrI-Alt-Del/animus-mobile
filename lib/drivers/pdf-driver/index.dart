import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animus/core/shared/interfaces/pdf_driver.dart';
import 'package:animus/drivers/pdf-driver/printing/animus_pdf_theme.dart';
import 'package:animus/drivers/pdf-driver/printing/printing_pdf_driver.dart';

final Provider<PdfDriver> pdfDriverProvider = Provider<PdfDriver>((Ref ref) {
  return const PrintingPdfDriver(theme: AnimusPdfTheme());
});
