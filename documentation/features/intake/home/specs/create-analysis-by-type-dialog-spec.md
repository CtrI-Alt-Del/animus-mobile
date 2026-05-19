---
title: Dialog de criacao de analise por tipo
prd: ../prd.md
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-101
status: open
last_updated_at: 2026-05-18
---

# 1. Objetivo

Permitir que o usuario, ao acionar o `FAB` da `Home`, escolha de forma explicita o tipo de analise que sera criado entre `CaseAssessmentAnalysis`, `FirstInstanceAnalysis` e `SecondInstanceAnalysis` antes de chamar `IntakeService.createAnalysis(type: ...)`. A entrega introduz um `CreateAnalysisTypeDialog` (`View + Presenter`) com tile por tipo, marcacao visual de selecionado, `FirstInstanceAnalysis` como default e botoes `Cancelar` / `Criar`, alem de adaptar `HomeScreenPresenter` para abrir o dialog, aguardar a selecao via Future e so entao criar a analise com o tipo escolhido. Nenhuma alteracao de contrato em `core`, `rest` ou `drivers` e necessaria.

---

# 2. Escopo

## 2.1 In-scope

- Criar widget interno `CreateAnalysisTypeDialog` em `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/` com `View + Presenter` e `index.dart` com `typedef`.
- Criar subwidget visual `CreateAnalysisTypeOption` (`View only`) em `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_option/` para representar uma opcao de tipo na lista (titulo, descricao curta, icone e estado selecionado).
- Adaptar `HomeScreenPresenter.createAnalysis()` para receber um `AnalysisTypeDto` selecionado, mantendo `FirstInstanceAnalysis` como tipo default quando a UI nao informar nada (chamadas legadas).
- Adaptar `HomeScreenView` (e o callback de `RecentAnalysesEmptyState`) para abrir o dialog via `showDialog<AnalysisTypeDto>` e, ao confirmar, delegar a criacao para o presenter com o tipo retornado.
- Manter o spinner de loading do `CreateAnalysisFabView` ligado a `isCreatingAnalysis` apenas durante a criacao efetiva (apos a confirmacao do dialog).
- Garantir que ao cancelar (botao `Cancelar`, tap fora ou back) nada e criado e nenhuma rota e disparada.

## 2.2 Out-of-scope

- Telas dedicadas para `CaseAssessmentAnalysis` e `SecondInstanceAnalysis` (continuam navegando para a rota mapeada hoje em `Routes.getAnalysis`).
- Alteracoes em `IntakeService`, `IntakeRestService`, `AnalysisMapper` ou qualquer DTO/contrato de `core`/`rest`/`drivers`.
- Mudanca em `Routes.getAnalysis` ou registro de novas rotas.
- Alteracoes na secao `Em andamento` ou nos cards de analise existentes.
- Compatibilidade com tipos legados `lawyer` / `judge` — o contrato anterior nao foi exposto ao mobile, conforme registrado no PRD de `home/prd.md`.
- Tracking/analytics da escolha do tipo.
- Localizacao (i18n); todos os textos continuam em PT-BR hard-coded como nos demais dialogs do app.
- Validacao via Google Stitch; nenhum `screen_id` foi fornecido para esta tarefa.
- Testes automatizados (nao fazem parte da spec, sao tratados em fase posterior).

---

# 3. Requisitos

## 3.1 Funcionais

- Ao tocar no `FAB` da `Home`, abrir o `CreateAnalysisTypeDialog` em vez de criar diretamente uma analise.
- O dialog deve listar exatamente 3 opcoes correspondentes aos valores de `AnalysisTypeDto`: `CaseAssessmentAnalysis`, `FirstInstanceAnalysis` e `SecondInstanceAnalysis`.
- A opcao `FirstInstanceAnalysis` deve estar **pre-selecionada** ao abrir o dialog.
- O usuario deve poder alternar a selecao entre as 3 opcoes; apenas uma fica marcada por vez.
- O botao primario do dialog deve estar habilitado sempre que houver uma opcao selecionada (o que e garantido pelo default).
- Ao confirmar, o dialog deve fechar e retornar via `Navigator.pop` o `AnalysisTypeDto` selecionado.
- Ao cancelar (`Cancelar`, tap fora ou back), o dialog deve fechar e retornar `null`, e nenhuma analise deve ser criada.
- O callback de criacao do `RecentAnalysesEmptyState` (botao "Iniciar primeira analise") deve abrir o mesmo dialog antes de criar.
- Apos a confirmacao, `HomeScreenPresenter.createAnalysis(type: ...)` deve usar o tipo retornado pelo dialog e proceder com o fluxo atual de criacao + navegacao + refresh, ja existente.
- Se o usuario cancelar enquanto uma criacao previa estiver em andamento (`isCreatingAnalysis == true`), o `FAB` deve permanecer desabilitado e o cancelamento nao deve afetar a criacao em curso.

