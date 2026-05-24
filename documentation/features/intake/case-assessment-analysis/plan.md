---
title: Plano de Implementação — Tela de avaliação de caso para advogado
spec: documentation/features/intake/case-assessment-analysis/case-assessment-analysis-screen-spec.md
created_at: 2026-05-24
status: closed
---

## Mapa de Paralelização

| Fase | Objetivo | Depende de | Pode rodar em paralelo com |
|------|----------|------------|----------------------------|
| F1 | Estabilizar contratos do core | - | - |
| F2 | Adaptar integração REST | F1 | F3, F4, F5 |
| F3 | Adequar componente global de precedentes | F1 | F2, F4, F5 |
| F4 | Implementar presenter da nova tela | F1 | F2, F3, F5 |
| F5 | Construir view e widgets internos da nova tela | F1 | F2, F3, F4 |
| F6 | Wiring de rotas e entrada | F1, F4, F5 | - |

## Fases e Tarefas

### F1 — Estabilizar contratos compartilhados do domínio

- [x] **F1-T1** — Adicionar os contratos `triggerCaseAssessmentCaseSummarization(...)` e `triggerPetitionDraftGeneration(...)` em `IntakeService`
  - Camada: `core`
  - Artefato: `lib/core/intake/interfaces/intake_service.dart`
  - Concluído em: `2026-05-24`

- [x] **F1-T2** — Adicionar o campo `highlightedExcerpt` em `AnalysisPrecedentDto`
  - Camada: `core`
  - Artefato: `lib/core/intake/dtos/analysis_precedent_dto.dart`
  - Concluído em: `2026-05-24`

### F2 — Adaptar integração REST aos novos contratos

- [x] **F2-T1** — Implementar os dois novos triggers no `IntakeRestService`
  - Camada: `rest`
  - Artefato: `lib/rest/services/intake_rest_service.dart`
  - Concluído em: `2026-05-24`

- [x] **F2-T2** — Mapear `highlighted_excerpt`/`highlightedExcerpt` para `AnalysisPrecedentDto.highlightedExcerpt`
  - Camada: `rest`
  - Artefato: `lib/rest/mappers/intake/analysis_precedent_mapper.dart`
  - Concluído em: `2026-05-24`

### F3 — Adequar o componente global de precedentes ao novo DTO

- [x] **F3-T1** — Preservar `highlightedExcerpt` nas reconstruções manuais de `AnalysisPrecedentDto`
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/components/analysis_precedents_bubble/analysis_precedents_bubble_presenter.dart`
  - Concluído em: `2026-05-24`

- [x] **F3-T2** — Exibir `highlightedExcerpt` em seção própria no dialog de precedente
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/components/analysis_precedents_bubble/precedent_dialog/precedent_dialog_view.dart`
  - Concluído em: `2026-05-24`

### F4 — Implementar o presenter da nova tela

- [x] **F4-T1** — Criar `CaseAssessmentAnalysisScreenPresenter` com provider, estado e handlers descritos na spec
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart`
  - Concluído em: `2026-05-24`

### F5 — Construir a View e os widgets internos da nova tela

- [x] **F5-T1** — Criar widgets internos da minuta e respectivos barrels
  - Camada: `ui`
  - Artefatos:
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/generate_petition_draft_card/index.dart`
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/generate_petition_draft_card/generate_petition_draft_card_view.dart`
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/index.dart`
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/petition_draft_card_view.dart`
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/petition_draft_card_presenter.dart`
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/index.dart`
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/petition_draft_dialog_view.dart`
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/draft_content_section/index.dart`
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_dialog/draft_content_section/draft_content_section_view.dart`
  - Concluído em: `2026-05-24`

- [x] **F5-T2** — Criar `CaseAssessmentAnalysisScreenView` e barrel da tela
  - Camada: `ui`
  - Artefatos:
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_view.dart`
    - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/index.dart`
  - Concluído em: `2026-05-24`

### F6 — Registrar rota e corrigir ponto de entrada

- [x] **F6-T1** — Adicionar rota `caseAssessmentAnalysis`, getter e corrigir fallback de `getAnalysis(...)`
  - Camada: `constants`
  - Artefato: `lib/constants/routes.dart`
  - Concluído em: `2026-05-24`

- [x] **F6-T2** — Registrar `GoRoute` da nova tela com redirect por `analysisId` vazio
  - Camada: `ui`
  - Artefato: `lib/router.dart`
  - Concluído em: `2026-05-24`

- [x] **F6-T3** — Atualizar `HomeScreenPresenter.openAnalysis(...)` para rota de case assessment
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`
  - Concluído em: `2026-05-24`

## Pendências

- Nenhuma
