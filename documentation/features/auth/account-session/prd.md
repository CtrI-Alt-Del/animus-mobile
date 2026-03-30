# PRD - Account Session

## Objetivo

Consolidar os fluxos de autenticacao e sessao do usuario no app mobile do Animus,
com foco em reduzir friccao de entrada e garantir persistencia segura da sessao.

## Entregas do fluxo

- [x] Cadastro via e-mail e senha
- [x] Login via e-mail e senha
- [x] Login com conta Google
- [x] Redefinicao de senha por e-mail
- [ ] Edicao de perfil
- [ ] Solicitacao de exclusao de conta

## Impacto da entrega de Login com Google

- O usuario agora pode entrar com Google tanto pela tela de `Sign In` quanto pela tela de `Sign Up`.
- O fluxo social reutiliza a mesma persistencia de sessao do login tradicional, levando o usuario direto para a home quando a autenticacao remota retorna sucesso.
- Cancelamentos do provedor nao exibem erro punitivo para o usuario.
- Falhas tecnicas ou de API continuam exibindo feedback generico consistente com os demais fluxos de auth.

## Observacoes de rollout

- A implementacao Flutter e os fluxos do app foram concluidos.
- A validacao manual em device real ainda depende do provisionamento dos valores de OAuth do Google e da configuracao nativa final de Android/iOS.
