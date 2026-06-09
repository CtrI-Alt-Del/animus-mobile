prd: https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/49053697
ticket: N/A
status: closed
last_updated: 2026-06-06

# Exportação da minuta de petição em DOCX (mobile)

## Objetivo

Permitir que o advogado exporte a minuta de petição em DOCX a partir da tela de Case Assessment. O mobile chama o endpoint de exportação no server, recebe o `file_path` do DOCX gerado no GCS, baixa o arquivo e abre o share sheet nativo.

---

## Escopo

### In-scope

- Adicionar método `exportPetitionDraft(...)` ao `IntakeService`
- Implementar no `IntakeRestService`: `POST /intake/analyses/{analysis_id}/petition-drafts/export` (status 201)
- Criar DTO `ExportedDocumentDto` com campo `filePath`
- Criar mapper `ExportedDocumentMapper`
- Baixar o DOCX do GCS via `FileStorageDriver.getFile(filePath)` (já existente)
- Compartilhar o arquivo via share sheet nativo
- Adicionar ação "Exportar minuta" no header do `PetitionDraftDialog`
- Controlar estado de exportação (`isExportingDraft`) no `PetitionDraftDialogPresenter`

### Out-of-scope

- Server (endpoint já coberto em ticket próprio)
- Geração do DOCX (responsabilidade do server com `python-docx`)
- Exportação da minuta de sentença de 2ª instância em DOCX
- Alterações no fluxo de exportação do relatório PDF (RF 06)

---

## DTO novo

```dart
class ExportedDocumentDto {
  final String filePath;

  const ExportedDocumentDto({required this.filePath});
}
```

---

## Contrato REST

```
POST /intake/analyses/{analysis_id}/petition-drafts/export
Status: 201
Response: { "file_path": "intake/analyses/{analysis_id}/documents/{file_id}.docx" }
```

---

## Fluxo

1. Advogado toca em "Exportar minuta" no header do `PetitionDraftDialog`
2. Presenter valida que o form está válido (nenhum campo vazio)
3. Presenter seta `isExportingDraft = true`
3. Chama `IntakeService.exportPetitionDraft(analysisId)` → recebe `ExportedDocumentDto` com `filePath`
4. Chama `FileStorageDriver.getFile(filePath)` → baixa do GCS, retorna `File` em diretório temporário
5. Compartilha o `File` via share sheet nativo
6. Presenter seta `isExportingDraft = false`
7. Em falha: exibe `generalError` com mensagem amigável

---

## Compartilhamento do arquivo

O `PdfDriver.sharePdf(...)` existente usa `Printing.sharePdf` que aceita apenas `Uint8List` de PDF. Para DOCX, é necessário um mecanismo de compartilhamento genérico de arquivos.

Duas opções:

**Opção A — Adicionar método `shareFile(File, String filename)` ao `PdfDriver` (renomeado ou não):** reutiliza o driver existente, mas o nome `PdfDriver` fica semanticamente descolado.

**Opção B — Criar `FileShareDriver` com método `shareFile(File, String filename)`:** driver novo e específico para compartilhamento genérico de arquivos. Implementação concreta usa `share_plus` ou `open_filex`.

> Decisão pendente — escolher entre A e B antes da implementação.

---

## Mudanças no IntakeService

- **Arquivo:** `lib/core/intake/interfaces/intake_service.dart`
- **Método novo:** `Future<RestResponse<ExportedDocumentDto>> exportPetitionDraft({required String analysisId})`

---

## Mudanças no IntakeRestService

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`
- **Método novo:** `Future<RestResponse<ExportedDocumentDto>> exportPetitionDraft({required String analysisId})` — chama `POST /intake/analyses/$analysisId/petition-drafts/export`, retorna `toResponse(response, ExportedDocumentMapper.toDto)`.

---

## Mudanças no PetitionDraftDialogPresenter

- **Arquivo:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/petition_draft_dialog_presenter.dart`
- **Dependência nova:** `FileStorageDriver` (para download do GCS)
- **Signal novo:** `isExportingDraft: Signal<bool>`
- **Método novo:** `Future<bool> exportPetitionDraft()` — orquestra o fluxo: chama `IntakeService.exportPetitionDraft(analysisId)` → recebe `file_path` → chama `FileStorageDriver.getFile(filePath)` → compartilha via share sheet → trata erro.
- **Filename:** `[Nome da análise] — Minuta.docx` (recebe `analysisName` como parâmetro do provider, usando o mesmo padrão de sanitização do `_buildReportFilename` existente na screen).

---

## Mudanças na PetitionDraftDialogView

- **Arquivo:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/petition_draft_dialog_view.dart`
- **Mudança:** adicionar botão "Exportar minuta" no header do dialog (AppBar), ao lado do botão "Regerar minuta" já existente.
- **Estado:** indicador de carregamento enquanto `isExportingDraft == true`; botão desabilitado durante exportação e durante save com erro (form inválido).
- **Bloqueio:** exportação bloqueada se algum campo estiver vazio (form inválido).

---

## Critérios de aceite

- [ ] Botão "Exportar minuta" visível no header do `PetitionDraftDialog`
- [ ] Botão desabilitado quando o form está inválido (campo vazio)
- [ ] Exportação chama POST, recebe `file_path`, baixa do GCS e abre share sheet
- [ ] Nome do arquivo compartilhado segue `[Nome da análise] — Minuta.docx`
- [ ] Indicador de carregamento durante exportação
- [ ] Tentativas concorrentes bloqueadas durante exportação
- [ ] Erro no POST ou download exibe mensagem amigável sem perder estado da tela
- [ ] Exportação PDF do relatório continua funcionando independentemente