## 3.2 Nao funcionais

- **Acessibilidade:** cada tile do dialog deve ser tocavel em area suficiente (`InkWell` com `minimumSize` consistente aos demais dialogs); `Tooltip` no `FAB` segue o padrao atual.
- **Arquitetura:** a `View` do dialog nao executa logica de selecao — toda mudanca de estado fica no `CreateAnalysisTypeDialogPresenter`.
- **Compatibilidade:** o `HomeScreenPresenter.createAnalysis` deve aceitar chamada sem argumentos preservando `FirstInstanceAnalysis` como default para nao quebrar testes existentes em `test/ui/intake/widgets/pages/home_screen/home_screen_presenter_test.dart`.
- **Visual:** o dialog deve reutilizar `AppThemeTokens` e a mesma forma de container usada por `ArchiveAnalysisDialogView` e `ProfileUpdateNameDialogView` para manter consistencia (`Dialog` transparente, `Container` com `surfaceCard`, `borderRadius: 24`, `border: borderSubtle`).

---

# 4. O que ja existe?

## Core

- **`AnalysisTypeDto`** (`lib/core/intake/dtos/analysis_type_dto.dart`) — enum com `caseAssessment`, `firstInstance` e `secondInstance`; ja exposto ao app e usado pelo `HomeScreenPresenter` para chamar `createAnalysis(type: ...)`.
- **`IntakeService.createAnalysis({required AnalysisTypeDto type, String? folderId})`** (`lib/core/intake/interfaces/intake_service.dart`) — contrato ja tipado por tipo de analise; nao precisa de alteracao.

## UI

- **`HomeScreenView`** (`lib/ui/intake/widgets/pages/home_screen/home_screen_view.dart`) — monta o `Scaffold` da `Home`, observa o presenter via Riverpod e hoje liga o `FAB` diretamente a `presenter.createAnalysis`.
- **`HomeScreenPresenter`** (`lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`) — orquestrador da `Home`; possui `Signal<bool> isCreatingAnalysis`, `Future<void> createAnalysis()` que ja chama `IntakeService.createAnalysis(type: AnalysisTypeDto.firstInstance)` e `openAnalysis(AnalysisDto)` com switch por tipo (`firstInstance`, `secondInstance`, `caseAssessment`).
- **`CreateAnalysisFabView`** (`lib/ui/intake/widgets/pages/home_screen/create_analysis_fab/create_analysis_fab_view.dart`) — botao `FAB` com `Tooltip`, gradient, spinner durante loading; **nao precisa de alteracao estrutural** para esta spec — continua chamando `onPressed` quando nao esta loading.
- **`RecentAnalysesSectionView`** (`lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_section_view.dart`) — define o callback `onCreateFirstAnalysis: VoidCallback` repassado para `RecentAnalysesEmptyState`; hoje conectado a `presenter.createAnalysis`.
- **`RecentAnalysesEmptyState`** (`lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_empty_state/`) — empty state com botao "Iniciar primeira analise".
- **`ArchiveAnalysisDialogView`** (`lib/ui/intake/widgets/components/analysis_header/archive_analysis_dialog/archive_analysis_dialog_view.dart`) — referencia visual mais proxima para o novo dialog: `Dialog` transparente, container com `surfaceCard`, `borderRadius: 24`, dois botoes (`OutlinedButton` + `FilledButton`) com `minimumSize: Size.fromHeight(52)`.
- **`ProfileUpdateNameDialogView`** (`lib/ui/auth/widgets/pages/profile_screen/profile_update_name_dialog/profile_update_name_dialog_view.dart`) — referencia de dialog com estado local (`StatefulWidget`) e presenter coadjuvante (`ProfileUpdateNameDialogPresenter` const) chamado pela `View`.
- **`AppThemeTokens` / `AppTheme`** (`lib/theme.dart`) — tokens visuais (`surfaceCard`, `surfacePage`, `surfaceElevated`, `borderSubtle`, `borderStrong`, `accent`, `accentStrong`, `textPrimary`, `textSecondary`, `textMuted`) usados em todos os dialogs.

