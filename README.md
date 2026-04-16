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

   Depois, preencha as variaveis abaixo no arquivo `.env`:

   - `ANIMUS_SERVER_APP_URL`
     - **O que e:** URL base do backend Animus consumido pelo app.
     - **Como obter (dev local Android Emulator):** use `http://10.0.2.2:8080` se o backend estiver rodando na sua maquina na porta `8080`.
     - **Como obter (dispositivo fisico):** use o IP da maquina na rede local (ex.: `http://192.168.0.10:8080`).

   - `GOOGLE_IOS_CLIENT_ID`
     - **O que e:** OAuth Client ID do tipo **iOS** para o app nativo.
     - **Como obter:**
       1. Acesse o [Google Cloud Console](https://console.cloud.google.com/).
       2. Selecione o projeto usado pelo Animus.
       3. Va em **APIs & Services > Credentials**.
       4. Crie (ou copie) um **OAuth client ID** do tipo **iOS**.
       5. Use o valor de **Client ID** nesta variavel.
     - **Importante iOS:** mantenha o `reversed client id` alinhado com `CFBundleURLSchemes` no `Info.plist`.

   - `GOOGLE_SERVER_CLIENT_ID`
     - **O que e:** OAuth Client ID do tipo **Web/Server**, usado para emissao/validacao de token no backend.
     - **Como obter:**
       1. No mesmo projeto do Google Cloud, abra **APIs & Services > Credentials**.
       2. Crie (ou copie) um **OAuth client ID** do tipo **Web application**.
       3. Use o valor de **Client ID** nesta variavel.

   - `GCS_URL`
     - **O que e:** endpoint base do servico de storage usado pelo app.
     - **Como obter (dev local):** se estiver usando emulacao/local storage gateway, use `http://10.0.2.2:4443` no Android Emulator.

   - `GCS_DOWNLOAD_URL`
     - **O que e:** endpoint base para download de objetos no bucket.
     - **Como obter (dev local):** normalmente segue o padrao:
       `http://10.0.2.2:4443/download/storage/v1/b/<bucket>/o`
       substituindo `<bucket>` pelo nome real do bucket (no projeto atual: `animus-bucket`).

   Exemplo de `.env` para ambiente local:

   ```env
   ANIMUS_SERVER_APP_URL=http://10.0.2.2:8080
   GOOGLE_IOS_CLIENT_ID=seu-client-id-ios.apps.googleusercontent.com
   GOOGLE_SERVER_CLIENT_ID=seu-client-id-web.apps.googleusercontent.com
   GCS_URL=http://10.0.2.2:4443
   GCS_DOWNLOAD_URL=http://10.0.2.2:4443/download/storage/v1/b/animus-bucket/o
   ```

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

## 📦 Release de APK

O repositório possui um workflow de CD em `.github/workflows/android-cd.yml` que roda a cada `push` nas branches `main` e `production`.

- `main`: gera um APK assinado do ambiente `main` e publica uma nova GitHub Release com o asset `animus-main-<sha>.apk`
- `production`: gera um APK assinado do ambiente `production` e publica uma nova GitHub Release com o asset `animus-production-<sha>.apk`

### GitHub Environments

Crie dois environments no GitHub:

- `main`
- `production`

Cada environment deve conter os secrets abaixo com os valores do respectivo ambiente:

- `ANIMUS_SERVER_APP_URL`
- `GOOGLE_IOS_CLIENT_ID`
- `GOOGLE_SERVER_CLIENT_ID`
- `GCS_URL`
- `GCS_DOWNLOAD_URL`
- `PANGEA_URL`
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

### Keystore Android

- `ANDROID_KEYSTORE_BASE64` deve conter o arquivo `.jks` oficial codificado em Base64
- o workflow reconstrói a keystore no runner, gera `android/key.properties` dinamicamente e assina o `flutter build apk --release`
- `android/key.properties` e arquivos `.jks` ficam ignorados no Git e não devem ser versionados

### Observação

Os APKs de `main` e `production` são separados para distribuição, mas usam o mesmo `applicationId`. Por isso, instalar um deles sobre o outro substituirá o app já instalado no dispositivo.

## 📝 Licenca

Este projeto esta licenciado sob a licenca [MIT](LICENSE).
