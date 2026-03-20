# Prompt: Refinar PRD (Equiny Mobile)

**Objetivo principal**
Analisar e refinar trechos ou documentos completos fornecidos em Markdown (PRDs, specs e afins). O resultado deve aplicar boas praticas de estruturacao e formatacao para maximizar clareza, consistencia e facilidade de uso por desenvolvedores e por Modelos de Linguagem (LLMs), sem inventar requisitos.

## Contexto do projeto

- **Stack**: Flutter/Dart.
- **Arquitetura**: camadas inspiradas em Clean Architecture com MVP na UI.
- **Camadas**: Core (`lib/core`), Rest (`lib/rest`), Drivers (`lib/drivers`), UI (`lib/ui`).
- **DI/Estado**: Riverpod + Signals.

Referencias do projeto (leitura obrigatoria para manter consistencia):

- [`documentation/architecture.md`](../architecture.md)
- [`documentation/rules/rules.md`](../rules/rules.md)
- [`documentation/rules/code-conventions-rules.md`](../rules/code-conventions-rules.md)
- [`documentation/rules/core-layer-rules.md`](../rules/core-layer-rules.md)
- [`documentation/rules/rest-layer-rules.md`](../rules/rest-layer-rules.md)
- [`documentation/rules/drivers-layer-rules.md`](../rules/drivers-layer-rules.md)
- [`documentation/rules/ui-layer-rules.md`](../rules/ui-layer-rules.md)
- [`documentation/rules/unit-tests-rules.md`](../rules/unit-tests-rules.md)

## Entrada

- Caminho do arquivo do documento em Markdown a ser refinado.

## Diretrizes de execucao

1. **Padronizacao e clareza**
   - Reestruture o conteudo para que a hierarquia seja logica (do geral para o especifico).
   - Use recursos de Markdown quando ajudarem (cabecalhos, negrito, listas, tabelas, blocos de codigo).
   - Mantenha o texto em **Portugues**; mantenha nomes de classes/arquivos/rotas/identificadores de codigo em **Ingles**.

2. **Fidelidade ao conteudo (nao inventar escopo)**
   - Nao adicione features, regras de negocio ou integracoes que nao estejam no texto original.
   - Quando algo estiver implicito/ambiguo, registre como **Pergunta em aberto** ou **Assuncao** (de forma explicita).
   - Preserve valores, limites e criterios de aceite existentes; se corrigir inconsistencias, justifique.

3. **Estrutura recomendada (ajuste ao caso, sem rigidez)**
   - **Visao do produto** (1-2 paragrafos)
   - **Objetivos** e **Nao-objetivos** (escopo in/out)
   - **Personas/Publico-alvo** e **Casos de uso**
   - **Regras de negocio** (definicoes, restricoes, invariantes)
   - **Requisitos funcionais** (por modulo/epico)
   - **Fluxos do usuario** (end-to-end)
   - **Requisitos nao funcionais** (seguranca, privacidade, desempenho, acessibilidade, observabilidade)
   - **Criterios de aceite** (por funcionalidade)
   - **Riscos e trade-offs**
   - **Perguntas em aberto**

4. **Compatibilidade com a arquitetura do Equiny Mobile**
   - Quando o PRD mencionar comportamento de app, mantenha o texto orientado a produto, mas facilite a traducao para implementacao:
     - identifique entidades/dados (candidatos a DTOs no `core/`)
     - identifique integracoes (candidatos a services no `core/` e implementacoes no `rest/` ou `drivers/`)
     - identifique telas/fluxos (candidatos a `ui/` com MVP)
   - Nao descreva detalhes de codigo a menos que o documento original exija.

5. **Validacao de referencias (obrigatorio)**
   - Identifique todas as referencias a:
     - arquivos/pastas do repo (ex.: `documentation/...`, `lib/...`)
     - links externos (URLs)
   - Para cada referencia:
     - **Links Markdown**: garanta sintaxe correta (`[texto](url)`), sem parenteses quebrados.
     - **Arquivos do repo**: verifique se o arquivo existe; se nao existir, sugira o caminho correto ou marque como **Referencia quebrada**.
     - **URLs**: se nao for possivel validar acesso, mantenha o link e marque como **Nao verificado**.

## Saida esperada

1. **Documento refinado em Markdown**
   - Estrutura coerente, headings consistentes e conteudo fiel ao original.
   - Secoes de **Perguntas em aberto** e **Assuncoes** quando aplicavel.

2. **Relatorio de validacao de referencias**
   - Lista de referencias encontradas (arquivos e URLs), com status: `ok`, `referencia quebrada`, `nao verificado`.
