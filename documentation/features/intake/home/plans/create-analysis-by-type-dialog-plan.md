---
title: Plano de Implementacao — Dialog de criacao de analise por tipo
spec: ../specs/create-analysis-by-type-dialog-spec.md
created_at: 2026-05-18
status: open
---

---

## Analise de Dependencias

### Artefatos do `core` que desbloqueiam outras camadas

- Nenhum artefato novo de `core` precisa ser criado. O enum `AnalysisTypeDto` (`lib/core/intake/dtos/analysis_type_dto.dart`) e o contrato `IntakeService.createAnalysis({required AnalysisTypeDto type, String? folderId})` (`lib/core/intake/interfaces/intake_service.dart`) ja existem e ja sao consumidos por `HomeScreenPresenter`.

### Partes de `rest` e `drivers` independentes entre si

- Nao aplicavel. Esta entrega nao toca `lib/rest` nem `lib/drivers` (somente `lib/ui`). Os contratos remotos e os adaptadores de plataforma permanecem inalterados.

### Presenters/widgets/screens paralelizaveis

- **`CreateAnalysisTypeOptionView`** (`View only` puramente visual) e independente — pode ser criado isoladamente assim que os tokens de tema forem confirmados (ja existem).
- **`CreateAnalysisTypeDialogPresenter`** nao depende de nenhum outro novo artefato; pode ser criado em paralelo com o `OptionView`.
- **Ajuste em `HomeScreenPresenter.createAnalysis`** (adicionar parametro `type` com default `firstInstance` e usar `Routes.getAnalysis(analysisType: type)` para navegar) e independente do dialog em si, pois mantem a chamada sem argumentos compativel; pode rodar em paralelo com a criacao do dialog.
- **`CreateAnalysisTypeDialogView`** depende de `CreateAnalysisTypeDialogPresenter` (consome `Signal`/getters) e de `CreateAnalysisTypeOptionView` (renderiza tiles).
- **Ajuste em `HomeScreenView`** depende de `CreateAnalysisTypeDialog` (precisa do `typedef` exportado pelo `index.dart`) e do `HomeScreenPresenter` ja aceitando o parametro `type`.

### Tarefas iniciaveis com stub

- **F4 — Ajustar `HomeScreenPresenter`** pode iniciar imediatamente, sem stub, pois nao consome novos artefatos.
- **F2 — `CreateAnalysisTypeDialogPresenter`** pode iniciar imediatamente (nao depende de outras tarefas).
- **F1 — `CreateAnalysisTypeOptionView`** pode iniciar imediatamente (nao depende de outras tarefas).
- **F3 — `CreateAnalysisTypeDialogView`** pode iniciar com stub do `CreateAnalysisTypeOptionView` e do `CreateAnalysisTypeDialogPresenter` se necessario, mas o ganho e baixo — recomendado aguardar F1 e F2.

---

## ⚠️ Gargalos identificados

- **Nenhum gargalo critico.** F1, F2 e F4 podem rodar simultaneamente. F3 e F5 sao consolidadores no final. O caminho critico passa por F1 + F2 (paralelas) → F3 → F5 (a parte mais visivel ao usuario), com F4 podendo rodar em paralelo a esse caminho.

---

## Mapa de Paralelizacao

| Fase | Objetivo | Depende de | Pode rodar em paralelo com |
|------|----------|------------|----------------------------|
| F1   | Criar widget interno `CreateAnalysisTypeOption` (View only) | — | F2, F4 |
| F2   | Criar `CreateAnalysisTypeDialogPresenter` (Signals, getters de copy/icone) | — | F1, F4 |
| F3   | Criar `CreateAnalysisTypeDialogView` e barrel `index.dart` do dialog | F1, F2 | F4 |
| F4   | Ajustar `HomeScreenPresenter.createAnalysis(type: ...)` e navegacao via `Routes.getAnalysis` | — | F1, F2, F3 |
| F5   | Ajustar `HomeScreenView` para abrir o dialog via `showDialog<AnalysisTypeDto>` | F3, F4 | — |

---

## Fases e Tarefas

### F1 — Widget interno `CreateAnalysisTypeOption`

- [ ] **F1-T1** — Criar `CreateAnalysisTypeOptionView` (View only)
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_option/create_analysis_type_option_view.dart` *(novo)*
  - Detalhes: `StatelessWidget` com props `title`, `description`, `icon`, `isSelected`, `onTap`. Usa `AppThemeTokens` (`surfaceCard`/`surfacePage`/`surfaceElevated`, `borderSubtle`, `accent`, `textPrimary`, `textSecondary`). Renderiza `InkWell` + `Container` com `borderRadius: 16`; alterna borda/cor quando `isSelected == true` (`tokens.accent`, `surfaceElevated`). Inclui icone Material, titulo (`labelMedium` bold) e descricao (`bodySmall`, `textMuted`). Envolve conteudo com `Semantics(selected: isSelected, button: true, label: title)`. Tap delega para `onTap`. Indicador visual: `Icons.radio_button_checked` quando `isSelected`, `Icons.radio_button_unchecked` caso contrario.
  - Depende de: —
  - Desbloqueia: F1-T2, F3-T1

- [ ] **F1-T2** — Criar `index.dart` do widget interno
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_option/index.dart` *(novo)*
  - Detalhes: arquivo barrel com `typedef CreateAnalysisTypeOption = CreateAnalysisTypeOptionView;` e import correspondente.
  - Depende de: F1-T1
  - Desbloqueia: F3-T1

### F2 — Presenter do dialog

