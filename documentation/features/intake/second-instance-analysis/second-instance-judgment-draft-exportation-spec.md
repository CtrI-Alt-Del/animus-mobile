prd: https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/49348609
ticket: N/A

# Exportação da minuta de sentença de 2ª instância em DOCX (mobile)

## Objetivo

Permitir que o juiz exporte a minuta de sentença em DOCX a partir do `JudgmentDraftDialog`. O mobile chama o endpoint de exportação no server, recebe `AnalysisDocumentDto` com o `filePath` do DOCX gerado no GCS, baixa o arquivo via `FileStorageDriver` e abre o share sheet nativo. O botão de exportação vive no header do dialog, consistente com o padrão do `PetitionDraftDialog`.

---

## Escopo

### In-scope

- Adicionar método `exportJudgmentDraft(...)` ao `IntakeService`
- Implementar no `IntakeRestService`: `POST /intake/analyses/{analysis_id}/second-instance-judgment-drafts/export` (status 201)
- Adicionar `isExportingDraft: Signal<bool>` ao `JudgmentDraftDialogPresenter`
- Adicionar método `exportJudgmentDraft()` ao `JudgmentDraftDialogPresenter`
- Adicionar botão "Exportar minuta" no header do `JudgmentDraftDialog`
- Baixar o DOCX do GCS via `FileStorageDriver.getFile(filePath)` (já existente)
- Compartilhar o arquivo via share sheet nativo
- Bloquear exportação concorrente durante processamento

### Out-of-scope

- Server (endpoint já coberto em ticket próprio)
- Geração do DOCX (responsabilidade do server)
- Edição da minuta de sentença (ticket separado)
- Exportação da minuta de petição em DOCX (ticket separado)
- Alterações no relatório PDF existente

---

## Contrato REST

```
POST /intake/analyses/{analysis_id}/second-instance-judgment-drafts/export
Status: 201
Response: AnalysisDocumentDto {
  analysis_id: String
  uploaded_at: String
  file_path: String
  name: String
}
```

O `AnalysisDocumentDto` e o `AnalysisDocumentMapper` já existem no mobile — reutilizar.

---

## Fluxo

1. Juiz toca em "Exportar minuta" no header do `JudgmentDraftDialog`
2. Presenter seta `isExportingDraft = true`, botão desabilitado
3. Chama `IntakeService.exportJudgmentDraft(analysisId)` → recebe `AnalysisDocumentDto`
4. Chama `FileStorageDriver.getFile(filePath)` → baixa do GCS, retorna `File` em diretório temporário
5. Compartilha o `File` via share sheet nativo com nome `[Nome da análise] — Minuta de Sentença.docx`
6. Presenter seta `isExportingDraft = false`
7. Em falha: exibe `generalError` com mensagem amigável

---

## Mudanças no IntakeService

- **Arquivo:** `lib/core/intake/interfaces/intake_service.dart`
- **Método novo:** `Future<RestResponse<AnalysisDocumentDto>> exportJudgmentDraft({required String analysisId})`

---

## Mudanças no IntakeRestService

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`
- **Método novo:** `Future<RestResponse<AnalysisDocumentDto>> exportJudgmentDraft({required String analysisId})` — chama `POST /intake/analyses/$analysisId/second-instance-judgment-drafts/export`, retorna `toResponse(response, AnalysisDocumentMapper.toDto)`.

---

## Mudanças no JudgmentDraftDialogPresenter

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_presenter.dart`
- **Dependências novas:** `IntakeService`, `FileStorageDriver`, `analysisName: String`
- **Signal novo:** `isExportingDraft: Signal<bool>`
- **Método novo:** `Future<bool> exportJudgmentDraft()` — seta `isExportingDraft = true`, chama `IntakeService.exportJudgmentDraft(analysisId)`, recebe `AnalysisDocumentDto`, chama `FileStorageDriver.getFile(filePath)`, compartilha via share sheet com filename sanitizado usando o mesmo padrão de `_buildReportFilename` da screen mas com extensão `.docx`; em falha seta `generalError`; sempre seta `isExportingDraft = false` no `finally`.

---

## Mudanças no JudgmentDraftDialogView

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_view.dart`
- **Mudança:** adicionar botão "Exportar minuta" no `AppBar` ao lado do botão "Regerar minuta" já existente.
- **Estado:** botão desabilitado quando `isExportingDraft == true`; indicador de carregamento discreto durante exportação.

---

## Critérios de aceite

- [ ] Botão "Exportar minuta" visível no header do `JudgmentDraftDialog`
- [ ] Exportação chama POST, recebe `AnalysisDocumentDto`, baixa do GCS e abre share sheet
- [ ] Nome do arquivo compartilhado segue `[Nome da análise] — Minuta de Sentença.docx`
- [ ] Botão desabilitado durante exportação em andamento
- [ ] Tentativas concorrentes bloqueadas
- [ ] Erro no POST ou download exibe mensagem amigável sem fechar o dialog
- [ ] Exportação do relatório PDF na screen continua funcionando independentemente