---
feature: shared
title: Shared (cross-cutting) — PRD placeholder
status: informal
---

# PRD — Shared (cross-cutting concerns)

> Sem PRD formal. Os requisitos abaixo foram inferidos do ticket
> [ANI-108 — [mobile] Dark/light mode](https://joaogoliveiragarcia.atlassian.net/browse/ANI-108)
> e dos requisitos do desenvolvedor responsável pela task.

Esta pasta `shared/` agrupa specs/plans de preocupações transversais da aplicação
(tema, infraestrutura visual) que não pertencem a um módulo de domínio específico
(auth, intake, library, storage, notification).

## ANI-108 — Dark/light mode (resumo)

- Mecanismo completo de tema dark/light com persistência da preferência.
- Default dark quando não há preferência salva.
- Todas as telas reagem ao tema vigente via design tokens
  (`AppThemeTokens` / `Theme.of(context).extension<AppThemeTokens>()`).
- Toggle no Perfil (tile "Tema") alterna e persiste o modo.

Quando o time de design publicar os tokens oficiais da paleta light, esta paleta
(definida pelo desenvolvedor) deve ser revisada e ajustada.
