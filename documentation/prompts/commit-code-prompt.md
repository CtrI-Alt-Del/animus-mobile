---
description: Prompt para analisar alteracoes e executar commits reais com Conventional Commits + task Jira.
---

# Prompt: Fazer Commits no Codigo

**Objetivo Principal**

Criar **e executar commits reais** no repositorio para todas as alteracoes detectadas,
seguindo o padrao **Conventional Commits** com inclusao obrigatoria da task no Jira.

Voce **deve executar comandos git**, nao apenas sugerir mensagens.

---

## Regra Critica

Se existirem arquivos modificados, voce e obrigado a:

- executar `git add`
- executar `git commit`
- repetir o processo ate nao restarem mudancas pendentes

Nunca apenas sugira commits. Nunca pare somente na mensagem. **Sempre execute os comandos.**

---

## Diretrizes de Execucao

### Pre-condicao obrigatoria

Antes de qualquer comando git, valide se a entrada do usuario forneceu a task Jira.

- Se **nao** houver `JIRA-TASK-ID` valido (formato `ANI-123`), **interrompa a execucao imediatamente**
- Nao execute `git status`, `git add` ou `git commit` sem task Jira
- Responda exatamente: `ERROR: Missing Jira task id (expected format: ANI-123)`

---

### 1 Detectar Alteracoes

Execute primeiro:

`git status --porcelain`

- Se vazio -> responda: `No changes to commit`
- Se houver alteracoes -> continue

---

### 2 Analise do Contexto

- Analise nome/caminho e tambem o diff das alteracoes
- Agrupe por responsabilidade
- Se houver mudancas em camadas diferentes (ex: UI e REST), crie commits separados

---

### 3 Padrao de Mensagem (Strict)

Cada commit deve seguir **obrigatoriamente** o formato:

`<type>: <JIRA-TASK-ID> <description>`

Exemplo:

`feat: ANI-23 add sign in screen`

Regras:

- Mensagem em ingles
- `JIRA-TASK-ID` obrigatoria em todos os commits (ex: `ANI-23`)
- Um commit por responsabilidade
- Sem emoji

Tipos permitidos (Conventional Commits):

- `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`

---

### 4 Execucao Obrigatoria

Para cada grupo de arquivos identificado, execute:

`git add <arquivos-do-grupo>`
`git commit -m "<type>: <JIRA-TASK-ID> <description>"`

Nao peca confirmacao. Nao gere apenas sugestao. **Execute.**

---

### 5 Exemplos de Referencia

- `feat: ANI-23 add sign in screen`
- `fix: ANI-77 prevent duplicate achievement unlock`
- `refactor: ANI-91 simplify challenge repository contract`
- `docs: ANI-10 update mobile architecture guide`

---

### 6 Verificacao Final (Antes de cada commit)

- tipo valido de Conventional Commits
- task Jira presente no formato `ANI-123`
- descricao curta, objetiva e em ingles
- representa corretamente o grupo de arquivos

---

### 7 Formato de Saida Obrigatorio

Mostre apenas comandos executados:

`EXECUTING: git add src/modules/auth/sign-in.tsx`
`EXECUTING: git commit -m "feat: ANI-23 add sign in screen"`

Sem explicacoes longas. Sem sugestoes. Sem parar antes de commitar.
