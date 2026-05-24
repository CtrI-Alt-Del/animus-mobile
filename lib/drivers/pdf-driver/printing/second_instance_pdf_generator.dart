import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:animus/core/intake/dtos/analysis_precedent_applicability_level_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/second_instance_analysis_report_dto.dart';
import 'package:animus/drivers/pdf-driver/printing/animus_pdf_theme.dart';

class SecondInstancePdfGenerator {
  final AnimusPdfTheme _theme;

  const SecondInstancePdfGenerator({required AnimusPdfTheme theme})
    : _theme = theme;

  Future<Uint8List> generate({
    required SecondInstanceAnalysisReportDto report,
  }) async {
    final pw.Document doc = pw.Document(
      theme: await _theme.load(),
      title: report.analysis.name,
    );

    final DateTime generatedAt = DateTime.now();
    final List<AnalysisPrecedentDto> sortedPrecedents =
        List<AnalysisPrecedentDto>.from(report.precedents)..sort(
          (AnalysisPrecedentDto a, AnalysisPrecedentDto b) =>
              a.finalRank.compareTo(b.finalRank),
        );
    final List<AnalysisPrecedentDto> associatedPrecedents = sortedPrecedents
        .where((AnalysisPrecedentDto item) => item.isChosen)
        .toList(growable: false);
    final List<AnalysisPrecedentDto> precedentsForReport =
        associatedPrecedents.isNotEmpty
        ? associatedPrecedents
        : sortedPrecedents;

    doc.addPage(_buildHeaderPage(report, generatedAt));
    doc.addPage(_buildCaseSummaryPage(report, generatedAt));
    doc.addPage(_buildJudgmentDraftPage(report, generatedAt));
    doc.addPage(
      _buildPrecedentsPage(
        precedents: precedentsForReport,
        generatedAt: generatedAt,
      ),
    );

    return doc.save();
  }

  pw.Page _buildHeaderPage(
    SecondInstanceAnalysisReportDto report,
    DateTime generatedAt,
  ) {
    return pw.Page(
      pageTheme: _buildPageTheme(),
      build: (pw.Context context) {
        return _buildStaticPage(
          context: context,
          stripeWidth: 156,
          generatedAt: generatedAt,
          content: <pw.Widget>[
            _buildBrandHeader(),
            pw.SizedBox(height: 12),
            _buildSectionTitle(
              'Relatório de análise de segunda instância',
              fontSize: 24,
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              _buildReportSubtitle(report),
              style: pw.TextStyle(color: _theme.textMuted, fontSize: 13),
            ),
            pw.SizedBox(height: 16),
            _buildDivider(height: 2),
            pw.SizedBox(height: 14),
            _buildEyebrow('DADOS DA ANÁLISE'),
            pw.SizedBox(height: 10),
            _buildMetaRow('Nome da análise', report.analysis.name),
            _buildMetaRow(
              'Criada em',
              _formatDateTime(_parseDate(report.analysis.createdAt)),
            ),
            pw.SizedBox(height: 12),
            _buildDivider(height: 2),
            pw.SizedBox(height: 14),
            _buildEyebrow('DOCUMENTO E FILTROS'),
            pw.SizedBox(height: 10),
            _buildMetaRow('Arquivo', report.document.name),
            _buildMetaRow('Filtros aplicados', _buildUploadAndFilters(report)),
          ],
        );
      },
    );
  }

  pw.Page _buildCaseSummaryPage(
    SecondInstanceAnalysisReportDto report,
    DateTime generatedAt,
  ) {
    return pw.MultiPage(
      pageTheme: _buildPageTheme(),
      header: (pw.Context context) =>
          _buildPageChrome(context: context, stripeWidth: 176),
      footer: (pw.Context context) =>
          _buildFooter(context: context, generatedAt: generatedAt),
      build: (pw.Context context) {
        return <pw.Widget>[
          _buildSectionTitle('Resumo do caso', fontSize: 22),
          pw.SizedBox(height: 16),
          _buildEyebrow('RESUMO DO CASO'),
          pw.SizedBox(height: 8),
          _buildTextCard(report.caseSummary.caseSummary),
          pw.SizedBox(height: 12),
          _buildEyebrow('QUESTÃO CENTRAL'),
          pw.SizedBox(height: 8),
          _buildHighlightTextCard(report.caseSummary.centralQuestion),
          pw.SizedBox(height: 12),
          _buildEyebrow('QUESTÕES JURÍDICAS'),
          pw.SizedBox(height: 8),
          _buildTextCard(_buildLegalIssuesSummary(report)),
          pw.SizedBox(height: 12),
          _buildEyebrow('FATOS E PEDIDOS RELEVANTES'),
          pw.SizedBox(height: 6),
          _buildStructuredList(
            _buildCaseSummaryHighlights(report),
            ordered: true,
          ),
          pw.SizedBox(height: 12),
          _buildEyebrow('LEIS E FILTROS DE PRECEDENTES'),
          pw.SizedBox(height: 6),
          _buildStructuredList(_buildSearchAndLawHighlights(report)),
        ];
      },
    );
  }

