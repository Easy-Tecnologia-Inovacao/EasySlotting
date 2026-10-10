# Revisão completa de Planos do super admin

Data: 10/10/2026. Base da revisão: commit `419c61b`. Skills aplicadas: `easyslotting-security-review` e `easyslotting-secure-feature`.

## Correções implementadas após a revisão

Os achados abaixo ficam preservados como histórico do comportamento anterior. P01 a P07 receberam correções nesta árvore de trabalho:

| Achado | Comportamento corrigido |
| --- | --- |
| P01 | O catálogo público usa a vigência do model, com início inclusivo e fim exclusivo. Preço e desconto são publicados a partir da mesma avaliação de vigência na resposta; preço zero também aparece corretamente na landing page. |
| P02 | O formulário escolhe preço ou percentual. O model deriva a outra informação com BigDecimal e rejeita fontes conflitantes; a regra duplicada no controller foi removida. |
| P03 | Booleanos, quotas dentro da faixa integer, duração, datas e campos obrigatórios de promoção são validados antes de gravar/calcular. Entradas inválidas recebem 422. Desativar a promoção limpa seus campos. |
| P04 | `PlanQuotaPolicy` aplica quotas de serviços, funcionários e agendamentos nos models, com lock transacional por estabelecimento. Reativação, restauração e mudança de mês também verificam capacidade. Veja [regras das quotas](plan-quotas.md). |
| P05 | Falhas e respostas incompatíveis não representam catálogo vazio. A tela bloqueia mutações até carregar uma lista válida e oferece nova tentativa. |
| P06 | Frações e valores fora da faixa são rejeitados sem truncamento. Campos opcionais vazios continuam null. |
| P07 | Datas locais são enviadas em ISO 8601 com fuso explícito, preservando o instante ao editar. |

Validação das correções: 28 testes Rails de catálogo/model/exclusão/concorrência, com 230 assertions; mais 14 testes Rails de promoções/quotas/concorrência/segurança de serviços, com 114 assertions. Todos passaram, sem falhas ou erros. Frontend: 36 testes aprovados; type-check e build aprovados. Brakeman: zero alertas e zero erros. Há avisos existentes de DLLs opcionais Vips, depreciação de rotas Rails, `fork` indisponível no Windows e tamanho de bundle no Vite. Não foi feita validação visual em navegador nem publicação na VM/VPS.

Os quatro testes direcionados do frontend também passaram em America/Sao_Paulo, UTC e Europe/Berlin, verificando o envio do instante da promoção com fuso explícito.

Não foram implementados carrinho, checkout ou integração de pagamentos. Não há migration nem reset de banco nesta correção. As observações de governança sobre retenção de logs, auditoria não atômica, paginação e ausência de snapshot integral dos benefícios continuam aplicáveis. Sem contrato vigente, o comportamento legado permanece sem quota comercial; isso não é uma autorização de pagamento, e deverá ser definido ao implementar o acesso condicionado à assinatura.

## Histórico da revisão inicial

A etapa inicial somente revisou e reproduziu comportamentos. As seções seguintes descrevem essa fotografia anterior às correções; seus números de linha se referem à base indicada no início.

Escopo: listagem, criação, edição e exclusão em `/super-admin/planos`; chamadas Axios; rotas `/api/super_admin/plans`; callbacks de autenticação/autorização; model Plan; restrições PostgreSQL; auditoria; publicação de preços e origem dos limites comerciais. Os caminhos de serviços e assinaturas foram examinados para verificar os efeitos das configurações. Não é uma revisão completa desses outros módulos.

## Resultado

Não foi encontrado bypass de autorização nos cenários testados. A exclusão preserva assinaturas, e as faixas de sessões mantêm restrições e ordem crescente. Foram encontrados problemas de integridade comercial, validação e UX que precisam de correção. Nenhum achado crítico foi demonstrado; os defeitos de escrita de planos exigem acesso de super admin, mas preços publicados e limites afetam outras contas.

## Achados confirmados

### P01 — Média: preço publicado ignora vigência da promoção

