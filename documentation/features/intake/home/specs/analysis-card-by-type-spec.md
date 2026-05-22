---
title: Card de análise na Home adaptado por tipo de análise
prd: ../prd.md
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-102
status: closed
last_updated_at: 2026-05-20
---

# 1. Objetivo

Adaptar a apresentação do card de análise na lista da `Home` (`RecentAnalysesSectionView`) para refletir, de forma visual e textual, o tipo de cada análise (`CaseAssessmentAnalysis`, `FirstInstanceAnalysis`, `SecondInstanceAnalysis`) sem depender mais da nomenclatura legada `lawyer` / `judge`. A entrega introduz um ícone e um rótulo de tipo ao lado da data em cada card (tanto no card de "Em andamento" — `ProcessingAnalysisCardView` — quanto no card de "Recentes" — `RecentAnalysisCardView`), reaproveitando a mesma escolha de ícone e título por tipo já definida em `CreateAnalysisTypeDialogPresenter` para manter consistência visual com o dialog de criação. A regra de mapeamento `lawyer → firstInstance` e `judge → secondInstance` continua centralizada em `AnalysisMapper._toType`, preservando compatibilidade com payload legado vindo do backend.

---

# 2. Escopo

## 2.1 In-scope

- Criar um helper de apresentação `AnalysisTypePresentation` em `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/` (subpasta `analysis_type_presentation/`) que centraliza, para um `AnalysisTypeDto`, os textos curtos (`shortLabel`) e o `IconData` correspondente — reaproveitando exatamente as mesmas escolhas já feitas em `CreateAnalysisTypeDialogPresenter` (`titleFor`, `iconFor`) para manter consistência visual.
- Criar widget interno `AnalysisTypeBadge` (`View only`) em `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/analysis_type_badge/` para renderizar um "chip" (`Container` arredondado com ícone + rótulo) representando o tipo da análise.
- Adaptar `RecentAnalysisCardView` para receber um `AnalysisTypeDto type` obrigatório e renderizar o `AnalysisTypeBadge` ao lado do rótulo de data, mantendo o `statusLabel` opcional como já está hoje.
- Adaptar `ProcessingAnalysisCardView` para receber o mesmo `AnalysisTypeDto type` e renderizar o `AnalysisTypeBadge` no mesmo lugar (linha do header `Wrap` que hoje exibe data + status), preservando o gradient e o spinner de processamento.
- Adaptar `RecentAnalysesSectionView` para passar `analysis.type` ao construir cada card.
- Adaptar `recent_analyses_section/index.dart` (barrel) para reexportar `AnalysisTypeBadge` e `AnalysisTypePresentation`, mantendo a fronteira pública da seção.
- Garantir, via `AnalysisMapper._toType`, que payloads legados (`LAWYER` / `JUDGE`) continuam sendo normalizados para `firstInstance` / `secondInstance` antes de chegar à UI — não criar lógica de fallback na camada UI.

## 2.2 Out-of-scope

- Alterações em `CreateAnalysisTypeDialogPresenter` ou em qualquer arquivo dentro de `create_analysis_type_dialog/` — o presenter do dialog continua sendo a referência de copy/ícone para os 3 tipos.
- Alterações em `lib/core/intake/dtos/analysis_type_dto.dart` (já tem os 3 tipos via ANI-115; nenhum método `normalize` precisa ser introduzido).
- Alterações em `IntakeService`, `IntakeRestService`, `AnalysisMapper._toType` ou em qualquer DTO/contrato de `core`/`rest`/`drivers` — o mapeamento `LAWYER → firstInstance` / `JUDGE → secondInstance` já existe e deve continuar como está.
- Alterações em `HomeScreenPresenter`, `HomeScreenView`, `CreateAnalysisFabView`, `RecentAnalysesEmptyState`, `RecentAnalysesErrorState`, `RecentAnalysesInlineError`, `RecentAnalysesLoadingMore`, `RecentAnalysesLoadingState` ou `RecentAnalysesSkeletonCard` — o escopo é exclusivamente os dois cards (recentes e em andamento).
- Mudanças em `Routes` ou navegação pós-tap; o `onTap` do card continua delegando para `HomeScreenPresenter.openAnalysis`.
- Alterações nas labels de status existentes (`_resolveStatusLabel` em `RecentAnalysesSectionView`).
- Tracking/analytics de exibição do tipo no card.
- Localização (i18n); todos os textos permanecem em PT-BR hard-coded e acentuados, alinhados ao padrão atual da app.
- Testes automatizados (não fazem parte da spec; são tratados em fase posterior do conclude-spec).

