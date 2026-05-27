---
description: Prompt para concluir uma spec com review de código integrado, validação final, atualização de documentação e geração de resumo estruturado para PR.
---

# Prompt: Conclude Spec

**Objetivo:** Finalizar e consolidar a implementação de uma Spec técnica no
Animus Mobile, garantindo que o código Flutter esteja revisado, polido,
documentado e validado no contexto do app — produzindo ao final um checklist
de validação, os documentos atualizados e um resumo estruturado para PR.

---

## Entradas Esperadas

- **Spec Técnica:** O documento que guiou a implementação
  (`documentation/features/<modulo>/specs/<nome>-spec.md`), injetado
  como caminho para o arquivo no contexto.

---

## Fase 0 — Review de Código

> ⚠️ **Esta fase deve ser executada antes de qualquer verificação estática.**

O objetivo é revisar manualmente o diff da implementação com olhos críticos de
revisor — identificando bugs, erros lógicos, inconsistências de nomenclatura e
problemas de design que ferramentas de lint e análise estática não capturam.

**0.1 Escaneamento Manual do Diff**

Com base no diff injetado no contexto, leia o código implementado e procure
ativamente por:

- Erros de digitação em nomes de variáveis, funções, classes e arquivos
- Erros lógicos: condições invertidas, retornos incorretos, operações na ordem errada
- Inconsistências de nomenclatura: camelCase vs snake_case, plural vs singular,
  prefixos/sufixos fora do padrão do projeto (ex.: `I` em interfaces, sufixos `Service`, `Presenter`, `Dto`)
- Dead code: imports não utilizados, variáveis declaradas mas nunca lidas, branches inalcançáveis
- Problemas de legibilidade: blocos muito longos sem extração de método, magic numbers sem constante nomeada
- Erros óbvios de sintaxe que podem passar pelo parser mas indicam intenção equivocada

Para cada problema encontrado, registre no formato:
```
- Arquivo: lib/...
- Linha(s): N-M
- Problema: descrição objetiva
- Correção aplicada: o que foi ajustado
```

**0.2 Verificação de Conformidade com a Spec**

Leia a Spec técnica e o código produzido lado a lado. Verifique se a
**intenção do código** corresponde ao **comportamento esperado pela Spec** — não
apenas se os componentes existem, mas se estão implementados corretamente
(contratos respeitados, regras de domínio codificadas fielmente, edge cases
tratados, estados de UI corretos).

> Esta verificação é complementar ao checklist da Fase 1.4, que valida
> presença dos componentes. A Fase 0.2 valida a **correção lógica** da
> implementação.

**0.3 Correções**

Aplique imediatamente todas as correções identificadas nas etapas 0.1 e 0.2.
Não avance para a Fase 1 com problemas de código identificados e não corrigidos.

---

## Fase 1 — Verificação

Esta fase é analítica e deve ser concluída antes de qualquer atualização de
documento.

**1.1 Testes**

Execute `flutter test` na raiz do projeto. Todos os testes — novos e
existentes — devem estar passando. Caso algum falhe, interrompa e reporte.

Se a Spec impactar apenas uma parte do app, você pode executar primeiro o
arquivo ou diretório de teste mais específico para feedback rápido, mas a
validação final deve considerar `flutter test` na raiz.

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

- [x] <Comportamento A> — coberto em `test/caminho/do/test_arquivo.dart`
- [x] <Comportamento B> — coberto em `test/caminho/do/test_arquivo.dart`
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

> O subagent é responsável por criar os arquivos de teste, seguir as regras de
> nomenclatura e estrutura do projeto, e garantir que `flutter test` passe ao
> final. Não avance para a Fase 2 enquanto o subagent não concluir sem falhas.

**1.2 Lint e Formatação**

Execute `dart format .` e `flutter analyze` na raiz do projeto. Nenhum warning
ou erro deve restar. Caso existam, liste-os explicitamente e corrija antes de
prosseguir.

**1.3 Checagem de Tipos**

Execute `flutter analyze` na raiz do projeto como checagem estática final.
O analisador Dart/Flutter deve retornar zero erros. Liste qualquer violação
explicitamente e corrija antes de prosseguir.

**1.4 Cobertura de Requisitos**

Com base no diff real injetado no contexto, compare cada componente descrito na
Spec (seções "O que deve ser criado" e "O que deve ser modificado") contra o
código implementado. Ao final desta etapa, produza um **checklist de validação**
no seguinte formato:
```markdown
## Checklist de Validação

- [x] <Requisito A> — implementado em `lib/core/...`, `lib/rest/...`, `lib/drivers/...` ou `lib/ui/...`
- [x] <Requisito B> — implementado em `lib/core/...`, `lib/rest/...`, `lib/drivers/...` ou `lib/ui/...`
- [ ] <Requisito C> — **ausente ou incompleto** (detalhe o gap)
```

