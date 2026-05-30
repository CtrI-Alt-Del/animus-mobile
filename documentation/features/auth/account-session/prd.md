# PRD - Account Session

## Objetivo

Consolidar os fluxos de autenticacao e sessao do usuario no app mobile do Animus,
com foco em reduzir friccao de entrada, manter a sessao valida por mais tempo e
encerrar o acesso local apenas quando a renovacao da sessao falhar.

## Entregas do fluxo

- [x] Cadastro via e-mail e senha
- [x] Login via e-mail e senha
- [x] Login com conta Google
- [x] Redefinicao de senha por e-mail
- [x] Tela de perfil read-only com navegacao pela Home
- [x] Renovacao automatica de sessao com refresh token
- [ ] Edicao de perfil
- [ ] Solicitacao de exclusao de conta

## Impacto da entrega de Login com Google

- O usuario agora pode entrar com Google tanto pela tela de `Sign In` quanto pela tela de `Sign Up`.
- O fluxo social reutiliza a mesma persistencia de sessao do login tradicional, levando o usuario direto para a home quando a autenticacao remota retorna sucesso.
- Cancelamentos do provedor nao exibem erro punitivo para o usuario.
- Falhas tecnicas ou de API continuam exibindo feedback generico consistente com os demais fluxos de auth.

## Impacto da entrega de refresh automatico de sessao

- Requests autenticadas passam a reutilizar o `access_token` salvo localmente sem configuracao manual por service.
- Quando o `access_token` expira e o `refresh_token` ainda e valido, o app renova a sessao automaticamente e repete a request original sem friccao visivel para o usuario.
- Endpoints publicos de autenticacao continuam preservando seus erros funcionais originais, sem tentativa indevida de refresh.
- Quando a renovacao falha de forma definitiva, os tokens locais sao limpos e o fluxo volta para `Sign In`, evitando sessao inconsistente.

## Observacoes de rollout

- A implementacao Flutter e os fluxos do app foram concluidos.
- O usuario autenticado agora pode acessar a tela de perfil pela bottom navigation da Home e pelo avatar do cabecalho, consultando nome e e-mail da conta atual em uma experiencia read-only.
- O shell visual de configuracoes e o CTA `Sair da Conta` foram entregues nesta sprint apenas como estrutura de interface; edicao de perfil e exclusao de conta continuam dependentes de contratos backend dedicados.
- A renovacao automatica da sessao agora fica centralizada na composicao REST do app, reduzindo risco de requests protegidas sem `Authorization` e eliminando validacoes manuais espalhadas pelos services.
- A validacao manual em device real ainda depende do provisionamento dos valores de OAuth do Google e da configuracao nativa final de Android/iOS.
