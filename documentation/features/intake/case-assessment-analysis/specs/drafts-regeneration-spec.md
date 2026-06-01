---
title: Dialog de regeração de minuta com comentários do usuário
prd: https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/49053697
prd_complementar: https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/49348609
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-127
status: closed
last_updated_at: 2026-05-30
---

# 1. Objetivo

Implementar o fluxo mobile de **regeração de minuta com comentários do usuário** para as telas de análise que já exibem minuta gerada: minuta de petição no fluxo de Advogado (`CaseAssessmentAnalysisScreen`) e minuta de sentença no fluxo de Juiz em 2ª instância (`SecondInstanceAnalysisScreen`). A entrega adiciona contratos no `core`, implementações REST para os endpoints de regeração, um dialog reutilizável com campo obrigatório de comentários e ajustes nos presenters/views para disparar a regeração, acompanhar o status por polling, fechar imediatamente os dialogs após a confirmação do envio e recarregar obrigatoriamente a minuta atualizada ao concluir.

---

# 2. Escopo

## 2.1 In-scope

- Adicionar contratos em `IntakeService` para regerar minuta de petição e minuta de sentença com `comments`.
- Implementar chamadas REST para:
  - `POST /intake/analyses/{analysis_id}/petition-drafts/regenerate`
  - `POST /intake/analyses/{analysis_id}/judgment-drafts/regenerate`
- Criar dialog reutilizável `RegenerateDraftDialog` em `lib/ui/intake/widgets/components/`.
- Exigir comentário não vazio antes de confirmar a regeração.
- Abrir o dialog ao tocar em **Regerar minuta** no fluxo de petição e no fluxo de sentença.
- No fluxo de petição, substituir o disparo atual de `triggerPetitionDraftGeneration` durante a regeração por `regeneratePetitionDraft` quando houver comentários do usuário.
- No fluxo de sentença, substituir o disparo atual de `triggerSecondInstanceJudgmentDraftGeneration` durante a regeração por `regenerateJudgmentDraft` quando houver comentários do usuário.
- Manter o polling existente de `getAnalysis` com intervalo de 3 segundos e, no caminho de regeração, recarregar obrigatoriamente a minuta com `getPetitionDraft` ou `getSecondInstanceJudgmentDraft` ao chegar em `DONE`, mesmo quando existir minuta anterior em memória.
- Em `FAILED`, preservar a minuta anterior visível e exibir erro recuperável inline.
- Atualizar `PetitionDraftCard`, `PetitionDraftModal`, `JudgmentDraftCard` e `JudgmentDraftDialog` para expor ação de regeração a partir da visualização da minuta.
- Fechar imediatamente o `RegenerateDraftDialog` após a confirmação do envio e, quando a ação partir de `PetitionDraftModal` ou `JudgmentDraftDialog`, fechar também a visualização fullscreen da minuta.

## 2.2 Out-of-scope

- Implementar ou alterar endpoints no backend. A entrega depende de `ANI-126`.
- Editar diretamente o conteúdo da minuta dentro do app.
- Suportar histórico ou múltiplas versões simultâneas da minuta.
- Alterar o formato dos DTOs `PetitionDraftDto` e `SecondInstanceJudgmentDraftDto`.
- Alterar o fluxo de geração inicial de minuta.
- Alterar exportação de PDF.
- Criar testes automatizados nesta spec.
- Usar Google Stitch: nenhum `screen_id` foi informado.

---

# 3. Requisitos

## 3.1 Funcionais

