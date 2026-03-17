---
description: Alterar a implementação de uma feature existente
---

# Prompt: Alterar Implementação

## Objetivo

Alterar a implementação de uma feature existente e identificar, analisar e corrigir possíveis **side effects** decorrentes das mudanças no código-fonte.

## Entrada

Fornecerei os seguintes itens:

* **Caminho do arquivo ou diretório** onde a feature está implementada
* **Spec da feature afetada**
* **Descrição objetiva da alteração** que deve ser realizada

## Instruções

Com base nas entradas fornecidas, execute a tarefa seguindo estas diretrizes:

1. **Analise o contexto atual da implementação**

   * Leia os arquivos relevantes no caminho informado
   * Entenda como a feature funciona hoje
   * Identifique dependências diretas e indiretas
   * Considere fluxos relacionados que possam ser impactados pela alteração

2. **Compare a implementação atual com a spec**

   * Verifique se o comportamento atual está aderente à spec fornecida
   * Identifique quais partes precisam ser alteradas para atender à nova necessidade

3. **Implemente a alteração solicitada**

   * Modifique somente o necessário para atender ao objetivo
   * Preserve o estilo, padrões e convenções já adotados no projeto
   * Evite mudanças desnecessárias fora do escopo

4. **Identifique side effects**

   * Procure impactos colaterais causados pela alteração
   * Considere regressões funcionais, quebra de contratos, mudanças de comportamento, problemas de tipagem, validação, integração e efeitos em fluxos adjacentes
   * Aponte claramente quais arquivos, funções, componentes ou módulos podem ter sido afetados

5. **Corrija os side effects encontrados**

   * Ajuste o código impactado
   * Garanta consistência entre a nova implementação e os demais fluxos do sistema
   * Caso exista ambiguidade, explicite a suposição adotada

6. **Execute validações obrigatórias**
   Após realizar as alterações, execute obrigatoriamente os comandos abaixo:

   * `dart format .`
   * `flutter analyze`
   * `flutter test`

   Se fizer sentido para o contexto, execute também outros checks relevantes do projeto, como:

   * testes de integração
   * golden tests
   * lint customizado
   * build_runner
   * validações específicas de CI

7. **Corrija problemas encontrados nas validações**

   * Não finalize a tarefa sem tratar erros introduzidos pela alteração
   * Se algum comando falhar por motivo não relacionado diretamente à mudança, informe isso claramente
   * Descreva quais falhas foram corrigidas e quais permaneceram, se houver

8. **Valide o resultado final**

   * Revise se a implementação final atende à spec e à descrição da mudança
   * Confirme que os comandos de formatação, análise e testes foram executados
   * Verifique se não houve regressões evidentes
   * Considere casos de borda e cenários relacionados

## Resultado esperado

Sua resposta deve conter:

1. **Resumo do que foi alterado**
2. **Lista dos arquivos impactados**
3. **Descrição dos side effects identificados**
4. **Descrição das correções aplicadas**
5. **Resultado dos comandos executados**
   * `dart format .`
   * `flutter analyze`
   * `flutter test`
6. **Riscos ou pontos de atenção remanescentes**
7. **Sugestão de testes adicionais** para validar a mudança

## Regras adicionais

* Não faça mudanças fora do escopo sem justificar
* Se faltar contexto, explicite o que está assumindo
* Priorize segurança, legibilidade e manutenção do código
* Preserve compatibilidade com o restante do sistema
* Seja objetivo, técnico e rastreável na explicação das alterações
* Só considere a tarefa concluída após executar as validações obrigatórias e relatar o resultado
