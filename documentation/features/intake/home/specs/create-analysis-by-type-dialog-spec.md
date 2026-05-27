---
title: Dialog de criação de análise por tipo
prd: ../prd.md
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-101
status: closed
last_updated_at: 2026-05-18
---

# 1. Objetivo

Permitir que o usuário, ao acionar o `FAB` da `Home`, escolha de forma explícita o tipo de análise que será criado entre `CaseAssessmentAnalysis`, `FirstInstanceAnalysis` e `SecondInstanceAnalysis` antes de chamar `IntakeService.createAnalysis(type: ...)`. A entrega introduz um `CreateAnalysisTypeDialog` (`View + Presenter`) com tile por tipo, marcação visual de selecionado, `FirstInstanceAnalysis` como default e botões `Cancelar` / `Criar`, além de adaptar `HomeScreenPresenter` para abrir o dialog, aguardar a seleção via Future e só então criar a análise com o tipo escolhido. Nenhuma alteração de contrato em `core`, `rest` ou `drivers` é necessária.

---

# 2. Escopo

## 2.1 In-scope

- Criar widget interno `CreateAnalysisTypeDialog` em `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/` com `View + Presenter` e `index.dart` com `typedef`.
- Criar subwidget visual `CreateAnalysisTypeOption` (`View only`) em `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_option/` para representar uma opção de tipo na lista (título, descrição curta, ícone e estado selecionado).
- Adaptar `HomeScreenPresenter.createAnalysis()` para receber um `AnalysisTypeDto` selecionado, mantendo `FirstInstanceAnalysis` como tipo default quando a UI não informar nada (chamadas legadas).
- Adaptar `HomeScreenView` (e o callback de `RecentAnalysesEmptyState`) para abrir o dialog via `showDialog<AnalysisTypeDto>` e, ao confirmar, delegar a criação para o presenter com o tipo retornado.
- Manter o spinner de loading do `CreateAnalysisFabView` ligado a `isCreatingAnalysis` apenas durante a criação efetiva (após a confirmação do dialog).
- Garantir que ao cancelar (botão `Cancelar`, tap fora ou back) nada é criado e nenhuma rota é disparada.

## 2.2 Out-of-scope

- Telas dedicadas para `CaseAssessmentAnalysis` e `SecondInstanceAnalysis` (continuam navegando para a rota mapeada hoje em `Routes.getAnalysis`).
- Alterações em `IntakeService`, `IntakeRestService`, `AnalysisMapper` ou qualquer DTO/contrato de `core`/`rest`/`drivers`.
- Mudança em `Routes.getAnalysis` ou registro de novas rotas.
- Alterações na seção `Em andamento` ou nos cards de análise existentes.
- Compatibilidade com tipos legados `lawyer` / `judge` — o contrato anterior não foi exposto ao mobile, conforme registrado no PRD de `home/prd.md`.
- Tracking/analytics da escolha do tipo.
- Localização (i18n); todos os textos continuam em PT-BR hard-coded como nos demais dialogs do app.
- Validação via Google Stitch; nenhum `screen_id` foi fornecido para esta tarefa.
- Testes automatizados (não fazem parte da spec, são tratados em fase posterior).

---

# 3. Requisitos

## 3.1 Funcionais

- Ao tocar no `FAB` da `Home`, abrir o `CreateAnalysisTypeDialog` em vez de criar diretamente uma análise.
- O dialog deve listar exatamente 3 opções correspondentes aos valores de `AnalysisTypeDto`: `CaseAssessmentAnalysis`, `FirstInstanceAnalysis` e `SecondInstanceAnalysis`.
- A opção `FirstInstanceAnalysis` deve estar **pré-selecionada** ao abrir o dialog.
- O usuário deve poder alternar a seleção entre as 3 opções; apenas uma fica marcada por vez.
- O botão primário do dialog deve estar habilitado sempre que houver uma opção selecionada (o que é garantido pelo default).
- Ao confirmar, o dialog deve fechar e retornar via `Navigator.pop` o `AnalysisTypeDto` selecionado.
- Ao cancelar (`Cancelar`, tap fora ou back), o dialog deve fechar e retornar `null`, e nenhuma análise deve ser criada.
- O callback de criação do `RecentAnalysesEmptyState` (botão "Iniciar primeira análise") deve abrir o mesmo dialog antes de criar.
- Após a confirmação, `HomeScreenPresenter.createAnalysis(type: ...)` deve usar o tipo retornado pelo dialog e proceder com o fluxo atual de criação + navegação + refresh, já existente.
- Se o usuário cancelar enquanto uma criação prévia estiver em andamento (`isCreatingAnalysis == true`), o `FAB` deve permanecer desabilitado e o cancelamento não deve afetar a criação em curso.