- O botão **Regerar minuta** deve estar disponível somente quando já existir minuta gerada e o status local permitir regeração (`DONE`).
- Ao tocar em **Regerar minuta**, o app deve abrir um dialog com campo de texto multi-linha para comentários.
- O CTA de confirmação do dialog deve ficar desabilitado enquanto o comentário normalizado estiver vazio.
- Ao confirmar, o dialog deve fechar imediatamente após aceitar o envio e a tela deve entrar em estado de processamento.
- Para minuta de petição, a tela deve chamar `IntakeService.regeneratePetitionDraft(analysisId: analysisId, comments: comments)`.
- Para minuta de sentença, a tela deve chamar `IntakeService.regenerateJudgmentDraft(analysisId: analysisId, comments: comments)`.
- Durante a regeração, a tela deve exibir o mesmo estado visual já usado para geração inicial (`GeneratePetitionDraftCard` ou `GenerateJudgmentDraftCard`).
- Ao concluir com `DONE`, a tela deve recarregar obrigatoriamente a minuta atualizada via `getPetitionDraft` ou `getSecondInstanceJudgmentDraft`, sem reaproveitar a minuta anterior em memória no caminho de regeração.
- Ao falhar com `FAILED`, a tela deve exibir erro inline e permitir nova tentativa sem apagar a minuta anterior.
- A nova versão da minuta deve substituir a anterior no estado do presenter.
- Quando a confirmação partir da visualização fullscreen da minuta, essa visualização também deve ser fechada após a aceitação do envio.

## 3.2 Não funcionais

- **Performance:** manter polling com intervalo mínimo de **3 segundos** entre chamadas de `getAnalysis`.
- **Performance:** manter timeout local de **10 segundos** por tentativa remota, alinhado aos presenters atuais.
- **Acessibilidade:** o campo do dialog deve ter label/hint claro, área de toque adequada e foco inicial no campo de comentário.
- **Segurança:** o comentário não deve ser persistido em cache local; deve circular apenas no request de regeração.
- **Arquitetura:** Views não chamam `RestClient`; presenters consomem apenas `IntakeService`.
- **Arquitetura:** payload `{ comments }` é montado na camada REST, não na UI.
- **Arquitetura:** a transição para `AnalysisStatusDto.generatingPetitionDraft` e `AnalysisStatusDto.generatingJudgmentDraft` durante a regeração é apenas local, em memória; o backend continua como fonte da verdade via `getAnalysis`.

---

# 4. O que já existe?

## Core

- **`IntakeService`** (`lib/core/intake/interfaces/intake_service.dart`) — contrato de `intake`; já possui geração inicial de petição, geração inicial de sentença, leitura de análise e leitura das minutas.
- **`AnalysisStatusDto`** (`lib/core/intake/dtos/analysis_status_dto.dart`) — enum tipado compartilhado; já contém `generatingPetitionDraft`, `generatingJudgmentDraft`, `done` e `failed`.
- **`PetitionDraftDto`** (`lib/core/intake/dtos/petition_draft_dto.dart`) — DTO da minuta de petição exibida no fluxo de Advogado.
- **`SecondInstanceJudgmentDraftDto`** (`lib/core/intake/dtos/second_instance_judgment_draft_dto.dart`) — DTO da minuta de sentença exibida no fluxo de 2ª instância.
- **`RestResponse<T>`** (`lib/core/shared/responses/rest_response.dart`) — wrapper usado pelos contratos remotos.

## REST

- **`IntakeRestService`** (`lib/rest/services/intake_rest_service.dart`) — implementação REST de `IntakeService`; já concentra endpoints de análise, geração inicial de minutas e leitura de minutas.
- **`RestClient`** (`lib/core/shared/interfaces/rest_client.dart`) — contrato usado por `IntakeRestService` para chamadas HTTP.
- **`Service`** (`lib/rest/services/service.dart`) — base usada para conversão de respostas sem corpo por `toVoidResponse`.
- **`PetitionDraftMapper`** (`lib/rest/mappers/intake/petition_draft_mapper.dart`) — mapper da resposta de `getPetitionDraft`.
- **`SecondInstanceJudgmentDraftMapper`** (`lib/rest/mappers/intake/second_instance_judgment_draft_mapper.dart`) — mapper da resposta de `getSecondInstanceJudgmentDraft`.

## UI

