## Objetivo

Este PR organiza a base de contratos para a feature de biblioteca no mobile, separando o domínio de pastas em um `LibraryService`, movendo o `FolderDto` para o módulo correto e ajustando a tipagem genérica da paginação. Além disso, adiciona artefatos de documentação para padronizar a criação de tickets Jira no repositório.

## Changelog

- cria `lib/core/library/interfaces/library_service.dart` com os contratos de listagem, criação, leitura, renomeação e arquivamento de pastas
- move `FolderDto` de `lib/core/intake/dtos/folder_dto.dart` para `lib/core/library/dtos/folder_dto.dart`
- adiciona `analysisCount` e reorganiza os campos expostos por `FolderDto`
- remove responsabilidades de biblioteca de `IntakeService`, mantendo a separação entre intake e library no core
- renomeia o parâmetro genérico de `CursorPaginationResponse` de `T` para `Item` para melhorar legibilidade
- adiciona `documentation/prompts/create-jira-ticket-prompt.md` com o prompt de criação de tickets
- adiciona `jira-ticket.md` com o rascunho estruturado do ticket da biblioteca

## Como testar

1. Execute `flutter analyze lib/core/library/dtos/folder_dto.dart lib/core/library/interfaces/library_service.dart lib/core/intake/interfaces/intake_service.dart`.
2. Verifique que `FolderDto` está disponível em `lib/core/library/dtos/folder_dto.dart`.
3. Verifique que os contratos de pasta estão centralizados em `LibraryService`.
4. Confirme que `IntakeService` não expõe mais operações de biblioteca.
5. Revise os arquivos `documentation/prompts/create-jira-ticket-prompt.md` e `jira-ticket.md` para validar o conteúdo documental.

## Observacoes

- O escopo desta branch mistura ajustes de core e documentação já presentes no histórico local da `ANI-75`.
- Não houve adição de dependências novas.
- O `LibraryService` foi introduzido apenas no core; integrações REST e UI continuam para etapas seguintes.