## 3.2 Não funcionais

- **Acessibilidade:** cada tile do dialog deve ser tocável em área suficiente (`InkWell` com `minimumSize` consistente aos demais dialogs); `Tooltip` no `FAB` segue o padrão atual.
- **Arquitetura:** a `View` do dialog não executa lógica de seleção — toda mudança de estado fica no `CreateAnalysisTypeDialogPresenter`.
- **Compatibilidade:** o `HomeScreenPresenter.createAnalysis` deve aceitar chamada sem argumentos preservando `FirstInstanceAnalysis` como default para não quebrar testes existentes em `test/ui/intake/widgets/pages/home_screen/home_screen_presenter_test.dart`.
- **Visual:** o dialog deve reutilizar `AppThemeTokens` e a mesma forma de container usada por `ArchiveAnalysisDialogView` e `ProfileUpdateNameDialogView` para manter consistência (`Dialog` transparente, `Container` com `surfaceCard`, `borderRadius: 24`, `border: borderSubtle`).

---

# 4. O que já existe?

## Core

- **`AnalysisTypeDto`** (`lib/core/intake/dtos/analysis_type_dto.dart`) — enum com `caseAssessment`, `firstInstance` e `secondInstance`; já exposto ao app e usado pelo `HomeScreenPresenter` para chamar `createAnalysis(type: ...)`.
- **`IntakeService.createAnalysis({required AnalysisTypeDto type, String? folderId})`** (`lib/core/intake/interfaces/intake_service.dart`) — contrato já tipado por tipo de análise; não precisa de alteração.

## UI

- **`HomeScreenView`** (`lib/ui/intake/widgets/pages/home_screen/home_screen_view.dart`) — monta o `Scaffold` da `Home`, observa o presenter via Riverpod e hoje liga o `FAB` diretamente a `presenter.createAnalysis`.
- **`HomeScreenPresenter`** (`lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart`) — orquestrador da `Home`; possui `Signal<bool> isCreatingAnalysis`, `Future<void> createAnalysis()` que já chama `IntakeService.createAnalysis(type: AnalysisTypeDto.firstInstance)` e `openAnalysis(AnalysisDto)` com switch por tipo (`firstInstance`, `secondInstance`, `caseAssessment`).
- **`CreateAnalysisFabView`** (`lib/ui/intake/widgets/pages/home_screen/create_analysis_fab/create_analysis_fab_view.dart`) — botão `FAB` com `Tooltip`, gradient, spinner durante loading; **não precisa de alteração estrutural** para esta spec — continua chamando `onPressed` quando não está loading.
- **`RecentAnalysesSectionView`** (`lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_section_view.dart`) — define o callback `onCreateFirstAnalysis: VoidCallback` repassado para `RecentAnalysesEmptyState`; hoje conectado a `presenter.createAnalysis`.
- **`RecentAnalysesEmptyState`** (`lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_empty_state/`) — empty state com botão "Iniciar primeira análise".
- **`ArchiveAnalysisDialogView`** (`lib/ui/intake/widgets/components/analysis_header/archive_analysis_dialog/archive_analysis_dialog_view.dart`) — referência visual mais próxima para o novo dialog: `Dialog` transparente, container com `surfaceCard`, `borderRadius: 24`, dois botões (`OutlinedButton` + `FilledButton`) com `minimumSize: Size.fromHeight(52)`.
- **`ProfileUpdateNameDialogView`** (`lib/ui/auth/widgets/pages/profile_screen/profile_update_name_dialog/profile_update_name_dialog_view.dart`) — referência de dialog com estado local (`StatefulWidget`) e presenter coadjuvante (`ProfileUpdateNameDialogPresenter` const) chamado pela `View`.
- **`AppThemeTokens` / `AppTheme`** (`lib/theme.dart`) — tokens visuais (`surfaceCard`, `surfacePage`, `surfaceElevated`, `borderSubtle`, `borderStrong`, `accent`, `accentStrong`, `textPrimary`, `textSecondary`, `textMuted`) usados em todos os dialogs.

