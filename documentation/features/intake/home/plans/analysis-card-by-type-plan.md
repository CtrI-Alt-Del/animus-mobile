---
title: Plano de Implementação — Card de análise na Home adaptado por tipo de análise
spec: ../specs/analysis-card-by-type-spec.md
created_at: 2026-05-20
status: closed
---

---

## Análise de Dependências

### Artefatos do `core` que desbloqueiam outras camadas

- Nenhum. `AnalysisTypeDto` (`lib/core/intake/dtos/analysis_type_dto.dart`) e `AnalysisDto` (`lib/core/intake/dtos/analysis_dto.dart`) já existem com os 3 tipos do domínio e já são consumidos pela `Home`. A spec não introduz nem altera DTOs/contratos.

### Partes de `rest` e `drivers` independentes entre si

- Nenhuma alteração em `rest` ou `drivers`. `AnalysisMapper._toType` (`lib/rest/mappers/intake/analysis_mapper.dart`) já normaliza `LAWYER → firstInstance` e `JUDGE → secondInstance` desde ANI-115 — a compatibilidade com payload legado fica intacta.

### Presenters/widgets/screens paralelizáveis

- `AnalysisTypePresentation` (helper estático puro) e `AnalysisTypeBadge` (View only) são dois artefatos independentes entre si que podem ser criados em paralelo:
  - `AnalysisTypeBadge` consome `AnalysisTypePresentation`, mas como ambos vivem na camada UI e o helper é trivial (3 cases por método), na prática a fase 1 implementa ambos em sequência muito rápida — não há ganho real em paralelizar dentro da fase.
- A adaptação de `RecentAnalysisCardView` (card "Recentes") e `ProcessingAnalysisCardView` (card "Em andamento") consome o mesmo `AnalysisTypeBadge` e pode ser feita em paralelo entre si — mesma fase, tarefas distintas (F2-T1 e F2-T2).
- A propagação no `RecentAnalysesSectionView` depende das duas adaptações anteriores (as props mudam para obrigatórias).

### Tarefas iniciáveis com stub

- Nenhuma. Como o `AnalysisTypeBadge` é trivial (input enum → output `Container` com label/icon), não há motivo arquitetural para mockar — o componente é completado em poucos minutos antes dos cards consumirem.

---

## ⚠️ Gargalos identificados

- **F1-T2 — Criar `AnalysisTypeBadge`**: bloqueia F2-T1 (adaptar `RecentAnalysisCardView`) e F2-T2 (adaptar `ProcessingAnalysisCardView`); deve ser a segunda tarefa concluída após o helper de apresentação (F1-T1).
- **F2 — Adaptação dos cards**: bloqueia F3 (propagação no `RecentAnalysesSectionView` + barrel) porque as props dos cards mudam de assinatura.

---

## Mapa de Paralelização

| Fase | Objetivo | Depende de | Pode rodar em paralelo com |
|------|----------|------------|----------------------------|
| F1   | Criar artefatos novos (helper de apresentação e badge) | - | - |
| F2   | Adaptar os dois cards existentes (recente e em andamento) para receber `type` e renderizar o badge | F1 | - (T1 e T2 da F2 podem rodar em paralelo entre si) |
| F3   | Propagar `analysis.type` na seção e atualizar barrel + testes existentes | F2 | - |

---

## Fases e Tarefas

### F1 — Criar artefatos novos (helper de apresentação e badge)

- [x] **F1-T1** — Criar `AnalysisTypePresentation` (helper estático puro de UI)
  - Camada: `ui`
  - Artefatos:
    - `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/analysis_type_presentation/analysis_type_presentation.dart` *(novo)*
    - `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/analysis_type_presentation/index.dart` *(novo)*
  - Depende de: —
  - Desbloqueia: F1-T2
  - Detalhe: classe `final AnalysisTypePresentation { const AnalysisTypePresentation._(); }` com `static String shortLabelFor(AnalysisTypeDto type)` e `static IconData iconFor(AnalysisTypeDto type)`. Valores espelham `CreateAnalysisTypeDialogPresenter.titleFor` e `.iconFor` (mesmas strings PT-BR acentuadas: "Avaliação de caso", "Primeira instância", "Segunda instância"; mesmos `Icons.fact_check_outlined`, `Icons.gavel_outlined`, `Icons.account_balance_outlined`). O `index.dart` faz `export` do arquivo principal (sem typedef — não é widget).
  - Concluído em: 2026-05-20

