# Review Code Skill

**Objetivo:**
Realizar uma revisão técnica rigorosa da base de código para assegurar conformidade com os padrões do projeto, identificar bugs latentes e manter a integridade da análise estática (no-warnings policy).

**Entrada:**
*   **Contexto:** Spec que acabou de ser implementada (opcional).
*   **Alvo:** Todo o projeto ou caminhos específicos fornecidos.

**Diretrizes de Execução:**

1.  **Verificação de Spec e Lógica:**
    *   **Conformidade:** Verifique se a spec foi implementada corretamente, respeitando todos os requisitos definidos.
    *   **Escaneamento Manual:** Procure por erros de digitação, erros de lógica, problemas de nomenclatura e erros de sintaxe óbvios.

2.  **Análise de Qualidade Estática:**
    *   **Diagnóstico:** Use o `flutter analyze` para listar erros, alertas (warnings) e inconsistências de codificação.
    *   **Priorização:** Examine a severidade dos problemas reportados para planejar a ordem de correção, priorizando erros de compilação críticos.

3.  **Correção Automatizada:**
    *   **Quick Fixes:** Aplique o `dart format .` para resolver automaticamente violações de regras que possuam correções rápidas.

4.  **Refatoração e Alinhamento com Protocolos:**
    *   **Manual:** Corrija manualmente os problemas persistentes que as ferramentas automatizadas não puderam resolver.
    *   **Diretrizes:** Siga rigorosamente os padrões de projeto conforme documentado em:
    *   **Convenções de codificação:** [code-conventions-guidelines.md](../code-conventions-guidelines.md)
        *   **Arquitetura:** [architecture.md](../architecture.md)
        *   **Core:** [core-layer-rules.md](../core-layer-rules.md)
        *   **Rest:** [rest-layer-rules.md](../rest-layer-rules.md)
        *   **UI:** [ui-layer-rules.md](../ui-layer-rules.md)
        *   **Testes:** [unit-tests-guidelines.md](../unit-tests-guidelines.md)
    *   **Padrões:** Garanta o uso correto de MVP, injeção de dependência com Riverpod e reatividade com Signals.

5.  **Validação Final:**
    *   **Testes:** Execute o `flutter test` para validar que as alterações não impactaram o comportamento funcional do sistema.
    *   **Certificação:** Realize uma rodada final de `flutter analyze` para confirmar o estado "limpo" do código.

**Critério de Sucesso:**
A revisão é considerada concluída quando a análise estática retornar **"No issues found"** e todos os testes automatizados relevantes passarem sem falhas.