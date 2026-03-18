# Tooling do Projeto

Este documento centraliza os comandos usados para validacao local do projeto Animus Mobile.

## Pre-requisito

Antes de executar qualquer validacao, instale as dependencias do projeto:

```bash
flutter pub get
```

## Typecheck

O projeto nao possui um comando dedicado chamado `typecheck` no momento. A verificacao estatica e feita com o analisador do Flutter:

```bash
flutter analyze
```

## Codecheck

Para garantir padrao de formatacao e validacao estatica, execute:

```bash
dart format .
flutter analyze
```

## Testes

Para executar a suite de testes automatizados do projeto:

```bash
flutter test
```

Tambem existe um atalho no `Makefile` para os testes:

```bash
make test
```