---

# 3. Requisitos

## 3.1 Funcionais

- Cada card de análise renderizado em `RecentAnalysesSectionView` (tanto na seção `Em andamento` quanto na seção `Recentes`) deve exibir um indicador visual do tipo da análise composto por ícone + rótulo curto.
- O rótulo curto e o ícone devem ser idênticos aos usados em `CreateAnalysisTypeDialogPresenter` para o mesmo `AnalysisTypeDto`:
  - `caseAssessment` → `Icons.fact_check_outlined` + "Avaliação de caso"
  - `firstInstance` → `Icons.gavel_outlined` + "Primeira instância"
  - `secondInstance` → `Icons.account_balance_outlined` + "Segunda instância"
- O layout textual/visual do card passa a ser organizado com o título em uma linha superior e, abaixo, uma linha contendo a data e o badge de tipo (via `Wrap` para quebrar gracioso em telas estreitas).
- Quando houver `statusLabel`, ele continua sendo exibido no card como pill/indicador visual em **linha separada** com ícone próprio, sem a exigência de permanecer no mesmo `Wrap` da data e do badge de tipo.
- O comportamento de tap e navegação do card deve permanecer inalterado apesar da reorganização visual do conteúdo.
- O badge não deve ser opcional na API do card — `type` é parâmetro obrigatório, garantindo que toda análise listada tenha tipo explícito (refletindo o domínio que já é obrigatoriamente tipado em `AnalysisDto.type`).
- Se a análise vier do backend com payload legado (`LAWYER` / `JUDGE`), o card deve renderizar corretamente como "Primeira instância" / "Segunda instância", já que a normalização ocorre em `AnalysisMapper._toType` antes da UI receber o DTO. **Nenhuma lógica de fallback adicional deve viver na camada UI.**

## 3.2 Não funcionais

- **Acessibilidade:** o badge deve envolver ícone + rótulo em um `Semantics(label: 'Tipo: <shortLabel>')` para que leitores de tela anunciem o tipo da análise; o conteúdo do badge deve manter contraste legível em relação ao fundo com tint aplicado para cada tipo.
- **Arquitetura:** nenhuma lógica de mapeamento `string → tipo` deve vazar para a UI; o ícone/texto/cor por tipo deve ser obtido via `AnalysisTypePresentation` (helper puro de UI, sem dependência de service ou driver).
- **Visual:** o badge deve usar a cor semântica de cada tipo de análise (a mesma usada para definir ícone e rótulo), aplicando variações com transparência/tint dessa cor no fundo e na borda, e usar `borderRadius: 999` (mesmo padrão de pill do badge de status atual em `RecentAnalysisCardView`).
- **Compatibilidade visual:** a altura visual do card não deve aumentar significativamente em telas estreitas — o `Wrap` existente garante quebra de linha quando data + tipo + status não couberem na mesma linha.

---

# 4. O que já existe?

## Core

- **`AnalysisTypeDto`** (`lib/core/intake/dtos/analysis_type_dto.dart`) — enum com `caseAssessment`, `firstInstance` e `secondInstance`; cobre os 3 tipos do domínio; consumido em todo o app.
- **`AnalysisDto`** (`lib/core/intake/dtos/analysis_dto.dart`) — possui `final AnalysisTypeDto type` obrigatório; é o DTO já consumido por `RecentAnalysesSectionView` e que passará o tipo para cada card.

