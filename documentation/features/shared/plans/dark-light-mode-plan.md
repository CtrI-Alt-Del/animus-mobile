---
title: Plano de Implementação — Dark/Light Mode (ANI-108)
spec: ../specs/dark-light-mode-spec.md
created_at: 2026-05-28
status: closed
---

---

## Análise de Dependências

### Artefatos que desbloqueiam outras camadas

- **`CacheKeys.themeMode`** (`lib/constants/cache_keys.dart`) — chave de cache;
  pré-requisito do `ThemeModeNotifier`. *(já aplicada)*
- **`AppTheme.lightTokens` + `AppTheme.light`** (`lib/theme.dart`) — tokens e
  `ThemeData` light; pré-requisito de `AnimusApp` e da migração de cores.
- **`themeModeProvider` / `ThemeModeNotifier`** (`lib/ui/shared/theme/`) —
  estado de tema; pré-requisito de `AnimusApp` e do toggle do Perfil.

### Partes independentes entre si

- A migração de cor de cada módulo (auth, intake, library) é independente:
  cada arquivo só depende de `AppThemeTokens` (já existe) e do fallback
  `AppTheme.tokens` (já existe). Podem rodar em paralelo após F1.

### Tarefas iniciáveis com stub

- A migração de cor (F2-F4) pode iniciar imediatamente — depende apenas de
  `AppThemeTokens`, que já existe. Não precisa aguardar o provider.

---

## Gargalos identificados

- **F1 (mecanismo core)**: desbloqueia o comportamento de alternância e o
  registro do light theme. A migração de cor (F2-F4) é tecnicamente
  independente, mas o resultado visual só é verificável com F1 pronto.

---

## Mapa de Paralelização

| Fase | Objetivo | Depende de | Pode rodar em paralelo com |
|------|----------|------------|----------------------------|
| F1   | Mecanismo core: tokens light, ThemeData light, provider, wiring app, status bar, toggle Perfil | — | F2, F3, F4 |
| F2   | Migração de cor — módulo `auth` | — (usa AppThemeTokens) | F1, F3, F4 |
| F3   | Migração de cor — módulo `intake` | — | F1, F2, F4 |
| F4   | Migração de cor — módulo `library` | — | F1, F2, F3 |
| F5   | Testes + conclude (ThemeModeNotifier, widget tests) | F1 | — |

---

## Fases e Tarefas

### F1 — Mecanismo core de tema

- [x] **F1-T1** — Adicionar `CacheKeys.themeMode = 'app:theme_mode'`
  - Camada: `constants`
  - Artefato: `lib/constants/cache_keys.dart`
- [x] **F1-T2** — Paleta light + `AppTheme.lightTokens` + `AppTheme.light`
  - Camada: `ui` (theme)
  - Artefato: `lib/theme.dart`
  - Depende de: —
  - Desbloqueia: F1-T3, migração de cor
- [x] **F1-T3** — `ThemeModeNotifier` + `themeModeProvider` + barrel
  - Camada: `ui` (shared/theme)
  - Artefato: `lib/ui/shared/theme/theme_mode_provider.dart`, `lib/ui/shared/theme/index.dart`
  - Depende de: F1-T1
- [x] **F1-T4** — `AnimusApp` → `ConsumerWidget`, wiring theme/darkTheme/themeMode
  - Camada: `app`
  - Artefato: `lib/app.dart`
  - Depende de: F1-T2, F1-T3
- [x] **F1-T5** — Status bar inicial por tema persistido em `main()`
  - Camada: `app`
  - Artefato: `lib/main.dart`, `lib/theme.dart` (helper de overlay)
  - Depende de: F1-T2
- [x] **F1-T6** — Conectar toggle do tile "Tema" via `ProfileScreenPresenter.toggleTheme()`
  - Camada: `ui` (auth/profile)
  - Artefato: profile_screen presenter/view + profile_settings_group
  - Depende de: F1-T3

### F2 — Migração de cor: `auth` (9 arquivos)

- [x] **F2-T1** — Migrar cores hard-coded dos arquivos de `lib/ui/auth/`
  - Arquivos: check_email_screen, email_confirmation_screen,
    profile_account_card, profile_error_card, profile_loading_card,
    profile_logout_button, profile_settings_group,
    profile_settings_tile, profile_update_name_dialog

### F3 — Migração de cor: `intake` (15 arquivos)

- [x] **F3-T1** — Migrar cores hard-coded dos arquivos de `lib/ui/intake/`
  - Arquivos: analysis_header (archive/rename/unarchive dialogs),
    analysis_precedents_bubble (add_precedent, precedent_dialog,
    precedents_filters_dialog + court_filter_section + filter_chip +
    section_header, precedents_limit_dialog),
    case_assessment_analysis_screen, first_instance_analysis_screen,
    create_analysis_type_dialog, analysis_type_presentation,
    second_instance_analysis_screen

