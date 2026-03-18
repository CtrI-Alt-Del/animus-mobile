# Fluxo de Trabalho de Desenvolvimento

## Estrategia de branches

O projeto utiliza fluxo baseado em `main` com branches curtas por objetivo.

### Nomenclatura

| Prefixo | Proposito | Exemplo |
| --- | --- | --- |
| `feature/` | Nova funcionalidade | `feature/ani-25-sign-up-screen` |
| `fix/` | Correcao de bug | `fix/ani-40-windows-console-stream` |
| `refactor/` | Melhoria estrutural sem mudar comportamento | `refactor/ani-44-router-cleanup` |
| `docs/` | Ajustes de documentacao | `docs/ani-51-architecture-update` |

## Convencao de PR

- O titulo do PR deve iniciar com o ID da task Jira: `[ANI-123] <titulo objetivo>`.
- O PR deve descrever objetivo, escopo, validacao e impactos.
- Sempre registrar comandos usados para validar (`flutter analyze`, `flutter test`).

## Convencao de commits

Os commits seguem [Conventional Commits](https://www.conventionalcommits.org/) com escopo opcional.

Formato:

```text
<type>(<scope>): <mensagem>
```

Tipos recomendados: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`.

Exemplos:

```text
feat(auth): criar tela inicial de cadastro
fix(windows): corrigir redirecionamento de stderr no runner
docs(rules): alinhar guideline com estado atual do bootstrap
```

## Checklist antes de subir alteracoes

1. Atualizar documentacao impactada pela mudanca.
2. Executar `flutter analyze` sem erros.
3. Executar `flutter test` com cenarios relevantes.
4. Garantir ausencia de segredos em arquivos versionados.
5. Confirmar se o titulo do PR segue o padrao com Jira.