## Rest

- **`AnalysisMapper._toType`** (`lib/rest/mappers/intake/analysis_mapper.dart`) — já mapeia `LAWYER → firstInstance` e `JUDGE → secondInstance`, além dos valores canônicos `CASE_ASSESSMENT`, `FIRST_INSTANCE` e `SECOND_INSTANCE`. Garante que a camada UI nunca receba nomenclatura legada. **Nenhuma alteração é necessária — a compatibilidade já está implementada.**

## UI

- **`RecentAnalysesSectionView`** (`lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_section_view.dart`) — lista as análises separando "Em andamento" e "Recentes"; itera por `analyses: List<AnalysisDto>` e instancia `ProcessingAnalysisCard` ou `RecentAnalysisCard` para cada item. Já tem acesso a `analysis.type`.
- **`RecentAnalysisCardView`** (`lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analysis_card/recent_analysis_card_view.dart`) — card visual da seção `Recentes`; renderiza `dateLabel` + `statusLabel` opcional em um `Wrap` + título + chevron. Vai ganhar o badge de tipo.
- **`ProcessingAnalysisCardView`** (`lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/processing_analysis_card/processing_analysis_card_view.dart`) — card visual da seção `Em andamento`; mesma estrutura visual com gradient + spinner; também vai ganhar o badge de tipo.
- **`CreateAnalysisTypeDialogPresenter`** (`lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_dialog_presenter.dart`) — referência canônica de copy e ícone por tipo (`titleFor`, `iconFor`); o novo helper de apresentação deve usar exatamente as mesmas escolhas para manter consistência visual entre o dialog de criação e os cards.
- **`AppThemeTokens` / `AppTheme`** (`lib/theme.dart`) — tokens visuais (`surfaceElevated`, `borderSubtle`, `textSecondary`, `textMuted`) usados no badge de status atual e que serão reutilizados pelo badge de tipo.
- **Barrel `recent_analyses_section/index.dart`** (`lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/index.dart`) — barrel atual da seção; precisará reexportar os dois novos artefatos.

---

# 5. O que deve ser criado?

## Camada UI (Helper de apresentação)

### `AnalysisTypePresentation` *(novo arquivo)*

- **Localização:** `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/analysis_type_presentation/analysis_type_presentation.dart`
- **Natureza:** classe utilitária `final` com construtor privado e métodos estáticos puros — sem estado, sem dependências, sem `Signals`. Não é um `Presenter` no sentido MVP; é um helper de apresentação local da seção `recent_analyses_section`.
- **Justificativa de não ser presenter MVP:** o widget consumidor (`AnalysisTypeBadge`) é puramente visual (View only) — não há estado nem handlers. O conteúdo (label + icon) é derivação determinística de `AnalysisTypeDto`, e portanto vive em um helper estático ao invés de um presenter Signals/Riverpod. Mesma decisão já adotada para `CreateAnalysisTypeDialogPresenter.titleFor/iconFor`, mas como aqui não há nada além desses getters, a classe não precisa do overhead de presenter.
- **Métodos:**
  - `static String shortLabelFor(AnalysisTypeDto type)` — retorna o rótulo curto correspondente: "Avaliação de caso", "Primeira instância" ou "Segunda instância". Valores idênticos a `CreateAnalysisTypeDialogPresenter.titleFor`.
  - `static IconData iconFor(AnalysisTypeDto type)` — retorna o `IconData` correspondente: `Icons.fact_check_outlined`, `Icons.gavel_outlined` ou `Icons.account_balance_outlined`. Valores idênticos a `CreateAnalysisTypeDialogPresenter.iconFor`.
- **Arquivos:**
  - `analysis_type_presentation.dart`
  - `index.dart` com `export 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/analysis_type_presentation/analysis_type_presentation.dart';` (sem typedef — não é widget).

## Camada UI (Widgets Internos)