  pw.Page _buildPrecedentsPage({
    required List<AnalysisPrecedentDto> precedents,
    required DateTime generatedAt,
  }) {
    return pw.MultiPage(
      pageTheme: _buildPageTheme(),
      header: (pw.Context context) =>
          _buildPageChrome(context: context, stripeWidth: 190),
      footer: (pw.Context context) =>
          _buildFooter(context: context, generatedAt: generatedAt),
      build: (pw.Context context) {
        return <pw.Widget>[
          _buildSectionTitle('Precedentes escolhidos', fontSize: 22),
          pw.SizedBox(height: 8),
          if (precedents.isEmpty)
            _buildTextCard('Nenhum precedente associado à minuta.')
          else
            ...precedents.map(
              (AnalysisPrecedentDto precedent) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: _buildPrecedentCard(
                  precedent,
                  highlight: precedent.isChosen,
                ),
              ),
            ),
        ];
      },
    );
  }

  pw.Page _buildJudgmentDraftPage(
    SecondInstanceAnalysisReportDto report,
    DateTime generatedAt,
  ) {
    return pw.MultiPage(
      pageTheme: _buildPageTheme(),
      header: (pw.Context context) =>
          _buildPageChrome(context: context, stripeWidth: 164),
      footer: (pw.Context context) =>
          _buildFooter(context: context, generatedAt: generatedAt),
      build: (pw.Context context) {
        return <pw.Widget>[
          _buildSectionTitle('Minuta do julgamento', fontSize: 22),
          pw.SizedBox(height: 4),
          pw.Text(
            'Campos da minuta agrupados para compor a decisão.',
            style: pw.TextStyle(color: _theme.textMuted, fontSize: 12),
          ),
          pw.SizedBox(height: 12),
          _buildDivider(),
          pw.SizedBox(height: 12),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              _buildDraftSection(
                title: 'RELATÓRIO',
                content: report.judgmentDraft.report,
              ),
              if (_hasContent(report.judgmentDraft.preliminaryIssues))
                _buildDraftSection(
                  title: 'PRELIMINARES',
                  content: report.judgmentDraft.preliminaryIssues!,
                  italic: true,
                ),
              _buildDraftSection(
                title: 'MÉRITO',
                content: report.judgmentDraft.meritAnalysis,
              ),
              _buildDraftSection(
                title: 'ADERÊNCIA AOS PRECEDENTES',
                content: report.judgmentDraft.precedentAdherenceAnalysis,
              ),
              _buildDraftListSection(
                title: 'DISPOSITIVO',
                values: report.judgmentDraft.ruling,
              ),
              if (_hasContent(report.judgmentDraft.noApplicablePrecedentNotice))
                _buildDraftSection(
                  title: 'AVISO OPCIONAL',
                  content: report.judgmentDraft.noApplicablePrecedentNotice!,
                  muted: true,
                  italic: true,
                ),
            ],
          ),
        ];
      },
    );
  }

  pw.Widget _buildPrecedentCard(
    AnalysisPrecedentDto precedent, {
    bool highlight = false,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: highlight ? _theme.highlightFill : PdfColors.white,
        border: pw.Border.all(
          color: highlight ? _theme.accent : _theme.divider,
          width: highlight ? 1.5 : 0.5,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <pw.Widget>[
              _buildPrecedentChip(precedent.precedent.identifier.court.value),
              _buildPrecedentDivider(),
              _buildPrecedentChip(
                _theme.formatKindLabel(precedent.precedent.identifier.kind),
              ),
              _buildPrecedentDivider(),
              _buildPrecedentChip(
                precedent.precedent.identifier.number.toString(),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Expanded(
                child: pw.Text(
                  'Similaridade ${_buildSimilarityPercent(precedent)}',
                  style: pw.TextStyle(
                    color: _theme.textMuted,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              _buildApplicabilityBadge(precedent.applicabilityLevel),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Nivel de aplicabilidade: ${_buildApplicabilityLabel(precedent.applicabilityLevel)}',
            style: pw.TextStyle(
              color: _theme.textMuted,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildField(
            title: 'ENUNCIADO',
            content: _truncateForPdf(
              precedent.precedent.enunciation,
              maxChars: 650,
            ),
            titleColor: _theme.textMuted,
          ),
          if (_hasContent(precedent.precedent.thesis)) ...<pw.Widget>[
            pw.SizedBox(height: 12),
            _buildField(
              title: 'TESE FIRMADA',
              content: _truncateForPdf(
                precedent.precedent.thesis,
                maxChars: 700,
              ),
              titleColor: _theme.textMuted,
            ),
          ],
          pw.SizedBox(height: 12),
          _buildField(
            title: 'SÍNTESE',
            content: _truncateForPdf(precedent.synthesis, maxChars: 420),
            titleColor: _theme.textMuted,
            contentColor: _theme.textSecondary,
            italicContent: true,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildApplicabilityBadge(
    AnalysisPrecedentApplicabilityLevelDto level,
  ) {
    final ({String label, PdfColor background, PdfColor text}) badge =
        _buildApplicabilityBadgeData(level);

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

  ({String label, PdfColor background, PdfColor text})
  _buildApplicabilityBadgeData(AnalysisPrecedentApplicabilityLevelDto level) {
    switch (level) {
      case AnalysisPrecedentApplicabilityLevelDto.applicable:
        return (
          label: 'Aplicavel',
          background: const PdfColor(0.91, 0.98, 0.95),
          text: _theme.success,
        );
      case AnalysisPrecedentApplicabilityLevelDto.possiblyApplicable:
        return (
          label: 'Possivelmente aplicavel',
          background: _theme.pageBadgeFill,
          text: _theme.accentStrong,
        );
      case AnalysisPrecedentApplicabilityLevelDto.notApplicable:
        return (
          label: 'Nao aplicavel',
          background: const PdfColor(0.99, 0.93, 0.92),
          text: _theme.danger,
        );
    }
  }

  String _buildApplicabilityLabel(
    AnalysisPrecedentApplicabilityLevelDto level,
  ) {
    return _buildApplicabilityBadgeData(level).label;
  }

  String _buildSimilarityPercent(AnalysisPrecedentDto precedent) {
    final int similarity = precedent.similarityScore.clamp(0, 100).round();

    return '$similarity%';
  }

  pw.Widget _buildPrecedentChip(String label) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: pw.BoxDecoration(
        color: _theme.surfaceMuted,
        border: pw.Border.all(color: _theme.divider, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Text(
        _nonEmpty(label),
        style: pw.TextStyle(
          color: _theme.textMuted,
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildPrecedentDivider() {
    return pw.Container(width: 1, height: 14, color: _theme.divider);
  }

  pw.Widget _buildDraftSection({
    required String title,
    required String content,
    bool muted = false,
    bool italic = false,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _buildDivider(color: _theme.pageBadgeFill),
        pw.SizedBox(height: 8),
        _buildEyebrow(title),
        pw.SizedBox(height: 4),
        pw.Text(
          _nonEmpty(content),
          style: pw.TextStyle(
            color: muted ? _theme.textMuted : _theme.textPrimary,
            fontSize: 12,
            lineSpacing: 4,
            fontStyle: italic ? pw.FontStyle.italic : null,
          ),
        ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _buildDraftListSection({
    required String title,
    required List<String> values,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _buildDivider(color: _theme.pageBadgeFill),
        pw.SizedBox(height: 8),
        _buildEyebrow(title),
        pw.SizedBox(height: 4),
        _buildStructuredList(values, ordered: true),
        pw.SizedBox(height: 12),
      ],
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: pw.BoxDecoration(
        color: _theme.surfaceMuted,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _theme.divider, width: 0.5),
      ),
      child: pw.Text(
        _nonEmpty(content),
        style: pw.TextStyle(
          color: _theme.textPrimary,
          fontSize: 13,
          lineSpacing: 4,
        ),
      ),
    );
  }

  pw.Widget _buildHighlightTextCard(String content) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: _theme.divider, width: 1),
      ),
      child: pw.Text(
        _nonEmpty(content),
        style: pw.TextStyle(
          color: _theme.textPrimary,
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          lineSpacing: 4,
        ),
      ),
    );
  }

  pw.Widget _buildStructuredList(List<String> values, {bool ordered = false}) {
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
            final String marker = ordered ? '${entry.key + 1}.' : '•';

            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.SizedBox(
                    width: 14,
                    child: pw.Text(
                      marker,
                      style: pw.TextStyle(
                        color: _theme.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      entry.value,
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
            '§',
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

  String _buildReportSubtitle(SecondInstanceAnalysisReportDto report) {
    final String typeOfAction = _nonEmpty(
      report.caseSummary.typeOfAction,
      fallback: 'Apelação cível',
    );

    return '$typeOfAction | minuta orientada por precedentes e aderência jurisprudencial';
  }

  String _buildUploadAndFilters(SecondInstanceAnalysisReportDto report) {
    final searchFilters = report.analysis.precedentsSearchFilters;
    final List<String> values = [];
    if (searchFilters == null) {
      values.add('Nenhum filtro aplicado');
    } else {
      values.addAll(searchFilters.courts.map((court) => court.value));
      values.addAll(searchFilters.precedentKinds.map(_theme.formatKindLabel));
      values.add('Limite ${searchFilters.limit}');
    }

    return _joinValues(values, separator: ' | ');
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

  pw.Widget _buildDivider({double height = 1, PdfColor? color}) {
    return pw.Container(
      width: double.infinity,
      height: height,
      color: color ?? _theme.divider,
    );
  }

  pw.Widget _buildStaticPage({
    required pw.Context context,
    required double stripeWidth,
    required DateTime generatedAt,
    required List<pw.Widget> content,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _buildPageChrome(context: context, stripeWidth: stripeWidth),
        ...content,
        pw.Spacer(),
        _buildFooter(context: context, generatedAt: generatedAt),
      ],
    );
  }

  pw.Widget _buildPageChrome({
    required pw.Context context,
    required double stripeWidth,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 28),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: <pw.Widget>[
          pw.Container(
            width: stripeWidth,
            height: 6,
            decoration: pw.BoxDecoration(
              color: _theme.accent,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
          ),
          pw.SizedBox(width: 1),
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
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: <pw.Widget>[
            pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: pw.TextStyle(color: _theme.textMuted, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  String _buildLegalIssuesSummary(SecondInstanceAnalysisReportDto report) {
    final List<String> parts = <String>[
      report.caseSummary.legalIssue,
      ...report.caseSummary.secondaryLegalIssues,
      if (_hasContent(report.caseSummary.jurisdictionIssue))
        'Competência: ${report.caseSummary.jurisdictionIssue!}',
      if (_hasContent(report.caseSummary.standingIssue))
        'Legitimidade: ${report.caseSummary.standingIssue!}',
    ];

    return _joinValues(parts, separator: '\n');
  }

  List<String> _buildCaseSummaryHighlights(
    SecondInstanceAnalysisReportDto report,
  ) {
    return <String>[
      ...report.caseSummary.keyFacts,
      ...report.caseSummary.requestedRelief.map(
        (String item) => 'Pedido: $item',
      ),
      ...report.caseSummary.proceduralIssues.map(
        (String item) => 'Questão processual: $item',
      ),
      ...report.caseSummary.excludedOrAccessoryTopics.map(
        (String item) => 'Observação: $item',
      ),
    ];
  }

  List<String> _buildSearchAndLawHighlights(
    SecondInstanceAnalysisReportDto report,
  ) {
    final searchFilters = report.analysis.precedentsSearchFilters;

    return <String>[
      ...report.caseSummary.relevantLaws,
      ...?searchFilters?.courts.map((court) => 'Tribunal: ${court.value}'),
      ...?searchFilters?.precedentKinds.map(
        (kind) => 'Tipo de precedente: ${_theme.formatKindLabel(kind)}',
      ),
      if (searchFilters != null) 'Limite: ${searchFilters.limit}',
      if (_hasContent(report.caseSummary.typeOfAction))
        'Tipo de ação: ${report.caseSummary.typeOfAction!}',
    ];
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

  String _joinValues(Iterable<String?> values, {String separator = ' · '}) {
    final List<String> sanitizedValues = values
        .map((String? value) => value?.trim() ?? '')
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);

    if (sanitizedValues.isEmpty) {
      return '-';
    }

    return sanitizedValues.join(separator);
  }

  bool _hasContent(String? value) {
    return value != null && value.trim().isNotEmpty;
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

  pw.PageTheme _buildPageTheme() {
    return pw.PageTheme(
      margin: const pw.EdgeInsets.all(48),
      pageFormat: PdfPageFormat.a4,
      buildBackground: (pw.Context context) {
        return pw.Container(color: _theme.surfacePage);
      },
    );
  }
}
