---
title: Plano de Implementação — Tela de análise de caso pelo advogado (Case Assessment)
spec: ../specs/case-assessment-analysis-screen-spec.md
created_at: 2026-05-24
status: closed
---

---

## Análise de Dependências

### Artefatos do `core` que desbloqueiam outras camadas

Nenhum artefato novo no `core` é exigido por esta tarefa. Os contratos abaixo já existem e são consumidos integralmente:

- `IntakeService` (`lib/core/intake/interfaces/intake_service.dart`) — `getAnalysis`, `createAnalysisDocument`, `getAnalysisDocument`, `updateAnalysisStatus`, `getCaseSummary`, `triggerFirstInstanceCaseSummarization`, `getPetitionDraft`, `getCaseAssessmentAnalysisReport`, `renameAnalysis`, `archiveAnalysis`.
- `StorageService` — `generateAnalysisDocumentUploadUrl`.
- `AnalysisStatusDto`, `AnalysisDto`, `AnalysisDocumentDto`, `CaseSummaryDto`, `PetitionDraftDto`, `CaseAssessmentAnalysisReportDto`, `AnalysisTypeDto.caseAssessment`.
- `PdfDriver` (interface) — o método `generateCaseAssessmentReport(...)` é uma pendência da spec (10.1); presenter trata ausência com `MessageBox`.
- `DocumentPickerDriver`, `FileStorageDriver`, `CacheDriver`.

### Partes de `rest` e `drivers` independentes entre si

Nenhuma alteração em `rest` ou `drivers` é necessária para esta entrega. Implementações já existem.

### Presenters/widgets/screens paralelizáveis

Todos os widgets internos novos são **independentes entre si** e podem ser construídos em paralelo após o `Presenter` da Screen ter sua assinatura definida (props consumidas):

- `GeneratePetitionDraftCard` (View only, sem props) — totalmente independente.
- `PetitionDraftCard` + `PreviewSection` (View only, props: `draft`, `onOpenModal`, `onRegenerate?`) — pode ser feito antes do presenter da screen, pois consome diretamente `PetitionDraftDto`.
- `PetitionDraftModal` (View only, props: `draft`) — pode ser feito antes do presenter da screen.
- `CaseAssessmentAnalysisScreenPresenter` — central; pode iniciar em paralelo aos widgets internos, pois os widgets não dependem do presenter (apenas consomem props tipadas).
- `CaseAssessmentAnalysisScreenView` — depende do `Presenter` e dos widgets internos para compor.
- Atualização de `Routes` (Constants) e `router.dart` — depende do barrel da Screen estar exportando o widget.

### Tarefas iniciáveis com stub

- Os 3 widgets internos podem ser construídos com `PetitionDraftDto` real (já existe no `core`), sem qualquer stub.
- A `View` da Screen pode ser construída em paralelo ao `Presenter` se o desenvolvedor stubar a API pública do presenter (signals e métodos previstos na spec) — não é necessário pois a spec já define a assinatura completa.

---

## ⚠️ Gargalos identificados

- **F2-T1 (`CaseAssessmentAnalysisScreenPresenter`)**: bloqueia F3-T1 (View da Screen) e F4-T1 (router wiring). É o artefato mais denso da entrega e deve ser priorizado.
- **F3-T1 (`CaseAssessmentAnalysisScreenView`)**: bloqueia F4-T1 (router wiring) e F4-T2 (correção do switch em `Routes.getAnalysis`). Deve ser iniciada assim que o presenter expor os signals e métodos necessários.

---

## Mapa de Paralelização

| Fase | Objetivo | Depende de | Pode rodar em paralelo com |
|------|----------|------------|----------------------------|
| F1   | Criar os 3 widgets internos puros de UI (cards + modal) | — | F2 (presenter da Screen pode ser feito em paralelo aos widgets) |
| F2   | Implementar `CaseAssessmentAnalysisScreenPresenter` + provider | — | F1 |
| F3   | Implementar `CaseAssessmentAnalysisScreenView` + barrel `index.dart` | F1, F2 | — |
| F4   | Registrar rota e corrigir switch de `Routes.getAnalysis` no router | F3 | — |

---

## Fases e Tarefas

### F1 — Widgets internos puros de UI

