# PRD - Home

## Objetivo

Concentrar nesta pasta o contexto de produto da tela `Home` do `intake` no mobile. A `Home` e o ponto de entrada da experiencia juridica do usuario apos o login, agregando saudacao personalizada, listagem das analises mais recentes e os pontos de criacao de novas analises. Este PRD orienta a evolucao da tela em direcao ao modelo multi-tipo do dominio (`CaseAssessmentAnalysis`, `FirstInstanceAnalysis` e `SecondInstanceAnalysis`).

## Entregas do fluxo

- [x] Estrutura inicial da `Home` com header, saudacao dinamica, listagem paginada e `FAB` de criacao de analise (ANI-60)
- [x] Polling de analises em processamento na secao `Em andamento` (ANI-104)
- [ ] Dialog de criacao de analise por tipo acionado pelo `FAB`, com selecao explicita entre `CaseAssessmentAnalysis`, `FirstInstanceAnalysis` e `SecondInstanceAnalysis` (ANI-101)

## Impacto da entrega

- O usuario passa a controlar de forma explicita qual tipo de analise quer iniciar, alinhando o app a taxonomia ja adotada pelo dominio (`AnalysisTypeDto`).
- A `Home` deixa de criar diretamente um tipo fixo por toque no `FAB`, evitando criacoes acidentais e reduzindo retrabalho para deletar/arquivar analises do tipo errado.
- A entrega prepara o terreno para que os fluxos dedicados de `CaseAssessmentAnalysis` e `SecondInstanceAnalysis` ganhem rota propria em futuras issues, sem precisar redesenhar o ponto de criacao.
- A `FirstInstanceAnalysis` permanece como tipo default visual e funcional durante a transicao, mantendo continuidade com o fluxo ja conhecido do usuario.

## O que mudou em relacao ao PRD original

- Como nao havia um `prd.md` materializado nesta pasta, este documento foi consolidado com base nas specs ja entregues e na atualizacao de direcionamento de produto registrada em ANI-115, que substituiu a divisao binaria `lawyer` / `judge` pela taxonomia de tres tipos.
- O escopo de ANI-101 foi recortado para entregar somente o dialog de selecao, mantendo a navegacao pos-criacao alinhada ao mapeamento ja existente em `Routes.getAnalysis`.

## Observacoes de rollout

- A `FirstInstanceAnalysis` deve permanecer como tipo default destacado no dialog enquanto as telas dedicadas dos demais tipos nao estiverem disponiveis.
- O `IntakeService.createAnalysis(type: ...)` ja aceita os tres tipos do dominio; nenhuma compatibilidade com payload legado de `lawyer` / `judge` precisa ser preservada no app porque o contrato anterior nao foi exposto ao mobile.
- O dialog deve respeitar o tema `AppThemeTokens` para manter consistencia visual com os demais dialogs do app (ex.: `ArchiveAnalysisDialog`, `RenameAnalysisDialog`, `ProfileUpdateNameDialog`).