## Constants

- **`Routes`** (`lib/constants/routes.dart`) — `Routes.getAnalysis({analysisId, analysisType})` ja mapeia os 3 tipos para rotas existentes; nenhum ajuste necessario.

---

# 5. O que deve ser criado?

## Camada UI (Presenters)

### `CreateAnalysisTypeDialogPresenter` *(novo arquivo)*

- **Localizacao:** `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_dialog_presenter.dart`
- **Dependencias injetadas:** nenhuma (presenter local de UI, sem service nem driver).
- **Estado (`signals`):**
  - `Signal<AnalysisTypeDto> selectedType` — tipo selecionado no momento; valor inicial vem do parametro `initialType` do presenter.
- **Provider Riverpod:** nao se aplica — o presenter e instanciado localmente no `State` do `Dialog` (mesmo padrao usado por `ProfileUpdateNameDialogPresenter`), porque o ciclo de vida do presenter coincide com o ciclo de vida do dialog e ele nao precisa de dependencias injetadas.
- **Metodos:**
  - `CreateAnalysisTypeDialogPresenter({AnalysisTypeDto initialType = AnalysisTypeDto.firstInstance})` — inicializa o `selectedType` com o tipo recebido (default `firstInstance`).
  - `void selectType(AnalysisTypeDto type)` — atualiza `selectedType.value`.
  - `bool isSelected(AnalysisTypeDto type)` — retorna `selectedType.value == type`; usado pela `View` para destacar a opcao corrente.
  - `AnalysisTypeDto get selected` — getter conveniente para a `View` recuperar o valor no confirm.
  - `String titleFor(AnalysisTypeDto type)` — devolve o texto curto da opcao (ex.: `Avaliacao de caso`, `Primeira instancia`, `Segunda instancia`).
  - `String descriptionFor(AnalysisTypeDto type)` — devolve descricao auxiliar de uma linha para cada tipo (ex.: `Diagnostico inicial do caso`, `Resposta a peticao inicial`, `Revisao de decisao em grau de recurso`).
  - `IconData iconFor(AnalysisTypeDto type)` — devolve o icone Material adequado (ex.: `Icons.fact_check_outlined`, `Icons.gavel_outlined`, `Icons.account_balance_outlined`).
  - `void dispose()` — libera `selectedType`.
- **Helper estatico:**
  - `static const List<AnalysisTypeDto> orderedTypes = <AnalysisTypeDto>[AnalysisTypeDto.caseAssessment, AnalysisTypeDto.firstInstance, AnalysisTypeDto.secondInstance];` — ordem visual fixa das opcoes (avaliacao primeiro, depois 1a e 2a instancia), refletindo a leitura natural do produto.

## Camada UI (Views)

### `CreateAnalysisTypeDialogView` *(novo arquivo)*

- **Localizacao:** `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_dialog_view.dart`
- **Base class:** `StatefulWidget` (necessario porque instancia e descarta o presenter local; mesmo padrao de `ProfileUpdateNameDialogView`).
- **Props:**
  - `AnalysisTypeDto initialType` *(opcional, default `AnalysisTypeDto.firstInstance`)* — tipo a ser pre-selecionado.
- **Bibliotecas de UI:** `flutter/material.dart`, `signals_flutter` (para observar `selectedType` via `Watch`).
- **Estrutura visual (referencia: `ArchiveAnalysisDialogView`):**
  - `Dialog` transparente, `insetPadding: EdgeInsets.symmetric(horizontal: 24)`.
  - Container com `maxWidth: 352`, `padding: EdgeInsets.all(20)`, `color: tokens.surfaceCard`, `borderRadius: 24`, `border: tokens.borderSubtle`.
  - `Column` com `mainAxisSize: MainAxisSize.min` e `crossAxisAlignment: stretch`:
    1. `Text('Nova analise', titleMedium bold)`
    2. `SizedBox(height: 8)`
    3. `Text('Escolha o tipo da analise.', bodySmall, textMuted)`
    4. `SizedBox(height: 16)`
    5. Lista vertical de `CreateAnalysisTypeOption` (uma por tipo em `orderedTypes`), separadas por `SizedBox(height: 8)`. Cada tile recebe `isSelected`, `onTap` e os textos/icone vindos do presenter.
    6. `SizedBox(height: 16)`
    7. `Row` com `OutlinedButton('Cancelar')` + `FilledButton('Criar')`, mesmas dimensoes/estilos do `ArchiveAnalysisDialogView`.