- **`CaseAssessmentAnalysisScreenPresenter`** (`lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart`) — presenter do fluxo de Advogado; já possui `requestPetitionDraft`, `regeneratePetitionDraft`, `_pollUntilPetitionDraftReady`, `petitionDraft`, `isManagingAnalysis` e `generalError`.
- **`CaseAssessmentAnalysisScreenView`** (`lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_view.dart`) — view do fluxo de Advogado; já renderiza `PetitionDraftCard`, `PetitionDraftModal`, `GeneratePetitionDraftCard` e aciona a regeração atual sem comentários.
- **`PetitionDraftCardView`** (`lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/petition_draft_card_view.dart`) — card visual da minuta de petição; já possui prop `onRegenerate`, mas hoje a view chama diretamente o presenter sem dialog.
- **`PetitionDraftModalView`** (`lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_modal/petition_draft_modal_view.dart`) — visualização fullscreen da minuta de petição; hoje não expõe ação de regeração.
- **`SecondInstanceAnalysisScreenPresenter`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`) — presenter do fluxo de 2ª instância; já possui `requestJudgmentDraft`, `regenerateJudgmentDraft`, `_pollUntilJudgmentDraftReady`, `judgmentDraft`, `isManagingAnalysis` e `generalError`.
- **`SecondInstanceAnalysisScreenView`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`) — view do fluxo de 2ª instância; hoje aciona `regenerateJudgmentDraft()` diretamente pelo CTA primário.
- **`JudgmentDraftCardView`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_card/judgment_draft_card_view.dart`) — card visual da minuta de sentença; hoje abre o dialog fullscreen da minuta, mas não expõe callback de regeração.
- **`JudgmentDraftDialogView`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_view.dart`) — visualização fullscreen da minuta de sentença; hoje não expõe ação de regeração.
- **`GeneratePetitionDraftCardView`** (`lib/ui/intake/widgets/pages/case_assessment_analysis_screen/generate_petition_draft_card/generate_petition_draft_card_view.dart`) — loading visual já usado na geração de minuta de petição.
- **`GenerateJudgmentDraftCardView`** (`lib/ui/intake/widgets/pages/second_instance_analysis_screen/generate_judgment_draft_card/generate_judgment_draft_card_view.dart`) — loading visual já usado na geração de minuta de sentença.
- **`RenameAnalysisDialogView`** (`lib/ui/intake/widgets/components/analysis_header/rename_analysis_dialog/rename_analysis_dialog_view.dart`) — referência visual para dialog simples com campo de texto, ações **Cancelar** e **Salvar**.

## Lacunas

- Não existem os métodos `regeneratePetitionDraft` e `regenerateJudgmentDraft` em `IntakeService`.
- Não existem implementações REST para os endpoints de regeração com `{ comments }`.
- Não existe dialog reutilizável de comentários para regeração de minutas.
- O fluxo atual de regeração não coleta comentários do usuário e reutiliza os triggers de geração inicial.

---

# 5. O que deve ser criado?

## Camada UI (Presenters)

### `RegenerateDraftDialogPresenter`

- **Localização:** `lib/ui/intake/widgets/components/regenerate_draft_dialog/regenerate_draft_dialog_presenter.dart` (**novo arquivo**).
- **Dependências injetadas:** nenhuma dependência externa; o presenter gerencia apenas estado local do dialog.
- **Estado (`signals`):**
  - `comments: Signal<String>` — texto digitado pelo usuário.
  - `validationError: Signal<String?>` — mensagem local quando a confirmação for tentada sem comentário válido.
  - `isSubmitting: Signal<bool>` — bloqueia duplo envio enquanto `onConfirm` está em andamento.
- **Computeds:**
  - `normalizedComments: ReadonlySignal<String>` — `comments.value.trim()`.
  - `canConfirm: ReadonlySignal<bool>` — `normalizedComments.value.isNotEmpty && !isSubmitting.value`.
- **Provider Riverpod:** `regenerateDraftDialogPresenterProvider` (`AutoDisposeProvider<RegenerateDraftDialogPresenter>`).
- **Métodos:**
  - `void updateComments(String value)` — atualiza o comentário e limpa `validationError` quando o texto normalizado não estiver vazio.
  - `Future<bool> confirm(Future<void> Function(String comments) onConfirm)` — valida comentário, marca `isSubmitting`, dispara `onConfirm(normalizedComments.value)` em background e retorna `true` assim que o envio for aceito localmente para permitir o fechamento imediato dos dialogs.
  - `void dispose()` — descarta os signals e computeds do presenter.