## Constants

- **`Routes`** (`lib/constants/routes.dart`) — `Routes.getAnalysis({analysisId, analysisType})` já mapeia os 3 tipos para rotas existentes; nenhum ajuste necessário.

---

# 5. O que deve ser criado?

## Camada UI (Presenters)

### `CreateAnalysisTypeDialogPresenter` *(novo arquivo)*

- **Localização:** `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_dialog_presenter.dart`
- **Dependências injetadas:** nenhuma (presenter local de UI, sem service nem driver).
- **Estado (`signals`):**
  - `Signal<AnalysisTypeDto> selectedType` — tipo selecionado no momento; valor inicial vem do parâmetro `initialType` do presenter.
- **Provider Riverpod:** não se aplica — o presenter é instanciado localmente no `State` do `Dialog` (mesmo padrão usado por `ProfileUpdateNameDialogPresenter`), porque o ciclo de vida do presenter coincide com o ciclo de vida do dialog e ele não precisa de dependências injetadas.
- **Métodos:**
  - `CreateAnalysisTypeDialogPresenter({AnalysisTypeDto initialType = AnalysisTypeDto.firstInstance})` — inicializa o `selectedType` com o tipo recebido (default `firstInstance`).
  - `void selectType(AnalysisTypeDto type)` — atualiza `selectedType.value`.
  - `bool isSelected(AnalysisTypeDto type)` — retorna `selectedType.value == type`; usado pela `View` para destacar a opção corrente.
  - `AnalysisTypeDto get selected` — getter conveniente para a `View` recuperar o valor no confirm.
  - `String titleFor(AnalysisTypeDto type)` — devolve o texto curto da opção (ex.: `Avaliação de caso`, `Primeira instância`, `Segunda instância`).
  - `String descriptionFor(AnalysisTypeDto type)` — devolve descrição auxiliar de uma linha para cada tipo (ex.: `Diagnóstico inicial do caso`, `Resposta à petição inicial`, `Revisão de decisão em grau de recurso`).
  - `IconData iconFor(AnalysisTypeDto type)` — devolve o ícone Material adequado (ex.: `Icons.fact_check_outlined`, `Icons.gavel_outlined`, `Icons.account_balance_outlined`).
  - `void dispose()` — libera `selectedType`.
- **Helper estático:**
  - `static const List<AnalysisTypeDto> orderedTypes = <AnalysisTypeDto>[AnalysisTypeDto.caseAssessment, AnalysisTypeDto.firstInstance, AnalysisTypeDto.secondInstance];` — ordem visual fixa das opções (avaliação primeiro, depois 1ª e 2ª instância), refletindo a leitura natural do produto.

## Camada UI (Views)

### `CreateAnalysisTypeDialogView` *(novo arquivo)*

- **Localização:** `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_dialog_view.dart`
- **Base class:** `StatefulWidget` (necessário porque instancia e descarta o presenter local; mesmo padrão de `ProfileUpdateNameDialogView`).
- **Props:**
  - `AnalysisTypeDto initialType` *(opcional, default `AnalysisTypeDto.firstInstance`)* — tipo a ser pré-selecionado.
