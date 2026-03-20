---
description: Criar um prompt generico (meta-prompt) para gerar prompts consistentes, reutilizaveis e adaptaveis a diferentes tarefas
---

# Prompt: Criar Prompt Generico (Meta-Prompt)

**Objetivo:**
- Gerar um prompt reutilizavel para a tarefa `{TEMA_TAREFA}` (ex.: spec tecnica, PRD, checklist, plano de refatoracao, roteiro de implementacao).
- O prompt gerado deve ser modular (variaveis claras), orientar fluxo de trabalho e checagens de qualidade.
- Quando faltar informacao, o prompt deve registrar pendencias e assumir defaults seguros sem inventar detalhes.

**Entrada:**
- Obrigatorio:
  - `{TEMA_TAREFA}`: o tipo de artefato/prompt final que se quer gerar.
  - `{OBJETIVO_FINAL}`: para que o artefato sera usado e qual decisao ele suporta.
  - `{CONTEXTO}`: produto/time, escopo, publico-alvo, maturidade, prazo.
  - `{RESTRICOES}`: o que nao pode (ex.: sem testes, sem mudancas breaking, nao tocar em producao).
  - `{FORMATO_SAIDA}`: Markdown, tabelas, checklist, RFC, etc.
- Opcional:
  - `{STACK}`: tecnologias, padroes e arquitetura.
  - `{FONTES}`: lista de fontes disponiveis (links, caminhos de arquivo, trechos, PRDs, docs internas).
  - `{EXEMPLOS}`: prompts existentes para usar como referencia (paths/links).
  - `{FERRAMENTAS}`: quais ferramentas estao disponiveis (repo search, docs oficiais, etc.).

Formato esperado para `{FONTES}`/`{EXEMPLOS}`:
- Links HTTP(s) ou caminhos de arquivo (sem inventar caminhos).
- Se colar trechos, inclua titulo + delimitadores claros.

**Diretrizes de Execucao:**
1. Entendimento e validacao
   - Confirme o que e o artefato final e o publico-alvo.
   - Extraia e liste as variaveis que deverao virar placeholders no prompt (ex.: `{ESCOPO}`, `{NFR}`, `{DEPENDENCIAS}`, `{CRITERIOS_DE_ACEITE}`).
   - Se houver ambiguidade material, nao pare: siga com defaults seguros e crie uma secao `Pendencias` no prompt gerado.
   - Nao exponha raciocinio passo-a-passo; exponha apenas decisoes, listas e saidas.

2. Levantamento do que ja existe (quando aplicavel)
   - Se `{EXEMPLOS}` existir: derive padroes de estrutura, nomenclatura e nivel de detalhe.
   - Se `{FONTES}` existir: defina quais fontes sao obrigatorias consultar antes de escrever.

3. Uso de ferramentas (se disponiveis)
   - Busca no repositorio: localizar arquivos similares, exemplos e regras do projeto antes de escrever qualquer secao normativa.
   - Documentacao oficial (ex.: Context7): quando `{STACK}` envolver bibliotecas/frameworks e houver duvida de API/boas praticas.
   - Se nao houver ferramentas: pedir ao usuario os trechos minimos necessarios (regras, arquitetura, exemplos) e seguir com placeholders ate receber.

4. Geracao do prompt final (o output e um prompt)
   - Escreva um prompt pronto para uso, com:
     - contexto e objetivos explicitos
     - entradas com formatos
     - passos de execucao (ordem e dependencias)
     - criterios de completude (Definition of Done do artefato)
     - template de saida obrigatorio com cabecalhos e placeholders

5. Checagens finais de qualidade
   - Consistencia: placeholders usados de forma uniforme (sem duplicar significados).
   - Completude: nenhuma secao obrigatoria faltando; template de saida tem todos os cabecalhos.
   - Anti-alucinacao: o prompt inclui regra explicita para nao inventar fatos, APIs, caminhos ou numeros.
   - Aderencia a `{RESTRICOES}` e `{STACK}`.

**Template de Saida (Estrutura Obrigatoria):**
# Prompt: {NOME_DO_PROMPT}

**Objetivo:**
- {OBJETIVO_FINAL}

**Contexto:**
- {CONTEXTO}

**Entrada:**
- Obrigatorio:
  - {ENTRADA_1}
  - {ENTRADA_2}
- Opcional:
  - {ENTRADA_OPCIONAL_1}

**Fontes a consultar (ordem):**
1. {FONTE_1}
2. {FONTE_2}

**Diretrizes de execucao:**
1. {PASSO_1}
2. {PASSO_2}
3. {PASSO_3}
4. {PASSO_4}

**Criterios de completude:**
- {CRITERIO_1}
- {CRITERIO_2}

**Template de saida (obrigatorio):**
# {SECAO_1}
- {ITENS_ESPERADOS}

# {SECAO_2}
- {ITENS_ESPERADOS}

# Pendencias (se houver)
- {PERGUNTAS_ABERTAS_OU_BURACOS_DE_INFO}

**Regras:**
- Use {FORMATO_SAIDA}.
- Nao invente caminhos de arquivo, APIs, numeros ou decisoes; se faltar informacao, registre em `Pendencias`.
- Siga {RESTRICOES}.
- Quando houver ferramentas, consulte fontes antes de escrever decisoes normativas.