> Todos os widgets desta fase consomem apenas `PetitionDraftDto` ou nada. Não dependem do Presenter da Screen. Podem ser feitos em paralelo entre si.

- [x] **F1-T1** — Criar `GeneratePetitionDraftCard` (View only)
  - Camada: `ui`
  - Artefato:
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/generate_petition_draft_card/generate_petition_draft_card_view.dart` *(novo)*
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/generate_petition_draft_card/index.dart` *(novo)*
  - Detalhes: card de loading análogo ao `GenerateJudgmentDraftCardView` da 2ª instância, com título "Gerando minuta de petição" e texto auxiliar em PT-BR acentuado.
  - Depende de: —
  - Desbloqueia: F3-T1

- [x] **F1-T2** — Criar `PetitionDraftCard` + `PreviewSection`
  - Camada: `ui`
  - Artefato:
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/petition_draft_card_view.dart` *(novo)*
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/index.dart` *(novo)*
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/preview_section/preview_section_view.dart` *(novo)*
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/preview_section/index.dart` *(novo)*
  - Props do card: `final PetitionDraftDto draft`, `final VoidCallback onOpenModal`, `final VoidCallback? onRegenerate`.
  - Detalhes: cabeçalho "Minuta de petição", `PreviewSection` com preview truncado do `draft.content` (até ~6 linhas com `TextOverflow.ellipsis`), botão "Ver minuta" e (opcional) botão "Regerar minuta". Estilo alinhado ao `JudgmentDraftCardView` da 2ª instância.
  - Depende de: —
  - Desbloqueia: F3-T1

- [x] **F1-T3** — Criar `PetitionDraftModal` (View only)
  - Camada: `ui`
  - Artefato:
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_modal/petition_draft_modal_view.dart` *(novo)*
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_modal/index.dart` *(novo)*
  - Props: `final PetitionDraftDto draft`.
  - Detalhes: `Scaffold` fullscreen com cabeçalho (back button + título "Minuta de petição") e `SingleChildScrollView` exibindo o `draft.content` integral em estilo alinhado ao `JudgmentDraftDialogView` da 2ª instância.
  - Depende de: —
  - Desbloqueia: F3-T1

### F2 — Presenter da Screen

- [x] **F2-T1** — Criar `CaseAssessmentAnalysisScreenPresenter` + provider
  - Camada: `ui`
  - Artefato:
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart` *(novo)*
  - Detalhes: implementar conforme spec seção 5 — constantes (`allowedExtensions`, `maxFileSizeInBytes = 20MB`, `pollingInterval`, `requestTimeout`, mensagens), todos os signals, todos os computeds (`canPickDocument`, `canAnalyzeCase`, `canRegenerateSummary`, `canSearchPrecedents`, `canGeneratePetitionDraft`, `canRegeneratePetitionDraft`, `showCaseProcessingBubble`, `showPetitionDraftProcessingCard`, `canExportReport`, `primaryActionLabel`, `fileActionLabel`), métodos públicos (`load`, `pickDocument`, `analyzeCase`, `reanalyzeCase`, `retrySummary`, `confirmAndViewPrecedents`, `markPrecedentsReady`, `requestPetitionDraft`, `regeneratePetitionDraft`, `replaceDocument`, `renameAnalysis`, `archiveAnalysis`, `exportAnalysisReport`, `fileName`, `formatFileSize`, `dispose`), métodos privados (`_uploadAnalysisDocument`, `_pollUntilCaseReady`, `_pollUntilPetitionDraftReady`, `_tryLoadPetitionDraft`, `_applyFailure`, `_getExtension`, `_buildTimeoutMessage`, `_buildReportFilename`), e o `caseAssessmentAnalysisScreenPresenterProvider` (`Provider.autoDispose.family<CaseAssessmentAnalysisScreenPresenter, String>`).
  - Use como referência: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart` (estrutura de polling/draft) e `lib/ui/intake/widgets/pages/first_instance_analysis_screen/first_instance_analysis_screen_presenter.dart` (export de relatório + cache de `precedentsLimit`).
  - Tratamento de `PdfDriver.generateCaseAssessmentReport`: dentro de `exportAnalysisReport`, envolver a chamada em try/catch e, em caso de `UnimplementedError` ou `NoSuchMethodError`, setar `generalError = exportFailedMessage` e retornar `false`. Se o método ainda não existir no driver, usar `dynamic` cast/`try/catch` para suportar ambos os cenários (driver com e sem o método).
  - Depende de: —
  - Desbloqueia: F3-T1

