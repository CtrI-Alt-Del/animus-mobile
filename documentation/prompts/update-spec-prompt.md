---
description: Atualiza uma spec tecnica durante a implementacao, aplicando modo leve ou pesado conforme o tipo de mudanca.
---

# Prompt: Atualizar Spec

**Objetivo:** Aplicar uma mudanca durante a implementacao, atualizando o codigo
e a spec de forma consistente com a arquitetura em camadas do Animus Mobile,
os dominios do app e as regras documentadas em `documentation/rules/`. O modo
e determinado automaticamente pelo tipo de mudanca.

---

## Entrada

- **Caminho da spec** a ser atualizada.
- **Descricao da mudanca:** o que precisa mudar e por que.
- **Contexto do plano** (opcional) derivado desta spec.

> Antes de alterar qualquer coisa, leia:
> - `documentation/architecture.md`
> - `documentation/rules/rules.md`
> - `documentation/tooling.md`

---

## Passo 1 - Classificar a mudanca

| Categoria | Exemplos | Modo |
| --- | --- | --- |
| **Correcao factual** | Nome de classe, caminho, assinatura, typo | **Leve** |
| **Contrato** | DTO, mapper, interface de `service`/`driver`, assinatura de `presenter` | **Pesado** |
| **Escopo** | Adiciona ou remove item do in-scope / out-of-scope | **Pesado** |
| **Regra de negocio** | Nova invariante, alteracao de validacao, fluxo offline, tratamento de erro | **Pesado** |
| **Decisao de design** | Troca de abordagem tecnica, estrategia de estado, navegacao, integracao REST/driver | **Pesado** |

> Se misturar categorias, use o **modo mais restritivo**.
> Se a mudanca nao estiver clara, use a tool `question` antes de prosseguir.

---

## Modo Leve - Correcao Factual

1. Aplique a correcao no codigo.
2. Edite apenas o trecho incorreto na spec.
3. Atualize `last_updated_at` no frontmatter.
4. Confirme que nao ha outras ocorrencias do mesmo dado errado na spec.
5. Se a correcao citar paths, contratos ou nomes de simbolos, valide na codebase.

---

## Modo Pesado - Mudanca Estrutural

**2.1 Diagnostico**
- Mapeie todas as secoes da spec afetadas em cascata.
- Mapeie todos os arquivos de codigo impactados pela mudanca nas camadas
  `lib/ui/`, `lib/core/`, `lib/rest/` e `lib/drivers/`.
- Considere tambem impactos em `lib/router.dart`, `lib/constants/` e `test/`
  quando a mudanca afetar navegacao, configuracao ou cobertura existente.
- Se contradizer o PRD, use a tool `question` antes de prosseguir.
- Use **Serena** para confirmar consistencia com a codebase e localizar
  implementacoes similares.

**2.2 Implementacao**
- Aplique as mudancas no codigo nos arquivos mapeados no diagnostico.
- Consulte as regras da camada correspondente em `documentation/rules/` antes de alterar.
- Preserve os limites arquiteturais: `core` continua agnostico a detalhes de
  infraestrutura; `rest` e `drivers` implementam contratos definidos no `core`;
  `ui` consome contratos e presenters sem acessar API diretamente.
- Ao alterar widgets com logica, mantenha o padrao MVP adotado pelo projeto e o
  uso de componentes Flutter Material alinhados ao tema do projeto.

**2.3 Edicao da spec**
- Edite **somente** as secoes mapeadas no diagnostico.
- Atualize `last_updated_at` mantendo o formato `YYYY-MM-DD`.
- Secoes que deixarem de se aplicar: escreva **Nao aplicavel**.
- Mantenha caminhos reais relativos ao repositorio e marque arquivos novos como
  `**novo arquivo**`.
- Ao citar fluxo principal, reflita o encadeamento real da feature, por exemplo:
  `View -> Presenter -> Provider -> Interface do Core -> Implementacao REST/Driver`.

**2.4 Rules**

Se a mudanca introduz ou altera um padrao de camada, atualize o doc de rules
correspondente em `documentation/rules/` (consulte o indice em `rules.md`):

- **Novo padrao:** adicione com descricao e exemplo pratico.
- **Alteracao de padrao:** corrija ou complemente - nao apague o contexto anterior.

> Se nao introduzir nem alterar padrao, pule este passo.

**2.5 Impacto no plano** *(quando plano existir)*

Produza um relatorio com tarefas removidas, alteradas e novas. **Aguarde
confirmacao** antes de editar o plano.

**2.6 Verificacao**
- Spec consistente internamente.
- Spec consistente com PRD, arquitetura, regras e codebase atual.
- `Pendencias / Duvidas` atualizado se a mudanca gerou incertezas.

---

## Passo Final - Qualidade

Execute e corrija qualquer falha antes de encerrar:

```bash
dart format .
flutter analyze
flutter test
```

> Para mudancas localizadas, voce pode validar primeiro no diretorio ou escopo
> afetado, mas antes de encerrar a tarefa a verificacao final deve refletir o
> impacto real da mudanca.

> Falhas pre-existentes fora do escopo devem ser sinalizadas como regressao
> anterior. Nao encerre com falhas em aberto causadas pela mudanca atual.

---

## Restricoes

- Edicoes cirurgicas - nao reescreva a spec inteira.
- Nao invente arquivos, widgets, presenters, services, drivers, DTOs ou
  contratos sem evidencia na codebase ou no PRD.
- `lib/core/` nao pode depender de `Flutter`, `Dio`, `GoRouter`, plugins,
  SDKs de plataforma ou qualquer detalhe concreto de infraestrutura. Se a
  mudanca violar isso, recuse e registre em **Pendencias / Duvidas**.
- Referencias a codigo existente: caminho relativo real do repositorio
  (ex: `lib/ui/...`, `lib/rest/...`, `lib/core/...`, `lib/drivers/...`);
  novos arquivos: `**novo arquivo**`.
- Nao promova regra de negocio para `ui`, `rest` ou `drivers` se ela pertencer
  ao dominio.
- Nao descreva `View` fazendo chamadas diretas a cliente HTTP, plugin,
  armazenamento local ou roteador se o projeto usar `Presenter` e contratos de
  camada para isso.
- Nao edite o plano sem confirmacao explicita.