- [x] **F1-T2** — Criar widget `AnalysisTypeBadge` (View only)
  - Camada: `ui`
  - Artefatos:
    - `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/analysis_type_badge/analysis_type_badge_view.dart` *(novo)*
    - `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/analysis_type_badge/index.dart` *(novo)*
  - Depende de: F1-T1
  - Desbloqueia: F2-T1, F2-T2
  - Detalhe: `class AnalysisTypeBadgeView extends StatelessWidget` com prop obrigatória `final AnalysisTypeDto type`. Resolve `label = AnalysisTypePresentation.shortLabelFor(type)` e `icon = AnalysisTypePresentation.iconFor(type)` na `build`. Renderiza `Semantics(label: 'Tipo: $label', container: true)` envolvendo `Container` com `borderRadius: 999`, `padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3)`, `color: tokens.surfaceElevated`, `border: tokens.borderSubtle`, contendo um `Row(mainAxisSize: MainAxisSize.min)` com `Icon(icon, size: 14, color: tokens.textSecondary)`, `SizedBox(width: 4)` e `Text(label, style: textTheme.labelSmall?.copyWith(color: tokens.textSecondary, fontWeight: FontWeight.w600))`. O `index.dart` exporta `typedef AnalysisTypeBadge = AnalysisTypeBadgeView;`.
  - Concluído em: 2026-05-20

### F2 — Adaptar os dois cards existentes para receber `type` e renderizar o badge

> Tarefas F2-T1 e F2-T2 são independentes entre si — podem ser executadas em paralelo por dois desenvolvedores distintos.

- [x] **F2-T1** — Adaptar `RecentAnalysisCardView` para receber `type` e renderizar `AnalysisTypeBadge`
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analysis_card/recent_analysis_card_view.dart` *(modificado)*
  - Depende de: F1-T2
  - Desbloqueia: F3-T1
  - Detalhe: adicionar prop obrigatória `final AnalysisTypeDto type` no construtor; importar `AnalysisTypeDto` (de `package:animus/core/intake/dtos/analysis_type_dto.dart`) e `AnalysisTypeBadge` (de `package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/analysis_type_badge/index.dart`). Inserir `AnalysisTypeBadge(type: type)` no `Wrap` (linha ~47-77) entre o `Text(dateLabel)` e o badge de status atual.
  - Concluído em: 2026-05-20

- [x] **F2-T2** — Adaptar `ProcessingAnalysisCardView` para receber `type` e renderizar `AnalysisTypeBadge`
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/processing_analysis_card/processing_analysis_card_view.dart` *(modificado)*
  - Depende de: F1-T2
  - Desbloqueia: F3-T1
  - Detalhe: adicionar prop obrigatória `final AnalysisTypeDto type` no construtor; importar `AnalysisTypeDto` e `AnalysisTypeBadge`. Inserir `AnalysisTypeBadge(type: type)` no `Wrap` (linha ~52-87) entre o `Text(dateLabel)` e o badge de status atual. Preservar gradient + spinner sem alteração.
  - Concluído em: 2026-05-20

### F3 — Propagar `analysis.type` na seção e atualizar barrel

- [x] **F3-T1** — Propagar `analysis.type` aos cards em `RecentAnalysesSectionView`
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/recent_analyses_section_view.dart` *(modificado)*
  - Depende de: F2-T1, F2-T2
  - Desbloqueia: F3-T2 (pelo ciclo de qualidade — analyze precisa passar antes do barrel)
  - Detalhe: ao construir `ProcessingAnalysisCard(...)` (linha ~194) passar `type: analysis.type`; ao construir `RecentAnalysisCard(...)` (linha ~229) passar `type: analysis.type`. Importar `AnalysisTypeDto` se ainda não estiver disponível pela árvore de imports atual (já está, via `analysis_dto.dart` → `analysis_type_dto.dart`, mas verificar `dart analyze`).
  - Concluído em: 2026-05-20

- [x] **F3-T2** — Atualizar barrel `recent_analyses_section/index.dart`
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/home_screen/recent_analyses_section/index.dart` *(modificado)*
  - Depende de: F1-T1, F1-T2 (artefatos a serem reexportados precisam existir)
  - Desbloqueia: —
  - Detalhe: adicionar duas linhas de `export`:
    - `export 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/analysis_type_badge/index.dart';`
    - `export 'package:animus/ui/intake/widgets/pages/home_screen/recent_analyses_section/analysis_type_presentation/index.dart';`
  - Concluído em: 2026-05-20

---

## Pendências

- Nenhuma. A spec é autossuficiente; o `_write_spec` e o `_write_plan` não dependem de informações externas. Toda decisão arquitetural foi registrada nas seções 5, 6 e 8 da spec.
