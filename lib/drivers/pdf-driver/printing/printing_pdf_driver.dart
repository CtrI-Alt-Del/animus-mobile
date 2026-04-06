import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:animus/core/intake/dtos/analysis_precedent_classification_level_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/analysis_report_dto.dart';
import 'package:animus/core/shared/interfaces/pdf_driver.dart';
import 'package:animus/drivers/pdf-driver/printing/animus_pdf_theme.dart';

class PrintingPdfDriver implements PdfDriver {
  final AnimusPdfTheme _theme;

  const PrintingPdfDriver({required AnimusPdfTheme theme}) : _theme = theme;

  @override
  Future<Uint8List> generateAnalysisReport({
    required AnalysisReportDto report,
  }) async {
    final pw.Document doc = pw.Document(
      theme: await _theme.load(),
      title: report.analysis.name,
    );

    final DateTime generatedAt = DateTime.now();
    final List<AnalysisPrecedentDto> sortedPrecedents =
        List<AnalysisPrecedentDto>.from(report.precedents)..sort(
          (AnalysisPrecedentDto a, AnalysisPrecedentDto b) =>
              b.applicabilityPercentage.compareTo(a.applicabilityPercentage),
        );

    doc.addPage(_buildHeaderPage(report, generatedAt));
    doc.addPage(_buildPetitionSummaryPage(report, generatedAt));
    doc.addPage(_buildPrecedentsPage(sortedPrecedents, generatedAt));
    doc.addPage(_buildChosenPrecedentPage(report.chosenPrecedent, generatedAt));

    return doc.save();
  }

