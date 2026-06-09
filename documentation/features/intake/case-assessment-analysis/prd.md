# PRD - Case Assessment Analysis

## Objetivo

Substituir a entrada baseada em upload único de documento no fluxo de `Case Assessment` por um briefing jurídico estruturado, permitindo que o usuário descreva o caso com mais precisão antes da análise e mantenha o restante do pipeline de resumo, precedentes e minuta dentro da mesma experiência.

## Entregas do fluxo

- [x] Formulário estruturado de briefing com área jurídica, tribunal, pedidos principais e tese pretendida
- [x] Bloqueio do CTA principal enquanto os campos obrigatórios estiverem inválidos
- [x] Persistência remota do briefing com reentrada da tela já preenchida quando o status da análise for posterior a `WAITING_BRIEFING`
- [x] Substituição do gatilho de análise: o fluxo passa a começar pelo envio do briefing em vez do upload primário
- [x] Anexos opcionais de apoio em PDF ou DOCX com limite local de 20MB por arquivo
- [x] Preservação do fluxo posterior já existente: resumo do caso, precedentes, geração/regeneração da minuta e exportação do relatório
- [x] Edição manual da minuta de petição no próprio app, com salvamento automático por campo e validação inline antes de fechar
- [x] Exportação da minuta de petição em DOCX pelo editor em tela cheia, com download do arquivo remoto e share sheet nativo

## Impacto da entrega

- O usuário passa a iniciar a análise com contexto jurídico mais estruturado, reduzindo ambiguidade logo na entrada do fluxo.
- A experiência deixa de depender de um documento obrigatório para começar, diminuindo fricção em cenários em que o caso ainda está sendo consolidado.
- O briefing reaproveita a mesma linguagem de tribunais e do fluxo de precedentes, o que melhora consistência e reduz retrabalho.
- Documentos de apoio continuam possíveis, mas agora como complemento opcional ao raciocínio principal informado no formulário.
- A minuta deixa de ser apenas um artefato de leitura: o advogado pode refiná-la no mobile sem reiniciar a análise nem sair do fluxo atual.
- A minuta também passa a ser distribuível fora do app em DOCX sem depender da exportação do relatório completo em PDF.

## O que mudou em relação ao PRD original

- Como não havia um `prd.md` materializado nesta pasta, este documento foi consolidado com base na spec concluída e no comportamento efetivamente entregue.
- O upload de documento deixou de ser a pré-condição da análise e passou a funcionar apenas como apoio opcional ao briefing.
- A entrega passou a contemplar também edição manual da minuta de petição com autosave e aviso explícito de que uma nova regeração substitui a versão editada manualmente.
- A exportação da minuta foi entregue no header do editor em tela cheia, como ação separada da exportação do relatório PDF da análise.

## Observações de rollout

- A experiência depende dos endpoints de `POST` e `GET` do briefing estarem disponíveis e compatíveis com os enums acentuados de área jurídica enviados pelo app.
- O resumo, os precedentes, a minuta e a exportação continuam dependentes do pipeline já existente do backend para `Case Assessment`.
- A edição manual da minuta depende do endpoint de atualização retornar a minuta consolidada para manter o card de preview sincronizado após o fechamento do dialog.
- A exportação em DOCX depende do endpoint de exportação devolver o `file_path` do arquivo gerado para download e compartilhamento nativo.