### F3 — View da Screen

- [x] **F3-T1** — Criar `CaseAssessmentAnalysisScreenView` + `index.dart` da Screen
  - Camada: `ui`
  - Artefato:
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_view.dart` *(novo)*
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/index.dart` *(novo)*
  - Detalhes: `ConsumerStatefulWidget` com `ScrollController` para auto-scroll ao acionar CTAs. Compor `Scaffold` > `SafeArea` > `Center` > `ConstrainedBox(maxWidth: 402)` > `Stack(DotGridBackground, Column(AnalysisHeader, Expanded(SingleChildScrollView), AnalysisActionBar))`. Reusar `AiBubble`, `DocumentFileBubble`, `CaseSummaryCard`, `AnalysisPrecedentsBubble`, `MessageBox`, `GeneratePetitionDraftCard`, `PetitionDraftCard`, `PetitionDraftModal`. Implementar handlers para: rename, archive, filters, precedentsCount (delegando ao `AnalysisPrecedentsBubblePresenter` lido por `ref.read`), export report (com snackbar de sucesso), pickDocument, analyze, retry, openPrecedentDialog, openPetitionDraftModal. CTA primário decide ação por status conforme tabela 9.2 da spec. O `index.dart` deve exportar o presenter + provider e definir `typedef CaseAssessmentAnalysisScreen = CaseAssessmentAnalysisScreenView;`.
  - Use como referência: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart` (estrutura geral e integração com `AnalysisPrecedentsBubble`) e `lib/ui/intake/widgets/pages/first_instance_analysis_screen/first_instance_analysis_screen_view.dart` (header com export e dialogs).
  - Depende de: F1-T1, F1-T2, F1-T3, F2-T1
  - Desbloqueia: F4-T1, F4-T2

### F4 — Roteamento

- [x] **F4-T1** — Registrar rota `Routes.caseAssessmentAnalysis` e helper `getCaseAssessmentAnalysis`
  - Camada: `constants` + `ui` (router)
  - Artefato:
    - `lib/constants/routes.dart` *(modificado)*: adicionar `static const String caseAssessmentAnalysis = '/analyses/:analysisId/case-assessment';` e `static String getCaseAssessmentAnalysis({required String analysisId}) => ...`.
    - `lib/router.dart` *(modificado)*: importar `case_assessment_analysis_screen/index.dart` e adicionar `GoRoute` com redirect local se `analysisId` vazio, builder retornando `CaseAssessmentAnalysisScreen(analysisId: analysisId)`. Estrutura idêntica ao `GoRoute` de `secondInstanceAnalysis`.
  - Depende de: F3-T1
  - Desbloqueia: F4-T2

- [x] **F4-T2** — Corrigir switch de `Routes.getAnalysis(...)` para `caseAssessment`
  - Camada: `constants`
  - Artefato: `lib/constants/routes.dart` *(modificado)*
  - Detalhes: o case `AnalysisTypeDto.caseAssessment` no switch de `getAnalysis(...)` passa a retornar `Routes.getCaseAssessmentAnalysis(analysisId: analysisId)` em vez de `getSecondInstanceAnalysis(...)`.
  - Depende de: F4-T1
  - Desbloqueia: —

---

## Pendências

- **PdfDriver sem `generateCaseAssessmentReport`** (spec 10.1): a exportação chamará o método e tratará erro. Não bloqueia a entrega — apenas exibe `MessageBox` se o driver ainda não suportar. Registrado para ticket separado.
- **Comportamento server após `PRECEDENTS_SEARCHED`** (spec 10.2): se o servidor não avançar automaticamente para `GENERATING_PETITION_DRAFT`, o CTA "Gerar minuta" pode parecer inerte. Validar com backend; ticket cross-repo se necessário.
- **Nomenclatura de `triggerFirstInstanceCaseSummarization`** (spec 10.3): débito técnico de naming, não bloqueia.
