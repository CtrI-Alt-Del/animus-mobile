# Code Conventions & Guidelines

## Visão Geral
Este documento estabelece as convenções de código adotadas no projeto Animus para garantir consistência, legibilidade e manutenibilidade.

---

## 1. Diretrizes de Linguagem & Naming
*   **Código:** Todo o código (variáveis, classes, funções, arquivos, pastas de código) deve ser escrito em **Inglês**.
*   **Documentação e UI:** Comentários explicativos, documentação (como este arquivo) e textos exibidos ao usuário final (strings de UI) devem ser escritos em **Português**.
*   **Case Style:**
    *   **Classes/Interfaces:** `PascalCase`.
    *   **Variáveis/Funções:** `camelCase`.
    *   **Arquivos/Diretórios:** `snake_case`.

## 2. Qualidade de Código & Clean Code
*   **Responsabilidade Única (SRP):** Classes e funções devem ter apenas uma razão para mudar.
*   **Auto-documentação:** O código deve ser claro o suficiente para que comentários sejam raramente necessários. Evite abreviações.
*   **Dart & Flutter:** Siga rigorosamente o [Effective Dart](https://dart.dev/guides/language/effective-dart).
*   **Funções Pequenas:** Idealmente, funções não devem ultrapassar 30-40 linhas.

## 3. Arquitetura & UI (MVP Pattern)
*   **Estrutura de Widgets:** Todo widget complexo deve residir em sua própria pasta dentro de `ui/<modulo>/widgets/`.
*   **Componentização:** Se um widget for reutilizável globalmente, coloque-o em uma pasta comum de componentes (ex: `lib/ui/global/widgets/`).
*   **Padronização Visual:**
    *   Durante o bootstrap, Material Design e permitido para acelerar a base inicial.
    *   Para novas features, prefira componentes compartilhados e evolua para um design system consistente.
*   **Lógica de Estado:**
    *   Sempre que houver regra de negocio, separe View e Presenter.
    *   `signals` e `Riverpod` podem ser adotados de forma incremental conforme os modulos forem sendo implementados.
*   **Widgets internos:**
    *   Widgets internos devem ser criados em uma pasta dentro do widget pai.
    *   Widgets internos devem seguir o padrão MVP (Model-View-Presenter).

## 4. Organização de Importações
As importações devem ser organizadas em blocos separados por uma linha em branco, seguindo a hierarquia de camadas:

1.  **Bibliotecas Externas e SDK:** (`dart:*`, `package:flutter/*`, pacotes de terceiros).
2.  **Camada Core:** (`package:animus_mobile/core/*`).
3.  **Camada Rest:** (`package:animus_mobile/rest/*`).
4.  **Camada Drivers:** (`package:animus_mobile/drivers/*`).
5.  **Camada UI:** (`package:animus_mobile/ui/*`).

### Exemplo
```dart
// 1. Bibliotecas Externas
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signals/signals_flutter.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

// 2. Camada Core
import 'package:animus_mobile/core/catalog/dtos/product_dto.dart';
import 'package:animus_mobile/core/catalog/interfaces/catalog_service.dart';

// 3. Camada Rest
import 'package:animus_mobile/rest/dio/dio_rest_client.dart';

// 5. Camada UI
import 'package:animus_mobile/ui/catalog/widgets/screens/catalog/products-list/product-card/product_card_presenter.dart';
```

## 5. Manutenibilidade & Regras Gerais
*   **Imutabilidade:** Prefira o uso de `final` em campos de classes e variáveis locais sempre que possível.
*   **Tratamento de Erros:** Utilize o `RestResponse<T>` definido no Core para encapsular falhas de API.
*   **Imports Relativos:** Evite imports relativos (`../../`) para arquivos fora do diretório local; utilize sempre o caminho absoluto do pacote (`package:animus_mobile/...`).
