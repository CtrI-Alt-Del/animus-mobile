import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:animus/core/intake/dtos/analysis_document_dto.dart';
import 'package:animus/theme.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/support_documents_section/support_document_item/support_document_item_view.dart';
import 'package:animus/ui/intake/widgets/pages/case_assessment_analysis_screen/briefing_form_card/support_documents_section/support_documents_section_presenter.dart';

class SupportDocumentsSectionView extends ConsumerWidget {
  final String analysisId;
  final bool enabled;

  const SupportDocumentsSectionView({
    required this.analysisId,
    required this.enabled,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SupportDocumentsSectionPresenter presenter = ref.watch(
      supportDocumentsSectionPresenterProvider(analysisId),
    );
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Documentos de apoio',
                style: textTheme.titleSmall?.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Anexe arquivos PDF ou DOCX com até ${presenter.formatFileSize(SupportDocumentsSectionPresenter.maxFileSizeInBytes)} por arquivo.',
                style: textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Watch((BuildContext context) {
                  final bool isPicking = presenter.isPicking.watch(context);
                  final bool canAddDocument = presenter.canAddDocument.watch(
                    context,
                  );

                  return OutlinedButton.icon(
                    onPressed: enabled && canAddDocument
                        ? () => unawaited(presenter.addSupportDocument())
                        : null,
                    icon: isPicking
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: tokens.accent,
                            ),
                          )
                        : const Icon(Icons.attach_file_rounded, size: 18),
                    label: Text(
                      isPicking ? 'Selecionando...' : 'Adicionar documento',
                      style: textTheme.bodyMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Watch((BuildContext context) {
            final String? error = presenter.generalError.watch(context);
            if (error == null || error.isEmpty) {
              return const SizedBox.shrink();
            }

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: tokens.danger.withValues(alpha: 0.24),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.error_outline, size: 16, color: tokens.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error,
                      style: textTheme.bodySmall?.copyWith(
                        color: tokens.danger,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Watch((BuildContext context) {
            final List<AnalysisDocumentDto> documents = presenter.documents
                .watch(context);
            final Map<String, double?> uploadingDocuments = presenter
                .uploadingDocuments
                .watch(context);

            final List<Widget> items = <Widget>[
              ...uploadingDocuments.entries.map((
                MapEntry<String, double?> entry,
              ) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SupportDocumentItemView(
                    document: AnalysisDocumentDto(
                      analysisId: analysisId,
                      uploadedAt: '',
                      filePath: entry.key,
                      name: entry.key,
                    ),
                    progress: entry.value,
                    isUploading: true,
                    enabled: false,
                    onRemove: null,
                  ),
                );
              }),
              ...documents.map((AnalysisDocumentDto document) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SupportDocumentItemView(
                    document: document,
                    progress: null,
                    isUploading: false,
                    enabled: enabled,
                    onRemove: enabled
                        ? () => unawaited(
                            presenter.removeSupportDocument(document),
                          )
                        : null,
                  ),
                );
              }),
            ];

            if (items.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tokens.borderSubtle),
                ),
                child: Text(
                  'Nenhum documento de apoio anexado até o momento.',
                  style: textTheme.bodySmall?.copyWith(color: tokens.textMuted),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items,
            );
          }),
        ],
      ),
    );
  }
}
