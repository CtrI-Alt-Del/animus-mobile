# PRD - Judge Analysis Domain Alignment

## Objetivo

Alinhar o dominio de analises de `intake` no mobile ao contrato atual do backend, permitindo que o app diferencie tipos de analise, carregue resumo do caso por `analysisId` e prepare os fluxos futuros de avaliacao de caso, primeira instancia e segunda instancia sem expor payload cru para a UI.

## Entregas do fluxo

- [x] Renomeacao do resumo juridico para `CaseSummary` em contratos e consumidores do app
- [x] Tipagem explicita de analises com `caseAssessment`, `firstInstance` e `secondInstance`
- [x] Compatibilidade da UI atual da Home e da `analysis_screen` com o fluxo legado de primeira instancia
- [x] Novos endpoints tipados para buscar resumo do caso, minutas e reports agregados por tipo de analise
- [x] Exportacao da tela atual ajustada para consumir o report real de `FirstInstanceAnalysis`
- [x] Regras de status do backend traduzidas para o contrato legado consumido pela UI atual

## Impacto da entrega

- O app passa a refletir com mais fidelidade o modelo de analise do produto, reduzindo ambiguidades entre fluxos juridicos diferentes.
- A UI deixa de depender de `petitionId` para carregar o resumo do caso, simplificando a orquestracao da tela de analise.
- O backend pode evoluir endpoints e payloads por tipo de analise sem espalhar JSON cru pela interface.
- A base fica pronta para entregar as futuras telas dedicadas por tipo com menor retrabalho estrutural.

## O que mudou em relacao ao PRD original

- Como nao havia um `prd.md` materializado nesta pasta, este documento foi consolidado com base na implementacao concluida e na spec fechada.
- Nenhum desvio funcional em relacao a Spec original foi identificado na entrega final.

## Observacoes de rollout

- A Home continua criando analises `firstInstance` ate a entrega do seletor por tipo em `ANI-101`.
- Os endpoints agregados de report e draft por tipo precisam permanecer consistentes com os contratos consumidos pelo mobile.
