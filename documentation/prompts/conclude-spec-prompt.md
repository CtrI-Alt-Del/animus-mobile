---
description: Prompt para concluir uma spec com validação final, atualização de documentação e geração de resumo estruturado para PR.
---

# Prompt: Conclude Spec

**Objetivo:** Finalizar e consolidar a implementação de uma Spec técnica no
Animus Mobile, garantindo que o código Flutter esteja polido, documentado e
validado no contexto do app — produzindo ao final um checklist de validação, os
documentos atualizados e um resumo estruturado para PR.

---

## Entradas Esperadas

- **Spec Técnica:** O documento que guiou a implementação
  (`documentation/features/<modulo>/specs/<nome>-spec.md`), injetado
  como caminho para o arquivo no contexto.

---

## Fase 1 — Verificação

Esta fase é analítica e deve ser concluída antes de qualquer atualização de
documento.

**1.1 Testes**

Execute `flutter test` na raiz do projeto. Todos os testes - novos e
existentes - devem estar passando. Caso algum falhe, interrompa e reporte.

Se a Spec impactar apenas uma parte do app, voce pode executar primeiro o
arquivo ou diretório de teste mais específico para feedback rapido, mas a
validacao final deve considerar `flutter test` na raiz.

> Falhas pré-existentes fora do escopo da Spec devem ser sinalizadas
> explicitamente, indicando que são regressões anteriores e não introduzidas
> pela implementação atual.

**1.1.1 Cobertura de Testes**

Com base no diff injetado no contexto e nas regras em
`documentation/rules/unit-tests-rules.md`,
`documentation/rules/ui-layer-rules.md`,
`documentation/rules/core-layer-rules.md`,
`documentation/rules/rest-layer-rules.md` e
`documentation/rules/drivers-layer-rules.md`, verifique se os novos
comportamentos introduzidos pela Spec possuem testes correspondentes.
Considere como caminhos críticos que exigem cobertura:

- Lógica nova ou modificada em `lib/core` (DTOs, contratos, respostas tipadas e
  regras de domínio) — cobertos exclusivamente com **testes unitários**
- Casos de erro e edge cases relevantes (validações, falhas de integração,
  estados inválidos) — cobertos exclusivamente com **testes unitários**
- Mapeadores e services em `lib/rest` (payloads, parsing, tratamento de erro,
  tradução entre contrato remoto e DTO) — cobertos exclusivamente com **testes unitários**
- Drivers e adaptadores em `lib/drivers` (storage, cache, plugins e integrações
  de plataforma) — **não crie novos testes nesta etapa de conclude spec**;
  apenas verifique e sinalize a cobertura já existente quando houver
- Widgets, presenters e fluxos de UI alterados em `lib/ui`, incluindo estados
  de loading, empty, erro e interações relevantes — **testes de widget são
  permitidos somente para componentes da camada `lib/ui`; arquivos fora de
  `lib/ui` (core, rest, drivers) devem ser cobertos exclusivamente com testes
  unitários, nunca com testes de widget**

Ao final desta etapa, produza um relatório de cobertura no seguinte formato:
```markdown
## Cobertura de Testes

- [x] <Comportamento A> - coberto em `test/caminho/do/test_arquivo.dart`
- [x] <Comportamento B> - coberto em `test/caminho/do/test_arquivo.dart`
- [ ] <Comportamento C> — **sem cobertura** (detalhe o que está faltando)
```

**1.1.2 Criação de Testes para Componentes sem Cobertura**

Caso existam itens sem cobertura no relatório acima, acione um **subagent**
para criá-los antes de avançar para a Fase 2.

O subagent deve receber como contexto:

- O prompt `documentation/prompts/create-tests-prompt.md` como instrução base.
- A lista de componentes sem cobertura identificados no relatório (1.1.1),
  com os caminhos reais dos arquivos fonte (`lib/...`).
- O caminho da Spec técnica, para referência de contratos e comportamentos
  esperados.

