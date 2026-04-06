import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:animus/core/intake/dtos/precedent_kind_dto.dart';

class AnimusPdfTheme {
  const AnimusPdfTheme();

  Future<pw.ThemeData> load() async {
    return pw.ThemeData.withFont(
      base: await PdfGoogleFonts.interRegular(),
      bold: await PdfGoogleFonts.interSemiBold(),
      italic: await PdfGoogleFonts.interItalic(),
      boldItalic: await PdfGoogleFonts.interSemiBoldItalic(),
    );
  }

  String formatKindLabel(PrecedentKindDto kind) {
    switch (kind) {
      case PrecedentKindDto.sum:
        return 'Sumula';
      case PrecedentKindDto.sv:
        return 'Sumula vinculante';
      case PrecedentKindDto.oj:
        return 'Orientacao jurisprudencial';
      case PrecedentKindDto.rg:
        return 'Repercussao geral';
      case PrecedentKindDto.rr:
        return 'Recurso repetitivo';
      case PrecedentKindDto.tr:
        return 'Tema repetitivo';
      case PrecedentKindDto.irdr:
        return 'IRDR';
      case PrecedentKindDto.iac:
        return 'IAC';
      case PrecedentKindDto.puil:
        return 'PUIL';
      case PrecedentKindDto.adi:
        return 'ADI';
      case PrecedentKindDto.adc:
        return 'ADC';
      case PrecedentKindDto.ado:
        return 'ADO';
      case PrecedentKindDto.adpf:
        return 'ADPF';
      case PrecedentKindDto.nt:
        return 'Nota tecnica';
      case PrecedentKindDto.gr:
        return 'GR';
      case PrecedentKindDto.cont:
        return 'Controversia';
      case PrecedentKindDto.sirDr:
        return 'SIRDR';
      case PrecedentKindDto.irr:
        return 'IRR';
      case PrecedentKindDto.ct:
        return 'Caso teste';
    }
  }

  PdfColor get surfacePage => PdfColors.white;

  PdfColor get surfaceCard => const PdfColor(0.98, 0.98, 0.98);

  PdfColor get borderStrong => const PdfColor(0.86, 0.86, 0.86);

  PdfColor get textPrimary => PdfColors.black;

  PdfColor get textSecondary => const PdfColor(0.2, 0.2, 0.2);

  PdfColor get textMuted => const PdfColor(0.45, 0.45, 0.45);

  PdfColor get accent => const PdfColor(0.984, 0.886, 0.427);

  PdfColor get accentStrong => const PdfColor(0.769, 0.647, 0.208);

  PdfColor get success => const PdfColor(0.07, 0.53, 0.24);

  PdfColor get danger => const PdfColor(0.72, 0.13, 0.13);

  PdfColor get surfaceMuted => const PdfColor(0.96, 0.96, 0.95);

  PdfColor get divider => const PdfColor(0.89, 0.89, 0.90);

  PdfColor get pageBadgeFill => const PdfColor(0.996, 0.976, 0.886);

  PdfColor get highlightFill => const PdfColor(1, 0.988, 0.941);

  PdfColor get warningStroke => const PdfColor(1, 0.71, 0.28);
}