## Camada UI (Views)

### `RegenerateDraftDialogView`

- **Localização:** `lib/ui/intake/widgets/components/regenerate_draft_dialog/regenerate_draft_dialog_view.dart` (**novo arquivo**).
- **Base class:** `ConsumerWidget`.
- **Props:**
  - `final String title` — título do dialog, ex: `Regerar minuta de petição`.
  - `final String description` — texto auxiliar explicando o que o usuário deve informar.
  - `final String textFieldLabel` — label do campo, ex: `O que deseja alterar?`.
  - `final String confirmLabel` — label do CTA, ex: `Confirmar`.
  - `final Future<void> Function(String comments) onConfirm` — callback executado após validação.
- **Bibliotecas de UI:** `flutter/material.dart`, `flutter_riverpod`, `signals_flutter`, `AppThemeTokens`.
- **Estados visuais:**
  - **Idle:** campo multi-linha, botão **Cancelar** e botão **Confirmar** desabilitado quando vazio.
  - **Validation error:** exibe mensagem `Descreva as alterações desejadas para regerar a minuta.` abaixo do campo quando necessário.
  - **Submitting:** desabilita botões e exibe `CircularProgressIndicator` pequeno no CTA de confirmação.
- **Responsabilidades:** renderizar o dialog, observar o presenter, encaminhar alteração de texto para `updateComments`, chamar `confirm` e fechar o dialog com `Navigator.pop(true)` assim que a confirmação for aceita localmente.

## Camada UI (Widgets Internos)

### `RegenerateDraftDialog`

- **Localização:** `lib/ui/intake/widgets/components/regenerate_draft_dialog/` (**novo arquivo**).
- **Tipo:** `View + Presenter`.
- **Props:** mesmas props de `RegenerateDraftDialogView`.
- **Responsabilidade:** componente reutilizável para solicitar comentários antes de regerar qualquer tipo de minuta.

## Camada UI (Barrel Files / `index.dart`)

### `lib/ui/intake/widgets/components/regenerate_draft_dialog/index.dart`

- **Localização:** `lib/ui/intake/widgets/components/regenerate_draft_dialog/index.dart` (**novo arquivo**).
- **`typedef` exportado:** `typedef RegenerateDraftDialog = RegenerateDraftDialogView`.
- **Exports:** exportar `RegenerateDraftDialogPresenter` e `regenerateDraftDialogPresenterProvider` apenas se necessário para testes de UI futuros; para a implementação, a View pode manter o presenter encapsulado.

## Estrutura de Pastas

```text
lib/ui/intake/widgets/components/regenerate_draft_dialog/
  index.dart
  regenerate_draft_dialog_view.dart
  regenerate_draft_dialog_presenter.dart

lib/ui/intake/widgets/pages/case_assessment_analysis_screen/
  case_assessment_analysis_screen_view.dart          ← modificado
  case_assessment_analysis_screen_presenter.dart     ← modificado
  petition_draft_card/
    petition_draft_card_view.dart                    ← modificado
  petition_draft_modal/
    petition_draft_modal_view.dart                   ← modificado

lib/ui/intake/widgets/pages/second_instance_analysis_screen/
  second_instance_analysis_screen_view.dart          ← modificado
  second_instance_analysis_screen_presenter.dart     ← modificado
  judgment_draft_card/
    judgment_draft_card_view.dart                    ← modificado
  judgment_draft_dialog/
    judgment_draft_dialog_view.dart                  ← modificado
```

---

# 6. O que deve ser modificado?

## Camada Core

