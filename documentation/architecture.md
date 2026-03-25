# Arquitetura do Animus Mobile

## Visao Geral

O Animus Mobile e um aplicativo Flutter para apoiar a analise de precedentes juridicos. A arquitetura segue separacao por camadas para reduzir acoplamento, facilitar testes e permitir evolucao incremental dos dominios.

Dominios de negocio do produto:

- `auth`: cadastro, login, perfil e sessao do usuario.
- `intake`: envio de peticao e analise com IA de precedentes.
- `storage`: historico, organizacao e exportacao de analises.
- `notification`: notificacoes assicronas de eventos importantes.

## Camadas

- **UI (`lib/ui/`)**: telas, widgets e fluxo de navegacao.
- **Core (`lib/core/`)**: contratos, DTOs e regras de dominio.
- **REST (`lib/rest/`)**: clientes HTTP, services e mapeadores.
- **Drivers (`lib/drivers/`)**: infraestrutura e adaptadores externos.

## Estado atual do repositorio

O bootstrap inicial ja evoluiu para o primeiro fluxo completo de autenticacao por
e-mail e senha. A base atual contem:

- ponto de entrada da aplicacao (`lib/main.dart`) com carregamento de ambiente;
- configuracao da app e tema Material (`lib/app.dart`, `lib/theme.dart`);
- rotas de cadastro e confirmacao de e-mail por OTP (`lib/router.dart`, `lib/constants/routes.dart`);
- fluxo de cadastro em MVP na camada UI (`lib/ui/auth/widgets/pages/sign_up_screen/`);
- tela dedicada de confirmacao de e-mail (`lib/ui/auth/widgets/pages/email_confirmation_screen/`);
- contratos de autenticacao e sessao no Core (`lib/core/auth/`);
- implementacao REST concreta para `signUp`, `verifyEmail` e `resendVerificationEmail` (`lib/rest/services/auth_rest_service.dart`);
- persistencia local de tokens via driver de cache com `SharedPreferences` (`lib/drivers/cache-driver/shared_preferences_cache_driver.dart`).

## Integracoes previstas

- API backend para autenticacao e analise juridica.
- Persistencia local para tokens e configuracoes de sessao.
- Servicos de notificacao push.

A URL do backend deve ser configurada via `--dart-define` (`ANIMUS_SERVER_APP_URL`) para evitar acoplamento a ambiente local.

No fluxo atual de autenticacao, a camada REST consome os endpoints `POST /auth/sign-up`,
`POST /auth/verify-email` e `POST /auth/resend-verification-email`. Em caso de sucesso na
confirmacao de e-mail, a UI persiste `accessToken` e `refreshToken` via `CacheDriver`
antes de navegar para `Routes.home`.

## Principios arquiteturais

1. UI nao acessa API diretamente.
2. Regras de dominio ficam na camada Core.
3. Drivers e REST implementam contratos definidos no Core.
4. Componentes de UI devem ser pequenos e focados em responsabilidade unica.
5. Evolucoes multi-camada devem respeitar fronteiras e nomenclatura do projeto.