- [ ] **F2-T1** — Criar `CreateAnalysisTypeDialogPresenter`
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_dialog_presenter.dart` *(novo)*
  - Detalhes: classe `final` com construtor `CreateAnalysisTypeDialogPresenter({AnalysisTypeDto initialType = AnalysisTypeDto.firstInstance})`. Expoe `Signal<AnalysisTypeDto> selectedType` inicializado em `initialType`. Metodos: `void selectType(AnalysisTypeDto)`, `bool isSelected(AnalysisTypeDto)`, getter `AnalysisTypeDto get selected`, `String titleFor(AnalysisTypeDto)`, `String descriptionFor(AnalysisTypeDto)`, `IconData iconFor(AnalysisTypeDto)`, `void dispose()`. Constante estatica `static const List<AnalysisTypeDto> orderedTypes = <AnalysisTypeDto>[caseAssessment, firstInstance, secondInstance];`. Os textos PT-BR e os icones Material seguem o que esta na Secao 5 da spec (titles: `Avaliacao de caso`, `Primeira instancia`, `Segunda instancia`; descriptions: `Diagnostico inicial do caso`, `Resposta a peticao inicial`, `Revisao de decisao em grau de recurso`; icons: `Icons.fact_check_outlined`, `Icons.gavel_outlined`, `Icons.account_balance_outlined`).
  - Depende de: —
  - Desbloqueia: F3-T1

### F3 — View do dialog e barrel publico

- [ ] **F3-T1** — Criar `CreateAnalysisTypeDialogView`
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_dialog_view.dart` *(novo)*
  - Detalhes: `StatefulWidget` com prop opcional `AnalysisTypeDto initialType` (default `AnalysisTypeDto.firstInstance`). O `State` instancia `CreateAnalysisTypeDialogPresenter` em `initState` com `widget.initialType`, descarta em `dispose`. Layout segue a Secao 5 da spec: `Dialog` transparente (`insetPadding: 24h`), `Container` `maxWidth: 352`, `padding: 20`, `surfaceCard`, `borderRadius: 24`, `border: borderSubtle`. Coluna com titulo `Nova analise` (`titleMedium` bold), subtitulo `Escolha o tipo da analise.` (`bodySmall`, `textMuted`), lista de `CreateAnalysisTypeOption` por `presenter.orderedTypes` separadas por `SizedBox(height: 8)` envoltas por `Watch` para reagir a `selectedType`. Linha final com `OutlinedButton('Cancelar')` (pop sem valor) e `FilledButton('Criar')` (pop com `presenter.selected`), mesmas dimensoes do `ArchiveAnalysisDialogView` (`minimumSize: Size.fromHeight(52)`, `borderRadius: 12`). O botao `Criar` esta sempre habilitado porque sempre ha selecao default.
  - Depende de: F1-T2, F2-T1
  - Desbloqueia: F3-T2, F5-T1

- [ ] **F3-T2** — Criar `index.dart` do dialog
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/index.dart` *(novo)*
  - Detalhes: barrel com `typedef CreateAnalysisTypeDialog = CreateAnalysisTypeDialogView;` e import correspondente.
  - Depende de: F3-T1
  - Desbloqueia: F5-T1

### F4 — Ajuste no `HomeScreenPresenter`

- [ ] **F4-T1** — Adicionar parametro `type` em `createAnalysis` e ajustar navegacao
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart` *(modificacao)*
  - Detalhes: alterar a assinatura para `Future<void> createAnalysis({AnalysisTypeDto type = AnalysisTypeDto.firstInstance})`. Trocar `_intakeService.createAnalysis(type: AnalysisTypeDto.firstInstance)` por `_intakeService.createAnalysis(type: type)`. Trocar `_navigationDriver.pushTo(Routes.getFirstInstanceAnalysis(analysisId: analysisId))` por `_navigationDriver.pushTo(Routes.getAnalysis(analysisId: analysisId, analysisType: type))`. Demais comportamentos preservados (loading, refresh, tratamento de erro). Garantir que a chamada sem argumentos continua valida (default `firstInstance`) para nao quebrar testes existentes em `test/ui/intake/widgets/pages/home_screen/home_screen_presenter_test.dart`.
  - Depende de: —
  - Desbloqueia: F5-T1

### F5 — Integracao na `HomeScreenView`

- [ ] **F5-T1** — Integrar `showDialog<AnalysisTypeDto>` no `FAB` e no `EmptyState`
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/home_screen/home_screen_view.dart` *(modificacao)*
  - Detalhes: importar `CreateAnalysisTypeDialog` via `create_analysis_type_dialog/index.dart`. Criar funcao local `Future<void> handleCreateAnalysis(BuildContext context)` dentro de `build` que executa `final AnalysisTypeDto? selectedType = await showDialog<AnalysisTypeDto>(context: context, builder: (_) => const CreateAnalysisTypeDialog());` e, se `selectedType != null`, chama `await presenter.createAnalysis(type: selectedType);`. Substituir `onPressed: isLoadingInitialData ? null : presenter.createAnalysis` por `onPressed: isLoadingInitialData ? null : () => handleCreateAnalysis(context)`. Substituir `onCreateFirstAnalysis: () { presenter.createAnalysis(); }` por `onCreateFirstAnalysis: () { unawaited(handleCreateAnalysis(context)); }` (importar `dart:async` se necessario) — manter `unawaited` para nao mudar o tipo do callback.
  - Depende de: F3-T2, F4-T1
  - Desbloqueia: —

---

## Pendencias

- Nenhuma.