  @override
  Future<void> sharePdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  List<pw.Widget> buildPrecedentCards({
    required List<AnalysisPrecedentDto> precedents,
  }) {
    return precedents
        .map(
          (AnalysisPrecedentDto precedent) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: _buildPrecedentCard(precedent),
          ),
        )
        .toList(growable: false);
  }

  pw.Page _buildHeaderPage(AnalysisReportDto report, DateTime generatedAt) {
    final String analysisName = _nonEmpty(
      report.analysis.name,
      fallback: 'Analise sem nome',
    );

    return pw.Page(
      pageTheme: _buildPageTheme(),
      build: (pw.Context context) {
        return _buildStaticPage(
          context: context,
          pageNumber: 1,
          stripeWidth: 120,
          generatedAt: generatedAt,
          content: <pw.Widget>[
            _buildBrandHeader(),
            pw.SizedBox(height: 12),
            _buildSectionTitle('Relatório de análise jurídica', fontSize: 24),
            pw.SizedBox(height: 8),
            pw.Text(
              'Petição: ${_nonEmpty(report.petition.document.name)}',
              style: pw.TextStyle(color: _theme.textMuted, fontSize: 13),
            ),
            pw.SizedBox(height: 16),
            _buildDivider(height: 2),
            pw.SizedBox(height: 14),
            _buildEyebrow('DADOS DA ANÁLISE'),
            pw.SizedBox(height: 10),
            _buildMetaRow('Nome da análise', analysisName),
            _buildMetaRow(
              'Criada em',
              _formatDateTime(_parseDate(report.analysis.createdAt)),
            ),
            pw.SizedBox(height: 12),
            _buildDivider(height: 2),
            pw.SizedBox(height: 14),
            _buildEyebrow('DADOS DA PETIÇÃO'),
            pw.SizedBox(height: 10),
            _buildMetaRow('Arquivo', report.petition.document.name),
            _buildMetaRow(
              'Upload em',
              _formatDateTime(_parseDate(report.petition.uploadedAt)),
            ),
          ],
        );
      },
    );
  }

  pw.Page _buildPetitionSummaryPage(
    AnalysisReportDto report,
    DateTime generatedAt,
  ) {
    return pw.MultiPage(
      pageTheme: _buildPageTheme(),
      header: (pw.Context context) =>
          _buildPageChrome(pageNumber: 2, stripeWidth: 136),
      footer: (pw.Context context) =>
          _buildFooter(context: context, generatedAt: generatedAt),
      build: (pw.Context context) {
        return <pw.Widget>[
          _buildSectionTitle('Síntese da petição', fontSize: 22),
          pw.SizedBox(height: 16),
          _buildEyebrow('RESUMO DO CASO'),
          pw.SizedBox(height: 8),
          _buildTextCard(report.summary.caseSummary),
          pw.SizedBox(height: 12),
          _buildEyebrow('QUESTÃO CENTRAL'),
          pw.SizedBox(height: 8),
          _buildHighlightTextCard(report.summary.centralQuestion),
          pw.SizedBox(height: 12),
          _buildEyebrow('ENQUADRAMENTO JURÍDICO'),
          pw.SizedBox(height: 8),
          _buildTextCard(report.summary.legalIssue),
          pw.SizedBox(height: 12),
          _buildEyebrow('FATOS RELEVANTES'),
          pw.SizedBox(height: 6),
          _buildPlainList(report.summary.keyFacts, ordered: true),
          pw.SizedBox(height: 12),
          _buildEyebrow('LEGISLAÇÃO APLICÁVEL'),
          pw.SizedBox(height: 6),
          _buildPlainList(report.summary.relevantLaws),
        ];
      },
    );
  }

  pw.Page _buildPrecedentsPage(
    List<AnalysisPrecedentDto> precedents,
    DateTime generatedAt,
  ) {
    return pw.MultiPage(
      pageTheme: _buildPageTheme(),
      header: (pw.Context context) =>
          _buildPageChrome(pageNumber: 3, stripeWidth: 168),
      footer: (pw.Context context) =>
          _buildFooter(context: context, generatedAt: generatedAt),
      build: (pw.Context context) {
        return <pw.Widget>[
          _buildSectionTitle(
            'Precedentes analisados (${precedents.length} encontrados)',
            fontSize: 22,
          ),
          pw.SizedBox(height: 16),
          ...buildPrecedentCards(precedents: precedents),
        ];
      },
    );
  }

  pw.Page _buildChosenPrecedentPage(
    AnalysisPrecedentDto chosenPrecedent,
    DateTime generatedAt,
  ) {
    return pw.MultiPage(
      pageTheme: _buildPageTheme(),
      header: (pw.Context context) =>
          _buildPageChrome(pageNumber: 4, stripeWidth: 158),
      footer: (pw.Context context) =>
          _buildFooter(context: context, generatedAt: generatedAt),
      build: (pw.Context context) {
        return <pw.Widget>[
          _buildSectionTitle('Precedente escolhido', fontSize: 22),
          pw.SizedBox(height: 16),
          _buildPrecedentCard(chosenPrecedent, highlight: true),
        ];
      },
    );
  }

  pw.Widget _buildPrecedentCard(
    AnalysisPrecedentDto precedent, {
    bool highlight = false,
  }) {
    final String header =
        '${precedent.precedent.identifier.court.value} · '
        '${_theme.formatKindLabel(precedent.precedent.identifier.kind)} '
        '${precedent.precedent.identifier.number}';
    final double normalizedPercentage = precedent.applicabilityPercentage
        .clamp(0, 100)
        .toDouble();

    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.fromLTRB(16, 16, 16, highlight ? 18 : 16),
      decoration: _cardDecoration(highlight: highlight),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Expanded(
                child: pw.Text(
                  header,
                  style: pw.TextStyle(
                    color: _theme.textPrimary,
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              _buildClassificationBadge(precedent.classificationLevel),
            ],
          ),
          pw.SizedBox(height: 10),
          _buildApplicabilityLabel(normalizedPercentage),
          pw.SizedBox(height: 12),
          _buildField(
            title: 'ENUNCIADO',
            content: _truncateForPdf(
              precedent.precedent.enunciation,
              maxChars: 650,
            ),
            titleColor: _theme.textMuted,
          ),
          if (precedent.precedent.thesis.trim().isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 8),
            _buildField(
              title: 'TESE FIRMADA',
              content: _truncateForPdf(
                precedent.precedent.thesis,
                maxChars: 800,
              ),
              titleColor: _theme.textMuted,
            ),
          ],
          pw.SizedBox(height: 8),
          _buildField(
            title: 'SÍNTESE EXPLICATIVA',
            content: _truncateForPdf(precedent.synthesis, maxChars: 700),
            titleColor: _theme.textMuted,
            contentColor: _theme.textMuted,
            italicContent: true,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildField({
    required String title,
    required String content,
    PdfColor? titleColor,
    PdfColor? contentColor,
    bool italicContent = false,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          title,
          style: pw.TextStyle(
            color: titleColor ?? _theme.accentStrong,
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _nonEmpty(content),
          style: pw.TextStyle(
            color: contentColor ?? _theme.textPrimary,
            fontSize: 13,
            lineSpacing: 4,
            fontStyle: italicContent ? pw.FontStyle.italic : null,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildClassificationBadge(
    AnalysisPrecedentClassificationLevelDto level,
  ) {
    final _BadgeData badge = _badgeData(level);

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: badge.background,
        border: pw.Border.all(color: badge.text, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Text(
        badge.label,
        style: pw.TextStyle(
          color: badge.text,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  _BadgeData _badgeData(AnalysisPrecedentClassificationLevelDto level) {
    switch (level) {
      case AnalysisPrecedentClassificationLevelDto.applicable:
        return _BadgeData(
          label: 'Aplicavel',
          background: const PdfColor(0.91, 0.98, 0.95),
          text: _theme.success,
        );
      case AnalysisPrecedentClassificationLevelDto.possiblyApplicable:
        return _BadgeData(
          label: 'Possivelmente aplicavel',
          background: _theme.pageBadgeFill,
          text: _theme.accentStrong,
        );
      case AnalysisPrecedentClassificationLevelDto.notApplicable:
        return _BadgeData(
          label: 'Nao aplicavel',
          background: const PdfColor(0.99, 0.93, 0.92),
          text: _theme.danger,
        );
    }
  }

  pw.Widget _buildApplicabilityLabel(double percentage) {
    return pw.RichText(
      text: pw.TextSpan(
        children: <pw.InlineSpan>[
          pw.TextSpan(
            text: '${percentage.toStringAsFixed(0)}%',
            style: pw.TextStyle(
              color: _theme.textPrimary,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.TextSpan(
            text: ' de aplicabilidade',
            style: pw.TextStyle(color: _theme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title, {double fontSize = 18}) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: fontSize,
        color: _theme.textPrimary,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  pw.Widget _buildTextCard(String content) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: _cardDecoration(),
      child: pw.Text(
        _nonEmpty(content),
        style: pw.TextStyle(
          color: _theme.textPrimary,
          fontSize: 13,
          lineSpacing: 3,
        ),
      ),
    );
  }

  pw.Widget _buildHighlightTextCard(String content) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        color: const PdfColor(0.98, 0.98, 0.98),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: pw.Text(
        _nonEmpty(content),
        style: pw.TextStyle(
          color: _theme.textPrimary,
          fontSize: 13,
          lineSpacing: 3,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildListItem(String marker, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.SizedBox(
            width: 12,
            child: pw.Text(
              marker,
              style: pw.TextStyle(color: _theme.textPrimary, fontSize: 12),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                color: _theme.textPrimary,
                fontSize: 12,
                lineSpacing: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPlainList(List<String> values, {bool ordered = false}) {
    final List<String> sanitizedValues = values
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);

    if (sanitizedValues.isEmpty) {
      return pw.Text('-', style: pw.TextStyle(color: _theme.textSecondary));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: sanitizedValues
          .asMap()
          .entries
          .map((MapEntry<int, String> entry) {
            final String marker = ordered ? '${entry.key + 1}.' : '-';

            return _buildListItem(marker, entry.value);
          })
          .toList(growable: false),
    );
  }

  pw.Widget _buildMetaRow(String title, String content) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.SizedBox(
            width: 128,
            child: pw.Text(
              title,
              style: pw.TextStyle(color: _theme.textMuted, fontSize: 12),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              _nonEmpty(content),
              style: pw.TextStyle(
                color: _theme.textPrimary,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBrandHeader() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: <pw.Widget>[
        pw.Container(
          width: 32,
          height: 32,
          decoration: pw.BoxDecoration(
            color: _theme.accent,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          alignment: pw.Alignment.center,
          child: pw.Text(
            'A',
            style: pw.TextStyle(
              color: _theme.textPrimary,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text(
              'Animus',
              style: pw.TextStyle(
                color: _theme.textPrimary,
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'Análise Jurídica com IA',
              style: pw.TextStyle(color: _theme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildEyebrow(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        color: _theme.accentStrong,
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );
  }

  pw.Widget _buildDivider({double height = 1}) {
    return pw.Container(
      width: double.infinity,
      height: height,
      color: _theme.divider,
    );
  }

  pw.Widget _buildStaticPage({
    required pw.Context context,
    required int pageNumber,
    required double stripeWidth,
    required DateTime generatedAt,
    required List<pw.Widget> content,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _buildPageChrome(pageNumber: pageNumber, stripeWidth: stripeWidth),
        ...content,
        pw.Spacer(),
        _buildFooter(context: context, generatedAt: generatedAt),
      ],
    );
  }

  pw.Widget _buildPageChrome({
    required int pageNumber,
    required double stripeWidth,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 28),
      child: pw.Row(
        children: <pw.Widget>[
          pw.Container(
            width: stripeWidth,
            height: 6,
            decoration: pw.BoxDecoration(
              color: _theme.accent,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter({
    required pw.Context context,
    required DateTime generatedAt,
  }) {
    return pw.Column(
      children: <pw.Widget>[
        _buildDivider(),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: <pw.Widget>[
            pw.Text(
              'Gerado pelo Animus em ${_formatDateTime(generatedAt)}',
              style: pw.TextStyle(color: _theme.textMuted, fontSize: 11),
            ),
            pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: pw.TextStyle(color: _theme.textMuted, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  pw.BoxDecoration _cardDecoration({bool highlight = false}) {
    return pw.BoxDecoration(
      color: highlight ? _theme.highlightFill : _theme.surfaceMuted,
      border: pw.Border.all(
        color: highlight ? _theme.accent : _theme.divider,
        width: highlight ? 1.5 : 0.5,
      ),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
    );
  }

  pw.PageTheme _buildPageTheme() {
    return pw.PageTheme(
      margin: const pw.EdgeInsets.all(48),
      pageFormat: PdfPageFormat.a4,
      buildBackground: (pw.Context context) {
        return pw.Container(color: _theme.surfacePage);
      },
    );
  }

  DateTime _parseDate(String raw) {
    return DateTime.tryParse(raw) ?? DateTime.now();
  }

  String _formatDateTime(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString().padLeft(4, '0');
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year às $hour:$minute';
  }

  String _nonEmpty(String? value, {String fallback = '-'}) {
    final String normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return fallback;
    }

    return normalized;
  }

  String _truncateForPdf(String? value, {required int maxChars}) {
    final String normalized = _nonEmpty(value, fallback: '-');
    if (normalized.length <= maxChars) {
      return normalized;
    }

    return '${normalized.substring(0, maxChars).trimRight()}...';
  }
}

class _BadgeData {
  final String label;
  final PdfColor background;
  final PdfColor text;

  const _BadgeData({
    required this.label,
    required this.background,
    required this.text,
  });
}