- **Bibliotecas de UI:** `flutter/material.dart`, `signals_flutter` (para observar `selectedType` via `Watch`).
- **Estrutura visual (referência: `ArchiveAnalysisDialogView`):**
  - `Dialog` transparente, `insetPadding: EdgeInsets.symmetric(horizontal: 24)`.
  - Container com `maxWidth: 352`, `padding: EdgeInsets.all(20)`, `color: tokens.surfaceCard`, `borderRadius: 24`, `border: tokens.borderSubtle`.
  - `Column` com `mainAxisSize: MainAxisSize.min` e `crossAxisAlignment: stretch`:
    1. `Text('Nova análise', titleMedium bold)`
    2. `SizedBox(height: 8)`
    3. `Text('Escolha o tipo da análise.', bodySmall, textMuted)`
    4. `SizedBox(height: 16)`
    5. Lista vertical de `CreateAnalysisTypeOption` (uma por tipo em `orderedTypes`), separadas por `SizedBox(height: 8)`. Cada tile recebe `isSelected`, `onTap` e os textos/ícone vindos do presenter.
    6. `SizedBox(height: 16)`
    7. `Row` com `OutlinedButton('Cancelar')` + `FilledButton('Criar')`, mesmas dimensões/estilos do `ArchiveAnalysisDialogView`.
- **Side effects:**
  - `Cancelar` -> `Navigator.of(context).pop()` sem valor.
  - `Criar` -> `Navigator.of(context).pop<AnalysisTypeDto>(_presenter.selected)`.
- **Estados visuais:** não se aplica (loading/erro não acontecem aqui — o loading da criação continua no `FAB` controlado pelo `HomeScreenPresenter`).
- **Tap fora / back:** comportamento padrão do `Dialog` — fecha com `null`.

## Camada UI (Widgets Internos)

### `CreateAnalysisTypeOption` *(novo arquivo, `View only`)*

- **Localização:** `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_option/`
- **Tipo:** `View only` — widget puramente visual sem estado próprio; toda a lógica de seleção é responsabilidade do `CreateAnalysisTypeDialogPresenter`.
- **Arquivos:**
  - `create_analysis_type_option_view.dart`
  - `index.dart` com `typedef CreateAnalysisTypeOption = CreateAnalysisTypeOptionView;`
- **Props:**
  - `String title`
  - `String description`
  - `IconData icon`
  - `bool isSelected`
  - `VoidCallback onTap`
- **Responsabilidade:** renderizar um tile com `InkWell` + `Container` arredondado contendo ícone, título, descrição e indicador visual de seleção (ex.: `Icons.radio_button_checked` / `Icons.radio_button_unchecked` ou borda destacada com `tokens.accent` quando `isSelected == true`).
- **Estilo:**
  - Padding interno `EdgeInsets.all(12)`.
  - `borderRadius: 16`.
  - Quando `isSelected == true`: `border: tokens.accent` com largura 1.5 e `color: tokens.surfaceElevated`.
  - Quando `isSelected == false`: `border: tokens.borderSubtle`, `color: tokens.surfacePage`.
- **Acessibilidade:** uso de `InkWell` garante feedback de toque; `Semantics(selected: isSelected, button: true, label: title)` envolve o conteúdo para suporte a leitores de tela.

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
- **Mudança:** alterar a assinatura para `Future<void> createAnalysis({AnalysisTypeDto type = AnalysisTypeDto.firstInstance})` e usar o parâmetro `type` na chamada `_intakeService.createAnalysis(type: ...)`. O restante do fluxo (loading, navegação via `Routes.getAnalysis(analysisId: ..., analysisType: type)`, refresh) permanece igual.
- **Justificativa:** o presenter passa a aceitar o tipo escolhido pelo dialog mas continua aceitando chamadas sem argumentos com `FirstInstanceAnalysis` como default, garantindo compatibilidade com os testes existentes e com qualquer chamada legada interna.
- **Sub-mudança:** ao navegar após a criação, trocar a chamada hard-coded `Routes.getFirstInstanceAnalysis(analysisId: ...)` por `Routes.getAnalysis(analysisId: ..., analysisType: type)` para refletir corretamente o tipo escolhido (sem isso, qualquer escolha leva à rota de primeira instância).

