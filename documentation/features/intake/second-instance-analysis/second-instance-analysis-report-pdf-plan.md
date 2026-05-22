---
title: Plano de Implementação — Exportação PDF da Minuta da Análise de Segunda Instância
spec: [documentation/features/intake/second-instance-analysis/second-instance-analysis-report-pdf-spec.md](documentation/features/intake/second-instance-analysis/second-instance-analysis-report-pdf-spec.md)
created_at: 2026-05-21
status: closed
---

---

## Análise de Dependências

### Artefatos do `core` que desbloqueiam outras camadas
- `SecondInstanceAnalysisReportDto` em `lib/core/intake/dtos/second_instance_analysis_report_dto.dart` é o contrato central do fluxo e deve ser evoluído no mesmo arquivo para substituir o formato legado.
- `IntakeService.getSecondInstanceAnalysisReport({required String analysisId})` em `lib/core/intake/interfaces/intake_service.dart` precisa apontar para o DTO atualizado para liberar a integração da `ui` com a camada `rest`.
- `PdfDriver.generateSecondInstanceAnalysisReport({required SecondInstanceAnalysisReportDto report})` em `lib/core/shared/interfaces/pdf_driver.dart` precisa existir para liberar a geração do PDF pela camada `drivers`.
- A interface `PdfDriver` deve permanecer como porta pública única do `core`, enquanto a separação entre os geradores de 1ª e 2ª instância fica confinada à camada `drivers`.
- Não há necessidade de novos enums, rotas, constants, contratos de navegação ou estado global para esta feature.

### Partes de `rest` e `drivers` independentes entre si
- O trabalho de `rest` se divide em:
  - evoluir o mapper existente do relatório de 2ª instância para incluir `judgmentDraft`
  - atualizar `IntakeRestService` para consumir o endpoint oficial `GET /analyses/{analysis_id}/second-instance-report`
- O trabalho de `drivers` se divide em:
  - extrair a geração do relatório de 1ª instância para `FirstInstancePdfGenerator`
  - criar `SecondInstancePdfGenerator` para a minuta da 2ª instância
  - manter `PrintingPdfDriver` como fachada de composição que implementa `PdfDriver`, delega a geração aos generators e centraliza `sharePdf(...)`
- `rest` e `drivers` dependem apenas dos contratos do `core` e podem avançar em paralelo assim que F1 terminar.
- Dentro de `drivers`, `FirstInstancePdfGenerator` e `SecondInstancePdfGenerator` podem ser desenvolvidos em paralelo; a adaptação final de `PrintingPdfDriver` depende dos dois.

### Presenters/widgets/screens paralelizáveis
- `SecondInstanceAnalysisScreenPresenter` pode ser desenvolvido em paralelo com `rest` e `drivers` usando stubs dos contratos do `core`.
- `SecondInstanceAnalysisScreenView` pode ser desenvolvida em paralelo com a implementação real de `rest` e `drivers`, desde que a API pública do presenter já esteja definida.
- Não há múltiplas telas independentes neste fluxo; a paralelização real da `ui` está entre:
  - presenter da tela
  - view da tela
- `AnalysisHeader` e `AnalysisHeaderActionsView` já possuem a superfície visual necessária e não exigem fase própria.

### Tarefas iniciáveis com stub
- `F4-T1` pode iniciar com stub de `IntakeService.getSecondInstanceAnalysisReport(...)`.
- `F4-T1` pode iniciar com stub de `PdfDriver.generateSecondInstanceAnalysisReport(...)` e `sharePdf(...)`, sem aguardar a implementação real dos generators.
- `F5-T1` pode iniciar com stub do presenter após a definição de `isExportingReport`, `canExportReport` e `exportSecondInstanceAnalysisReport()`.
- Nenhuma tarefa de `rest` depende de `drivers`, e nenhuma tarefa de `drivers` depende da `ui`.

---

## ⚠️ Gargalos identificados