### `AnalysisTypeBadge` *(novo arquivo, `View only`)*

- **Localização:** `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/analysis_type_badge/`
- **Tipo:** `View only` — widget puramente visual sem estado próprio; toda derivação de label/icon vem do `AnalysisTypePresentation` e é resolvida pelo widget consumidor antes de instanciar o badge.
- **Arquivos:**
  - `analysis_type_badge_view.dart`
  - `index.dart` com `typedef AnalysisTypeBadge = AnalysisTypeBadgeView;`
- **Props:**
  - `AnalysisTypeDto type` — usado para resolver `label` e `icon` via `AnalysisTypePresentation` internamente; manter a prop como o próprio enum (e não como `String label` + `IconData icon` separados) deixa a API mais coesa e impede que callers passem combinações inconsistentes.
- **Bibliotecas de UI:** `flutter/material.dart`.
- **Responsabilidade:** renderizar um pill arredondado (`Container` com `borderRadius: 999`, `padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3)`) contendo um `Icon` (size 14) seguido de `SizedBox(width: 4)` e um `Text` com o `shortLabel`. Cores baseadas em `AppThemeTokens.surfaceElevated` (fundo), `tokens.borderSubtle` (borda), `tokens.textSecondary` (texto e ícone).
- **Acessibilidade:** envolver o badge em `Semantics(label: 'Tipo: $shortLabel', container: true)` para que leitores de tela anunciem explicitamente o tipo da análise.
- **Estilo:**
  - `Container` arredondado, mesma família visual do badge de status atual em `RecentAnalysisCardView` (linhas 59-76) — `borderRadius: 999`, `border: tokens.borderSubtle`, `color: tokens.surfaceElevated`.
  - Tipografia: `textTheme.labelSmall` com `color: tokens.textSecondary` e `fontWeight: FontWeight.w600`.
  - Tamanho do ícone: 14px para casar visualmente com a altura do `labelSmall`.

## Camada UI (Barrel Files / `index.dart`)

### `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/analysis_type_badge/index.dart` *(novo arquivo)*

- **`typedef` exportado:** `typedef AnalysisTypeBadge = AnalysisTypeBadgeView;`

### `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/analysis_type_presentation/index.dart` *(novo arquivo)*

- **Exporta:** `analysis_type_presentation.dart` (sem typedef; helper estático).

## Estrutura de Pastas

```text
lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/
  index.dart                                                    ← modificado: reexporta os dois novos
  recent_analyses_section_view.dart                             ← modificado: passa analysis.type aos cards
  analysis_type_badge/                                          ← NOVA pasta
    index.dart                                                  ← typedef AnalysisTypeBadge
    analysis_type_badge_view.dart
  analysis_type_presentation/                                   ← NOVA pasta
    index.dart                                                  ← export do helper
    analysis_type_presentation.dart
  recent_analysis_card/
    index.dart                                                  ← inalterado
    recent_analysis_card_view.dart                              ← modificado: aceita type e renderiza AnalysisTypeBadge
  processing_analysis_card/
    index.dart                                                  ← inalterado
    processing_analysis_card_view.dart                          ← modificado: aceita type e renderiza AnalysisTypeBadge
  ... (outros subwidgets inalterados)
```

---

# 6. O que deve ser modificado?

## Camada UI

### `RecentAnalysisCardView`

- **Arquivo:** `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analysis_card/recent_analysis_card_view.dart`
- **Mudança:**
  - Adicionar prop obrigatória `final AnalysisTypeDto type;` no construtor.
  - No `Wrap` que renderiza `dateLabel` + `statusLabel`, inserir um `AnalysisTypeBadge(type: type)` **entre** o `Text(dateLabel)` e o badge de status atual.
  - Importar `AnalysisTypeDto` (de `package:animus/core/intake/dtos/analysis_type_dto.dart`) e o novo `AnalysisTypeBadge` (via barrel `analysis_type_badge/index.dart`).
