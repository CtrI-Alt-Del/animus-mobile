# PRD - Gestão de Precedentes na Análise de 2ª Instância

## Objetivo

Permitir que a pessoa julgadora revise os precedentes retornados pela busca, escolha mais de um precedente relevante, adicione precedentes manualmente quando necessário e só gere a minuta quando houver ao menos um precedente efetivamente escolhido.

## Entregas do fluxo

- [x] Reconstrução dos precedentes escolhidos a partir do retorno da API, inclusive em reentrada na tela
- [x] Escolha múltipla e desescolha explícita de precedentes no fluxo compartilhado do bubble
- [x] Destaque visual inline para precedentes escolhidos e badge específico para itens adicionados manualmente
- [x] Inclusão manual de precedente por identificador com preview antes da confirmação
- [x] Filtros e quantidade de precedentes servidos pelo header das telas de análise com componentes compartilhados
- [x] Geração de minuta da 2ª instância bloqueada até existir ao menos um precedente escolhido
- [x] Tentativa de carregar a minuta da 2ª instância já nos estados intermediários do fluxo de precedentes

## Impacto da entrega

- O fluxo de precedentes fica mais confiável para casos em que a busca automática não encontra sozinha todos os itens relevantes.
- A pessoa usuária ganha controle explícito sobre quais precedentes sustentam a minuta antes de avançar.
- A experiência reduz tentativas inválidas de gerar minuta sem precedente escolhido.
- O produto passa a reaproveitar o mesmo componente de precedentes entre diferentes telas de análise com menos duplicidade visual e de comportamento.

## O que mudou em relação ao PRD original

- Como não havia um `prd.md` materializado nesta pasta, este documento foi consolidado com base na implementação concluída, na spec técnica e no ticket `ANI-117`.
- O estado de escolha passou a ser comunicado inline na lista de precedentes, sem card resumo persistente no bubble.
- A inclusão manual foi entregue com preview obrigatório por identificador antes da confirmação, reduzindo erro operacional na seleção do precedente.

## Observações de rollout

- O backend precisa manter consistentes os contratos `GET /precedents/identifier`, `POST /analyses/precedents`, `PATCH /intake/analyses/{analysisId}/precedents/choose` e `PATCH /intake/analyses/{analysisId}/precedents/unchoose`.
- A regra de bloqueio da minuta depende do retorno correto de `isChosen` na listagem de precedentes para reentrada de sessão.
