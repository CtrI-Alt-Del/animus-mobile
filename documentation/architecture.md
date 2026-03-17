# Arquitetura do Equiny Mobile

## Visao Geral

O Equiny usa arquitetura em camadas inspirada em Clean Architecture para reduzir acoplamento e facilitar testes. E um app de e-commerce em Flutter/Dart integrado a uma API RESTful chamdo Equiny Server.

## Camadas

- **UI (`lib/ui/`)**: Widgets, telas e presenters (MVP). Estado com Riverpod + Signals.
- **Core (`lib/core/`)**: DTOs, interfaces e tipos de resposta (ex.: `RestResponse`).
- **Rest (`lib/rest/`)**: Implementacoes HTTP e servicos externos (Dio + API RESTful).
- **Drivers (`lib/drivers/`)**: Infraestrutura externa (ex.: `.env`).

## Injecao de Dependencias

Riverpod centraliza a composicao de dependencias: providers para drivers, rest client, servicos e rotas.

## Padroes Principais

- **MVP** na UI para separar View e Presenter.
- **DTO** para contratos de dados entre camadas.
- **Adapter** para adaptar Dio ao `RestClient`.
- **Service/Mapper** para integrar Yampi e converter dados externos.

## Decisoes Arquiteturais

- Camadas garantem testabilidade e substituicao de implementacoes.
- Riverpod + Signals oferecem DI robusta e estado reativo granular.
- Yampi simplifica operacao de e-commerce via API REST.

## Armadilhas a Evitar

1. Logica de dominio fora do `core/`.
2. Chamar API diretamente na UI.
3. Dependencias circulares entre camadas.
4. Presenter fazendo requisicoes diretas.
5. DTOs mutaveis (prefira `final`).

## Stack Tecnologica

| Tecnologia | Pacote | Finalidade |
|------------|--------|------------|
| **Linguagem** | Dart | Linguagem principal |
| **Framework** | Flutter | Framework multiplataforma |
| **API** | Yampi Dev | Plataforma de e-commerce (RESTful) |
| **HTTP Client** | Dio | Requisicoes HTTP e interceptors |
| **Estado & DI** | flutter_riverpod | Injecao de dependencias e estado global |
| **Reatividade** | signals / signals_flutter | Estado reativo granular |
| **Rotas** | go_router | Navegacao declarativa |
| **UI Kit** | shadcn_flutter | Componentes de interface |
| **Animacoes** | flutter_animate, animate_do, lottie | Micro-interacoes e animacoes |
| **Icones** | font_awesome_flutter | Icones vetoriais |
| **SVG** | flutter_svg | Renderizacao de SVGs |
| **Env** | flutter_dotenv | Variaveis de ambiente (.env) |
| **Storage** | shared_preferences | Persistencia local (key-value) |
| **Formatacao** | intl | Internacionalizacao e formatacao de datas/moeda |
| **Conectividade** | internet_connection_checker_plus | Verificacao de conexao de rede |
| **URL** | url_launcher | Abertura de links externos (WhatsApp, email) |
| **Info do App** | package_info_plus | Versao e metadados do app |
| **Testes** | mocktail, faker, network_image_mock | Mocks e dados falsos para testes |

## Estrutura de Diretorios (essencial)

```
lib/
├── core/
├── rest/
├── drivers/
└── ui/
```

## Equiny Server

A API RESTful principal do Equiny é a Equiny Server, construinda com FastAPI, logo todos as respostas da API sao JSON, cujo atributos são sempre em snake_case.