- **Justificativa:** o card precisa exibir o tipo lado a lado com data e status; manter os 3 elementos no mesmo `Wrap` preserva o comportamento de quebra de linha em telas estreitas e respeita o `runSpacing` atual.

### `ProcessingAnalysisCardView`

- **Arquivo:** `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/processing_analysis_card/processing_analysis_card_view.dart`
- **Mudança:**
  - Adicionar prop obrigatória `final AnalysisTypeDto type;` no construtor.
  - No `Wrap` que renderiza `dateLabel` + `statusLabel`, inserir um `AnalysisTypeBadge(type: type)` **entre** o `Text(dateLabel)` e o badge de status atual.
  - Importar `AnalysisTypeDto` e `AnalysisTypeBadge`.
- **Justificativa:** mesma motivação do card de "Recentes" — consistência visual entre as duas seções e clareza do tipo durante o processamento.

### `RecentAnalysesSectionView`

- **Arquivo:** `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_section_view.dart`
- **Mudança:**
  - Ao construir `ProcessingAnalysisCard(...)` (linha ~194), passar `type: analysis.type`.
  - Ao construir `RecentAnalysisCard(...)` (linha ~229), passar `type: analysis.type`.
- **Justificativa:** propagar o tipo já presente em `AnalysisDto` para os cards; a section é o ponto natural de fan-out por já estar iterando sobre `AnalysisDto`.

### Barrel `recent_analyses_section/index.dart`

- **Arquivo:** `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/index.dart`
- **Mudança:** adicionar dois `export` para os novos artefatos:
  - `export 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/analysis_type_badge/index.dart';`
  - `export 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/analysis_type_presentation/index.dart';`
- **Justificativa:** manter a fronteira pública da pasta da seção, alinhada ao padrão de barrel files do projeto.

---

# 7. O que deve ser removido?

**Não aplicável** — a entrega adiciona um indicador visual aos cards existentes; não há código legado a remover. A nomenclatura `lawyer` / `judge` não vive na codebase (UI nem core) — apenas como string `LAWYER` / `JUDGE` no parser do `AnalysisMapper`, que deve permanecer intacta para garantir compatibilidade com payload legado do backend.

---

# 8. Decisões Técnicas e Trade-offs

### Decisão 1: helper estático `AnalysisTypePresentation` em vez de duplicar getters do dialog

- **Decisão:** criar um helper estático puro com `shortLabelFor` e `iconFor`, em vez de chamar diretamente os getters de `CreateAnalysisTypeDialogPresenter` ou copiar/colar as escolhas no novo widget.
- **Alternativas consideradas:**
  1. Chamar `CreateAnalysisTypeDialogPresenter.titleFor` e `.iconFor` diretamente do card — descartado: criaria acoplamento entre dois widgets independentes (`create_analysis_type_dialog` e `recent_analyses_section`) e exigiria instanciar um presenter só para ler getters.
  2. Mover os getters para uma extension em `AnalysisTypeDto` — descartado: `AnalysisTypeDto` vive em `lib/core/` e core não pode depender de Flutter (`IconData`), conforme regra arquitetural já registrada na Decisão 5 da spec ANI-101.
  3. Duplicar literalmente os getters dentro de `AnalysisTypeBadge` — descartado: viola DRY e cria risco real de divergência de copy/ícone entre o dialog e o card no futuro.
- **Motivo da escolha:** helper estático puro mantém a regra de mapeamento em um único local de UI, sem acoplar widgets entre si, sem violar `core` e sem overhead de presenter. Mantém a regra arquitetural "core não conhece Flutter".
- **Impactos / trade-offs:** se um dia o produto quiser copy ou ícone diferente entre o dialog (na criação) e o card (na listagem), basta divergir o helper do presenter — hoje eles são acoplados por convenção textual, mas livres a divergir. Há uma duplicação textual implícita entre `AnalysisTypePresentation` e `CreateAnalysisTypeDialogPresenter`; aceitamos isso porque os dois lugares têm contextos de uso distintos (dialog de seleção vs. badge de listagem) e a convergência semântica atual é o que produz a consistência visual desejada pelo PRD.