- **Side effects:**
  - `Cancelar` -> `Navigator.of(context).pop()` sem valor.
  - `Criar` -> `Navigator.of(context).pop<AnalysisTypeDto>(_presenter.selected)`.
- **Estados visuais:** nao se aplica (loading/erro nao acontecem aqui — o loading da criacao continua no `FAB` controlado pelo `HomeScreenPresenter`).
- **Tap fora / back:** comportamento padrao do `Dialog` — fecha com `null`.

## Camada UI (Widgets Internos)

### `CreateAnalysisTypeOption` *(novo arquivo, `View only`)*

- **Localizacao:** `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_option/`
- **Tipo:** `View only` — widget puramente visual sem estado proprio; toda a logica de selecao e responsabilidade do `CreateAnalysisTypeDialogPresenter`.
- **Arquivos:**
  - `create_analysis_type_option_view.dart`
  - `index.dart` com `typedef CreateAnalysisTypeOption = CreateAnalysisTypeOptionView;`
- **Props:**
  - `String title`
  - `String description`
  - `IconData icon`
  - `bool isSelected`
  - `VoidCallback onTap`
- **Responsabilidade:** renderizar um tile com `InkWell` + `Container` arredondado contendo icone, titulo, descricao e indicador visual de selecao (ex.: `Icons.radio_button_checked` / `Icons.radio_button_unchecked` ou borda destacada com `tokens.accent` quando `isSelected == true`).
- **Estilo:**
  - Padding interno `EdgeInsets.all(12)`.
  - `borderRadius: 16`.
  - Quando `isSelected == true`: `border: tokens.accent` com largura 1.5 e `color: tokens.surfaceElevated`.
  - Quando `isSelected == false`: `border: tokens.borderSubtle`, `color: tokens.surfacePage`.
- **Acessibilidade:** uso de `InkWell` garante feedback de toque; `Semantics(selected: isSelected, button: true, label: title)` envolve o conteudo para suporte a leitores de tela.

## Camada UI (Barrel Files / `index.dart`)

### `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/index.dart` *(novo arquivo)*

- **`typedef` exportado:** `typedef CreateAnalysisTypeDialog = CreateAnalysisTypeDialogView;`

### `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_option/index.dart` *(novo arquivo)*

- **`typedef` exportado:** `typedef CreateAnalysisTypeOption = CreateAnalysisTypeOptionView;`

## Estrutura de Pastas

```text
lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/
  index.dart
  create_analysis_type_dialog_view.dart
  create_analysis_type_dialog_presenter.dart
  create_analysis_type_option/
    index.dart
    create_analysis_type_option_view.dart
```

---

# 6. O que deve ser modificado?

## Camada UI

### `HomeScreenPresenter.createAnalysis`

- **Arquivo:** `lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`
- **Mudanca:** alterar a assinatura para `Future<void> createAnalysis({AnalysisTypeDto type = AnalysisTypeDto.firstInstance})` e usar o parametro `type` na chamada `_intakeService.createAnalysis(type: ...)`. O restante do fluxo (loading, navegacao via `Routes.getAnalysis(analysisId: ..., analysisType: type)`, refresh) permanece igual.
- **Justificativa:** o presenter passa a aceitar o tipo escolhido pelo dialog mas continua aceitando chamadas sem argumentos com `FirstInstanceAnalysis` como default, garantindo compatibilidade com os testes existentes e com qualquer chamada legada interna.
- **Sub-mudanca:** ao navegar apos a criacao, trocar a chamada hard-coded `Routes.getFirstInstanceAnalysis(analysisId: ...)` por `Routes.getAnalysis(analysisId: ..., analysisType: type)` para refletir corretamente o tipo escolhido (sem isso, qualquer escolha leva a rota de primeira instancia).

### `HomeScreenView` (`FAB` e `EmptyState`)

- **Arquivo:** `lib/ui/intake/widgets/pages/home_screen/home_screen_view.dart`
- **Mudanca:**
  - Encapsular o handler do `FAB` em uma funcao local `Future<void> handleCreateAnalysis(BuildContext context)` que executa `showDialog<AnalysisTypeDto>(context: context, builder: (_) => const CreateAnalysisTypeDialog())` e, se o retorno nao for `null`, chama `presenter.createAnalysis(type: selectedType)`.
  - O `onPressed` do `CreateAnalysisFab` passa a chamar `handleCreateAnalysis(context)` em vez de `presenter.createAnalysis`.
  - O `onCreateFirstAnalysis` do `RecentAnalysesSection` passa a chamar a mesma funcao `handleCreateAnalysis(context)`.
