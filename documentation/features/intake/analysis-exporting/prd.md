# PRD - Analysis Exporting

## Objetivo

Permitir que o usuario compartilhe um relatorio em PDF da analise juridica concluida diretamente pela tela de analise, transformando o resultado do fluxo de precedentes em um artefato pronto para circulacao externa.

## Entregas do fluxo

- [x] Acao `Exportar PDF` no menu da `analysis_screen` quando a analise ja tiver precedente escolhido
- [x] Geração do relatorio consolidado a partir do endpoint agregado do backend
- [x] Compartilhamento nativo do PDF em Android e iOS sem persistencia local obrigatoria
- [x] Feedback de carregamento, sucesso e erro durante a exportacao
- [x] Relatorio com capa, sintese da peticao, lista de precedentes analisados e destaque do precedente escolhido

## Impacto da entrega

- O usuario agora consegue levar o resultado da analise para fora do app em um formato compartilhavel e mais facil de apresentar para terceiros.
- A exportacao acontece apenas quando a analise chegou ao estado de decisao final, reduzindo risco de compartilhar material incompleto.
- O relatorio consolida os principais dados juridicos em um documento unico, diminuindo friccao para revisao, envio e registro.
- Falhas de rede, geracao ou compartilhamento continuam recuperaveis pelo mesmo menu, sem quebrar o fluxo da tela.

## O que mudou em relacao ao PRD original

- Como nao havia um `prd.md` materializado nesta pasta, este documento foi consolidado com base na entrega implementada e no escopo fechado da spec.
- O campo funcional de negocio equivalente a `Questao` por precedente foi entregue no PDF com o rotulo `Enunciado`, alinhado ao contrato real retornado pelo app e ao layout validado.

## Observacoes de rollout

- A experiencia depende do endpoint agregado `GET /intake/analyses/{analysis_id}/report` estar disponivel e consistente com o contrato esperado pelo app.
- O compartilhamento usa o fluxo nativo exposto pelo pacote `printing`, entao a validacao final em device real continua importante para Android e iOS.
