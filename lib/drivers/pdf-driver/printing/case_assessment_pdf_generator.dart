import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:animus/core/intake/dtos/analysis_precedent_applicability_level_dto.dart';
import 'package:animus/core/intake/dtos/analysis_precedent_dto.dart';
import 'package:animus/core/intake/dtos/case_assessment_analysis_report_dto.dart';
import 'package:animus/drivers/pdf-driver/printing/animus_pdf_theme.dart';

class CaseAssessmentPdfGenerator {
  final AnimusPdfTheme _theme;

  const CaseAssessmentPdfGenerator({required AnimusPdfTheme theme})
    : _theme = theme;

  Future<Uint8List> generate({
    required CaseAssessmentAnalysisReportDto report,
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
    final List<AnalysisPrecedentDto> chosenPrecedents = sortedPrecedents
        .where((AnalysisPrecedentDto precedent) => precedent.isChosen)
        .toList(growable: false);
    final List<AnalysisPrecedentDto> precedentsForReport =
        chosenPrecedents.isNotEmpty ? chosenPrecedents : sortedPrecedents;

    doc.addPage(_buildOverviewPage(report, generatedAt));
    doc.addPage(_buildCaseSummaryPage(report, generatedAt));
    doc.addPage(_buildPetitionDraftPage(report, generatedAt));
    doc.addPage(_buildPrecedentsPage(precedentsForReport, generatedAt));

    return doc.save();
  }

  pw.MultiPage _buildOverviewPage(
    CaseAssessmentAnalysisReportDto report,
    DateTime generatedAt,
  ) {
    return pw.MultiPage(
      pageTheme: _buildPageTheme(),
      footer: (pw.Context context) => _buildFooter(generatedAt),
      build: (pw.Context context) {
        return <pw.Widget>[
          _buildTitle('Relatório de análise do caso'),
          pw.SizedBox(height: 8),
          _buildSubtitle('Documento: ${_safe(report.document.name)}'),
          pw.SizedBox(height: 20),
          _buildSectionLabel('DADOS DA ANÁLISE'),
          pw.SizedBox(height: 10),
          _buildInfoCard(<({String label, String value})>[
            (label: 'Nome da análise', value: _safe(report.analysis.name)),
            (
              label: 'Criada em',
              value: _formatDateTime(_parseDate(report.analysis.createdAt)),
            ),
            (label: 'Gerado em', value: _formatDateTime(generatedAt)),
          ]),
          pw.SizedBox(height: 16),
          _buildSectionLabel('DADOS DO DOCUMENTO'),
          pw.SizedBox(height: 10),
          _buildInfoCard(<({String label, String value})>[
            (label: 'Arquivo', value: _safe(report.document.name)),
            (
              label: 'Upload em',
              value: _formatDateTime(_parseDate(report.document.uploadedAt)),
            ),
            (
              label: 'Precedentes escolhidos',
              value: precedentsCountLabel(report.precedents),
            ),
          ]),
        ];
      },
    );
  }

  pw.MultiPage _buildCaseSummaryPage(
    CaseAssessmentAnalysisReportDto report,
    DateTime generatedAt,
  ) {
    return pw.MultiPage(
      pageTheme: _buildPageTheme(),
      footer: (pw.Context context) => _buildFooter(generatedAt),
      build: (pw.Context context) {
        return <pw.Widget>[
          _buildTitle('Resumo do caso'),
          pw.SizedBox(height: 16),
          _buildLabeledText('RESUMO DO CASO', report.caseSummary.caseSummary),
          _buildLabeledText(
            'QUESTÃO CENTRAL',
            report.caseSummary.centralQuestion,
          ),
          _buildLabeledText(
            'ENQUADRAMENTO JURÍDICO',
            report.caseSummary.legalIssue,
          ),
          _buildLabeledList(
            'FATOS RELEVANTES',
            report.caseSummary.keyFacts,
            ordered: true,
          ),
          _buildLabeledList(
            'LEGISLAÇÃO APLICÁVEL',
            report.caseSummary.relevantLaws,
          ),
        ];
      },
    );
  }

  pw.MultiPage _buildPetitionDraftPage(
    CaseAssessmentAnalysisReportDto report,
    DateTime generatedAt,
  ) {
    return pw.MultiPage(
      pageTheme: _buildPageTheme(),
      footer: (pw.Context context) => _buildFooter(generatedAt),
      build: (pw.Context context) {
        return <pw.Widget>[
          _buildTitle('Minuta da petição inicial'),
          pw.SizedBox(height: 16),
          _buildLabeledText(
            'FATOS ESTRUTURADOS',
            report.petitionDraft.structuredFacts,
          ),
          _buildLabeledText(
            'FUNDAMENTOS JURÍDICOS',
            report.petitionDraft.legalGrounds,
          ),
          _buildLabeledText('TESE CENTRAL', report.petitionDraft.centralThesis),
          _buildLabeledList('PEDIDOS', report.petitionDraft.requests),
          _buildLabeledList(
            'CITAÇÕES DE PRECEDENTES',
            report.petitionDraft.precedentCitations,
          ),
        ];
      },
    );
  }

  pw.MultiPage _buildPrecedentsPage(
    List<AnalysisPrecedentDto> precedents,
    DateTime generatedAt,
  ) {
    return pw.MultiPage(
      pageTheme: _buildPageTheme(),
      footer: (pw.Context context) => _buildFooter(generatedAt),
      build: (pw.Context context) {
        return <pw.Widget>[
          _buildTitle('Precedentes escolhidos'),
          pw.SizedBox(height: 12),
          if (precedents.isEmpty)
            _buildBodyCard('Nenhum precedente escolhido para a minuta.')
          else
            ...precedents.map(
              (AnalysisPrecedentDto precedent) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: _buildPrecedentCard(precedent),
              ),
            ),
        ];
      },
    );
  }

