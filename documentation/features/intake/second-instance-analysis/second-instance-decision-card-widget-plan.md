---
title: Plano de Implementação — Formulário de descrição da decisão da Segunda Instância
spec: [documentation/features/intake/second-instance-analysis/second-instance-decision-card-widget-spec.md](documentation/features/intake/second-instance-analysis/second-instance-decision-card-widget-spec.md)
created_at: 2026-06-06
status: closed
---

---

## Análise de Dependências

### Artefatos do `core` que desbloqueiam outras camadas
- `lib/core/intake/dtos/second_instance_decision_dto.dart` é o contrato base compartilhado por `rest` e `ui`.
- `lib/core/intake/interfaces/intake_service.dart` precisa expor `createSecondInstanceDecision(...)` e `getSecondInstanceDecision(...)` antes da implementação concreta em `rest` e antes do consumo pelo presenter da tela.
- `lib/core/intake/dtos/analysis_status_dto.dart` e `lib/core/intake/dtos/second_instance_analysis_status_dto.dart` precisam receber `decisionSubmitted` antes de `rest` aceitar o novo status e antes da `ui` reagir ao novo fluxo.
- `lib/core/intake/dtos/second_instance_analysis_report_dto.dart` precisa receber `decision` antes do `SecondInstanceAnalysisReportMapper` ser ajustado.

### Partes de `rest` e `drivers` independentes entre si
- Não há trabalho novo em `drivers` nesta spec.
- Em `rest`, o fluxo de endpoints de decisão é independente do fluxo de enriquecimento do report agregado, exceto pelo reuso do `SecondInstanceDecisionMapper`.
- `analysis_mapper.dart` pode ser ajustado em paralelo à criação do `SecondInstanceDecisionMapper`.
- `intake_rest_service.dart` pode ser ajustado em paralelo ao trabalho de `ui` assim que o contrato do `core` estiver estável.

### Presenters/widgets/screens paralelizáveis
- `SecondInstanceDecisionCard` pode ser construído em paralelo ao `SecondInstanceDecisionDialog`, desde que o `SecondInstanceDecisionDto` exista.
- `SecondInstanceDecisionDialogPresenter` pode ser construído em paralelo ao `SecondInstanceDecisionCard`.
- `SecondInstanceAnalysisScreenPresenter` pode avançar em paralelo aos widgets novos usando apenas o contrato do `IntakeService`.
- `SecondInstanceAnalysisScreenView` depende do presenter e dos widgets novos, então fica para uma fase de composição.

### Tarefas iniciáveis com stub
- `SecondInstanceAnalysisScreenPresenter` pode iniciar com stub de `IntakeService.createSecondInstanceDecision(...)` e `IntakeService.getSecondInstanceDecision(...)` após a definição do contrato no `core`.
- `SecondInstanceDecisionDialog` pode iniciar com stub do callback `Future<String?> Function(String description) onConfirm`.
- `SecondInstanceDecisionCard` pode iniciar apenas com o DTO do `core`, sem aguardar `rest`.
- Não há tarefa de `drivers`, `cache`, `rotas` ou `go_router` a preparar em paralelo.

---

## ⚠️ Gargalos identificados

- **F1 — Contratos e modelos do Core**: bloqueia 8 tarefas; deve ser iniciada primeiro.
- **F2-T3 — Implementar os métodos no `IntakeRestService`**: desbloqueia a integração real ponta a ponta sem dependência externa.
- **F5-T2 — Integrar decisão ao presenter da tela**: bloqueia 2 tarefas de composição final da UI; deve começar assim que F1 terminar.

---

## Mapa de Paralelização

