## Objetivo
Este PR corrige a integracao do novo `classificationLevel` dos precedentes para que a interface da tela de analise aplique a estilização correta do badge com base na classificacao retornada pela API, mantendo fallback por percentual para compatibilidade.

## Causa do bug
O campo `classificationLevel` foi adicionado ao DTO `AnalysisPrecedentDto` como obrigatorio, mas os mapeamentos e recriacao de objetos no fluxo de precedentes nao propagavam esse valor. Com isso, havia quebra de compilacao e risco de estilização inconsistente baseada apenas no percentual.

## Changelog
- Atualiza DTO e enum de classificacao de precedentes em `lib/core/intake/dtos`.
- Atualiza `AnalysisPrecedentMapper` para mapear `classification_level` e aplicar fallback por `applicability_percentage`.
- Atualiza `ApplicabilityBadgeView` para priorizar `classificationLevel` na definicao de label e paleta visual.
- Propaga `classificationLevel` no fluxo de UI da `analysis_screen` (`precedent_list_item`, `content_state`, `chosen_precedent_summary`, `precedent_dialog`).
- Ajusta `RelevantPrecedentsBubblePresenter` para preservar `classificationLevel` ao selecionar/recriar precedentes.
- Atualiza faker de precedentes para suportar `classificationLevel` e fallback coerente em testes.
- Adiciona teste de widget garantindo estilização condicional por classificacao em `relevant_precedents_bubble_view_test.dart`.

## Como testar
1. Executar `flutter test test/ui/intake/widgets/pages/analysis_screen`.
2. Validar que todos os testes do fluxo de `analysis_screen` passam.
3. Em especial, conferir o cenário `usa classificationLevel para estilizar o badge` em `relevant_precedents_bubble_view_test.dart`.
4. Opcionalmente, executar o app e abrir a `analysis_screen` para verificar que badges exibem label/cor conforme `classificationLevel`.

## Observacoes
- O arquivo `tmp/pr_ani_49_body.md` foi mantido no branch como artefato auxiliar de abertura de PR.
- Nao houve adicao de novas dependencias.