> ⚠️ **Restrição obrigatória ao subagent:** testes de widget **só são
> permitidos para componentes da camada `lib/ui`**. Arquivos fora de `lib/ui`
> (core, rest, drivers) devem ser cobertos exclusivamente com **testes
> unitários** — nunca com testes de widget, independentemente do contexto ou
> da solicitação.

> ⚠️ **Restrição adicional obrigatória ao subagent:** **não criar testes para
> arquivos em `lib/drivers`** durante o conclude spec. Para drivers, apenas
> registre no relatório se existe ou não cobertura já presente; não abra
> lacunas criando novos testes nessa fase.

> O subagent e responsavel por criar os arquivos de teste, seguir as regras de
> nomenclatura e estrutura do projeto, e garantir que `flutter test` passe ao
> final. Nao avance para a Fase 2 enquanto o subagent nao concluir sem falhas.

**1.2 Lint e Formatação**

Execute `dart format .` e `flutter analyze` na raiz do projeto. Nenhum warning
ou erro deve restar. Caso existam, liste-os explicitamente e corrija antes de
prosseguir.

**1.3 Checagem de Tipos**

Execute `flutter analyze` na raiz do projeto como checagem estatica final.
O analisador Dart/Flutter deve retornar zero erros. Liste qualquer violacao
explicitamente e corrija antes de prosseguir.

**1.4 Cobertura de Requisitos**

Com base no diff real injetado no contexto, compare cada componente descrito na
Spec (seções "O que deve ser criado" e "O que deve ser modificado") contra o
código implementado. Ao final desta etapa, produza um **checklist de validação**
no seguinte formato:
```markdown
## Checklist de Validação

- [x] <Requisito A> - implementado em `lib/core/...`, `lib/rest/...`, `lib/drivers/...` ou `lib/ui/...`
- [x] <Requisito B> - implementado em `lib/core/...`, `lib/rest/...`, `lib/drivers/...` ou `lib/ui/...`
- [ ] <Requisito C> — **ausente ou incompleto** (detalhe o gap)
```

**1.5 Conformidade Arquitetural e de Padrões**

Leia `documentation/rules/rules.md` para identificar quais documentos de regras
são acionados pelas camadas impactadas pela Spec. Em seguida, leia cada um dos
docs relevantes e valide o código implementado contra eles.

Verifique obrigatoriamente os documentos acionados pelas camadas impactadas.
Em geral, os mais comuns no Animus Mobile sao:

- `documentation/rules/core-layer-rules.md` - `lib/core` puro, contendo DTOs,
  contratos e tipos compartilhados sem dependencias de infraestrutura
- `documentation/rules/rest-layer-rules.md` - services HTTP, clients e mappers
  focados em integracao e traducao de dados
- `documentation/rules/drivers-layer-rules.md` - adaptadores de plugins, cache,
  storage, env e outros recursos concretos da plataforma
- `documentation/rules/ui-layer-rules.md` - padrao MVP, widgets Flutter,
  presenters, composicao de telas e estado visual
- `documentation/rules/websocket-layer-rules.md` - listeners, envelopes e
  integracoes realtime, quando a Spec tocar comunicacao ao vivo
- `documentation/rules/code-conventions-rules.md` - nomenclatura, organizacao
  de modulos, imports e padroes gerais de codigo
- `documentation/rules/unit-tests-rules.md` - estrutura, mocks, fakers e
  convencoes de testes

Ao validar a camada `lib/drivers`, trate cobertura de testes apenas como
diagnóstico: a fase de conclude spec **não deve criar novos testes para
drivers**, mesmo quando houver lacunas.

Para cada regra violada, reporte:

- **Arquivo:** caminho relativo do arquivo com o desvio
- **Regra violada:** referência ao doc e à regra específica
- **Desvio encontrado:** descrição objetiva do problema
- **Correção necessária:** o que deve ser ajustado

Corrija todos os desvios encontrados antes de avançar para a Fase 2.

---

## Fase 2 — Consolidação de Documentos

Esta fase é de síntese. Execute-a somente após a Fase 1 estar completa e sem
pendências.

**2.1 Atualização da Spec Técnica**

Atualize apenas os metadados da Spec para refletir a conclusão da implementação:

