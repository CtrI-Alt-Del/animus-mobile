Rerank de Precedentes — Como Funciona
O rerank acontece em 4 etapas sequenciais após o retrieval do Qdrant:

Etapa 1 — Retrieval (Qdrant)
PetitionSummary → embeddings (N chunks) → Qdrant
Para cada chunk de embedding da petição, o Qdrant busca os limit * 10 precedentes mais similares em cada campo (enunciation e thesis). O resultado é um pool de candidatos com scores cosseno brutos entre 0 e 1.

Etapa 2 — Agregação de Scores por Precedente (_score_identifiers)
Múltiplos chunks da petição podem retornar o mesmo precedente. O método consolida tudo em um único score por precedente:
python# Para cada precedente, mantém:
thesis_max      # melhor score cosseno no campo thesis
enunciation_max # melhor score cosseno no campo enunciation
total_hits      # quantas vezes o precedente apareceu no pool
Um precedente que aparece muitas vezes (alto total_hits) é mais provável de ser relevante — isso é recompensado no próximo passo.

Etapa 3 — Cálculo do Score Base (_calculate_applicability_percentage)
pythonbase_score = (thesis_max * 0.58) + (enunciation_max * 0.42)
coverage_bonus = min(total_hits * 0.02, 0.08)  # máx +8%

final_score = base_score + coverage_bonus + lexical_adjustment
percentage = min(max(final_score * 100, 0.0), 95.0)
```

O peso maior na `thesis` (58%) reflete que a tese do precedente é mais discriminante do que o enunciado para determinar aplicabilidade. O `coverage_bonus` recompensa precedentes que aparecem consistentemente em múltiplos chunks.

---

### Etapa 4 — Ajuste Lexical (`_calculate_lexical_adjustment`)

É aqui que o rerank efetivo acontece. O perfil lexical da petição é extraído em 6 buckets:

| Bucket | O que contém | Extraído de |
|---|---|---|
| `issue_anchors` | Frases da controvérsia central | `legal_issue` + `central_question` |
| `law_anchors` | Normas e search terms | `relevant_laws` + `search_terms` |
| `context_anchors` | Fatos e resumo | `key_facts` + `case_summary` |
| `accessory_terms` | Termos secundários | Qualquer campo com marcadores acessórios |
| `core_terms` | União de issue + law | — |
| `domain_anchors` | Números de lei/decreto e search terms específicos | `relevant_laws` + `search_terms` com número ou 3+ palavras |

Para cada precedente candidato, o texto combinado `enunciation + thesis` é comparado contra esses buckets:
```
lexical_adjustment = issue_bonus
                   + law_bonus
                   + context_bonus
                   - specialization_penalty
                   - accessory_penalty
                   - specialization_terms_penalty
                   - negative_penalty
                   - domain_penalty
```

| Componente | Condição | Efeito |
|---|---|---|
| `issue_bonus` | Precedente contém termos da controvérsia central | **+até 24%** |
| `law_bonus` | Precedente contém normas/search terms da petição | **+até 12%** |
| `context_bonus` | Precedente contém fatos do caso | **+até 3%** |
| Penalidade base | `issue_hits == 0 AND law_hits == 0` | **-25%** imediato |
| `specialization_penalty` | Tem lei mas não tem controvérsia central | **-7%** |
| `accessory_penalty` | Só tem termos acessórios, sem controvérsia | **-até 8%** |
| `specialization_terms_penalty` | Tem subtema lateral não presente no caso | **-até 12%** |
| `negative_penalty` | Contém termos genéricos negativos (FGTS, IRF…) | **-até 16%** |
| `domain_penalty` | Sem nenhum termo específico do domínio do caso | **-15%** |

---

### Fluxo Completo
```
Qdrant pool (N * 10 candidatos)
    ↓
_score_identifiers → thesis_max, enunciation_max, total_hits por precedente
    ↓
_calculate_applicability_percentage → base_score + coverage_bonus
    ↓
_extract_lexical_profile(petition_summary) → 6 buckets de ancoragem
    ↓
_calculate_lexical_adjustment → penalidades e bônus lexicais
    ↓
score final ordenado → top-N retornados
O efeito prático é que o Qdrant é responsável por trazer os precedentes semanticamente próximos, e o reranker é responsável por promover os que tocam o domínio jurídico específico do caso e penalizar os que compartilham apenas termos processuais genéricos (competência, tutela, prescrição etc.).