- **Justificativa:** centraliza a orquestracao de abertura do dialog na `View`, mantendo o presenter agnostico ao framework de dialog (`showDialog` e responsabilidade visual). Garante que ambos os pontos de criacao (FAB e empty state) abrem o mesmo dialog.
- **Restricao arquitetural:** o presenter nao orquestra `showDialog` porque isso acoplaria o presenter a `BuildContext` e ao `Navigator` do Flutter. A logica que continua na `View` e estritamente de invocacao visual; o "que fazer com o tipo" continua no `HomeScreenPresenter.createAnalysis(type: ...)`.

---

# 7. O que deve ser removido?

**Nao aplicavel** — nenhum arquivo, contrato ou comportamento legado precisa ser removido por esta spec. A semantica antiga `lawyer` / `judge` ja nao existe na codebase e ja foi tratada em ANI-115.

---

# 8. Decisoes Tecnicas e Trade-offs

### Decisao 1: `showDialog` na `View`, criacao no `Presenter`

- **Decisao:** o `HomeScreenView` chama `showDialog<AnalysisTypeDto>` e, ao receber o tipo, delega para `presenter.createAnalysis(type: ...)`. O presenter nao recebe nem cria o dialog.
- **Alternativas consideradas:**
  1. Mover `showDialog` para o presenter via um `DialogDriver` (port) — descartado: nao existe `DialogDriver` no projeto e introduzir um novo driver so para este caso e overhead arquitetural desnecessario; os demais dialogs do app (`ProfileUpdateNameDialog`, `ArchiveAnalysisDialog`) seguem o mesmo padrao View-orquestra-dialog.
  2. Tornar o `FAB` um `Stack` com o dialog ja embutido — descartado: quebra a separacao de pasta/widget e dificulta reuso do dialog pelo botao `EmptyState`.
- **Motivo da escolha:** alinhamento com o padrao ja estabelecido na codebase; mantem o presenter livre de `BuildContext`; minimiza a superficie de mudanca.
- **Impactos / trade-offs:** o teste de widget do `HomeScreenView` precisara cobrir a abertura/cancelamento do dialog; o teste de presenter atual continua valido porque a assinatura `createAnalysis()` (sem argumentos) ainda funciona com default.

### Decisao 2: presenter local instanciado no `State` do dialog (sem Riverpod)

- **Decisao:** `CreateAnalysisTypeDialogPresenter` e instanciado no `initState` do `_CreateAnalysisTypeDialogViewState` e descartado no `dispose`, sem provider Riverpod.
- **Alternativas consideradas:**
  1. Provider Riverpod `autoDispose` dedicado para o dialog — descartado: o presenter nao tem dependencias injetadas, e o ciclo de vida coincide exatamente com o dialog (mesma situacao do `ProfileUpdateNameDialogPresenter`).
- **Motivo da escolha:** consistencia com padroes de dialogs ja existentes no projeto; evita provider sem ganho real.
- **Impactos / trade-offs:** teste de widget do dialog instanciara o `View` diretamente; testes unitarios do presenter podem ser feitos sem `ProviderContainer`.

### Decisao 3: `FirstInstanceAnalysis` como tipo default selecionado e default do presenter

- **Decisao:** o `initialType` do dialog default e `AnalysisTypeDto.firstInstance`, e `HomeScreenPresenter.createAnalysis` continua com `firstInstance` como default de parametro.
- **Motivo da escolha:** mantem continuidade com o comportamento atual (o fluxo de `FirstInstanceAnalysis` e o unico com tela dedicada implementada); reduz friccao para o usuario comum que sempre cria primeira instancia; preserva compatibilidade com testes existentes que chamam `createAnalysis()` sem argumentos.
- **Impactos / trade-offs:** se no futuro o produto quiser destacar outro tipo como default, basta passar `initialType` diferente para `CreateAnalysisTypeDialog` ou ajustar o default do presenter.

### Decisao 4: navegacao pos-criacao usa `Routes.getAnalysis(analysisType: type)`

