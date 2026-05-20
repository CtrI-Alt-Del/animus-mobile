## Objetivo

Este PR consolida a evolucao do fluxo de analises de intake no mobile, alinhando o app aos novos tipos de analise do dominio (`caseAssessment`, `firstInstance` e `secondInstance`) e preparando a base para os fluxos dedicados de primeira e segunda instancia.

## Changelog

- atualiza contratos do dominio de intake com `AnalysisTypeDto`, enums de status por tipo, drafts e reports agregados por fluxo
- renomeia o resumo juridico para `CaseSummary` e ajusta services, mappers e consumidores da UI
- separa os reports por tipo de analise e ajusta a exportacao atual para `FirstInstanceAnalysisReportDto`
- adiciona fluxo dedicado de segunda instancia com tela, presenter e componentes proprios
- reorganiza a antiga `analysis_screen` em `first_instance_analysis_screen` e extrai componentes reutilizaveis de intake
- ajusta a Home para criar analises `firstInstance` e navegar corretamente para o fluxo legado atual
- atualiza rotas, mapeamentos REST, driver de PDF e compatibilidade de status da UI
- amplia a cobertura automatizada para mappers REST, service de intake e presenters/views impactados
- atualiza specs, PRD e documentacao correlata do modulo de intake

## Como testar

1. Execute `flutter analyze` na raiz do projeto.
2. Execute `flutter test` na raiz do projeto.
3. No app, crie uma nova analise pela Home e valide a navegacao para o fluxo de primeira instancia.
4. No fluxo de primeira instancia, envie um documento, valide o carregamento do `CaseSummary` e a exportacao do PDF.
5. Acesse um fluxo de segunda instancia e valide os estados de resumo, precedentes e geracao de minuta de julgamento.
6. Revise os contratos REST e os novos DTOs para confirmar o alinhamento com os tipos de analise do backend.

## Observacoes

- O PR inclui refatoracao estrutural relevante na UI de intake, com extracao de componentes e separacao da tela legada de primeira instancia.
- A compatibilidade visual da Home e do fluxo legado foi preservada por meio do mapeamento de `AnalysisStatusDto`.
- Nao houve adicao de dependencias novas.
