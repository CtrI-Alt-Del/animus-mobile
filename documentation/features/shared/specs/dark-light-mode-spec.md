---
title: Dark/Light Mode — mecanismo de tema e migração de cores para tokens
prd: ../prd.md
ticket: https://joaogoliveiragarcia.atlassian.net/browse/ANI-108
last_updated_at: 2026-05-28
status: closed
---

# 1. Objetivo

Entregar um mecanismo completo de tema **dark/light** no Animus Mobile, com
persistência da preferência do usuário, default **dark** quando não há
preferência salva, alternância via toggle no Perfil e — requisito crítico —
fazer com que **todas as telas** reajam ao tema vigente. Isso exige introduzir
uma paleta `light` derivada da paleta `dark` existente e **migrar todas as cores
hard-coded** (`Color(0x...)`, `Colors.xxx`) das telas em `lib/ui/` para os
design tokens já existentes em `AppThemeTokens`, de modo que nenhuma cor fique
"fora do tema".

# 2. Escopo

## 2.1 In-scope

- Paleta `light` (`AppTheme.lightTokens`) derivada da paleta `dark`.
- `ThemeData AppTheme.light` análogo a `AppTheme.dark`, registrando
  `lightTokens` em `extensions:`.
- `ThemeModeNotifier` + `themeModeProvider` (`Riverpod`), com load/toggle/persist.
- Persistência via `CacheDriver` (port do `core`), chave nova
  `CacheKeys.themeMode = 'app:theme_mode'`.
- `AnimusApp` convertido para `ConsumerWidget`, consumindo
  `theme/darkTheme/themeMode`.
- Status bar (`SystemUiOverlayStyle`) adaptada por tema.
- Toggle do tile "Tema" no Perfil conectado a
  `ProfileScreenPresenter.toggleTheme()`.
- Migração de **todas** as cores hard-coded de `lib/ui/` para `tokens.X`.

## 2.2 Out-of-scope

- Qualquer mudança de **layout, padding, radius, fonte, tamanho** — APENAS COR.
- Tokens oficiais de design (paleta light é provisória, definida pelo dev).
- Modo "system"/automático seguindo o SO (apenas dark/light explícito; o default
  na ausência de preferência é dark).
- Testes que não sejam do `ThemeModeNotifier` e widget tests de `lib/ui`.

# 3. Requisitos

## 3.1 Funcionais

- RF1 — App inicia em **dark** quando não há preferência salva.
- RF2 — Toggle no Perfil alterna entre dark e light e **persiste** a escolha.
- RF3 — Preferência persistida é **restaurada** no próximo boot.
- RF4 — Todas as telas refletem o tema vigente (zero cor hard-coded fora de
  casos legítimos como `Colors.transparent`).
- RF5 — Status bar/navigation bar adaptam ícones ao tema (claro no dark, escuro
  no light).

## 3.2 Não funcionais

- **Acessibilidade:** contraste legível no light — accent `#FBE26D` é ilegível
  sobre branco, então o accent do light usa um tom mais escuro (`#C4A535`).
- **Segurança:** persistência apenas via `CacheDriver` (port), nunca
  `SharedPreferences` direto na UI.
- **Compatibilidade:** sem novas dependências; usa `flutter_riverpod` e
  `shared_preferences` já presentes.

# 4. O que já existe?

## Camada UI (Theme)

- **`AppThemeTokens`** (`lib/theme.dart`) — `ThemeExtension` com `copyWith` +
  `lerp` prontos. Campos: `surfacePage, surfaceCard, surfaceElevated,
  borderSubtle, borderStrong, textPrimary, textSecondary, textMuted,
  textTertiary, accent, accentStrong, white, success, successDark, warning,
  danger, dangerDark, primaryGradient`.
- **`AppTheme.tokens`** (`lib/theme.dart`) — tokens DARK (`const`), usado como
  fallback por muitos widgets (`Theme.of(context).extension<AppThemeTokens>() ??
  AppTheme.tokens`). **NÃO renomear/remover.**
- **`AppTheme.dark` / `AppTheme._buildTheme()`** (`lib/theme.dart`) — `ThemeData`
  dark.
- **`AppTheme.defaultThemeMode = ThemeMode.dark`** (`lib/theme.dart`).

## Camada Drivers / Core

- **`CacheDriver`** (`lib/core/shared/interfaces/cache_driver.dart`) — contrato:
  `String? get(String key)`, `void set(String key, String value)`,
  `void delete(String key)`.
- **`cacheDriverProvider`** (`lib/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart`)
  — provider Riverpod do `CacheDriver`.