- **Arquivo/linha:** `backend/app/controllers/public/plans_controller.rb:17`; `backend/app/models/financial/plan.rb:77`; `frontend/src/views/landing/LandingPage/LandingPage.vue:231`.
- **Evidência:** o serializer público usa `promotion_active` e `promotional_price` sem verificar início/fim. `Plan.current_price`, usado na contratação, verifica `promotion_running?`. Teste com preço normal 100, promocional 80 e início em dois dias: GET público anuncia `effective_price = 80`, mas `current_price = 100`.
- **Impacto:** anúncio e valor do contrato divergem. Promoção vencida também permanece anunciada enquanto o checkbox estiver marcado. Não foi demonstrada cobrança real de cartão ou débito em conta; o fluxo atual cria contratos, sem integração de pagamento confirmado.
- **Correção:** usar uma regra única de preço vigente para serializer e contratação; expor status agendada/em andamento/encerrada e datas com fuso, e testar as fronteiras. O rótulo “Ativa” no painel administrativo também deve distinguir configuração habilitada de promoção vigente (`SuperAdminPlansPage.vue:91`).

### P02 — Média: editar só o percentual perde a alteração

- **Arquivo/linha:** `backend/app/models/financial/plan.rb:158` e `:164`; `frontend/src/views/super-admin/PlansPage/SuperAdminPlansPage.vue:636` e `:761`.
- **Evidência:** ao editar, o formulário carrega preço promocional e percentual simultaneamente. O callback sempre recalcula o percentual a partir do preço, e só recalcula o preço quando este está vazio. Teste PATCH de 50% num plano 100/80 retorna sucesso, mas mantém preço 80 e desconto 20%.
- **Impacto:** alterações aparentemente salvas não correspondem à intenção do administrador. A instrução de preencher um ou outro campo não evita que o próprio formulário carregue os dois.
- **Correção:** definir modo explícito de desconto por preço ou percentual; enviar a fonte escolhida e derivar o outro valor no backend. Rejeitar fontes conflitantes, usar BigDecimal para valores monetários e testar criação/edição parcial e integral.

### P03 — Média: validação incompleta permite configuração incoerente e exceções

- **Arquivo/linha:** `backend/app/models/financial/plan.rb:44`, `:48`, `:77`; `backend/app/controllers/super_admin/plans_controller.rb:15` e `:112`.
- **Evidência reproduzida:**
  - POST com `promotion_active: true`, sem datas nem desconto, retorna 201; promoção nunca roda. A exigência de datas existe somente no formulário.
  - `active: null` passa por `valid?` e chega a `ActiveRecord::NotNullViolation` na requisição, em vez de um 422 tratado.
  - `max_employees: 2147483648` passa por `valid?`, mas `save!` levanta `ActiveModel::RangeError`, pois excede a coluna integer.
- **Impacto:** configurações inválidas podem ser salvas ou gerar erro interno. Os casos foram reproduzidos no banco de testes, sem dados reais. O tamanho exato de resposta de erro em produção não foi observado; não foi demonstrado vazamento de stack trace ao público.
- **Correção:** validar booleanos por inclusão true/false; limites superiores compatíveis com o banco; exigir datas e uma fonte válida de desconto quando habilitado; validar formato/faixa antes de calcular datas. Tratar entradas inválidas como 422 com mensagens seguras. Não usar apenas rescue genérico para esconder validação ausente.

### P04 — Média: limites comerciais são cadastrados e divulgados sem enforcement demonstrado

