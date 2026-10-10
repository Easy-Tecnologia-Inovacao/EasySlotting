# Quotas comerciais dos planos

A configuração é feita pelo super admin em Planos. O servidor valida os campos e aplica os limites em `backend/app/services/plan_quota_policy.rb`, chamado pelos models Service, EstablishmentMembership e Appointment. Não há carrinho, checkout ou pagamento nesta implementação.

## Contagem

| Campo | Escopo e regra |
| --- | --- |
| `max_services` | Por estabelecimento: serviços não excluídos, inclusive inativos. Exclusão lógica libera vaga; restauração exige vaga. |
| `max_employees` | Por estabelecimento: vínculos ativos com role employee. Desativar o vínculo libera vaga; desativar somente o usuário não libera. Owner não ocupa essa quota. |
| `max_appointments_per_month` | Por estabelecimento e mês da data agendada: pendentes, confirmados e concluídos ocupam vaga. Cancelados não contam. Reativação e mudança de mês exigem capacidade no destino. |

Em todos esses campos, `null` significa ilimitado e `0` impede novos registros que ocupem vagas. São aceitos inteiros de 0 a 2147483647. São quotas de quantidade; não alteram a quota de sessões simultâneas, que segue [a política de sessões](session-policy.md).

O plano vem de `Subscription.current_for_use`: o contrato iniciado mais recente, desde que ainda utilizável. Uma tentativa pendente/futura não substitui o contrato atual. Cancelamento com período ainda válido preserva benefícios até o vencimento. Um contrato antigo não volta a conceder quota quando o substituto vence. **Sem contrato vigente não se aplica quota comercial**, preservando o comportamento legado. A autorização de uso sem assinatura válida precisa ser definida em uma etapa própria; estas quotas não comprovam pagamento nem substituem controle de acesso.

## Alterações e concorrência

Uma redução de limite não apaga registros existentes. Edições que não aumentam ocupação continuam permitidas; novos cadastros, restaurações, reativações e transferências para um destino sem vaga são bloqueados. Alterações do plano afetam os contratos que o usam, pois os benefícios não possuem snapshot independente. Não há promessa de congelar benefícios antigos.

Os saves normais do ActiveRecord verificam a contagem sob um advisory lock transacional PostgreSQL compartilhado por estabelecimento. Assim, cadastros concorrentes não consomem a mesma última vaga. O teste `PlanConcurrentQuotaTest` exerce esse cenário com conexões distintas. A criação de um pacote com vários agendamentos continua transacional: falhar em uma vaga reverte o lote.

`save(validate: false)`, `update_all`, importações por SQL e outras escritas que ignorem validações podem contornar a política. Novos fluxos devem usar saves normais e preservar a transação; executar `valid?` isoladamente não reserva vaga. Alterações administrativas de plano/contrato concorrentes com cadastros não usam esse lock e não removem excesso já existente: os próximos cadastros são avaliados contra a configuração então vigente.

## Promoções e contrato da API

`promotion_mode` é um parâmetro virtual de escrita, `price` ou `percentage`, permitido somente no controller de Planos do super admin. Envie apenas a fonte escolhida; a outra deve ser null. O model calcula o valor derivado com BigDecimal. Clientes antigos sem esse parâmetro ainda recebem inferência pela alteração dos campos; fontes conflitantes são rejeitadas.

Promoção habilitada exige início, duração inteira de 1 a 365 dias e desconto válido. Desconto por percentual aceita 1 a 100; preço promocional aceita zero e deve ser menor que o normal. `promotion_ends_at` é derivado e não é permitido como entrada. Desativar a promoção limpa suas configurações.

O frontend usa o fuso local para edição e envia ISO 8601 com offset explícito. A vigência inclui o início e exclui o fim. No catálogo público, `promotion_active` indica promoção efetivamente vigente; fora da vigência, preço promocional e percentual são null e `effective_price` é o normal. O painel administrativo preserva a configuração habilitada e distingue Agendada, Em andamento e Encerrada. Nenhum desses campos representa pagamento confirmado.

## Publicação e manutenção

Publique backend e frontend juntos para disponibilizar o seletor de desconto e os estados de erro. Não é preciso resetar banco ou rodar migration para estas correções. Revise limites de planos já usados antes de publicar: se já houver excesso, os dados permanecem e novos cadastros serão bloqueados.

Testes de referência: `plan_promotion_security_test.rb`, `plan_quota_test.rb`, `plan_concurrent_quota_test.rb` e `frontend/tests/plan-integrity.test.mjs`. Use dados fictícios e banco de testes. O relatório [de revisão de Planos](super-admin-plans-review.md) registra a evidência e as limitações de segurança e LGPD.
