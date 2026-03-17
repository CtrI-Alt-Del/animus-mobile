---
description: Prompt para concluir uma spec com validação final, atualização de documentação e geração de resumo estruturado para PR.
---

# Prompt: Conclude Spec

**Objetivo:** Finalizar e consolidar a implementação de uma Spec técnica,
garantindo que o código esteja polido, documentado e validado — produzindo ao
final um checklist de validação, os documentos atualizados e um rascunho
estruturado para o Pull Request.

---

## Entradas Esperadas

- **Spec Técnica:** O documento que guiou a implementação
  (`documentation/features/<modulo>/specs/<nome>-spec.md`), injetado
  integralmente no contexto.
- **Diff do Código:** As alterações realizadas nas camadas UI, Core, Rest e
  Drivers, injetadas como contexto para permitir verificação real dos requisitos.

> ⚠️ Ambas as entradas devem estar presentes no contexto antes da execução.
> Não simule a verificação caso alguma delas esteja ausente — interrompa e
> sinalize o que está faltando.

---

## Fase 1 — Verificação

Esta fase é analítica e deve ser concluída antes de qualquer atualização de
documento.

**1.1 Formatação**

Execute `dart format .` na raiz do projeto. Nenhum arquivo deve permanecer fora
do padrão Dart. Caso existam arquivos alterados pelo formatter, liste-os
explicitamente antes de prosseguir.

**1.2 Análise Estática**

Execute `flutter analyze` na raiz do projeto. O resultado final deve ser
**"No issues found"**. Caso existam warnings ou erros, liste-os explicitamente e
aguarde correção antes de prosseguir.

**1.3 Testes Unitários**

Execute `flutter test` na raiz do projeto. Todos os testes — novos e existentes
— devem estar passando. Caso algum falhe, interrompa e reporte.

> Falhas pré-existentes fora do escopo da Spec devem ser sinalizadas
> explicitamente, indicando que são regressões anteriores e não introduzidas
> pela implementação atual.

**1.3.1 Cobertura de Testes**

Com base no diff injetado no contexto, verifique se os novos comportamentos
introduzidos pela Spec possuem testes correspondentes. Considere como caminhos
críticos que exigem cobertura (conforme
`documentation/rules/unit-tests-rules.md`):

- Lógica de negócio nova ou modificada na camada Core (Use Cases, Entidades)
- Casos de erro e edge cases relevantes
- Contratos de integração entre camadas (ex: Core ↔ Drivers, Core ↔ Rest)
- Lógica de estado em Presenters (valores de `Signal`, fluxos de loading/erro)

Ao final desta etapa, produza um relatório de cobertura no seguinte formato:
```markdown
## Cobertura de Testes

- [x] <Comportamento A> — coberto em `test/caminho/do/arquivo_test.dart`
- [x] <Comportamento B> — coberto em `test/caminho/do/arquivo_test.dart`
- [ ] <Comportamento C> — **sem cobertura** (detalhe o que está faltando)
```

Caso existam lacunas em caminhos críticos, liste-as como pendências e aguarde
decisão antes de prosseguir para a Fase 2. Não avance com itens críticos
descobertos.

**1.4 Cobertura de Requisitos**

Com base no diff real injetado no contexto, compare cada componente descrito na
Spec (seções "O que deve ser criado" e "O que deve ser modificado") contra o
código implementado. Ao final desta etapa, produza um **checklist de validação**
no seguinte formato:
```markdown
## Checklist de Validação

- [x] <Requisito A> — implementado em `lib/caminho/do/arquivo.dart`
- [x] <Requisito B> — implementado em `lib/caminho/do/arquivo.dart`
- [ ] <Requisito C> — **ausente ou incompleto** (detalhe o gap)
```

**1.5 Conformidade com as Diretrizes do Projeto**

Verifique se os arquivos alterados respeitam as regras das camadas envolvidas:

