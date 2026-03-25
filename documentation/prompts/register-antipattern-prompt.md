---
description: Registra um anti-padrao cometido durante a implementacao no doc de rules da camada correspondente, alinhado a arquitetura e as regras reais do Animus Mobile.
---

# Prompt: Registrar Anti-padrao

## Objetivo

Documentar um erro de implementacao cometido durante a execucao no arquivo de rules mais adequado do projeto, de forma clara, acionavel e aderente a arquitetura atual do Animus Mobile, para evitar reincidencia em sessoes futuras.

Antes de registrar o anti-padrao, leia obrigatoriamente:

- o documento de visao geral do dominio no Confluence via MCP Atlassian (se o link direto falhar, busque pela arquitetura ou pelos requisitos do projeto no espaco do Animus)
- `documentation/architecture.md`
- `documentation/rules/rules.md`
- `documentation/tooling.md`

Use o MCP Serena para navegar pela codebase e confirmar caminhos, nomes e contexto real da camada afetada.

---

## Entrada

- **Descricao do anti-padrao:** o que foi feito de errado, em qual contexto e, se houver, o trecho de codigo ou comportamento incorreto.
- **Camada afetada** (opcional): se ja souber, informe a camada (`ui`, `core`, `drivers`, `rest`, `websocket`, `tests`, `code-conventions`, `development`). Se nao souber, identifique com base na arquitetura e no doc de rules.
- **Arquivos envolvidos** (opcional): paths reais afetados pela implementacao incorreta.

---

## Diretrizes de Execucao

### 1. Entender o contexto do erro

- Leia a descricao recebida e identifique qual limite arquitetural foi quebrado.
- Confirme a camada olhando para os paths reais do projeto e para as responsabilidades descritas em `documentation/architecture.md`.
- Se o anti-padrao envolver mais de uma camada, registre em todos os docs relevantes.
- Nao invente dominio, camada ou arquivo que nao existam no repositorio atual.

### 2. Identificar o doc de rules correto

Leia `documentation/rules/rules.md` e selecione o arquivo de rules correspondente:

| Contexto do anti-padrao | Arquivo |
| --- | --- |
| Contratos, DTOs, eventos, tipos compartilhados e limites de dominio | `documentation/rules/core-layer-rules.md` |
| Widgets, telas, presenters, estado visual e composicao da interface | `documentation/rules/ui-layer-rules.md` |
| Clients HTTP, services remotos, mapeadores e integracao REST | `documentation/rules/rest-layer-rules.md` |
| Adaptadores de plataforma, SDKs, storage, env, navegacao e infraestrutura | `documentation/rules/drivers-layer-rules.md` |
| Canais realtime, listeners, eventos e integracao WebSocket | `documentation/rules/websocket-layer-rules.md` |
| Nomeacao, organizacao geral, imports e convencoes transversais | `documentation/rules/code-conventions-rules.md` |
| Testes unitarios e de widget | `documentation/rules/tests-rules.md` |
| Fluxo de trabalho, commits, branches e processo de desenvolvimento | `documentation/rules/developement-rules.md` |

Regras de mapeamento:

- Se o erro for de dependencia invertida ou acoplamento entre camadas, registre em todas as camadas impactadas e, quando fizer sentido, tambem em `documentation/rules/code-conventions-rules.md`.
- Se o erro estiver em teste, mas refletir uma violacao arquitetural do codigo produtivo, registre no doc de testes e no doc da camada produtiva afetada.
- Se o problema for apenas de processo ou Git, registre somente em `documentation/rules/developement-rules.md`.

### 3. Validar o documento antes de editar

- Abra o arquivo de rules escolhido e preserve o estilo textual existente.
- Localize obrigatoriamente as secoes `## ✅ O que DEVE conter` e `## ❌ O que NUNCA deve conter`.
- O registro do anti-padrao deve atualizar essas secoes existentes, sem criar nova secao dedicada para anti-padroes.
- Nunca remova nem reescreva entradas existentes para encaixar o novo conteudo.

### 4. Traduzir o anti-padrao para regras acionaveis

Em vez de criar um bloco narrativo novo, converta o aprendizado em dois tipos de ajuste no documento:

- uma entrada positiva em `## ✅ O que DEVE conter`, descrevendo a pratica correta que passa a ser obrigatoria
- uma entrada negativa em `## ❌ O que NUNCA deve conter`, descrevendo explicitamente o erro que nao pode se repetir

Regras de escrita:

- As novas entradas devem ser bullets curtos, especificos e verificaveis em code review.
- O bullet em `## ✅ O que DEVE conter` deve orientar a implementacao correta.
- O bullet em `## ❌ O que NUNCA deve conter` deve registrar o anti-padrao concreto observado.
- Seja especifico sobre o erro real; nao transforme um caso concreto em uma regra excessivamente generica.
- Use caminhos, nomes de classes, arquivos e camadas reais do projeto quando isso ajudar.
- Explique implicitamente o limite quebrado ao escrever os bullets, por exemplo:
  - UI deve delegar regra de negocio ao Presenter ou a contratos do Core
  - Core nunca deve depender de Flutter, Riverpod, Dio ou implementacoes concretas
  - REST nunca deve vazar payload cru ou detalhes de transporte
  - Drivers nao devem assumir responsabilidade de UI ou Core
  - WebSocket nao deve concentrar parse ou orquestracao fora do contrato correto
  - Testes nao devem acoplar detalhes indevidos da implementacao

### 5. Inserir no doc de rules

- Adicione os novos bullets ao final das secoes `## ✅ O que DEVE conter` e `## ❌ O que NUNCA deve conter`.
- Mantenha a linguagem normativa do documento (`deve`, `nao deve`, `pode` quando apropriado).
- Preserve a coerencia com a arquitetura em camadas do projeto:
  - `lib/ui/` renderiza e coordena interacao visual
  - `lib/core/` define contratos e modelos compartilhados
  - `lib/rest/` implementa integracoes HTTP
  - `lib/drivers/` encapsula infraestrutura e SDKs
  - `lib/websocket/` concentra comunicacao realtime quando existir
- Nao use exemplos herdados de outros projetos, stacks ou estruturas que nao existam no Animus Mobile.

### 6. Confirmar o resultado

Depois de inserir:

- informe o caminho do arquivo atualizado
- exiba somente os bullets adicionados
- confirme, em uma frase curta, qual recorrencia futura esse registro ajuda a evitar

---

## Saida Esperada

- Um ou mais docs em `documentation/rules/` atualizados com o novo anti-padrao na secao mais apropriada.
- Exibicao dos bullets inseridos para confirmacao visual.
- Confirmacao objetiva do path atualizado.

---

## Restricoes

- Nao remova, resuma ou reescreva entradas existentes.
- Nao invente arquivos de rules, camadas ou paths que nao existam no projeto.
- Nao use referencias de outra arquitetura que nao a atual do Animus Mobile.
- Nao registre problemas hipoteticos; documente apenas o erro efetivamente observado.
- Nao crie nova secao para o anti-padrao; atualize as secoes `## ✅ O que DEVE conter` e `## ❌ O que NUNCA deve conter` do documento escolhido.
- Se faltar contexto suficiente para identificar a camada, o arquivo correto ou a correcao recomendada, use a tool `question` antes de editar.
