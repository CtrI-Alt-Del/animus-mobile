## Objetivo
Este PR conclui a implementacao da spec de busca assincrona de precedentes na tela de analise, incluindo o fluxo completo de configuracao, busca, acompanhamento de status, visualizacao e escolha de precedente no app mobile.

## Changelog
- Implementa fluxo de precedentes na `analysis_screen` com componentes dedicados (`RelevantPrecedentsBubble`, `PrecedentDialog`, `ChosenPrecedentSummary`, dialogs de filtros e quantidade).
- Adiciona contratos e DTOs no `core` para busca/listagem/escolha de precedentes e filtros (`courts`, `precedent_kinds`, `limit`).
- Implementa integracao REST no `IntakeRestService` para `POST /precedents/search`, `GET /precedents` e `PATCH /precedents/choose`.
- Implementa driver de link externo para abrir precedentes no Pangea e adiciona `PANGEA_URL` no ambiente.
- Evolui `AnalysisScreenPresenter` para persistir limite em cache, aplicar filtros e retomar fluxos em reentrada.
- Altera o fluxo de resumo da peticao para `summarizePetition` assíncrono com polling de `analysis.status` ate `PETITION_ANALYZED`.
- Adiciona cobertura de testes para presenters/views do fluxo de precedentes e casos de reentrada em `ANALYZING_PETITION`.
- Atualiza documentacao de arquitetura e specs relacionadas ao fluxo implementado.

## Novas dependencias
- `url_launcher`
  - Local: `pubspec.yaml` e `pubspec.lock`
  - Motivo: abrir link externo do precedente no Pangea pela camada de driver.
  - Impacto esperado: habilita abertura segura de URLs externas em runtime; sem impacto significativo de build alem da geracao padrao de plugins por plataforma.

## Como testar
1. Configurar `PANGEA_URL` no `.env`.
2. Executar `flutter analyze` e validar que nao ha erros/warnings.
3. Executar `flutter test` e validar que a suite completa passa.
4. Abrir a `analysis_screen` com analise em `petitionAnalyzed` e acionar `Buscar precedentes`.
5. Validar estados do bubble (loading, erro com retry, vazio, conteudo) e ordenacao por aplicabilidade.
6. Abrir um item, validar `PrecedentDialog`, acionar `Acessar Pangea` e confirmar escolha.
7. Sair e voltar para a tela durante `ANALYZING_PETITION` e validar que o polling retoma ate carregar `PetitionSummary`.

## Observacoes
- A listagem final foi entregue como lista unica ordenada por aplicabilidade, conforme alinhamento da implementacao atual.
- O PR inclui atualizacoes de artefatos gerados por plugins Flutter em `linux/`, `macos/` e `windows/` devido a nova dependencia.
- O PR tambem inclui sincronizacao de arquivos de prompt/agente e artefatos de design presentes no branch.