**1.5 Conformidade Arquitetural e de Padrões**

Leia `documentation/rules/rules.md` para identificar quais documentos de regras
são acionados pelas camadas impactadas pela Spec. Em seguida, leia cada um dos
docs relevantes e valide o código implementado contra eles.

Verifique obrigatoriamente os documentos acionados pelas camadas impactadas.
Em geral, os mais comuns no Animus Mobile são:

- `documentation/rules/core-layer-rules.md` — `lib/core` puro, contendo DTOs,
  contratos e tipos compartilhados sem dependências de infraestrutura
- `documentation/rules/rest-layer-rules.md` — services HTTP, clients e mappers
  focados em integração e tradução de dados
- `documentation/rules/drivers-layer-rules.md` — adaptadores de plugins, cache,
  storage, env e outros recursos concretos da plataforma
- `documentation/rules/ui-layer-rules.md` — padrão MVP, widgets Flutter,
  presenters, composição de telas e estado visual
- `documentation/rules/websocket-layer-rules.md` — listeners, envelopes e
  integrações realtime, quando a Spec tocar comunicação ao vivo
- `documentation/rules/code-conventions-rules.md` — nomenclatura, organização
  de módulos, imports e padrões gerais de código
- `documentation/rules/unit-tests-rules.md` — estrutura, mocks, fakers e
  convenções de testes

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

> Não copie conteúdo técnico de baixo nível para o PRD — sintetize o valor
> entregue.

**Divergência spec → PRD:** Caso a implementação concluída introduza algum
aspecto que contradiga ou não esteja coberto pelo PRD (ex: regra de negócio
refinada, escopo ampliado ou reduzido, comportamento diferente do especificado),
atualize o PRD para refletir a realidade entregue. Registre a divergência no
campo **"O que mudou em relação à Spec original"** do resumo de conclusão da spec
(seção 3.1).

**2.3 Atualização da Arquitetura (se aplicável)**

Caso a implementação tenha introduzido novo fluxo de dados, novo contrato entre
camadas, nova integração (REST, WebSocket, cache, storage ou plugin) ou mudança
relevante na estrutura de diretórios, atualize `documentation/architecture.md`
para refletir a realidade atual do projeto.

**2.4 Atualização de Rules (se aplicável)**

Caso a implementação tenha introduzido um padrão de projeto novo, não mapeado
nas rules existentes, atualize o arquivo de regras correspondente com o novo
padrão e exemplos práticos.

---

## Fase 3 — Comunicação

Esta fase produz o artefato final para facilitar a abertura do Pull Request.

**3.1 Resumo de Conclusão da Spec**

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

<Riscos, áreas sensíveis, dependências externas ou decisões que merecem revisão
cuidadosa. Inclua mudanças de contrato REST/WebSocket, DTOs compartilhados,
impactos em cache/local storage, efeitos em navegação, dependências de plugin,
uso de `--dart-define` ou side effects relevantes em presenters/services. Se
nenhum, declare explicitamente "Nenhum ponto de atenção identificado.">

## Checklist

- [ ] Revisão de código manual aplicada (Fase 0: bugs, lógica, nomenclatura)
- [ ] `dart format .` aplicado nos arquivos impactados
- [ ] `flutter analyze` passou sem warnings ou erros
- [ ] `flutter test` passou sem falhas (ou regressões pré-existentes devidamente sinalizadas)
- [ ] Cobertura de testes verificada e lacunas críticas endereçadas
- [ ] Limites arquiteturais validados
- [ ] Spec atualizada com status `closed` e data
- [ ] PRD atualizado com os itens concluídos (e divergências registradas, se houver)
- [ ] `architecture.md` atualizado (se aplicável)
- [ ] Rules atualizadas (se novos padrões foram introduzidos)
```

---

## Saídas Esperadas

Ao final da execução, devem ter sido produzidos:

1. **Relatório de revisão de código** (Fase 0) — bugs, erros lógicos e inconsistências corrigidos
2. **Relatório de cobertura de testes** (Fase 1.1.1)
3. **Testes criados pelo subagent** para componentes sem cobertura (Fase 1.1.2, quando aplicável)
4. **Checklist de validação** de requisitos (Fase 1.4)
5. **Spec atualizada** com status `closed` e data (Fase 2.1)
6. **PRD atualizado** com itens marcados como concluídos e divergências registradas, se houver (Fase 2.2)
7. **Resumo de conclusão da spec** com estrutura completa (Fase 3.1)