- **Arquivo:** `lib/core/intake/interfaces/intake_service.dart`
- **Mudança:** adicionar os contratos:
  - `Future<RestResponse<void>> regeneratePetitionDraft({required String analysisId, required String comments})` — dispara a regeração assíncrona da minuta de petição com comentários do usuário.
  - `Future<RestResponse<void>> regenerateJudgmentDraft({required String analysisId, required String comments})` — dispara a regeração assíncrona da minuta de sentença com comentários do usuário.
- **Justificativa:** presenters devem consumir uma interface do `core`; endpoints e payloads não podem vazar para a UI.

## Camada REST

- **Arquivo:** `lib/rest/services/intake_rest_service.dart`
- **Mudança:** implementar os métodos:
  - `Future<RestResponse<void>> regeneratePetitionDraft({required String analysisId, required String comments})` — chama `POST /intake/analyses/$analysisId/petition-drafts/regenerate` com body `<String, dynamic>{'comments': comments.trim()}` e retorna `toVoidResponse(response)`.
  - `Future<RestResponse<void>> regenerateJudgmentDraft({required String analysisId, required String comments})` — chama `POST /intake/analyses/$analysisId/judgment-drafts/regenerate` com body `<String, dynamic>{'comments': comments.trim()}` e retorna `toVoidResponse(response)`.
- **Justificativa:** a montagem do payload pertence à borda REST e o retorno esperado é `202 Accepted` sem DTO específico.

## Camada UI

- **Arquivo:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart`
- **Mudança:** alterar `regeneratePetitionDraft()` para `Future<void> regeneratePetitionDraft(String comments)`.
- **Método:** `Future<void> regeneratePetitionDraft(String comments)` — valida `canRegeneratePetitionDraft`, preserva a minuta anterior, seta `status = AnalysisStatusDto.generatingPetitionDraft` apenas em memória, chama `IntakeService.regeneratePetitionDraft`, faz polling com `_pollUntilPetitionDraftReady(forceReloadOnDone: true)` e recarrega `petitionDraft` ao concluir.
- **Justificativa:** a regeração deixa de ser geração inicial forçada e passa a consumir o endpoint específico com comentários.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
- **Mudança:** alterar `regenerateJudgmentDraft()` para `Future<void> regenerateJudgmentDraft(String comments)`.
- **Método:** `Future<void> regenerateJudgmentDraft(String comments)` — valida `canRegenerateJudgmentDraft`, preserva a minuta anterior, seta `status = AnalysisStatusDto.generatingJudgmentDraft` apenas em memória, chama `IntakeService.regenerateJudgmentDraft`, faz polling com `_pollUntilJudgmentDraftReady(forceReloadOnDone: true)` e recarrega `judgmentDraft` ao concluir.
- **Justificativa:** a regeração de sentença precisa usar endpoint próprio e comentário obrigatório.

- **Arquivo:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_view.dart`
- **Mudança:** adicionar helper `_showRegeneratePetitionDraftDialog(...)` e substituir chamadas diretas a `presenter.regeneratePetitionDraft()` por abertura de `RegenerateDraftDialog`.
- **Método:** `Future<bool> _showRegeneratePetitionDraftDialog(BuildContext context, CaseAssessmentAnalysisScreenPresenter presenter)` — abre `showDialog`, chama `presenter.regeneratePetitionDraft(comments)` no `onConfirm`, retorna se o envio foi aceito localmente e agenda scroll para o loading após confirmação.
- **Justificativa:** a View deve apenas abrir o dialog e encaminhar o evento; a orquestração segue no presenter.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart`
- **Mudança:** adicionar helper `_showRegenerateJudgmentDraftDialog(...)` e substituir chamadas diretas a `presenter.regenerateJudgmentDraft()` por abertura de `RegenerateDraftDialog`.
- **Método:** `Future<bool> _showRegenerateJudgmentDraftDialog(BuildContext context, SecondInstanceAnalysisScreenPresenter presenter)` — abre `showDialog`, chama `presenter.regenerateJudgmentDraft(comments)` no `onConfirm`, retorna se o envio foi aceito localmente e agenda scroll para o loading após confirmação.
- **Justificativa:** mesma UX e contrato de comentários nos dois contextos.

- **Arquivo:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/petition_draft_card_view.dart`
- **Mudança:** expor `final Future<bool> Function()? onRegenerate`, renderizar botão **Regerar minuta** quando a prop não for nula e suportar o fechamento encadeado dos dialogs.
- **Justificativa:** o card já declara a prop, mas não a usa; o CTA precisa aparecer também junto ao preview da minuta.

