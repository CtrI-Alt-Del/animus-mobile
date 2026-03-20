---
description: Meta-prompt para gerar documentos de regras arquiteturais de camadas da aplicação
---

# Prompt:Criar Regras de Camada

## Objetivo

Gerar um documento de regras arquiteturais para uma camada específica da aplicação (`{CAMADA}`),
padronizando sua descrição, limites, integrações e critérios de validação para novas features.
O resultado deve ser orientado à consistência, clareza e aplicabilidade no dia a dia do time.

---

## Entrada Esperada

Forneça preferencialmente:

- **Bullets** com regras, convenções e restrições conhecidas
- **Caminhos de diretórios** no formato `rest/caminho/exemplo`
- **Trechos de código ou regras reais** quando disponíveis

---

## Diretrizes de Execução

### 1. Entendimento e validação de contexto

- Confirmar o objetivo do documento para a camada `{CAMADA}`
- Validar se as fontes fornecidas cobrem arquitetura, convenções e limites
- Quando houver lacunas: assumir padrões conservadores e registrar pendências explicitamente
  em `# Observações e Pendências`

### 2. Levantamento do que já existe

- Consultar arquivos de arquitetura e regras do projeto antes de redigir
- **Se MCP Serena disponível:** localizar documentos similares da camada e camadas análogas
- **Se MCP Context7 disponível:** consultar documentação oficial de bibliotecas/frameworks em dúvida
- **Sem ferramentas:** solicitar ao usuário trechos mínimos necessários (arquitetura, convenções
  e exemplos de regra)

### 3. Geração da estrutura final

- Produzir o documento com todas as seções obrigatórias em linguagem prescritiva (`deve` / `não deve`)
- Explicitar fronteiras da camada: o que pertence, o que não pertence e como comunicar com outras camadas
- Incluir exemplos práticos de padrões de projeto aplicados ao contexto `{CAMADA}`
- Incluir checklist objetivo para orientar a criação de novas features

### 4. Checagens finais de qualidade

- [ ] Consistência entre princípios, padrões e regras de integração
- [ ] Ausência de contradições com arquitetura global e regras existentes
- [ ] Todas as seções obrigatórias preenchidas
- [ ] Premissas adotadas e pendências marcadas claramente

---

## Template de Saída

> O documento final **deve conter exatamente** os títulos de primeiro nível abaixo.
```markdown
# Regras da Camada {CAMADA}

# Visão Geral
- Objetivo da camada
- Responsabilidades principais
- Limites da camada

# Estrutura de Diretórios Globais
- Mapa de pastas relevantes
- Responsabilidade de cada diretório
- Regras de organização e nomeação
- ⚠️ Não especificar arquivos específicos — isso muda constantemente

# Glossário Arquitetural da Camada
- Nomenclatura de classes e métodos
- Nomenclatura de arquivos e diretórios

# Padrões de Projeto
- Padrões arquiteturais aceitos
- Como aplicar cada padrão na camada
- Quando evitar cada padrão

# Regras de Integração com Outras Camadas
- Dependências permitidas e proibidas
- Contratos / interfaces de comunicação
- Direção de dependência e limites de acoplamento

# Checklist Rápido para Novas Features na Camada

## ✅ O que DEVE conter
- Elementos obrigatórios da camada
- Práticas recomendadas

## ❌ O que NUNCA deve conter
- Antipadrões e acoplamentos proibidos
- Responsabilidades que pertencem a outras camadas
```

---

## Regras de Geração

| Regra | Detalhe |
|-------|---------|
| **Formato** | Markdown |
| **Seções** | Nenhuma seção obrigatória pode ser omitida |
| **Invenção** | Nunca inventar caminhos, contratos ou componentes inexistentes |
| **Linguagem** | Normativa: usar `deve`, `não deve`, `pode` com critério |
| **Acionabilidade** | Priorizar regras verificáveis em code review |
| **Genericidade** | Evitar — adaptar exemplos ao contexto de `{CAMADA}` e `{STACK}` |
| **Lacunas críticas** | Registrar em `# Observações e Pendências` em vez de inferir livremente |
| **Arquitetura** | Alinhar com a arquitetura em camadas vigente do projeto |