## Camada Constants

- **`CacheKeys`** (`lib/constants/cache_keys.dart`) — chaves de cache.

## Camada App

- **`AnimusApp`** (`lib/app.dart`) — `StatelessWidget` com `MaterialApp.router`.
- **`main()`** (`lib/main.dart`) — já tem `ProviderScope` e overrides; já seta
  `SystemUiOverlayStyle` para dark.

## Camada UI (Perfil)

- **`ProfileSettingsGroupView`**
  (`lib/ui/auth/widgets/pages/profile_screen/profile_settings_group/profile_settings_group_view.dart`)
  — tile "Tema" com `onTap: _noop` e `isDarkThemeEnabled` estático.
- **`ProfileScreenPresenter`** (`lib/ui/auth/widgets/pages/profile_screen/...`)
  — presenter da tela de Perfil (a estender com `toggleTheme()`).

# 5. O que deve ser criado?

## Camada UI (Theme — provider de tema)

- **`ThemeModeNotifier`** + **`themeModeProvider`** — **novo arquivo**
  `lib/ui/shared/theme/theme_mode_provider.dart`.
  - `class ThemeModeNotifier extends Notifier<ThemeMode>` (ou
    `StateNotifier<ThemeMode>` conforme padrão Riverpod do projeto).
  - `ThemeMode build()` — lê `CacheKeys.themeMode` via `CacheDriver`; mapeia
    `'light' -> ThemeMode.light`, `'dark' -> ThemeMode.dark`; default
    `AppTheme.defaultThemeMode` (dark) quando ausente/inválido.
  - `void toggle()` — inverte dark<->light, atualiza state e persiste via
    `CacheDriver.set`.
  - `void setMode(ThemeMode mode)` — define e persiste explicitamente.
  - `themeModeProvider` — `NotifierProvider<ThemeModeNotifier, ThemeMode>`,
    injeta `cacheDriverProvider`.
  - Barrel `lib/ui/shared/theme/index.dart` (**novo arquivo**) exportando o provider.

## Camada Constants

- **`CacheKeys.themeMode`** — `static const String themeMode = 'app:theme_mode';`
  em `lib/constants/cache_keys.dart` (**adição**; já aplicada).

# 6. O que deve ser modificado?

## Camada UI (Theme — `lib/theme.dart`)

- Adicionar paleta `light`: cores privadas `_light*` e
  **`AppTheme.lightTokens`** (`const AppThemeTokens`).
- Adicionar **`AppTheme.light`** = `_buildTheme(...)` parametrizado por brilho,
  registrando `lightTokens` em `extensions:`. Refatorar `_buildTheme` para
  receber brightness + tokens (mantendo `AppTheme.dark` idêntico em
  comportamento).
- **NÃO** alterar `AppTheme.tokens` (continua dark, fallback).

## Camada App (`lib/app.dart`)

- `AnimusApp` vira `ConsumerWidget`.
- `MaterialApp.router` passa `theme: AppTheme.light`,
  `darkTheme: AppTheme.dark`, `themeMode: ref.watch(themeModeProvider)`.

## Camada App (`lib/main.dart`)

- Manter o `SystemUiOverlayStyle` inicial coerente com o tema persistido
  (ler `CacheKeys.themeMode` no boot, ou manter dark como default e deixar o
  app ajustar). Adaptar overlay por tema.

## Camada UI (Perfil)

- `ProfileScreenPresenter` ganha `void toggleTheme()` delegando ao
  `ThemeModeNotifier.toggle()`.
- `ProfileScreenView`/`ProfileSettingsGroupView` passam a ler o tema vigente do
  `themeModeProvider` (`isDarkThemeEnabled = themeMode == ThemeMode.dark`) e
  ligam `onTap` do tile "Tema" a `toggleTheme()`. Trocar as constantes
  hard-coded (`_profileSettingsSurfaceColor`, `_profileSettingsBorderColor`,
  `_profileSettingsDividerColor`) por `tokens`.

## Camada UI (migração de cores — todas as telas)

- Para **cada** arquivo em `lib/ui/` com cor hard-coded (`Color(0x...)`,
  `Colors.xxx`), obter `tokens` via
  `Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens` e
  substituir por `tokens.X` equivalente. Scrims pretos translúcidos (ex.
  `#00000099`) viram token de scrim adaptável. Casos legítimos
  (`Colors.transparent`, overlays que devem ser sempre pretos) permanecem e
  são documentados.

# 7. O que deve ser removido?