| Fase | Objetivo | Depende de | Pode rodar em paralelo com |
|------|----------|------------|----------------------------|
| F1 | Definir contratos e modelos compartilhados da decisão | - | - |
| F2 | Implementar suporte REST aos endpoints e ao novo status | F1 | F4, F5 |
| F3 | Enriquecer o report agregado de 2ª instância com `decision` | F1, F2 | F4, F5 |
| F4 | Criar widgets internos da decisão | F1 | F2, F3, F5 |
| F5 | Integrar a decisão ao presenter da tela `(pode iniciar com stub de IntakeService)` | F1 | F2, F3, F4 |
| F6 | Compor a tela final com card, dialog e bloqueio do CTA | F4, F5 | - |

---

## Fases e Tarefas

### F1 — Definir contratos e modelos compartilhados da decisão

- [x] **F1-T1** — Criar o DTO `SecondInstanceDecisionDto`
  - Camada: `core`
  - Artefato: `lib/core/intake/dtos/second_instance_decision_dto.dart`
  - Depende de: —
  - Desbloqueia: F2-T1, F2-T3, F3-T1, F4-T1, F4-T2, F5-T1
  - Artefatos: `lib/core/intake/dtos/second_instance_decision_dto.dart`
  - Concluído em: 2026-06-06

- [x] **F1-T2** — Adicionar `decisionSubmitted` aos status compartilhados da análise
  - Camada: `core`
  - Artefato: `lib/core/intake/dtos/analysis_status_dto.dart`, `lib/core/intake/dtos/second_instance_analysis_status_dto.dart`
  - Depende de: —
  - Desbloqueia: F2-T2, F5-T1
  - Artefatos: `lib/core/intake/dtos/analysis_status_dto.dart`, `lib/core/intake/dtos/second_instance_analysis_status_dto.dart`
  - Concluído em: 2026-06-06

- [x] **F1-T3** — Estender o report agregado de 2ª instância com `decision`
  - Camada: `core`
  - Artefato: `lib/core/intake/dtos/second_instance_analysis_report_dto.dart`
  - Depende de: F1-T1
  - Desbloqueia: F3-T1
  - Artefatos: `lib/core/intake/dtos/second_instance_analysis_report_dto.dart`
  - Concluído em: 2026-06-06

- [x] **F1-T4** — Estender o contrato `IntakeService` com criação e leitura da decisão
  - Camada: `core`
  - Artefato: `lib/core/intake/interfaces/intake_service.dart`
  - Depende de: F1-T1
  - Desbloqueia: F2-T3, F5-T2
  - Artefatos: `lib/core/intake/interfaces/intake_service.dart`
  - Concluído em: 2026-06-06

### F2 — Implementar suporte REST aos endpoints e ao novo status

- [x] **F2-T1** — Criar o `SecondInstanceDecisionMapper`
  - Camada: `rest`
  - Artefato: `lib/rest/mappers/intake/second_instance_decision_mapper.dart`
  - Depende de: F1-T1
  - Desbloqueia: F2-T3, F3-T1
  - Artefatos: `lib/rest/mappers/intake/second_instance_decision_mapper.dart`
  - Concluído em: 2026-06-06

- [x] **F2-T2** — Ajustar `AnalysisMapper` para aceitar `DECISION_SUBMITTED`
  - Camada: `rest`
  - Artefato: `lib/rest/mappers/intake/analysis_mapper.dart`
  - Depende de: F1-T2
  - Desbloqueia: compatibilidade de status para F5-T2
  - Artefatos: `lib/rest/mappers/intake/analysis_mapper.dart`
  - Concluído em: 2026-06-06

- [x] **F2-T3** — Implementar `createSecondInstanceDecision(...)` e `getSecondInstanceDecision(...)` no `IntakeRestService`
  - Camada: `rest`
  - Artefato: `lib/rest/services/intake_rest_service.dart`
  - Depende de: F1-T1, F1-T4, F2-T1
  - Desbloqueia: integração concreta consumida por F5-T2
  - Artefatos: `lib/rest/services/intake_rest_service.dart`
  - Concluído em: 2026-06-06

### F3 — Enriquecer o report agregado de 2ª instância com `decision`

