---
description: Meta-prompt para ajustar widgets para ficarem consistentes com um design do Google Stitch
---

# Prompt: Ajustar Widgets para Bater com o Google Stitch

**Objetivo:**
- Alterar um widget (ou conjunto de widgets) para ficar o mais parecido possivel com o design definido no Google Stitch, mantendo o comportamento existente.
- Derivar do Stitch um guia pratico (tokens e regras) e aplicar isso diretamente no codigo (Flutter) com mudancas pequenas e rastreaveis.

**Entrada:**
- Obrigatorio:
  - `{ALVO}`: qual tela/fluxo/feature esta sendo ajustada.
  - `{WIDGETS_ALVO}`: caminhos e nomes dos widgets a serem alterados (ex: `lib/.../foo_widget.dart`, `FooWidget`).
  - `{CRITERIOS_DE_ACEITE}`: como validar que ficou mais parecido (bullets objetivas).
  - `{REFERENCIA_DE_DESIGN}`: escolha uma (ou ambas):
    - Stitch: `{STITCH_PROJECT_ID}` e `{STITCH_SCREEN_IDS}`
    - Screenshot: `{SCREENSHOT}` (imagem anexada ou link direto)
- Opcional:
  - `{STITCH_PROJECT_ID}`: id do projeto no Stitch.
  - `{STITCH_SCREEN_IDS}`: lista de telas relevantes (uma ou mais).
  - `{SCREENSHOT}`: screenshot do design-alvo.
  - `{NAO_MEXER}`: o que nao pode mudar (ex: sem alterar logica, rotas, contratos, acessibilidade minima).
  - `{LIMITES}`: tempo/escopo (ex: "sem criar novos componentes", "apenas ajustes de estilo").
  - `{FONTES_DISPONIVEIS}`: links/caminhos (docs internas, guidelines, design system do projeto, exemplos existentes).
  - `{STACK_UI}`: padrao do projeto (ThemeExtensions, design tokens, libs de UI).

**Diretrizes de Execucao:**
1. Entendimento e protecao de escopo
   - Leia `documentation\rules\ui-layer-rules.md`
   - Reafirme `{ALVO}` e `{WIDGETS_ALVO}` em 2-5 linhas.
   - Congele constraints: liste `{NAO_MEXER}` e `{LIMITES}` como regras de trabalho.
   - Se faltarem caminhos de widgets, pare antes de codar e registre em `Pendencias` exatamente o que falta.
   - Se nao houver referencia de design (nem Stitch nem screenshot), pare antes de codar e registre em `Pendencias`.
   - Prefira sempre usar os tokens e regras do `lib\ui\shared\theme\app_theme.dart`

2. Levantamento do estado atual (codigo)
   - Localize os `{WIDGETS_ALVO}` e identifique:
     - Estrutura de layout (Row/Column/Stack, paddings, constraints)
     - Tipografia (TextStyle, lineHeight, weight)
     - Cores, elevacao, border radius, bordas
     - Componentes reutilizados (botoes, inputs, cards)
     - Estados (loading/empty/error/disabled)
   - Procure no repositorio exemplos similares e reuse padroes existentes (cite caminhos reais).

3. Captura da referencia de design e traducao para regras acionaveis
   - Se `{SCREENSHOT}` for fornecido:
     - Extraia e descreva de forma objetiva: espacamentos, alinhamentos, tamanhos, grid, hierarquia tipografica, paleta, raios, sombras, componentes e estados.
     - Se algum detalhe nao for inferivel com seguranca (ex: tamanho exato, cor exata), marque como `Pendencia` ou `Assuncao` (com baixa confianca).
   - Se `{STITCH_PROJECT_ID}` e `{STITCH_SCREEN_IDS}` forem fornecidos:
     - Use as ferramentas do Google Stitch.
     - Se precisar, liste telas do projeto e selecione as que correspondem ao `{ALVO}`.
     - Para cada `screenId` relevante, extraia: espacamentos, alinhamentos, tamanhos, grid, hierarquia tipografica, paleta, raios, sombras, componentes e estados.
   - Converta a(s) referencia(s) em um `Guia de Consistencia` com tokens sugeridos (ex: `radius=12`, `gap=8/12/16`, `titleStyle`, `surfaceColor`).
   - Se o projeto ja tiver tokens/Theme, mapeie referencia -> tokens existentes. Se nao existir token equivalente, proponha o menor ajuste possivel.

4. Plano de mudancas (antes de editar)
   - Liste um `Mapa de Diferencas` (atual -> Stitch) por widget:
     - Layout: {mudanca}
     - Tipografia: {mudanca}
     - Cores/superficies: {mudanca}
     - Componentes: {mudanca}
     - Estados: {mudanca}
   - Priorize mudancas com maior impacto visual e menor risco (ordem de execucao).

5. Implementacao
   - Aplique as mudancas no codigo:
     - Preferir reutilizar componentes existentes e Theme do projeto.
     - Evitar refactors grandes: altere somente o necessario para aproximar do Stitch.
     - Nao mudar comportamento/negocio a menos que `{CRITERIOS_DE_ACEITE}` exija.
   - Se precisar criar/ajustar um componente compartilhado, justifique e limite o escopo.

6. Checagens finais
   - Verifique que `{CRITERIOS_DE_ACEITE}` foram atendidos.
   - Garanta que nao violou `{NAO_MEXER}` e `{LIMITES}`.
   - Nao invente valores: se algo nao estiver claro no Stitch/codigo, registre em `Pendencias`.

**Template de Saida (Estrutura Obrigatoria):**
# Ajuste de Widgets para Consistencia com Stitch ({ALVO})

## Fontes Consultadas
- {CAMINHOS_E_LINKS_REAIS}

## Referencia de Design
- Observacoes (Stitch): {STITCH_NOTES}
- Observacoes (Screenshot): {SCREENSHOT_NOTES}

## Guia de Consistencia (Derivado do Stitch)
- Layout/espacamentos: {REGRAS_E_TOKENS}
- Tipografia: {REGRAS_E_TOKENS}
- Cores/superficies: {REGRAS_E_TOKENS}
- Raios/sombras/bordas: {REGRAS_E_TOKENS}
- Componentes e estados: {REGRAS_E_TOKENS}

## Mapa de Diferencas (Atual -> Stitch)
- {DIFERENCAS_POR_WIDGET}

## Mudancas Aplicadas
- Arquivos alterados: {LISTA_DE_ARQUIVOS}
- Descricao objetiva das mudancas: {LISTA_CURTA}

## Pendencias
- {O_QUE_FALTA_PARA_100_PERCENT_FIEL}

## Checklist de Qualidade
- [ ] Visual mais proximo do Stitch (layout/tipografia/cores/componentes)
- [ ] Sem mudanca de logica fora do escopo
- [ ] Reuso de tokens/componentes existentes quando possivel
- [ ] Sem valores inventados; pendencias registradas

**Regras:**
- Foco e consistencia: o objetivo e aproximar do Stitch, nao redesenhar.
- Nao invente caminhos/IDs/valores: se nao estiver no Stitch ou no codigo, marque como `Pendencia`.
- Quando Stitch estiver disponivel, priorize Stitch como fonte de verdade para medidas/tokens.
- Prefira mudancas pequenas e rastreaveis; evite refactor amplo.