- **Arquivo:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_modal/petition_draft_modal_view.dart`
- **Mudança:** adicionar `final Future<bool> Function()? onRegenerate`, reorganizar o cabeçalho para telas estreitas e renderizar ação **Regerar minuta** no cabeçalho quando a prop existir, fechando o modal após a confirmação.
- **Justificativa:** o ticket pede abertura a partir da tela da minuta; o modal fullscreen é a visualização dedicada da minuta.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_card/judgment_draft_card_view.dart`
- **Mudança:** adicionar `final Future<bool> Function()? onRegenerate` e passar a prop para `JudgmentDraftDialog` quando abrir a visualização fullscreen; renderizar botão **Regerar minuta** no card quando aplicável.
- **Justificativa:** deixa o fluxo de sentença consistente com o fluxo de petição.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_view.dart`
- **Mudança:** adicionar `final Future<bool> Function()? onRegenerate`, reorganizar o cabeçalho para telas estreitas e renderizar ação **Regerar minuta** no cabeçalho quando a prop existir, fechando o dialog fullscreen após a confirmação.
- **Justificativa:** o usuário deve conseguir solicitar nova versão a partir da tela da minuta.

---

# 7. O que deve ser removido?

## Camada UI

- **Arquivo:** `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart`
- **Motivo da remoção:** remover o uso de `triggerPetitionDraftGeneration` dentro do caminho de regeração (`regeneratePetitionDraft`).
- **Impacto esperado:** `requestPetitionDraft` continua usando `triggerPetitionDraftGeneration` para geração inicial; apenas a regeração passa a usar `regeneratePetitionDraft`.

- **Arquivo:** `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart`
- **Motivo da remoção:** remover o uso de `triggerSecondInstanceJudgmentDraftGeneration` dentro do caminho de regeração (`regenerateJudgmentDraft`).
- **Impacto esperado:** `requestJudgmentDraft` continua usando `triggerSecondInstanceJudgmentDraftGeneration` para geração inicial; apenas a regeração passa a usar `regenerateJudgmentDraft`.

---

# 8. Decisões Técnicas e Trade-offs

- **Decisão:** criar um único `RegenerateDraftDialog` reutilizável para petição e sentença.
- **Alternativas consideradas:** criar dialogs separados por fluxo.
- **Motivo da escolha:** a interação é idêntica nos dois contextos: comentário obrigatório, cancelar e confirmar.
- **Impactos / trade-offs:** reduz duplicidade; diferenças de texto entram por props.

- **Decisão:** manter os métodos de geração inicial (`requestPetitionDraft` e `requestJudgmentDraft`) separados dos métodos de regeração com comentários.
- **Alternativas consideradas:** adicionar parâmetro opcional `comments` nos métodos existentes.
- **Motivo da escolha:** geração inicial e regeração têm endpoints diferentes e semânticas diferentes.
- **Impactos / trade-offs:** mais métodos nos presenters, mas fluxo mais explícito e menos ambíguo.

- **Decisão:** preservar a minuta anterior durante a regeração.
- **Alternativas consideradas:** limpar `petitionDraft`/`judgmentDraft` ao iniciar a regeração.
- **Motivo da escolha:** requisito de erro recuperável pede preservar a minuta anterior em caso de falha.
- **Impactos / trade-offs:** durante o loading, a View deve priorizar o card de processamento e ocultar temporariamente a minuta antiga se necessário, sem apagar o estado.

- **Decisão:** manter a mudança para `generatingPetitionDraft` e `generatingJudgmentDraft` apenas em memória durante a regeração.
- **Alternativas consideradas:** persistir a transição via `updateAnalysisStatus` antes de chamar o endpoint de regeração.
- **Motivo da escolha:** o backend continua como fonte da verdade para o status remoto; o frontend usa apenas estado local transitório até o polling de `getAnalysis` refletir o processamento real.
- **Impactos / trade-offs:** reduz risco de inconsistência entre cliente e servidor; o loading visual depende do estado local até a primeira resposta do polling.

- **Decisão:** fechar os dialogs imediatamente após a confirmação local da regeração.
- **Alternativas consideradas:** manter o dialog aberto até a conclusão do fluxo assíncrono completo.
- **Motivo da escolha:** o usuário deve voltar imediatamente para a tela principal e acompanhar o processamento pelo card de loading já existente.
- **Impactos / trade-offs:** falhas remotas após o fechamento passam a ser comunicadas apenas pelo erro inline da tela principal.

- **Decisão:** forçar recarga da minuta ao chegar em `DONE` no caminho de regeração.
- **Alternativas consideradas:** reutilizar a minuta já presente em memória quando o status remoto chegasse em `DONE`.
- **Motivo da escolha:** a minuta antiga é preservada em memória para cenários de falha; sem recarga obrigatória, o frontend pode estabilizar em `DONE` mostrando conteúdo desatualizado.
- **Impactos / trade-offs:** adiciona uma leitura final obrigatória do endpoint da minuta ao concluir a regeração, mas garante consistência visual com o resultado efetivo do backend.

- **Decisão:** montar o body `{ comments }` diretamente em `IntakeRestService`.
- **Alternativas consideradas:** criar DTO/mapper de request para comentários.
- **Motivo da escolha:** as regras REST do projeto permitem montar payload de request diretamente no service quando usado por um único método e sem DTO compartilhado.
- **Impactos / trade-offs:** menos arquivos; o contrato permanece tipado pelo método do `core`.

- **Decisão:** usar o status remoto `FAILED` como falha recuperável e manter CTA de retry via nova abertura do dialog.
- **Alternativas consideradas:** repetir automaticamente a regeração com os mesmos comentários.
- **Motivo da escolha:** comentários não serão persistidos localmente por segurança e simplicidade; o usuário confirma nova tentativa explicitamente.
- **Impactos / trade-offs:** usuário precisa reinformar comentários em nova tentativa.

---

# 9. Diagramas e Referências

- **Fluxo de dados:**

```text
CaseAssessmentAnalysisScreenView / SecondInstanceAnalysisScreenView
  -> showDialog(RegenerateDraftDialog)
      -> RegenerateDraftDialogPresenter
          -> onConfirm(comments)
              -> ScreenPresenter.regeneratePetitionDraft(comments)
              -> ScreenPresenter.regenerateJudgmentDraft(comments)
          -> Navigator.pop(true) [fecha dialog imediatamente]
      -> se origem for fullscreen da minuta, fechar PetitionDraftModal / JudgmentDraftDialog
                  -> IntakeService (core)
                      -> IntakeRestService (rest)
                          -> RestClient (Dio)
                              -> API regenerate endpoint
                  -> getAnalysis(...) [polling 3s]
                      -> DONE -> getPetitionDraft(...) / getSecondInstanceJudgmentDraft(...) [recarga obrigatória na regeração]
                      -> FAILED -> generalError + minuta anterior preservada
