# PRD - Regeração de Minutas com Comentários

> Referências de produto:
> - RF 07: https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/49053697
> - RF 08: https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/49348609

## Objetivo

Permitir que a pessoa usuária solicite uma nova versão da minuta já gerada, informando quais ajustes deseja no próprio app, sem sair do fluxo de análise. A experiência deve funcionar tanto na minuta de petição do fluxo de Advogado quanto na minuta de sentença do fluxo de Juiz em 2ª instância.

## Entregas

- [x] Ação de **Regerar minuta** disponível quando já existe minuta gerada.
- [x] Dialog reutilizável com comentário obrigatório para orientar a nova geração.
- [x] Fechamento imediato do dialog após a confirmação local, mantendo o acompanhamento do processamento pela própria tela.
- [x] Regeração da minuta de petição com comentários do usuário no fluxo `CaseAssessmentAnalysisScreen`.
- [x] Regeração da minuta de sentença com comentários do usuário no fluxo `SecondInstanceAnalysisScreen`.
- [x] Reabertura da visualização principal com estado de processamento idêntico ao da geração inicial.
- [x] Recarga obrigatória da minuta atualizada ao concluir, substituindo a versão anterior em tela.
- [x] Tratamento de falha recuperável sem apagar a minuta anterior.

## Impacto no produto

- A pessoa usuária consegue orientar refinamentos da minuta sem depender de um ciclo externo ao app.
- O fluxo reduz retrabalho, porque a solicitação de ajustes acontece no mesmo contexto em que a minuta foi lida.
- A experiência fica consistente entre os fluxos de Advogado e Juiz, reduzindo fricção de uso e suporte.
- O erro continua recuperável e seguro: a minuta anterior permanece visível e os comentários não ficam persistidos no dispositivo.

## O que mudou em relação ao escopo anterior

- A regeração deixou de reutilizar o trigger da geração inicial e passou a usar endpoints dedicados com comentários do usuário.
- O pedido de ajustes agora pode partir tanto do card resumido quanto da visualização fullscreen da minuta.
- A conclusão do processamento sempre recarrega a minuta no servidor antes de atualizar a UI, evitando exibir conteúdo desatualizado.
