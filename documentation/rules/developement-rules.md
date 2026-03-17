Aqui está a tradução para o português:

# Fluxo de Trabalho de Desenvolvimento

## Estratégia de Branches

O Stardust utiliza um fluxo de trabalho de *feature-branch* (ramificação por funcionalidade) baseado na branch `main`.

```
main
  │
  ├── feature/user-filtering
  ├── feature/star-users-dialog
  ├── fix/achievement-unlock
  └── refactor/sortable-column

```

### Nomenclatura de Branches

| Prefixo | Propósito | Exemplo |
| --- | --- | --- |
| `feature/` | Nova funcionalidade | `feature/challenges-table-skeleton` |
| `fix/` | Correção de bugs | `fix/svg-title-error` |
| `refactor/` | Melhorias de código | `refactor/period-picker` |
| `docs/` | Atualizações de documentação | `docs/api-endpoints` |

## Convenção de Commits

Os commits seguem o padrão [Conventional Commits](https://www.conventionalcommits.org/) com emojis e escopos opcionais.

### Formato

```
<emoji> <prefixo>: <mensagem>

```

### Tipos de Commit

| Tipo | Emoji | Descrição |
| --- | --- | --- |
| `domain` | 🌐 | Mudanças na camada core |
| `rest` | 📶 | Mudanças na API REST |
| `ui` | 🖥️ | Componentes de UI (Interface do Usuário) |
| `db` | 💾 | Mudanças no banco de dados |
| `interface` | 📑 | Definições de interface |
| `type` | 🏷️ | Definições de tipos |
| `docs` | 📚 | Documentação |
| `fix` | 🐛 | Correção de bugs |
| `refactor` | ♻️ | Refatoração |
| `test` | 🧪 | Testes |
| `config` | ⚙️ | Configuração |
| `validation` | 📮 | Schemas de validação |
| `deps` | 📦 | Dependências |

### Exemplos

```bash
# Com escopo
🐛 fix: garantir que apenas uma conquista seja desbloqueada por vez

# Sem escopo
📑 interface: adicionar AchievementsRepository

# Casos de uso (nenhum verbo necessário)
♻️ refactor: listar todos os desafios
🧪 test: caso de uso de listar todos os desafios

```