### `HomeScreenView` (`FAB` e `EmptyState`)

- **Arquivo:** `lib/ui/intake/widgets/pages/home_screen/home_screen_view.dart`
- **Mudança:**
  - Encapsular o handler do `FAB` em uma função local `Future<void> handleCreateAnalysis(BuildContext context)` que executa `showDialog<AnalysisTypeDto>(context: context, builder: (_) => const CreateAnalysisTypeDialog())` e, se o retorno não for `null`, chama `presenter.createAnalysis(type: selectedType)`.
  - O `onPressed` do `CreateAnalysisFab` passa a chamar `handleCreateAnalysis(context)` em vez de `presenter.createAnalysis`.
  - O `onCreateFirstAnalysis` do `RecentAnalysesSection` passa a chamar a mesma função `handleCreateAnalysis(context)`.
- **Justificativa:** centraliza a orquestração de abertura do dialog na `View`, mantendo o presenter agnóstico ao framework de dialog (`showDialog` é responsabilidade visual). Garante que ambos os pontos de criação (FAB e empty state) abrem o mesmo dialog.
- **Restrição arquitetural:** o presenter não orquestra `showDialog` porque isso acoplaria o presenter a `BuildContext` e ao `Navigator` do Flutter. A lógica que continua na `View` é estritamente de invocação visual; o "que fazer com o tipo" continua no `HomeScreenPresenter.createAnalysis(type: ...)`.

---

# 7. O que deve ser removido?

**Não aplicável** — nenhum arquivo, contrato ou comportamento legado precisa ser removido por esta spec. A semântica antiga `lawyer` / `judge` já não existe na codebase e já foi tratada em ANI-115.

---

# 8. Decisões Técnicas e Trade-offs

### Decisão 1: `showDialog` na `View`, criação no `Presenter`

- **Decisão:** o `HomeScreenView` chama `showDialog<AnalysisTypeDto>` e, ao receber o tipo, delega para `presenter.createAnalysis(type: ...)`. O presenter não recebe nem cria o dialog.
- **Alternativas consideradas:**
  1. Mover `showDialog` para o presenter via um `DialogDriver` (port) — descartado: não existe `DialogDriver` no projeto e introduzir um novo driver só para este caso é overhead arquitetural desnecessário; os demais dialogs do app (`ProfileUpdateNameDialog`, `ArchiveAnalysisDialog`) seguem o mesmo padrão View-orquestra-dialog.
  2. Tornar o `FAB` um `Stack` com o dialog já embutido — descartado: quebra a separação de pasta/widget e dificulta reuso do dialog pelo botão `EmptyState`.
- **Motivo da escolha:** alinhamento com o padrão já estabelecido na codebase; mantém o presenter livre de `BuildContext`; minimiza a superfície de mudança.
- **Impactos / trade-offs:** o teste de widget do `HomeScreenView` precisará cobrir a abertura/cancelamento do dialog; o teste de presenter atual continua válido porque a assinatura `createAnalysis()` (sem argumentos) ainda funciona com default.

### Decisão 2: presenter local instanciado no `State` do dialog (sem Riverpod)

- **Decisão:** `CreateAnalysisTypeDialogPresenter` é instanciado no `initState` do `_CreateAnalysisTypeDialogViewState` e descartado no `dispose`, sem provider Riverpod.
- **Alternativas consideradas:**
  1. Provider Riverpod `autoDispose` dedicado para o dialog — descartado: o presenter não tem dependências injetadas, e o ciclo de vida coincide exatamente com o dialog (mesma situação do `ProfileUpdateNameDialogPresenter`).
- **Motivo da escolha:** consistência com padrões de dialogs já existentes no projeto; evita provider sem ganho real.
- **Impactos / trade-offs:** teste de widget do dialog instanciará o `View` diretamente; testes unitários do presenter podem ser feitos sem `ProviderContainer`.

### Decisão 3: `FirstInstanceAnalysis` como tipo default selecionado e default do presenter

