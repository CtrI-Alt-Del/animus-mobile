---
description: Resolver conversas nao resolvidas de PR com correcoes e validacao no contexto do Animus Mobile
---

# Prompt: Resolver conversas de PR

## Objetivo principal

Analisar, implementar e resolver todas as conversas **pendentes e nao resolvidas** em um Pull Request (PR) do GitHub, respeitando a arquitetura e as regras do projeto **Animus Mobile** (Flutter).

> Escopo obrigatorio: trate apenas threads com `isResolved: false`. Ignore por completo conversas ja resolvidas.

## Entrada

- Link completo do PR (ex.: `https://github.com/owner/repo/pull/123`).

## Diretrizes de execucao

### 1. Coleta de contexto do PR

- Extraia `owner`, `repo` e `pullNumber` da URL.
- Use exclusivamente `gh` CLI para consultar e resolver review threads.

### 2. Mapeamento de threads nao resolvidas

- Liste as review threads via GraphQL:

```bash
gh api graphql -f query='
  query($owner: String!, $repo: String!, $number: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $number) {
        reviewThreads(first: 100) {
          nodes {
            id
            isResolved
            comments(first: 20) {
              nodes {
                body
                path
                line
                author { login }
                createdAt
              }
            }
          }
        }
      }
    }
  }
' -f owner={owner} -f repo={repo} -F number={pullNumber}
```

- Filtre estritamente por `isResolved: false`.
- Se nao houver nenhuma thread pendente, encerre informando que nao ha trabalho a fazer.

### 3. Analise e implementacao por thread

Para cada conversa nao resolvida:

- Leia o contexto completo da thread (comentario inicial + replies).
- Localize arquivo/linha e identifique a camada impactada.
- Aplique as correcoes no codigo local, seguindo as regras do projeto.

Consulte o indice de regras em `documentation/rules/rules.md` e leia os guias necessarios:

- UI -> `documentation/rules/ui-layer-rules.md`
- Core -> `documentation/rules/core-layer-rules.md`
- REST -> `documentation/rules/rest-layer-rules.md`
- Drivers -> `documentation/rules/drivers-layer-rules.md`
- WebSocket -> `documentation/rules/websocket-layer-rules.md`
- Convencoes -> `documentation/rules/code-conventions-rules.md`
- Testes -> `documentation/rules/unit-tests-rules.md`

Tambem valide aderencia aos principios em `documentation/architecture.md`.

### 4. Validacao local obrigatoria

Depois de implementar as correcoes:

```bash
dart format .
flutter analyze
flutter test
```

Se algum comando falhar:

- corrija os problemas;
- rode novamente ate obter estado estavel;
- so depois resolva a thread no GitHub.

### 5. Resolver thread no GitHub

Quando a correcao estiver validada, resolva a thread correspondente:

```bash
gh api graphql -f query='
  mutation($threadId: ID!) {
    resolveReviewThread(input: { threadId: $threadId }) {
      thread {
        id
        isResolved
      }
    }
  }
' -f threadId={threadId}
```

Use o `threadId` exato da etapa de coleta.

### 6. Conclusao e relatorio

No retorno final, inclua **somente** as conversas nao resolvidas que foram tratadas nesta execucao:

- arquivo e linha afetados;
- problema apontado pelo revisor;
- alteracao implementada;
- status da validacao (`dart format`, `flutter analyze`, `flutter test`);
- confirmacao de thread resolvida.

Nao liste conversas que ja estavam resolvidas antes de iniciar.

## Workflow resumido

1. Coletar threads do PR.
2. Filtrar somente `isResolved: false`.
3. Implementar correcoes com base nas regras de camada.
4. Validar localmente (`dart format .`, `flutter analyze`, `flutter test`).
5. Resolver cada thread via GraphQL.
6. Entregar relatorio final objetivo das threads tratadas.

## Pos-condicao opcional

Se as correcoes alterarem comportamento funcional documentado, atualize o artefato correspondente (Spec, PRD ou Bug Report) antes de finalizar.