- **F1-T1**: bloqueia 6 tarefas; deve ser iniciada primeiro.
- **F1-T2**: bloqueia 2 tarefas; deve ser concluída logo após o DTO.
- **F1-T3**: bloqueia 4 tarefas; deve ser concluída logo após o DTO.
- **F2-T2**: bloqueia a integração real ponta a ponta com o backend; deve ser priorizada após o mapper.
- **F3-T3**: bloqueia a integração final do `PdfDriver` público com os dois generators; deve ser priorizada assim que F3-T1 e F3-T2 terminarem.
- **F4-T1**: bloqueia a conexão visual final da feature; deve começar assim que os contratos do `core` estiverem estáveis.
- **Shape final de `SecondInstanceAnalysisReportDto`**: qualquer oscilação no contrato trava simultaneamente `rest`, `drivers` e `ui`; por isso o DTO deve ser estabilizado cedo.

---

## Mapa de Paralelização

| Fase | Objetivo | Depende de | Pode rodar em paralelo com |
|------|----------|------------|----------------------------|
| F1   | Consolidar contratos do relatório no `core` | - | - |
| F2   | Alinhar `rest` ao DTO e ao endpoint oficial | F1 | F3, F4 |
| F3   | Separar a geração de PDF por tipo de relatório | F1 | F2, F4 |
| F4   | Orquestrar exportação e concorrência no presenter da tela (pode iniciar com stub de `IntakeService` e `PdfDriver`) | F1 | F2, F3 |
| F5   | Conectar a ação visual de exportação na tela existente | F4 | F2, F3 |

---

## Fases e Tarefas

### F1 — Consolidar contratos do relatório no `core`

- [x] **F1-T1** — Evoluir `SecondInstanceAnalysisReportDto` no mesmo arquivo existente, removendo `chosenPrecedent` e adicionando `judgmentDraft` tipado
  - Camada: `core`
  - Artefato: `lib/core/intake/dtos/second_instance_analysis_report_dto.dart`
  - Concluído em: 2026-05-21
  - Depende de: —
  - Desbloqueia: F1-T2, F1-T3, F2-T1, F3-T2, F4-T1

- [x] **F1-T2** — Atualizar o contrato `IntakeService.getSecondInstanceAnalysisReport(...)` para o DTO evoluído
  - Camada: `core`
  - Artefato: `lib/core/intake/interfaces/intake_service.dart`
  - Concluído em: 2026-05-21
  - Depende de: F1-T1
  - Desbloqueia: F2-T2, F4-T1

- [x] **F1-T3** — Adicionar `generateSecondInstanceAnalysisReport(...)` na interface `PdfDriver`, preservando a interface pública única do `core`
  - Camada: `core`
  - Artefato: `lib/core/shared/interfaces/pdf_driver.dart`
  - Concluído em: 2026-05-21
  - Depende de: F1-T1
  - Desbloqueia: F3-T1, F3-T2, F3-T3, F4-T1

### F2 — Alinhar `rest` ao DTO e ao endpoint oficial

- [x] **F2-T1** — Evoluir o mapper existente do relatório de 2ª instância para mapear `analysis`, `document`, `case_summary`, `precedents` e `judgment_draft`, removendo a lógica do contrato legado
  - Camada: `rest`
  - Artefato: `lib/rest/mappers/intake/second_instance_analysis_report_mapper.dart`
  - Concluído em: 2026-05-21
  - Depende de: F1-T1
  - Desbloqueia: F2-T2

- [x] **F2-T2** — Atualizar `IntakeRestService.getSecondInstanceAnalysisReport(...)` para consumir o endpoint oficial `GET /analyses/{analysis_id}/second-instance-report`, preservar o padrão de `requireAuth`, `RestResponse`, `resolveErrorMessage` e `FormatException`, e usar o mapper evoluído
  - Camada: `rest`
  - Artefato: `lib/rest/services/intake_rest_service.dart`
  - Concluído em: 2026-05-21
  - Depende de: F1-T2, F2-T1
  - Desbloqueia: integração real de F4-T1 com a API

### F3 — Separar a geração de PDF por tipo de relatório

