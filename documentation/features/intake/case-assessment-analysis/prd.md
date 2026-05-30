# PRD - Regeracao de Minutas com Comentarios

> Referencias de produto:
> - RF 07: https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/49053697
> - RF 08: https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/49348609

## Objetivo

Permitir que a pessoa usuaria solicite uma nova versao da minuta ja gerada, informando quais ajustes deseja no proprio app, sem sair do fluxo de analise. A experiencia deve funcionar tanto na minuta de peticao do fluxo de Advogado quanto na minuta de sentenca do fluxo de Juiz em 2ª instancia.

## Entregas

- [x] Acao de **Regerar minuta** disponivel quando ja existe minuta gerada.
- [x] Dialog reutilizavel com comentario obrigatorio para orientar a nova geracao.
- [x] Fechamento imediato do dialog apos a confirmacao local, mantendo o acompanhamento do processamento pela propria tela.
- [x] Regeracao da minuta de peticao com comentarios do usuario no fluxo `CaseAssessmentAnalysisScreen`.
- [x] Regeracao da minuta de sentenca com comentarios do usuario no fluxo `SecondInstanceAnalysisScreen`.
- [x] Reabertura da visualizacao principal com estado de processamento identico ao da geracao inicial.
- [x] Recarga obrigatoria da minuta atualizada ao concluir, substituindo a versao anterior em tela.
- [x] Tratamento de falha recuperavel sem apagar a minuta anterior.

## Impacto no produto

- A pessoa usuaria consegue orientar refinamentos da minuta sem depender de um ciclo externo ao app.
- O fluxo reduz retrabalho, porque a solicitacao de ajustes acontece no mesmo contexto em que a minuta foi lida.
- A experiencia fica consistente entre os fluxos de Advogado e Juiz, reduzindo friccao de uso e suporte.
- O erro continua recuperavel e seguro: a minuta anterior permanece visivel e os comentarios nao ficam persistidos no dispositivo.

## O que mudou em relacao ao escopo anterior

- A regeracao deixou de reutilizar o trigger da geracao inicial e passou a usar endpoints dedicados com comentarios do usuario.
- O pedido de ajustes agora pode partir tanto do card resumido quanto da visualizacao fullscreen da minuta.
- A conclusao do processamento sempre recarrega a minuta no servidor antes de atualizar a UI, evitando exibir conteudo desatualizado.
