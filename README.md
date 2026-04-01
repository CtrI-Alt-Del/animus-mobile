# <h1 align="center">Animus Mobile</h1>

Aplicativo mobile do **Animus**, uma plataforma de analise de precedentes juridicos a partir de peticoes iniciais. Este cliente foi desenvolvido em **Flutter**, com foco em separacao por camadas, evolucao incremental dos dominios e integracao com servicos de autenticacao, analise juridica com IA, historico de analises e notificacoes.

## 🚀 Visao Geral

O Animus Mobile atende os principais fluxos do produto:

- **Auth:** cadastro, login, perfil e sessao do usuario.
- **Intake:** envio de petição inicial para analise de precedentes com IA.
- **Storage:** historico, organizacao e exportacao de analises realizadas.
- **Notification:** notificacoes assincronas sobre eventos importantes, como conclusao de analises.

O produto e voltado para advogados e juizes, atuando como ferramenta de apoio para identificacao de precedentes juridicos relevantes. A decisao final sobre o uso dos precedentes continua sendo do usuario.

## 🛠 Tech Stack

O repositorio mobile utiliza atualmente:

- **Framework:** [Flutter](https://flutter.dev/)
- **Linguagem:** [Dart](https://dart.dev/) 3.10+
- **Navegacao:** [go_router](https://pub.dev/packages/go_router)
- **Linting:** [flutter_lints](https://pub.dev/packages/flutter_lints)
- **Testes:** [flutter_test](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html)

No contexto do produto Animus, a aplicacao tambem se integra com uma stack mais ampla formada por backend em FastAPI, IA generativa, autenticacao, storage e notificacoes push.

## 🏗 Arquitetura

O projeto segue uma arquitetura em camadas para reduzir acoplamento, facilitar testes e permitir a evolucao dos dominios de negocio.

### Estrutura de Camadas

- **UI (`lib/ui/`)**: telas, widgets e fluxo de navegacao.
- **Core (`lib/core/`)**: contratos, DTOs e regras de dominio.
- **REST (`lib/rest/`)**: clientes HTTP, services e mapeadores.
- **Drivers (`lib/drivers/`)**: infraestrutura e adaptadores externos.

### Estado atual do repositorio

O repositorio esta em fase de bootstrap e ja contem:

- ponto de entrada da aplicacao (`lib/main.dart`)
- configuracao da app e tema (`lib/app.dart`, `lib/theme.dart`)
- rotas iniciais (`lib/router.dart`, `lib/constants/routes.dart`)
- primeira tela de autenticacao (`lib/ui/auth/widgets/pages/sign_up_screen/index.dart`)

As camadas `core`, `rest` e `drivers` ja fazem parte da estrutura-base e serao expandidas conforme os proximos modulos do produto forem implementados.

Para detalhes tecnicos, consulte a [Documentacao de Arquitetura](documentation/architecture.md).

## 📂 Estrutura do Projeto

```bash
lib/
├── app.dart
├── main.dart
├── router.dart
├── theme.dart
├── constants/
├── core/
├── drivers/
├── rest/
└── ui/
```

## ⚙️ Configuracao e Instalacao

### Pre-requisitos

- Flutter SDK compativel com o projeto
- Dart SDK 3.10+
- Android Studio e/ou Xcode, conforme a plataforma alvo

### Passo a passo

1. **Clone o repositorio:**

   ```bash
   git clone <url-do-repositorio>
   cd animus-mobile
   ```

2. **Instale as dependencias:**

   ```bash
   flutter pub get
   ```

3. **Configure o ambiente local via `.env`:**

   ```bash
   Copy-Item .env.example .env
   ```

   Depois, preencha `ANIMUS_SERVER_APP_URL` no arquivo `.env`. Se for validar o login com Google em iOS ou em fluxos que exijam configuracao explicita, preencha tambem `ANIMUS_GOOGLE_IOS_CLIENT_ID` e `ANIMUS_GOOGLE_SERVER_CLIENT_ID`.

4. **Execute o app em desenvolvimento:**

   ```bash
   make dev
   ```

   Ou, se preferir, execute diretamente com Flutter:

   ```bash
   flutter run
   ```

## 📖 Documentacao

Os principais documentos do projeto estao em `documentation/`:

- [Arquitetura e decisoes tecnicas](documentation/architecture.md)
- [Indice de regras e diretrizes](documentation/rules/rules.md)

Os dominios atuais do produto sao:

- `auth`: autenticacao, perfil e sessao
- `intake`: envio de petição e analise de precedentes
- `storage`: historico, organizacao e exportacao de analises
- `notification`: notificacoes assincronas

## 🧪 Testes e Qualidade

Execute os comandos abaixo para validar o projeto:

```bash
flutter analyze
flutter test
dart format .
```

Atalhos disponiveis no `Makefile`:

```bash
make dev
make test
make build
```

## 📝 Licenca

Este projeto esta licenciado sob a licenca [MIT](LICENSE).