- [x] **F3-T1** — Mapear `decision` no `SecondInstanceAnalysisReportMapper`
  - Camada: `rest`
  - Artefato: `lib/rest/mappers/intake/second_instance_analysis_report_mapper.dart`
  - Depende de: F1-T3, F2-T1
  - Desbloqueia: exportação futura do report agregado com o novo campo
  - Artefatos: `lib/rest/mappers/intake/second_instance_analysis_report_mapper.dart`
  - Concluído em: 2026-06-06

### F4 — Criar widgets internos da decisão

- [x] **F4-T1** — Criar o widget `SecondInstanceDecisionCard` com estado vazio, preenchido e loading
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_decision_card/second_instance_decision_card_view.dart`, `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_decision_card/index.dart`
  - Depende de: F1-T1
  - Desbloqueia: F6-T1
  - Artefatos: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_decision_card/second_instance_decision_card_view.dart`, `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_decision_card/index.dart`
  - Concluído em: 2026-06-06

- [x] **F4-T2** — Criar o `SecondInstanceDecisionDialogPresenter` local
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_decision_dialog/second_instance_decision_dialog_presenter.dart`
  - Depende de: F1-T1
  - Desbloqueia: F4-T3
  - Artefatos: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_decision_dialog/second_instance_decision_dialog_presenter.dart`
  - Concluído em: 2026-06-06

- [x] **F4-T3** — Criar o `SecondInstanceDecisionDialogView` fullscreen e seu barrel público
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_decision_dialog/second_instance_decision_dialog_view.dart`, `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_decision_dialog/index.dart`
  - Depende de: F4-T2
  - Desbloqueia: F6-T1
  - Artefatos: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_decision_dialog/second_instance_decision_dialog_view.dart`, `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_decision_dialog/index.dart`
  - Concluído em: 2026-06-06

### F5 — Integrar a decisão ao presenter da tela

- [x] **F5-T1** — Adicionar estado reativo da decisão e regras derivadas de habilitação
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
  - Depende de: F1-T1, F1-T2
  - Desbloqueia: F5-T2, F6-T2
  - Artefatos: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
  - Concluído em: 2026-06-06

- [x] **F5-T2** — Implementar `createDecision(...)`, `_loadDecision()` e a reentrada da decisão no `load()`
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
  - Depende de: F1-T4, F5-T1
  - Desbloqueia: F6-T1, integração concreta com F2-T3
  - Observação: pode iniciar com stub de `IntakeService`, mas a integração final depende de F2-T3
  - Artefatos: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
  - Concluído em: 2026-06-06

### F6 — Compor a tela final com card, dialog e bloqueio do CTA

- [x] **F6-T1** — Inserir o `SecondInstanceDecisionCard` na tela e abrir o `SecondInstanceDecisionDialog` com o callback do presenter
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`
  - Depende de: F4-T1, F4-T3, F5-T2
  - Desbloqueia: fluxo visual completo da decisão na tela
  - Artefatos: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`
  - Concluído em: 2026-06-06

- [x] **F6-T2** — Ajustar a composição da action bar para refletir o bloqueio de “Buscar precedentes” até existir `decision`
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`
  - Depende de: F5-T1
  - Desbloqueia: comportamento final do CTA primário alinhado ao novo fluxo
  - Artefatos: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`, `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`
  - Concluído em: 2026-06-06

---

## Pendências

- `flutter test` continua falhando na suíte atual do projeto. Impacto: a implementação foi concluída e `flutter analyze` está verde, mas a suíte não fica verde até ajustar cenários já quebrados ou agora desalinhados com a regra nova da decisão obrigatória.
- O teste `test/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view_test.dart` ainda espera o CTA final acionável em `caseAnalyzed` sem decisão. Impacto: esse cenário não corresponde mais à spec implementada e precisa ser atualizado.
- O teste `test/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter_test.dart` ainda falha no cenário `should retry judgment draft reload after done when draft is not found yet`. Impacto: precisa de investigação isolada, pois não foi resolvido durante esta entrega.

---

## Divergências em relação à Spec

- Nenhuma.