- **Arquivo/linha:** `frontend/src/views/super-admin/PlansPage/SuperAdminPlansPage.vue:297`, `:314` e `:331`; `backend/app/controllers/admin/services_controller.rb:18`; `backend/app/models/financial/plan.rb:48`.
- **Evidência:** busca em `backend/app` por `max_employees`, `max_services` e `max_appointments_per_month` encontrou somente permissões de parâmetros, validação e serialização. Nenhum consumidor desses limites no cadastro foi localizado. Teste real com owner, contrato ativo e `max_services = 1` criou dois serviços via `POST /api/services`, ambos com 201.
- **Impacto:** o administrador configura benefícios que parecem limitar uso, mas a quota de serviços não é aplicada. Ausência de enforcement para funcionários/agendamentos foi verificada estaticamente, sem reprodução de excesso nesses dois fluxos. O limite de sessões simultâneas possui implementação independente e não está incluído neste defeito.
- **Correção:** política central por estabelecimento/contrato atual, aplicada no servidor, com lock para impedir ultrapassagem concorrente. Definir null como ilimitado, significado de zero, contagem de ativos/excluídos, janela mensal, regras de downgrade e reativação. Enquanto não implementado, não anunciar como quota já aplicada. Não adicionar limites somente ao frontend.

### P05 — Média, confiabilidade: falha de carregamento permite agir sobre catálogo desconhecido

- **Arquivo/linha:** `frontend/src/views/super-admin/PlansPage/SuperAdminPlansPage.vue:593` e `:605`.
- **Evidência:** falha GET deixa `plans = []`, remove loading e mostra erro; `openCreateModal` pode abrir e apaga a mensagem. Resposta não array é silenciosamente convertida para lista vazia. Diagnóstico executando o script real confirmou erro de carga seguido de criação liberada.
- **Impacto:** a interface apresenta catálogo vazio e faixas livres sem ter obtido os dados. O backend continua rejeitando conflitos; não foi identificado bypass das regras de catálogo por esse estado.
- **Correção:** distinguir carga, falha, sucesso vazio e sucesso com itens; bloquear mutações quando não há catálogo válido; oferecer retry. Validar o contrato da API, e não transformar resposta incompatível em sucesso vazio.

### P06 — Baixa, integridade de entrada: inteiros são truncados silenciosamente

- **Arquivo/linha:** `frontend/src/views/super-admin/PlansPage/SuperAdminPlansPage.vue:796` e `:800`.
- **Evidência:** `parseInt` normaliza campos antes da validação e envio. Diagnóstico com duração `2.9` concluiu o salvamento enviando `duration_months = 2`, sem erro de validação. O backend recebe o inteiro alterado e não consegue identificar a entrada original.
- **Impacto:** duração/quotas/percentual enviados podem diferir do preenchimento. Requisições diretas com frações nos campos cuja validação exige inteiro são rejeitadas pelo model, conforme testes existentes; o problema é a transformação do frontend.
- **Correção:** converter com Number, validar Number.isFinite/Number.isInteger e faixas e rejeitar frações/entradas inválidas sem truncar; manter null para opcionais em branco.

## Risco condicional identificado

### P07 — Baixa: datas locais da promoção perdem o offset

- **Arquivo/linha:** `frontend/src/views/super-admin/PlansPage/SuperAdminPlansPage.vue:763` e `:813`; `backend/config/application.rb:29`.
- **Evidência de código:** formata a data no fuso do navegador e envia `datetime-local` sem offset. Rails interpreta a string no fuso configurado, Brasília.
- **Impacto condicional:** se o navegador estiver em outro fuso, abrir e salvar pode deslocar o instante de início. Não foi reproduzido em navegador configurado em outro fuso nesta revisão.
- **Correção:** enviar ISO 8601 com offset explícito e rotular o fuso da interface; testar round-trip em Brasília, UTC e outro fuso, inclusive alterações de horário quando aplicáveis.

## Controles verificados e observações

