# PRD - Archived Analyses Screen

> Origem: [PRD do produto no Confluence](https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/131218/Requisitos+do+produto)
> Ticket: [ANI-107 - mobile - Tela de analises arquivadas](https://joaogoliveiragarcia.atlassian.net/browse/ANI-107)

## Objetivo

Permitir que o usuario consulte, busque e desarquive as analises previamente arquivadas, sem polui-las na Home, mantendo o acesso para auditoria, leitura e retomada quando necessario.

## Entregas do fluxo

- [ ] Entrada visivel na tela de Perfil para acessar `Analises arquivadas`.
- [ ] Tela dedicada (`Routes.archivedAnalyses`) com listagem paginada por cursor das analises com `is_archived = true`.
- [ ] Estados visuais previstos: `loading` (skeleton), `empty`, `error com retry`, conteudo com `loading more` e `inline error` em paginacao subsequente.
- [ ] Busca textual local sobre os items ja carregados, com `clear` rapido.
- [ ] Ao tocar em uma analise arquivada, navegar para a tela correta segundo o `AnalysisTypeDto` (`FIRST_INSTANCE/LAWYER`, `SECOND_INSTANCE/JUDGE`, `PRECEDENT/CASE_ASSESSMENT`).
- [ ] Acao `Desarquivar` no item da lista que dispara `IntakeService.unarchiveAnalysis(analysisId)`, removendo o item da listagem em sucesso.
- [ ] Label visual `Analise arquivada` no `AnalysisHeader` quando `AnalysisDto.isArchived = true`, refletido em `AnalysisScreenView`, `FirstInstanceAnalysisScreenView` e `SecondInstanceAnalysisScreenView`.

## Impacto da entrega

- O usuario passa a contar com uma area dedicada para gerenciar analises arquivadas, sem precisar limpar ou poluir a Home.
- A acao `Desarquivar` cria um caminho funcional de retomada de analises, complementando o `Arquivar` existente.
- O label `Analise arquivada` deixa explicito quando uma analise aberta esta fora do fluxo ativo, evitando confusao sobre acoes possiveis e ciclo de vida do registro.

## Observacoes de rollout

- O endpoint `GET /intake/analyses?is_archived=true` e o `PATCH /intake/analyses/{id}/unarchive` ja estao implementados no backend; a feature depende deles estarem disponiveis e estaveis.
- A busca textual e local sobre o conjunto carregado; nao ha endpoint de busca server-side neste escopo.