- **Decisão:** o `initialType` do dialog default é `AnalysisTypeDto.firstInstance`, e `HomeScreenPresenter.createAnalysis` continua com `firstInstance` como default de parâmetro.
- **Motivo da escolha:** mantém continuidade com o comportamento atual (o fluxo de `FirstInstanceAnalysis` é o único com tela dedicada implementada); reduz fricção para o usuário comum que sempre cria primeira instância; preserva compatibilidade com testes existentes que chamam `createAnalysis()` sem argumentos.
- **Impactos / trade-offs:** se no futuro o produto quiser destacar outro tipo como default, basta passar `initialType` diferente para `CreateAnalysisTypeDialog` ou ajustar o default do presenter.

### Decisão 4: navegação pós-criação usa `Routes.getAnalysis(analysisType: type)`

- **Decisão:** após criar a análise, navegar usando `Routes.getAnalysis(analysisId: ..., analysisType: type)` em vez do hard-coded `Routes.getFirstInstanceAnalysis(...)`.
- **Motivo da escolha:** garante que, ao escolher `SecondInstanceAnalysis` ou `CaseAssessment`, a rota correta seja aberta (mesma lógica já usada por `HomeScreenPresenter.openAnalysis`).
- **Impactos / trade-offs:** `Routes.getAnalysis` já existe e atualmente mapeia `caseAssessment` para a mesma rota de `secondInstance` — esse mapeamento continua sob responsabilidade de ANI futuras e não é alterado aqui.

### Decisão 5: textos e ícones definidos no presenter, não na view

- **Decisão:** os getters `titleFor`, `descriptionFor` e `iconFor` ficam no `CreateAnalysisTypeDialogPresenter`.
- **Alternativas consideradas:** colocar um `Map` const na `View` ou no próprio `AnalysisTypeDto`.
- **Motivo da escolha:** o `AnalysisTypeDto` mora em `core` e não deve depender de Flutter (`IconData`); manter os textos no presenter centraliza o conhecimento de apresentação e facilita ajuste futuro de copy.
- **Impactos / trade-offs:** caso o projeto venha a ter i18n, os textos passam a vir de um repositório de tradutoras; até lá, hard-coded em PT-BR (consistente com o resto do app).

---

# 9. Diagramas e Referências

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
         ├─ Text "Nova análise"
         ├─ Text "Escolha o tipo da análise."
         ├─ CreateAnalysisTypeOption  (CaseAssessment)
         ├─ CreateAnalysisTypeOption  (FirstInstance, default selected)
         ├─ CreateAnalysisTypeOption  (SecondInstance)
         └─ Row [OutlinedButton "Cancelar", FilledButton "Criar"]
```

## Referências

- `lib/ui/intake/widgets/components/analysis_header/archive_analysis_dialog/archive_analysis_dialog_view.dart` — referência visual primária (container, botões, paddings, raios).
- `lib/ui/auth/widgets/pages/profile_screen/profile_update_name_dialog/profile_update_name_dialog_view.dart` — referência de `StatefulWidget` com presenter local instanciado no `State`.
- `lib/ui/auth/widgets/pages/profile_screen/profile_update_name_dialog/profile_update_name_dialog_presenter.dart` — referência de presenter de dialog (sem dependências externas).
- `lib/ui/auth/widgets/pages/profile_screen/profile_screen_view.dart` (linhas 98-114) — referência do padrão `await showDialog<T>()` consumido pela `View` pai.
- `lib/ui/intake/widgets/pages/home_screen/home_screen_presenter.dart` (`createAnalysis`, `openAnalysis`) — referência das chamadas existentes a `IntakeService.createAnalysis` e `Routes.getAnalysis`.

---

# 10. Pendências / Dúvidas

**Sem pendências.**

Os textos e ícones de cada opção foram definidos com base no glossário consolidado em ANI-115 (PRD em `documentation/features/intake/judge-analysis/prd.md`) e no PRD de home (`documentation/features/intake/home/prd.md`). Caso o produto valide copy diferente após a entrega, basta ajustar os getters `titleFor` / `descriptionFor` do presenter sem mudar contrato.