- **Autenticação, role e IDOR:** `authenticate_user!` e `require_super_admin!` precedem `Plan.find`. O catálogo é global, e o super admin tem autoridade sobre todos os planos; o find isolado aqui não caracteriza IDOR. Testes existentes verificam acesso negado a outras roles, ausência de credenciais e payload forjado. Customer JWT foi exercitado no teste de exclusão, não em todas as quatro ações.
- **Strong parameters:** IDs, role, owner, timestamps de cadastro e `promotion_ends_at` não são permitidos como autoridade. A data final é derivada. Os defeitos de validação restantes estão descritos em P03.
- **Sessões e catálogo:** faixas 1..4; exclusividade de ativos protegida por índice único parcial; ordem crescente de preço normal/sessões serializada por advisory lock; testes de concorrência aprovados. Não se somam sessões entre planos. SQL administrativo que ignore validações pode contornar a ordenação entre linhas, conforme documentação existente.
- **Exclusão:** model com restrict e FK impedem exclusão com qualquer assinatura vinculada, inclusive conflito após cache de associação vazio; resposta 409 segura. Sem cascata de contratos.
- **XSS/SQL:** texto sanitizado no model e interpolado pelo Vue sem v-html. SQL fixo ou parametrizado. Nenhuma injeção confirmada no fluxo revisado.
- **Segredos:** nenhum segredo hardcoded identificado nos arquivos revisados; não abri `.env` reais. Não houve varredura forense completa do histórico Git/bundle de produção. O componente não faz logging bruto de erros como o antigo dashboard.
- **Uploads:** não aplicável; este fluxo não aceita arquivos.
- **Auditoria:** ações registram ator e metadados, mas o AuditLogger captura falhas e não é atômico com a mutação. Isso é uma limitação conhecida, não uma garantia de trilha completa. `saved_changes` pode incluir descrição inteira; texto comercial deve evitar dados pessoais desnecessários. Uma eventual exigência de auditoria obrigatória precisa de transação/outbox, não apenas mais campos no logger.
- **LGPD:** o catálogo é comercial e não precisa receber dados pessoais de clientes. Logs de IP/ator/user-agent requerem finalidade, acesso e retenção definidos; não é necessário adicionar consentimento genérico como correção técnica. Não se conclui conformidade integral pela inspeção de uma página. Não foi encontrado vazamento de dados de clientes no retorno de planos revisado.
- **Cache e volume:** herda no-store para requisições autenticadas. Prefixo super admin já está no throttle administrativo por IP. Index retorna todos os planos, inclusive inativos; somente ativos são limitados a quatro faixas. Paginação e allowlist de campos são melhorias preventivas de escala/manutenção, sem DoS demonstrado.
- **Histórico e alterações:** preço pago é snapshot no contrato; preço atual e benefícios de sessões são lidos do plano por caminhos distintos. Alterar sessões de plano existente pode mudar quota de contratos atuais. Não há snapshot de todos os benefícios. Definir explicitamente política comercial antes de prometer grandfathering; isso não foi classificado como bug sem um requisito de congelamento.

## Testes e limites da evidência

- Rails: **34 testes, 249 assertions**, sem falhas/erros. Incluem 28 testes existentes de catálogo, ordenação, concorrência, exclusão e model, mais seis diagnósticos que reproduzem os problemas. Aprovação de diagnósticos significa confirmação do comportamento atual, não correção.
- Frontend: **6 verificações** no script Vue real confirmaram criação após falha e truncamento de duração.
- Brakeman: **zero alertas e zero erros**; não detecta automaticamente as divergências comerciais listadas.
- Scripts/logs em `tmp/`, ignorado pelo Git. Dados fictícios e banco de testes. Sem alteração de código da aplicação, testes no navegador, correções, commit, push ou deploy nesta etapa.

## Prioridade recomendada

1. Unificar preço anunciado/contratado e fonte do desconto; validar promoções no servidor.
2. Rejeitar entradas inválidas antes de cálculos/gravação e eliminar truncamento.
3. Implementar quotas comerciais com regras explícitas de contagem/concorrência ou sinalizar que ainda não são aplicadas.
4. Corrigir estados da carga e round-trip de fuso; avaliar paginação e exigências de auditoria conforme volume/requisitos.

Referências: [OWASP API Security Top 10](https://api-security.owasp.org/editions/2023/en/0x11-t10/) para autorização, validação e consumo de recursos; [LGPD, texto oficial](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm), especialmente necessidade/segurança no art. 6º e medidas do art. 46. O mapeamento é técnico, não uma certificação OWASP nem parecer jurídico.