- [x] **F3-T1** — Extrair a geração do relatório de 1ª instância para `FirstInstancePdfGenerator`, mantendo toda a montagem específica desse fluxo fora da fachada pública
  - Camada: `drivers`
  - Artefato: `lib/drivers/pdf-driver/printing/first_instance_pdf_generator.dart`
  - Concluído em: 2026-05-21
  - Depende de: F1-T3
  - Desbloqueia: F3-T3

- [x] **F3-T2** — Criar `SecondInstancePdfGenerator` para gerar o PDF da minuta da 2ª instância, com cabeçalho, dados da análise/documento, resumo do caso, minuta estruturada e precedentes associados, usando como referência visual os nós `phFCt`, `SzBDU`, `g4ffq` e `ZZyFU`
  - Camada: `drivers`
  - Artefato: `lib/drivers/pdf-driver/printing/second_instance_pdf_generator.dart`
  - Concluído em: 2026-05-21
  - Depende de: F1-T1, F1-T3
  - Desbloqueia: F3-T3, integração real de F4-T1 com geração do PDF

- [x] **F3-T3** — Transformar `PrintingPdfDriver` em fachada de composição, delegando `generateAnalysisReport(...)` para `FirstInstancePdfGenerator`, `generateSecondInstanceAnalysisReport(...)` para `SecondInstancePdfGenerator` e preservando `sharePdf(...)`
  - Camada: `drivers`
  - Artefato: `lib/drivers/pdf-driver/printing/printing_pdf_driver.dart`
  - Concluído em: 2026-05-21
  - Depende de: F3-T1, F3-T2
  - Desbloqueia: integração final real de F4-T1 com o `PdfDriver` público

### F4 — Orquestrar exportação e concorrência no presenter da tela

- [x] **F4-T1** — Renomear `SecondInstanceFirstInstanceAnalysisScreenPresenter` para `SecondInstanceAnalysisScreenPresenter`, renomear o provider para `secondInstanceAnalysisScreenPresenterProvider`, injetar `PdfDriver`, criar `isExportingReport` e `canExportReport`, implementar `exportSecondInstanceAnalysisReport()`, sanitizar `[Nome da analise] - Minuta de Sentenca.pdf` e bloquear renomear/arquivar/exportar/ações concorrentes durante a exportação
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
  - Artefatos complementares: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/index.dart`, `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`
  - Concluído em: 2026-05-21
  - Depende de: F1-T1, F1-T2, F1-T3
  - Desbloqueia: F5-T1

### F5 — Conectar a ação visual de exportação na tela existente

- [x] **F5-T1** — Atualizar `SecondInstanceAnalysisScreenView` para ligar `AnalysisHeader` ao presenter, exibir `Exportar PDF` apenas quando `status == AnalysisStatusDto.done` e houver `judgmentDraft`, manter o item visível durante exportação e refletir `Exportando PDF...`
  - Camada: `ui`
  - Artefato: `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`
  - Artefato complementar: `test/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view_test.dart`
  - Concluído em: 2026-05-21
  - Depende de: F4-T1
  - Desbloqueia: entrega visual final da feature

---

## Pendências

- A extração para `FirstInstancePdfGenerator` e a criação de `SecondInstancePdfGenerator` exigem cuidado para não mover acidentalmente responsabilidade de compartilhamento nativo para essas classes.
- Impacto: risco de acoplamento indevido com `Printing.sharePdf(...)`.
- Ação sugerida: manter `sharePdf(...)` exclusivamente em `PrintingPdfDriver`, deixando os generators responsáveis apenas por `generate(...)`.

- `PrintingPdfDriver` passa a ser ponto único de composição dos dois generators.
- Impacto: vira artefato crítico de integração da fase F3.
- Ação sugerida: tratá-lo como fechamento obrigatório da fase de drivers e evitar adicionar lógica de layout nele.

- Não há pendência funcional sobre limite de upload nesta feature.
- Impacto: nenhum; o valor correto para o fluxo base permanece `50MB`.
- Ação sugerida: nenhuma.