```

- **Hierarquia de widgets:**

```text
CaseAssessmentAnalysisScreenView
  PetitionDraftCard
    Regerar minuta -> RegenerateDraftDialog
    Ver minuta -> PetitionDraftModal
      Regerar minuta -> RegenerateDraftDialog -> fecha dialog de comentários -> fecha PetitionDraftModal

SecondInstanceAnalysisScreenView
  JudgmentDraftCard
    Regerar minuta -> RegenerateDraftDialog
    Ver completa -> JudgmentDraftDialog
      Regerar minuta -> RegenerateDraftDialog -> fecha dialog de comentários -> fecha JudgmentDraftDialog
```

- **Referências:**
  - `lib/ui/intake/widgets/components/analysis_header/rename_analysis_dialog/rename_analysis_dialog_view.dart` — referência visual de dialog com campo e CTAs.
  - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_presenter.dart` — referência de polling de minuta de petição e estado `generatingPetitionDraft`.
  - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/case_assessment_analysis_screen_view.dart` — ponto de abertura do dialog de petição.
  - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_card/petition_draft_card_view.dart` — card onde o CTA local de regeração deve aparecer.
  - `lib/ui/intake/widgets/pages/case_assessment_analysis_screen/petition_draft_modal/petition_draft_modal_view.dart` — visualização fullscreen da minuta de petição.
  - `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_presenter.dart` — referência de polling de minuta de sentença e estado `generatingJudgmentDraft`.
  - `lib/ui/intake/widgets/pages/second_instance_analysis_screen/second_instance_analysis_screen_view.dart` — ponto de abertura do dialog de sentença.
  - `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_card/judgment_draft_card_view.dart` — card onde o CTA local de regeração deve aparecer.
  - `lib/ui/intake/widgets/pages/second_instance_analysis_screen/judgment_draft_dialog/judgment_draft_dialog_view.dart` — visualização fullscreen da minuta de sentença.
  - `lib/rest/services/intake_rest_service.dart` — local dos endpoints REST de geração inicial e leitura das minutas.
  - `lib/core/intake/interfaces/intake_service.dart` — contrato a estender.
  - `https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/49053697` — PRD RF 07, referência principal para minuta de petição do Advogado.
  - `https://joaogoliveiragarcia.atlassian.net/wiki/spaces/ANM/pages/49348609` — PRD RF 08, referência complementar para minuta de sentença do Juiz.