### Decisão 2: `AnalysisTypeBadge` é View only

- **Decisão:** o widget interno `AnalysisTypeBadge` não tem presenter — recebe um `AnalysisTypeDto type` e resolve label/icon via `AnalysisTypePresentation` na própria `build`.
- **Alternativas consideradas:**
  - Criar `AnalysisTypeBadgePresenter` — descartado: não há estado, handler ou lógica reativa; o padrão MVP do projeto permite `View only` quando o widget é puramente visual.
- **Motivo da escolha:** a regra UI explícita autoriza `View only` para widgets visuais; introduzir presenter aqui seria abstração artificial (mesma diretriz "Quando evitar abstracao extra" do `ui-layer-rules.md`).
- **Impactos / trade-offs:** nenhum; o badge fica trivialmente testável via widget test.

### Decisão 3: badge no `Wrap` existente em vez de uma nova linha

- **Decisão:** inserir o badge no mesmo `Wrap` que hoje agrupa `dateLabel` + `statusLabel`, entre os dois.
- **Alternativas consideradas:**
  1. Criar uma nova `Row` acima da data com o badge isolado — descartado: aumenta a altura do card em ~22px, prejudica densidade de listagem e quebra o ritmo visual atual.
  2. Posicionar o badge no canto direito do card, ao lado do chevron — descartado: rouba área do título (que já é `maxLines: 2`) e foge da posição "metadados" naturalmente esperada.
- **Motivo da escolha:** o `Wrap` já existe com `runSpacing: 6` exatamente para esse tipo de evolução; preserva altura do card e a hierarquia "data → tipo → status → título" segue a leitura natural do usuário (quando? que tipo? em que estado? sobre o quê?).
- **Impactos / trade-offs:** em telas muito estreitas (< 320dp) os três pills podem ocupar duas linhas — comportamento aceitável e já previsto pelo `Wrap`.

### Decisão 4: `type` é prop obrigatória (e não opcional com default)

- **Decisão:** `final AnalysisTypeDto type` é parâmetro obrigatório nos dois cards.
- **Alternativas consideradas:**
  - Manter opcional com default `firstInstance` para suavizar migração — descartado: nenhum caller fora de `RecentAnalysesSectionView` instancia esses cards (verificado), e `AnalysisDto.type` é obrigatório, então nunca há ambiguidade de tipo no caller.
- **Motivo da escolha:** segurança de tipos; impede que um futuro caller esqueça de passar o tipo e exiba um badge silenciosamente incorreto.
- **Impactos / trade-offs:** quebra compatibilidade com testes existentes do `RecentAnalysesSectionView` que constroem mocks via `AnalysisDtoFaker.fake()`. O `Faker` já tem default `firstInstance`, então o impacto se limita ao caller atualizar a passagem do `type` no construtor dos cards — coberto pela própria alteração de section view.

### Decisão 5: compatibilidade com payload legado fica em `rest`, não em `ui`

- **Decisão:** a compatibilidade `LAWYER → firstInstance` / `JUDGE → secondInstance` permanece em `AnalysisMapper._toType`, sem nenhuma camada de fallback adicional na UI.
- **Alternativas consideradas:**
  - Adicionar um `static AnalysisTypeDto normalize(String raw)` em `AnalysisTypeDto` — descartado: o enum vive em `lib/core/` que é agnóstico de transporte; mistura responsabilidade de mapping de payload com definição de domínio. Além disso, ANI-115 já decidiu não expor a nomenclatura legada ao app via DTO.
  - Tratar o caso em `AnalysisTypePresentation` — descartado: o helper recebe `AnalysisTypeDto`, não `String`; a normalização precisa acontecer **antes** de virar enum.
