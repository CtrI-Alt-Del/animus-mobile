# PRD - Home

## Objetivo

Concentrar nesta pasta o contexto de produto da tela `Home` do `intake` no mobile. A `Home` é o ponto de entrada da experiência jurídica do usuário após o login, agregando saudação personalizada, listagem das análises mais recentes e os pontos de criação de novas análises. Este PRD orienta a evolução da tela em direção ao modelo multi-tipo do domínio (`CaseAssessmentAnalysis`, `FirstInstanceAnalysis` e `SecondInstanceAnalysis`).

## Entregas do fluxo

- [x] Estrutura inicial da `Home` com header, saudação dinâmica, listagem paginada e `FAB` de criação de análise (ANI-60)
- [x] Polling de análises em processamento na seção `Em andamento` (ANI-104)
- [x] Dialog de criação de análise por tipo acionado pelo `FAB`, com seleção explícita entre `CaseAssessmentAnalysis`, `FirstInstanceAnalysis` e `SecondInstanceAnalysis` (ANI-101)
- [ ] Card de análise na `Home` adaptado por tipo de análise, com ícone e rótulo curto exibidos no card de "Em andamento" e no card de "Recentes" (ANI-102)

## Impacto da entrega

- O usuário passa a controlar de forma explícita qual tipo de análise quer iniciar, alinhando o app à taxonomia já adotada pelo domínio (`AnalysisTypeDto`).
- A `Home` deixa de criar diretamente um tipo fixo por toque no `FAB`, evitando criações acidentais e reduzindo retrabalho para deletar/arquivar análises do tipo errado.
- A entrega prepara o terreno para que os fluxos dedicados de `CaseAssessmentAnalysis` e `SecondInstanceAnalysis` ganhem rota própria em futuras issues, sem precisar redesenhar o ponto de criação.
- A `FirstInstanceAnalysis` permanece como tipo default visual e funcional durante a transição, mantendo continuidade com o fluxo já conhecido do usuário.

## O que mudou em relação ao PRD original

- Como não havia um `prd.md` materializado nesta pasta, este documento foi consolidado com base nas specs já entregues e na atualização de direcionamento de produto registrada em ANI-115, que substituiu a divisão binária `lawyer` / `judge` pela taxonomia de três tipos.
- O escopo de ANI-101 foi recortado para entregar somente o dialog de seleção, mantendo a navegação pós-criação alinhada ao mapeamento já existente em `Routes.getAnalysis`.

## Observações de rollout

- A `FirstInstanceAnalysis` deve permanecer como tipo default destacado no dialog enquanto as telas dedicadas dos demais tipos não estiverem disponíveis.
- O `IntakeService.createAnalysis(type: ...)` já aceita os três tipos do domínio; nenhuma compatibilidade com payload legado de `lawyer` / `judge` precisa ser preservada no app porque o contrato anterior não foi exposto ao mobile.
- O dialog deve respeitar o tema `AppThemeTokens` para manter consistência visual com os demais dialogs do app (ex.: `ArchiveAnalysisDialog`, `RenameAnalysisDialog`, `ProfileUpdateNameDialog`).
