---
description: Registra um erro de implementação no doc de rules da camada correspondente, convertendo o aprendizado em regras objetivas nas seções DEVE/NUNCA.
---

# Prompt: Registrar Regra a partir de Anti-padrão

**Objetivo:** Documentar um erro de implementação cometido pela IA no arquivo
de regras da camada correspondente, de forma clara e acionável — para que o
mesmo erro não se repita em sessões futuras.

---

## Entrada

- **Descrição do anti-padrão:** o que foi feito de errado e em qual contexto
  (texto livre, trecho de código, descrição do comportamento incorreto).
- **Camada afetada** (opcional): se já souber, informe a camada
  (`core`, `database`, `rest`, `routers`, `pipes`, `pubsub`, `testing`,
  `code-conventions`). Se não souber, o prompt identifica automaticamente.

---

## Diretrizes de Execução

### 1. Identificar o doc de rules correto

Leia `documentation/rules/rules.md` e, com base na descrição do anti-padrão,
identifique o arquivo de regras da camada afetada:

| Camada | Arquivo |
|---|---|
| Regra de negócio / domínio | `core-layer-rules.md` |
| Persistência / SQLAlchemy | `database-layer-rules.md` |
| Endpoint / contrato HTTP | `rest-layer-rules.md` |
| Roteamento / composição | `routers-layers-rules.md` |
| Injeção de dependência | `pipes-layer-rules.md` |
| Jobs assíncronos / eventos | `pubsub-layer-rules.md` |
| Testes | `testing-rules.md` |
| Estilo / nomeação / organização | `code-conventions-rules.md` |

Se o erro cruzar mais de uma camada, registre em todos os docs relevantes.

### 2. Converter anti-padrão em regra objetiva

A partir do erro descrito, gere entradas curtas e prescritivas para:

- `## ✅ O que DEVE conter`
- `## ❌ O que NUNCA deve conter`

Formato esperado das entradas:

```markdown
- <Regra objetiva, curta e acionável>
```

Requisitos:

- Não criar subseções como `### ❌ Anti-padrão: ...`.
- Não adicionar blocos explicativos longos (`O que foi feito`, `Por que está errado`, etc.).
- Registrar o aprendizado como regra prática e direta.

### 3. Inserir no doc de rules

Abra o arquivo de rules identificado no passo 1 e:

- Localize as seções `## ✅ O que DEVE conter` e `## ❌ O que NUNCA deve conter`.
- Atualize **somente** essas duas seções (adicionando bullets ao final, sem remover existentes).
- Mantenha o estilo e a linguagem do documento original.

### 4. Confirmar

Após inserir, exiba os bullets adicionados e confirme o caminho do arquivo
atualizado.

---

## Saída Esperada

- Doc de rules da camada atualizado nas seções:
  - `## ✅ O que DEVE conter`
  - `## ❌ O que NUNCA deve conter`
- Exibição dos bullets inseridos para confirmação visual.

---

## Restrições

- **Não remova nem reescreva** entradas existentes no doc de rules.
- **Não generalize** além do que foi observado; registre exatamente o aprendizado útil.
- **Não criar nova seção** de anti-padrão (ex.: `### ❌ Anti-padrão: ...`).
- Se faltar contexto para identificar camada ou formular regra objetiva, use a tool `question` antes de escrever.