- **Decisao:** apos criar a analise, navegar usando `Routes.getAnalysis(analysisId: ..., analysisType: type)` em vez do hard-coded `Routes.getFirstInstanceAnalysis(...)`.
- **Motivo da escolha:** garante que, ao escolher `SecondInstanceAnalysis` ou `CaseAssessment`, a rota correta seja aberta (mesma logica ja usada por `HomeScreenPresenter.openAnalysis`).
- **Impactos / trade-offs:** `Routes.getAnalysis` ja existe e atualmente mapeia `caseAssessment` para a mesma rota de `secondInstance` — esse mapeamento continua sob responsabilidade de ANI futuras e nao e alterado aqui.

### Decisao 5: textos e icones definidos no presenter, nao na view

- **Decisao:** os getters `titleFor`, `descriptionFor` e `iconFor` ficam no `CreateAnalysisTypeDialogPresenter`.
- **Alternativas consideradas:** colocar um `Map` const na `View` ou no proprio `AnalysisTypeDto`.
- **Motivo da escolha:** o `AnalysisTypeDto` mora em `core` e nao deve depender de Flutter (`IconData`); manter os textos no presenter centraliza o conhecimento de apresentacao e facilita ajuste futuro de copy.
- **Impactos / trade-offs:** caso o projeto venha a ter i18n, os textos passam a vir de um repositorio de tradutoras; ate la, hard-coded em PT-BR (consistente com o resto do app).

---

# 9. Diagramas e Referencias

## Fluxo de dados

```text
HomeScreenView
  └─ FAB.onPressed = handleCreateAnalysis(context)
        └─ showDialog<AnalysisTypeDto>(builder: () => CreateAnalysisTypeDialog())
              └─ CreateAnalysisTypeDialogView (StatefulWidget)
                    ├─ CreateAnalysisTypeDialogPresenter (local, Signals)
                    │     └─ selectedType: Signal<AnalysisTypeDto>
                    └─ Buttons:
                          ├─ Cancelar -> Navigator.pop()        (returns null)
                          └─ Criar    -> Navigator.pop(type)    (returns AnalysisTypeDto)
        └─ if (type != null) -> presenter.createAnalysis(type: type)
              └─ IntakeService.createAnalysis(type: type)        (no change)
                    └─ NavigationDriver.pushTo(Routes.getAnalysis(analysisId, analysisType: type))
```

## Hierarquia de widgets

```text
HomeScreenView
└─ Scaffold
   ├─ floatingActionButton: CreateAnalysisFab           (unchanged)
   └─ body
      └─ ...
         └─ RecentAnalysesSection
            └─ RecentAnalysesEmptyState                  (unchanged, callback re-bound)

CreateAnalysisTypeDialog (showDialog)
└─ Dialog
   └─ Container (surfaceCard, radius 24, borderSubtle)
      └─ Column
         ├─ Text "Nova analise"
         ├─ Text "Escolha o tipo da analise."
         ├─ CreateAnalysisTypeOption  (CaseAssessment)
         ├─ CreateAnalysisTypeOption  (FirstInstance, default selected)
         ├─ CreateAnalysisTypeOption  (SecondInstance)
         └─ Row [OutlinedButton "Cancelar", FilledButton "Criar"]
```

## Referencias

- `lib/ui/intake/widgets/components/analysis_header/archive_analysis_dialog/archive_analysis_dialog_view.dart` — referencia visual primaria (container, botoes, paddings, raios).
- `lib/ui/auth/widgets/pages/profile_screen/profile_update_name_dialog/profile_update_name_dialog_view.dart` — referencia de `StatefulWidget` com presenter local instanciado no `State`.
- `lib/ui/auth/widgets/pages/profile_screen/profile_update_name_dialog/profile_update_name_dialog_presenter.dart` — referencia de presenter de dialog (sem dependencias externas).
- `lib/ui/auth/widgets/pages/profile_screen/profile_screen_view.dart` (linhas 98-114) — referencia do padrao `await showDialog<T>()` consumido pela `View` pai.
- `lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart` (`createAnalysis`, `openAnalysis`) — referencia das chamadas existentes a `IntakeService.createAnalysis` e `Routes.getAnalysis`.

---

# 10. Pendencias / Duvidas

**Sem pendencias.**

Os textos e icones de cada opcao foram definidos com base no glossario consolidado em ANI-115 (PRD em `documentation/features/intake/judge-analysis/prd.md`) e no PRD de home (`documentation/features/intake/home/prd.md`). Caso o produto valide copy diferente apos a entrega, basta ajustar os getters `titleFor` / `descriptionFor` do presenter sem mudar contrato.