- `documentation/rules/ui-layer-rules.md` — MVP, Signals, Riverpod, shadcn_flutter
- `documentation/rules/core-layer-rules.md` — Entidades, Use Cases, interfaces
- `documentation/rules/rest-layer-rules.md` — clientes HTTP, tratamento de respostas
- `documentation/rules/drivers-layer-rules.md` — adaptadores para libs externas
- `documentation/rules/code-conventions-rules.md` — nomenclatura, barrel files, estrutura de diretórios

Liste explicitamente qualquer desvio identificado.

---

## Fase 2 — Consolidação de Documentos

Esta fase é de síntese. Execute-a somente após a Fase 1 estar completa e sem
pendências.

**2.1 Atualização da Spec Técnica**

Refine o documento da Spec para refletir decisões de design tomadas durante a
implementação ou desvios de caminho. A audiência é técnica — mantenha o nível
de detalhe de engenharia. Atualize também:

- **Status:** `concluído`
- **Última atualização:** `{{ today }}`

**2.2 Diagramas ASCII**

Avalie se as mudanças implementadas alteraram fluxos de dados, sequências de
chamadas entre camadas ou a navegação de telas. Se sim, gere ou atualize um
diagrama ASCII dentro da Spec para facilitar a visualização da implementação
final.

**2.3 Atualização do PRD / Milestone**

O PRD está vinculado a um Milestone no GitHub. Use o GitHub CLI para ler e
atualizar o milestone correspondente, marcando como concluídos os itens
endereçados pela implementação.

```bash
# Exemplo: listar milestones
gh api repos/:owner/:repo/milestones

# Exemplo: atualizar milestone (ajuste o número e o body conforme necessário)
gh api --method PATCH repos/:owner/:repo/milestones/:number \
  -f description="..."
```

> 💡 Trate Spec e PRD como documentos com propósitos distintos. Não copie
> conteúdo técnico de baixo nível para o PRD — sintetize o valor entregue em
> linguagem de produto/negócio.

**2.4 Atualização de Rules (se aplicável)**

Caso a implementação tenha introduzido um padrão de projeto novo, não mapeado
nas rules existentes, atualize o arquivo de regras correspondente com o novo
padrão e exemplos práticos.

---

## Fase 3 — Comunicação

Esta fase produz o artefato final para facilitar a abertura do Pull Request.

**3.1 Rascunho do Pull Request**

Gere um rascunho de descrição de PR com a seguinte estrutura obrigatória:
```markdown
## O que foi feito

<Descrição objetiva das mudanças implementadas, em linguagem técnica>

## Por que foi feito assim

<Decisões de design relevantes e tradeoffs considerados>

## O que mudou em relação à Spec original

<Desvios ou refinamentos ocorridos durante a implementação. Se nenhum, declare
explicitamente "Nenhum desvio em relação à Spec original.">

## Pontos de atenção para o revisor

<Riscos, áreas sensíveis, dependências externas ou decisões que merecem revisão
cuidadosa. Se nenhum, declare explicitamente "Nenhum ponto de atenção
identificado.">

## Checklist

- [ ] `dart format .` executado sem arquivos alterados
- [ ] `flutter analyze` retornou "No issues found"
- [ ] `flutter test` passou sem falhas (ou regressões pré-existentes devidamente sinalizadas)
- [ ] Cobertura de testes verificada e lacunas críticas endereçadas
- [ ] Conformidade com as diretrizes das camadas validada
- [ ] Spec atualizada com status `concluído`, data e diagramas (se aplicável)
- [ ] PRD / Milestone atualizado com os itens concluídos
- [ ] Rules atualizadas (se novos padrões foram introduzidos)
```

---

## Saídas Esperadas

Ao final da execução, devem ter sido produzidos:

1. **Relatório de cobertura de testes** (Fase 1.3.1)
2. **Checklist de validação** de requisitos (Fase 1.4)
3. **Spec atualizada** com status `concluído`, data e diagramas ASCII (Fase 2.1 e 2.2)
4. **PRD / Milestone atualizado** via GitHub CLI (Fase 2.3)
5. **Rascunho de PR** com estrutura completa (Fase 3.1)