- **Motivo da escolha:** mantém cada camada com sua responsabilidade — `rest` traduz transporte, `ui` consome tipos canônicos. A regra "Nao deve fazer parse de JSON" do `ui-layer-rules.md` é respeitada literalmente.
- **Impactos / trade-offs:** se o backend introduzir outro alias legado no futuro, o ajuste fica concentrado em `AnalysisMapper._toType` — nenhum widget precisa ser tocado.

---

# 9. Diagramas e Referências

## Fluxo de dados

```text
Backend payload (com 'LAWYER' ou 'FIRST_INSTANCE')
    └─ AnalysisMapper._toType → AnalysisTypeDto.firstInstance   (camada rest, já existente)
          └─ AnalysisDto (core)
                └─ HomeScreenPresenter.recentAnalyses (Signal<List<AnalysisDto>>)
                      └─ HomeScreenView → RecentAnalysesSection (analyses: ...)
                            └─ RecentAnalysesSectionView
                                  ├─ ProcessingAnalysisCard(type: analysis.type, ...)
                                  │     └─ AnalysisTypeBadge(type: type)
                                  │           └─ AnalysisTypePresentation.shortLabelFor(type) + iconFor(type)
                                  └─ RecentAnalysisCard(type: analysis.type, ...)
                                        └─ AnalysisTypeBadge(type: type)
                                              └─ AnalysisTypePresentation.shortLabelFor(type) + iconFor(type)
```

## Hierarquia de widgets

```text
RecentAnalysesSectionView
└─ ListView
   ├─ ProcessingAnalysisCard                    (mudou: nova prop type)
   │  └─ Material > InkWell > Ink
   │     └─ Row
   │        ├─ Expanded > Column
   │        │  ├─ Wrap (spacing 8, runSpacing 6)
   │        │  │  ├─ Text(dateLabel)
   │        │  │  ├─ AnalysisTypeBadge(type: type)        ← NOVO
   │        │  │  └─ Container (statusLabel pill)         ← existente
   │        │  └─ Row [Spinner, Expanded(Text(title))]
   │        └─ Icon(chevron_right)
   └─ RecentAnalysisCard                        (mudou: nova prop type)
      └─ Material > InkWell > Ink
         └─ Row
            ├─ Expanded > Column
            │  ├─ Wrap (spacing 8, runSpacing 6)
            │  │  ├─ Text(dateLabel)
            │  │  ├─ AnalysisTypeBadge(type: type)        ← NOVO
            │  │  └─ Container (statusLabel pill)         ← existente
            │  └─ Text(title)
            └─ Icon(chevron_right)
```

## Referências

- `lib/ui/intake/widgets/pages/home_screen/create_analysis_type_dialog/create_analysis_type_dialog_presenter.dart` — fonte canônica das escolhas de copy/ícone por tipo (`titleFor`, `iconFor`). O helper `AnalysisTypePresentation` reaproveita exatamente as mesmas strings e ícones.
- `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analysis_card/recent_analysis_card_view.dart` (linhas 59-76) — referência visual do pill existente (`borderRadius: 999`, `border`, `color: surfaceElevated`); o `AnalysisTypeBadge` reaproveita exatamente o mesmo estilo.
- `lib/rest/mappers/intake/analysis_mapper.dart` (linhas 31-44) — referência da compatibilidade com payload legado `LAWYER` / `JUDGE` que continua intacta nesta spec.
- `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/processing_analysis_card/processing_analysis_card_view.dart` — referência para entender onde inserir o badge no card de "Em andamento" sem perturbar o gradient e o spinner.

---

# 10. Pendências / Dúvidas

**Sem pendências.**

A consistência visual entre o dialog de criação e o badge da listagem foi explicitamente solicitada pelo contexto da task ANI-102; a duplicação textual do copy entre `AnalysisTypePresentation` e `CreateAnalysisTypeDialogPresenter` é aceita conscientemente (ver Decisão 1). A compatibilidade com payload legado já está garantida em `AnalysisMapper._toType` (ANI-115) e a spec não precisa introduzir nenhuma lógica adicional para isso.
