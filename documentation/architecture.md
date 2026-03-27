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
- rotas de login, cadastro e confirmacao de e-mail por OTP (`lib/router.dart`, `lib/constants/routes.dart`);
- rotas de recuperacao de senha com pedido de link, confirmacao de envio e definicao de nova senha (`lib/router.dart`, `lib/constants/routes.dart`);
- fluxos de login e cadastro em MVP na camada UI (`lib/ui/auth/widgets/pages/sign_in_screen/`, `lib/ui/auth/widgets/pages/sign_up_screen/`);
- tela dedicada de confirmacao de e-mail (`lib/ui/auth/widgets/pages/email_confirmation_screen/`);
- telas dedicadas de reset de senha e listener app-scoped para deep link de recuperacao (`lib/ui/auth/widgets/pages/forgot_password_screen/`, `lib/ui/auth/widgets/pages/check_email_screen/`, `lib/ui/auth/widgets/pages/new_password_screen/`, `lib/ui/auth/widgets/components/password_reset_link_listener/`);
- contratos de autenticacao e sessao no Core (`lib/core/auth/`);
- implementacao REST concreta para `signIn`, `signUp`, `verifyEmail`, `resendVerificationEmail`, `forgotPassword`, `verifyResetToken` e `resetPassword` (`lib/rest/services/auth_rest_service.dart`);
- persistencia local de tokens via driver de cache com `SharedPreferences` (`lib/drivers/caches/shared_preferences/shared_preferences_cache_driver.dart`);
- driver dedicado para capturar o custom scheme `animus://reset-password?token=...` via `app_links` (`lib/core/auth/interfaces/password_reset_link_driver.dart`, `lib/drivers/password-reset-link-driver/`);
- abstracao de navegacao por contrato `NavigationDriver` implementado com `GoRouter` (`lib/core/shared/interfaces/navigation_driver.dart`, `lib/drivers/navigation/`).

## Integracoes previstas

- API backend para autenticacao e analise juridica.
- Persistencia local para tokens e configuracoes de sessao.
- Servicos de notificacao push.

A URL do backend deve ser configurada via `--dart-define` (`ANIMUS_SERVER_APP_URL`) para evitar acoplamento a ambiente local.

No fluxo atual de autenticacao, a camada REST consome os endpoints `POST /auth/sign-in`,
`POST /auth/sign-up`, `POST /auth/verify-email`, `POST /auth/resend-verification-email`,
`POST /auth/password/forgot`, `POST /auth/password/verify-reset-token` e
`POST /auth/password/reset`.
Em caso de sucesso no login ou na confirmacao de e-mail, a UI persiste `accessToken` e
`refreshToken` via `CacheDriver` antes de navegar para `Routes.home`. Quando o backend
responde `403` no login, a UI tenta reenviar automaticamente o OTP e redireciona o usuario
para a tela de confirmacao de e-mail.

No fluxo de redefinicao de senha, o usuario parte da tela de login, solicita o envio do
link por e-mail, acompanha uma tela de confirmacao com reenvio bloqueado por countdown e,
ao abrir o deep link, o app valida remotamente o token antes de liberar a tela de nova
senha. O token recebido pelo deep link nao e persistido localmente: ele permanece apenas no
listener/presenter ate a validacao e redirecionamento para a rota de redefinicao.

## Principios arquiteturais

1. UI nao acessa API diretamente.
2. Regras de dominio ficam na camada Core.
3. Drivers e REST implementam contratos definidos no Core.
4. Componentes de UI devem ser pequenos e focados em responsabilidade unica.
5. Evolucoes multi-camada devem respeitar fronteiras e nomenclatura do projeto.