- **Status:** `closed`
- **Última atualização:** `{{ today }}`

Não altere o conteúdo técnico da spec nesta fase — desvios de implementação
devem ter sido capturados pelo `update-spec-prompt` durante o desenvolvimento.

**2.2 Atualização do PRD**

Atualize o PRD associado à Spec. Ele está localizado no nível acima do diretório
da spec — ex.: se a spec está em
`documentation/features/<modulo>/specs/<nome>-spec.md`, o PRD está em
`documentation/features/<modulo>/prd.md`.

Marque como concluídos os itens endereçados pela implementação. A audiência aqui
é de produto — traduza o impacto técnico para linguagem de negócio.

> 💡 Não copie conteúdo técnico de baixo nível para o PRD — sintetize o valor
> entregue.

**Divergência spec → PRD:** Caso a implementação concluída introduza algum
aspecto que contradiga ou não esteja coberto pelo PRD (ex: regra de negócio
refinada, escopo ampliado ou reduzido, comportamento diferente do especificado),
atualize o PRD para refletir a realidade entregue. Registre a divergência no
campo **"O que mudou em relação à Spec original"** do resumo de conclusão da spec (seção 3.1).

**2.3 Atualização da Arquitetura (se aplicável)**

Caso a implementacao tenha introduzido novo fluxo de dados, novo contrato entre
camadas, nova integracao (REST, WebSocket, cache, storage ou plugin) ou mudanca
relevante na estrutura de diretorios, atualize `documentation/architecture.md`
para refletir a realidade atual do projeto.

**2.4 Atualização de Rules (se aplicável)**

Caso a implementação tenha introduzido um padrão de projeto novo, não mapeado
nas rules existentes, atualize o arquivo de regras correspondente com o novo
padrão e exemplos práticos.

---

## Fase 3 — Comunicação

Esta fase produz o artefato final para facilitar a abertura do Pull Request.

**3.1 Resumo de conclusão da spec**

Gere um resumo de conclusão com a seguinte estrutura obrigatória:
```markdown
## O que foi feito

<Descrição objetiva das mudanças implementadas, em linguagem técnica>

## Por que foi feito assim

<Decisões de design relevantes e tradeoffs considerados>

## O que mudou em relação à Spec original

<Desvios ou refinamentos ocorridos durante a implementação, incluindo
divergências que implicaram atualização do PRD. Se nenhum, declarar
explicitamente "Nenhum desvio em relação à Spec original.">

## Pontos de atenção para o revisor

<Riscos, areas sensiveis, dependencias externas ou decisoes que merecem revisao
cuidadosa. Inclua mudancas de contrato REST/WebSocket, DTOs compartilhados,
impactos em cache/local storage, efeitos em navegacao, dependencias de plugin,
uso de `--dart-define` ou side effects relevantes em presenters/services. Se
nenhum, declare explicitamente "Nenhum ponto de atencao identificado.">

## Checklist

- [ ] `dart format .` aplicado nos arquivos impactados
- [ ] `flutter analyze` passou sem warnings ou erros
- [ ] `flutter test` passou sem falhas (ou regressões pré-existentes devidamente sinalizadas)
- [ ] Cobertura de testes verificada e lacunas críticas endereçadas
- [ ] Limites arquiteturais validados
- [ ] PRD atualizado com os itens concluídos (e divergências registradas, se houver)
- [ ] `architecture.md` atualizado (se aplicável)
- [ ] Rules atualizadas (se novos padrões foram introduzidos)
```

---

## Saídas Esperadas

Ao final da execução, devem ter sido produzidos:

1. **Relatório de cobertura de testes** (Fase 1.1.1)
2. **Testes criados pelo subagent** para componentes sem cobertura (Fase 1.1.2, quando aplicável)
3. **Checklist de validação** de requisitos (Fase 1.4)
4. **Spec atualizada** com status `closed` e data (Fase 2.1)
5. **PRD atualizado** com itens marcados como concluídos e divergências registradas, se houver (Fase 2.2)
6. **Resumo de conclusão da spec** com estrutura completa (Fase 3.1)