- Constantes de cor locais e privadas em arquivos de `lib/ui/` que forem
  totalmente substituídas por tokens (ex.: `_profileSettingsSurfaceColor` etc.).
  Remover apenas quando não restar referência.

# 8. Decisões Técnicas e Trade-offs

- **Notifier x StateNotifier:** usar a API de `Notifier`/`NotifierProvider`
  (Riverpod 3.x, já no pubspec) para estado simples de `ThemeMode`.
  - *Alternativa:* `ChangeNotifier` — descartada por inconsistência com o
    restante da composição Riverpod.
- **Default dark sem preferência:** alinhado a `AppTheme.defaultThemeMode`.
- **Accent no light:** `#C4A535` (o `accentStrong` do dark) como `accent` do
  light, pois `#FBE26D` não tem contraste sobre branco.
- **`AppTheme.tokens` intacto:** muitos widgets usam como fallback `const`;
  renomear quebraria a app. Adiciona-se `lightTokens` ao lado.
- **Migração só de cor:** nenhuma mudança estrutural; reduz risco de regressão
  visual de layout.

# 9. Diagramas e Referências

```text
boot → main() lê CacheKeys.themeMode → SystemUiOverlayStyle inicial
AnimusApp (ConsumerWidget) → ref.watch(themeModeProvider) → MaterialApp.router
   theme: AppTheme.light / darkTheme: AppTheme.dark / themeMode: <watched>

Perfil:
ProfileSettingsGroupView (onTap Tema) → ProfileScreenPresenter.toggleTheme()
   → ThemeModeNotifier.toggle() → state + CacheDriver.set(themeMode)
   → MaterialApp re-renderiza com novo ThemeData
```

Referências de padrão: `cacheDriverProvider`
(`lib/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart`),
fallback de tokens em
`lib/ui/auth/widgets/pages/profile_screen/profile_settings_group/profile_settings_group_view.dart`.

# 10. Pendências / Dúvidas

- **Paleta light provisória:** definida pelo desenvolvedor; ajustar quando o
  design publicar os tokens oficiais. *Ação:* revisar na publicação do design.
- **Lista exata de arquivos com cor hard-coded:** ~28 arquivos em `lib/ui/`
  tinham `Color(0x...)` (138 ocorrências); todos migrados para tokens, exceto os
  casos legítimos abaixo. *Ação:* concluído.

## Casos legítimos remanescentes (intencionalmente NÃO migrados)

- **`analysis_type_presentation.dart`** — `colorFor()` retorna 3 cores de
  identidade visual por tipo de análise (`#B48BE6` roxo, `#FBE26D` dourado,
  `#7BC4E3` azul). São hues de identidade (badges distintivos), não superfícies
  de tema; legíveis em dark e light. É um método `static` sem `BuildContext`,
  então não tem acesso a tokens. Mantido como cor de marca.
- **`Colors.black.withValues(alpha: ...)`** em `folder_selection_action_bar`,
  `app_bottom_navigation` e `library_folder_settings_modal` — sombras/scrims que
  devem permanecer pretas translúcidas em ambos os temas (sombra de elevação).
- **`Colors.transparent`** — usado em diversos widgets (`Material`, `AppBar`,
  `FilledButton` sobre gradiente etc.); semanticamente correto em qualquer tema.

# 11. Paleta Light (provisória)

| Token | Dark (atual) | Light (novo) |
|---|---|---|
| surfacePage | `#0B0B0E` | `#F7F7F5` |
| surfaceCard | `#16161A` | `#FFFFFF` |
| surfaceElevated | `#1A1A1E` | `#EFEFEC` |
| borderSubtle | `#2A2A2E` | `#E2E2DD` |
| borderStrong | `#3A3A40` | `#C9C9C2` |
| textPrimary | `#FAFAF9` | `#1A1A1E` |
| textSecondary | `#6B6B70` | `#5A5A60` |
| textMuted | `#8E8E93` | `#6B6B70` |
| textTertiary | `#4A4A50` | `#A0A0A6` |
| accent | `#FBE26D` | `#C4A535` |
| accentStrong | `#C4A535` | `#9C8226` |
| white | `#FFFFFF` | `#FFFFFF` |
| success | `#32D583` | `#15A862` |
| successDark | `#059669` | `#047857` |
| warning | `#FBE26D` | `#B7902A` |
| danger | `#E85A4F` | `#D23B2F` |
| dangerDark | `#DC2626` | `#B91C1C` |
| primaryGradient | indigo `#6366F1`→`#4F46E5` | mantém |

> O `white` permanece `#FFFFFF` (semântica "sempre branco", usado sobre
> superfícies coloridas como o gradiente indigo).
