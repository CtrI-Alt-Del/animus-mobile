# PRD - Análise de Caso pelo Advogado (Case Assessment)

> Referência do PRD do produto: https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/131218/Requisitos+do+produto

## Objetivo

Permitir que o(a) advogado(a) execute o fluxo completo de **avaliação de caso** dentro do app mobile do Animus: do envio da petição (PDF ou DOCX) à geração da minuta de petição final, passando por sumarização do caso, busca de precedentes ranqueados por aplicabilidade e exportação do relatório final.

A tela é o ponto de entrada para o tipo de análise `CaseAssessment` (`AnalysisTypeDto.caseAssessment`), distinto dos fluxos de Juiz de 1ª e 2ª instância, e deve viver em rota e widget próprios — corrigindo o roteamento legado que hoje encaminha `caseAssessment` para a tela de 2ª instância.

## Entregas do fluxo

- [x] Tela dedicada `CaseAssessmentAnalysisScreenView` em `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/`, com presenter próprio e rota registrada
- [x] Upload de documento (PDF/DOCX, máx. 20MB) com `DocumentFileBubble` durante envio e após persistência
- [x] Trigger da sumarização do caso e exibição do `CaseSummaryCard` com botão de regerar
- [x] Trigger da busca de precedentes (lista ranqueada por aplicabilidade) reutilizando `AnalysisPrecedentsBubble` com botão de refazer busca
- [x] Geração e regeneração da minuta de petição (`PetitionDraftDto`) com preview no card e visualização completa em modal fullscreen (`PetitionDraftModal`)
- [~] Exportação do relatório completo (PDF) habilitada apenas no status `DONE` — UI habilita corretamente o botão, mas a geração do PDF depende de `PdfDriver.generateCaseAssessmentReport(...)` (ainda não disponível, ver PRD §Observações de rollout)
- [x] Tratamento de falha (`FAILED`) com `MessageBox` inline e ação de "Tentar novamente" contextual à etapa interrompida
- [x] Polling de `AnalysisDto` em todos os estados de processamento até o próximo estado terminal/intermediário esperado
- [x] Correção do roteamento: `Routes.getAnalysis(analysisType: caseAssessment)` passa a apontar para a nova rota dedicada

## Impacto da entrega

- O app passa a oferecer suporte real ao fluxo de análise do advogado, deixando de cair na tela de 2ª instância (workaround legado).
- A experiência fica alinhada ao fluxo de produto: upload, sumarização, precedentes ranqueados, minuta, exportação.
- Reaproveita componentes globais já consolidados (`AiBubble`, `AnalysisHeader`, `AnalysisActionBar`, `CaseSummaryCard`, `DocumentFileBubble`, `AnalysisPrecedentsBubble`, `MessageBox`), reduzindo duplicação.
- Desbloqueia ANI-101 (seleção de tipo na Home) e ANI-102, pois agora há destino real para `caseAssessment`.

## O que mudou em relação ao PRD original

- Documento materializado a partir do ticket ANI-103 e do PRD do Confluence, consolidado com base na codebase atual (pós-ANI-115/117).
- Nomenclatura ajustada: o fluxo é chamado de **`CaseAssessmentAnalysis`** no código (não `LawyerAnalysis` como menciona a Jira), alinhado ao DTO `CaseAssessmentAnalysisStatusDto` e `AnalysisTypeDto.caseAssessment` já existentes no `core`.
- O componente `AnalysisPrecedentsBubble` é reaproveitado integralmente — não há lista própria.
- O modal de minuta é nomeado `PetitionDraftModal` (alinhado ao DTO `PetitionDraftDto`).

## Observações de rollout

- A geração da minuta depende do endpoint `GET /intake/analyses/{id}/petition-draft` no servidor (`IntakeService.getPetitionDraft` já existe no mobile). Caso o backend ainda não esteja entregando o draft para o tipo `CaseAssessment`, o fluxo entra em `FAILED` na etapa de geração — esse comportamento já é tratado pelo retry contextual.
- A spec deve registrar como pendência a ausência de um trigger explícito `triggerCaseAssessmentCaseSummarization` e `triggerCaseAssessmentPetitionDraftGeneration` no contrato `IntakeService`. A decisão para esta entrega é: usar `triggerFirstInstanceCaseSummarization` para a sumarização (compatível server-side) e fazer a geração da minuta via polling após escolha de precedente (sem trigger explícito) — alinhado ao contrato atual do `IntakeService`. Caso o backend exija trigger dedicado, deve ser ajustado em ticket separado.
- O limite de 20MB para o documento da petição é específico desse fluxo (diferente dos 50MB usados em 1ª e 2ª instância).
- A tela usa polling de `AnalysisDto` com intervalo de 3s e timeout de 10s por requisição, padrão usado nas outras telas de análise.