  pw.Widget _buildPrecedentCard(AnalysisPrecedentDto precedent) {
    final String court = precedent.precedent.identifier.court.value;
    final String kind = _theme.formatKindLabel(
      precedent.precedent.identifier.kind,
    );
    final String number = precedent.precedent.identifier.number.toString();

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: precedent.isChosen ? _theme.highlightFill : _theme.surfaceCard,
        border: pw.Border.all(
          color: precedent.isChosen ? _theme.accentStrong : _theme.divider,
          width: precedent.isChosen ? 1.1 : 0.7,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Expanded(
                child: pw.Text(
                  '$court · $kind $number',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _theme.textPrimary,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              _buildBadge(_buildApplicabilityLabel(precedent)),
            ],
          ),
          pw.SizedBox(height: 8),
          _buildLabeledTextInline('ENUNCIADO', precedent.precedent.enunciation),
          if (_hasContent(precedent.precedent.thesis))
            _buildLabeledTextInline('TESE FIRMADA', precedent.precedent.thesis),
          _buildLabeledTextInline('SÍNTESE', precedent.synthesis),
        ],
      ),
    );
  }

  pw.Widget _buildTitle(String value) {
    return pw.Text(
      value,
      style: pw.TextStyle(
        fontSize: 22,
        fontWeight: pw.FontWeight.bold,
        color: _theme.textPrimary,
      ),
    );
  }

  pw.Widget _buildSubtitle(String value) {
    return pw.Text(
      value,
      style: pw.TextStyle(fontSize: 12, color: _theme.textMuted),
    );
  }

  pw.Widget _buildSectionLabel(String value) {
    return pw.Text(
      value,
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: _theme.accentStrong,
        letterSpacing: 1.1,
      ),
    );
  }

  pw.Widget _buildSmallLabel(String value) {
    return pw.Text(
      value,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: _theme.textMuted,
      ),
    );
  }

  pw.Widget _buildInfoCard(List<({String label, String value})> items) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _theme.surfaceCard,
        border: pw.Border.all(color: _theme.divider, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: items
            .map(
              (({String label, String value}) item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: <pw.InlineSpan>[
                      pw.TextSpan(
                        text: '${item.label}: ',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: _theme.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                      pw.TextSpan(
                        text: item.value,
                        style: pw.TextStyle(
                          color: _theme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  pw.Widget _buildLabeledText(String label, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          _buildSectionLabel(label),
          pw.SizedBox(height: 6),
          _buildBodyCard(text),
        ],
      ),
    );
  }

  pw.Widget _buildLabeledTextInline(String label, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          _buildSmallLabel(label),
          pw.SizedBox(height: 4),
          pw.Text(
            _safe(text),
            style: pw.TextStyle(
              fontSize: 12,
              color: _theme.textSecondary,
              lineSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildLabeledList(
    String label,
    List<String> items, {
    bool ordered = false,
  }) {
    final List<String> normalizedItems = items
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          _buildSectionLabel(label),
          pw.SizedBox(height: 6),
          if (normalizedItems.isEmpty)
            _buildBodyCard('-')
          else
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: _theme.surfaceCard,
                border: pw.Border.all(color: _theme.divider, width: 0.8),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: normalizedItems
                    .asMap()
                    .entries
                    .map((entry) {
                      final int index = entry.key;
                      final String value = entry.value;
                      final String prefix = ordered ? '${index + 1}.' : '•';

                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 6),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: <pw.Widget>[
                            pw.Text(
                              '$prefix ',
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: _theme.textPrimary,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                value,
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  color: _theme.textSecondary,
                                  lineSpacing: 3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildBodyCard(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _theme.surfaceCard,
        border: pw.Border.all(color: _theme.divider, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Text(
        _safe(text),
        style: pw.TextStyle(
          fontSize: 12,
          color: _theme.textSecondary,
          lineSpacing: 3,
        ),
      ),
    );
  }

  pw.Widget _buildBadge(String label) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _theme.pageBadgeFill,
        border: pw.Border.all(color: _theme.accentStrong, width: 0.7),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 10,
          color: _theme.accentStrong,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildFooter(DateTime generatedAt) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text(
            'Animus',
            style: pw.TextStyle(fontSize: 10, color: _theme.textMuted),
          ),
          pw.Text(
            _formatDateTime(generatedAt),
            style: pw.TextStyle(fontSize: 10, color: _theme.textMuted),
          ),
        ],
      ),
    );
  }

  pw.PageTheme _buildPageTheme() {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
    );
  }

  String precedentsCountLabel(List<AnalysisPrecedentDto> precedents) {
    final int chosenCount = precedents
        .where((AnalysisPrecedentDto precedent) => precedent.isChosen)
        .length;

    return '$chosenCount selecionado(s)';
  }

  String _buildApplicabilityLabel(AnalysisPrecedentDto precedent) {
    if (precedent.isManuallyAdded) {
      return 'Adicionado manualmente';
    }

    switch (precedent.applicabilityLevel) {
      case AnalysisPrecedentApplicabilityLevelDto.applicable:
        return 'Aplicável';
      case AnalysisPrecedentApplicabilityLevelDto.possiblyApplicable:
        return 'Possivelmente aplicável';
      case AnalysisPrecedentApplicabilityLevelDto.notApplicable:
        return 'Não aplicável';
    }
  }

  bool _hasContent(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  String _safe(String? value) {
    if (value == null) {
      return '-';
    }

    final String trimmed = value.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }

  DateTime _parseDate(String? value) {
    if (value == null) {
      return DateTime.now();
    }

    return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
  }

  String _formatDateTime(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/${value.year} $hour:$minute';
  }
}