---

# 10. Pendências / Dúvidas

- **Descrição da pendência:** `ANI-126` está vinculado como bloqueador e ainda consta em status **Tarefas pendentes** no Jira.
- **Impacto na implementação:** a implementação mobile pode ser escrita contra o contrato esperado, mas a validação manual ponta a ponta depende dos endpoints do backend.
- **Ação sugerida:** validar com backend antes de mover a task para QA; se o endpoint final divergir, ajustar apenas `IntakeRestService`.

- **Descrição da pendência:** o ticket menciona retorno `202 Accepted`, mas a codebase usa `RestResponse<void>` e `toVoidResponse` sem lógica específica para `202`.
- **Impacto na implementação:** se o `RestClient` tratar `202` como sucesso, não há ajuste adicional; se não tratar, a chamada falhará mesmo com backend correto.
- **Ação sugerida:** verificar comportamento do `RestClient` durante implementação ou validação com endpoint real.

- **Descrição da pendência:** o PRD local um nível acima da spec não existe no repositório; a referência usada é o PRD atual no Confluence informado no arquivo e no ticket.
- **Impacto na implementação:** documentação fica dependente de link externo no frontmatter.
- **Ação sugerida:** se o padrão desejado for PRD local, criar `documentation/features/intake/case-assessment-analysis/prd.md` em tarefa documental separada.

---

# Restrições

- **Não incluir testes automatizados na spec.**
- A `View` não deve conter lógica de negócio; ela apenas abre dialogs, observa estado e encaminha eventos.
- Presenters não fazem chamadas diretas a `RestClient`; devem consumir `IntakeService`.
- O payload `{ comments }` deve ser montado apenas em `IntakeRestService`.
- Não criar DTO ou mapper novo para o request de comentários, salvo mudança posterior de contrato.
- Não limpar a minuta anterior ao iniciar a regeração; ela deve ser preservada para falhas recuperáveis.
- Todo caminho citado como existente foi validado na codebase ou está marcado como **novo arquivo**.
- Todo widget novo segue o padrão `View + Presenter`; o dialog possui pasta própria, `index.dart`, `*_view.dart` e `*_presenter.dart`.
- Usar componentes Flutter Material alinhados ao tema do projeto (`AppThemeTokens`).
- Arquivos novos devem usar `snake_case`, classes em `PascalCase` e textos de UI em PT-BR com acentuação.