### F4 — Migração de cor: `library` (3 arquivos)

- [x] **F4-T1** — Migrar cores hard-coded dos arquivos de `lib/ui/library/`
  - Arquivos: folder_grid_card, library_screen, library_folder_screen

### F5 — Testes e conclusão

- [x] **F5-T1** — Testes do `ThemeModeNotifier` (toggle/persist/load/default-dark)
  - Artefato: `test/ui/shared/theme/theme_mode_provider_test.dart`
- [x] **F5-T2** — Widget test do toggle de tema no Perfil (lib/ui)
  - Artefato: `test/ui/auth/.../profile_settings_group_view_test.dart`
- [x] **F5-T3** — Ciclo de qualidade final + conclude (status closed)

---

## Mapeamento hex -> token (referência da migração)

| Hex literal (dark) | Token |
|---|---|
| `0xFFFBE26D` | `tokens.accent` |
| `0xFFC4A535` | `tokens.accentStrong` |
| `0xFF0B0B0E` | `tokens.surfacePage` |
| `0xFF16161A` / `0xFF1E1E24` / `0xFF1F1F26` / `0xFF2C2C32` | `tokens.surfaceCard` |
| `0xFF1A1A1E` | `tokens.surfaceElevated` |
| `0xFF2A2A2E` | `tokens.borderSubtle` |
| `0xFF3A3A40` | `tokens.borderStrong` |
| `0xFFFAFAF9` | `tokens.textPrimary` |
| `0xFF6B6B70` | `tokens.textSecondary` |
| `0xFF8E8E93` / `0xFFB0B0B5` | `tokens.textMuted` |
| `0xFF4A4A50` | `tokens.textTertiary` |
| `0xFFFFFFFF` | `tokens.white` |
| `0xFF32D583` | `tokens.success` |
| `0xFF059669` | `tokens.successDark` |
| `0xFFE85A4F` / `0xFFEF4444` | `tokens.danger` |
| `0xFFDC2626` | `tokens.dangerDark` |
| `0xFFFFD700` | `tokens.accent` (dourado -> accent) |
| `0xFF6366F1` | `tokens.primaryGradient.colors.first` (indigo) |
| `0x186366F1` | indigo translucido -> token accent/indigo `withValues(alpha:)` |
| `0x33FBE26D` / `0x1AFBE26D` / `0x0DFBE26D` | `tokens.accent.withValues(alpha: 0.2/0.1/0.05)` |
| `0x99000000` | scrim -> `tokens.scrim` (novo token) |

> Alpha-variants de accent/indigo sao reescritos como
> `tokens.<base>.withValues(alpha: <a>)`. Scrims pretos translucidos passam a
> usar um token de scrim adaptavel para clarear no light.

---

## Divergencias em relacao a Spec

- Nenhuma ate o momento.

## Pendencias

- Paleta light e provisoria (definida pelo dev). Ajustar quando o design
  publicar os tokens oficiais.

---

## Resumo de Conclusão (Fase 3.1)

### O que foi feito

Mecanismo completo de tema dark/light:
- `AppTheme.lightTokens` (paleta light derivada) + `AppTheme.light` (`ThemeData`),
  com `_buildTheme(brightness, tokens)` parametrizado; `AppTheme.tokens` (dark)
  preservado como fallback.
- Novo token `scrim` adicionado a `AppThemeTokens` (copyWith/lerp atualizados).
- `ThemeModeNotifier` + `themeModeProvider` (`Riverpod` `Notifier`), com
  load/toggle/setMode e persistência via `CacheDriver`
  (`CacheKeys.themeMode = 'app:theme_mode'`). Leitura de cache resiliente
  (fallback dark se driver indisponível).
- `AnimusApp` agora é `ConsumerWidget`, passando
  `theme/darkTheme/themeMode`.
- `main.dart` resolve o tema inicial do cache e aplica `SystemUiOverlayStyle`
  por tema; `AppTheme.overlayStyleFor(mode)` centraliza o overlay.
- Toggle do tile "Tema" no Perfil conectado via `themeModeProvider.toggle()`.
- Migração de TODAS as cores hard-coded de `lib/ui/` para tokens.

### O que mudou em relação à Spec original

- Adicionado token `scrim` (não previsto na spec): necessário para clarear
  scrims pretos translúcidos no light.
- `ProfileScreenView` consome `themeModeProvider` diretamente (em vez de
  `ProfileScreenPresenter.toggleTheme()`), pois o presenter usa `signals` e o
  toggle é uma ação de UI de uma linha — alinhado à regra "não criar presenter
  artificial só para repassar".

### Pontos de atenção para o revisor

- Paleta light é provisória (definida pelo dev) — revisar com tokens oficiais.
- 3 casos legítimos não migrados (ver spec seção 10): identidade de tipo de
  análise, scrims pretos de sombra, `Colors.transparent`.
