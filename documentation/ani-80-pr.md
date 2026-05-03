## Objetivo

Implementa a fundacao mobile de push notifications do ticket ANI-80 usando OneSignal no app Flutter.

Este PR deixa o app tecnicamente apto a receber notificacoes disparadas pelo backend, mantendo o SDK encapsulado em um driver proprio, inicializando a integracao no bootstrap, associando o usuario autenticado ao OneSignal e limpando essa associacao no logout.

## Changelog

- [x] Adiciona o contrato `PushNotificationDriver` no `core`, sem dependencia direta do SDK OneSignal.
- [x] Adiciona `OneSignalPushNotificationDriver` em `drivers`, encapsulando inicializacao, permissao, identificacao de usuario e limpeza de identidade.
- [x] Expoe `pushNotificationDriverProvider` como fronteira Riverpod do novo driver.
- [x] Adiciona `ONESIGNAL_APP_ID` ao `.env.example` e expoe `Env.oneSignalAppId`.
- [x] Adiciona chave local para registrar que o prompt de permissao de notificacao ja foi tentado.
- [x] Inicializa o OneSignal no bootstrap apos `dotenv.load` e antes de `runApp`.
- [x] Identifica o usuario no OneSignal com `AccountDto.id` quando ha sessao valida.
- [x] Solicita permissao de notificacao uma unica vez apos sessao valida, sem bloquear Home ou navegacao.
- [x] Limpa a identidade OneSignal no logout.
- [x] Adiciona a permissao Android `POST_NOTIFICATIONS` preservando o deep link `animus://reset-password`.

## Novas dependencias

- [x] Adiciona `onesignal_flutter: ^5.5.2` em `pubspec.yaml` e `pubspec.lock`.
  - Motivo: disponibilizar o SDK oficial do OneSignal para Flutter.
  - Impacto esperado: inicializacao do SDK em runtime, registro do device, solicitacao de permissao e associacao do usuario autenticado via external ID.

## Como testar

1. Configure o `.env` local com o App ID do OneSignal:

```env
ONESIGNAL_APP_ID=<app_id_do_onesignal>
```

2. Execute as validacoes locais:

```bash
flutter pub get
flutter analyze
flutter test test\ui\intake\widgets\pages\home_screen\home_screen_presenter_test.dart test\ui\auth\widgets\pages\profile_screen\profile_screen_presenter_test.dart
```

3. Instale o app em Android fisico ou emulador com Google Play Services.
4. Limpe os dados do app ou reinstale para garantir que o prompt de permissao possa aparecer.
5. Faca login com uma conta valida e acesse a Home.
6. Aceite a permissao de notificacao.
7. No dashboard do OneSignal, confirme que o device foi registrado.
8. Confirme que o usuario/device esta associado ao `external_id` igual ao `AccountDto.id`.
9. Envie uma push manual de teste pelo dashboard do OneSignal para esse usuario/device.
10. Com o app em background, confirme que a notificacao nativa do Android e exibida.
11. Faca logout e confirme que o app volta para a tela de login sem erro.

## Observacoes

- `ONESIGNAL_API_KEY` nao e usada no mobile; ela deve permanecer apenas no backend/ambiente seguro.
- A configuracao Android/Firebase/FCM no dashboard do OneSignal e obrigatoria para entrega real de push, mas nao e versionada no app.
- Este PR nao implementa envio de notificacoes pelo mobile.
- Este PR nao adiciona notificacoes locais, inbox, historico, cards, handlers de clique ou navegacao por payload de push.
- Configuracao iOS esta fora do escopo deste ticket.
