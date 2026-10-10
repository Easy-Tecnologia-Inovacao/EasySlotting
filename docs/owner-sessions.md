# Sessões simultâneas do proprietário e funcionários por plano

Implementado em 09/10/2026. Este recurso limita acessos da **mesma conta `owner`**, em navegadores/aparelhos diferentes. Não é quantidade de funcionários cadastrados, número de clientes nem alternância entre quatro contas no navegador.

Atualização: cada **funcionário vinculado ativamente** herda a mesma quota do proprietário, de forma independente. As vagas não são um pool compartilhado entre funcionários/owner. Super admin único tem cinco acessos; clientes não têm teto comercial. Consulte a [política por perfil](session-policy.md).

## Configuração e uso

Para retirar ofertas, consulte [exclusão e inativação de planos](plan-deletion.md). Planos com assinaturas vinculadas são preservados.

No painel super admin, em **Planos → criar/editar → Aparelhos simultâneos por conta da equipe**, selecione de **1 a 4**. O campo `Plan.max_owner_sessions` mantém o identificador técnico por compatibilidade, é obrigatório e tem default 1/restrição equivalente no PostgreSQL. Cada limite só pode pertencer a **um plano ativo**. A soma dos números do catálogo não calcula sessões.

Exemplos comerciais possíveis, sem criar novos preços automaticamente:

| Exemplo de plano | Configuração |
| --- | --- |
| Standard | `max_owner_sessions: 1` |
| Plus | `max_owner_sessions: 2` |
| Pro | `max_owner_sessions: 3` |
| Ultra | `max_owner_sessions: 4` |

Os nomes são exemplos; não foram criados planos ou preços automaticamente. Quando o maior plano ativo já oferece quatro sessões, **Novo plano** fica indisponível, mesmo que existam menos de quatro planos: não há uma faixa superior permitida. O formulário identifica limites ocupados e opções fora da ordem crescente, mantendo disponível o próprio limite durante a edição. O Rails também valida a exclusividade, e um índice único parcial no PostgreSQL protege contra cadastros/reativações concorrentes. Conflitos retornam 422 sem detalhes internos do banco.

**Não há quantidade mínima de planos nem obrigação de oferecer a faixa de quatro sessões.** Catálogos com limites 1/2/3 ou 1/2/4 são válidos quando cadastrados nessa ordem, com preços normais também crescentes. Quantidades não podem se repetir: 2/2/4 é rejeitado pela repetição de 2, sem somar os valores.

Planos inativos podem permanecer no histórico, inclusive com um limite reutilizado por outro plano ativo, desde que a sequência de cadastro seja respeitada. Inativar não apaga assinaturas existentes nem retira o benefício de um contrato ainda válido. Reativar exige uma faixa disponível e valores compatíveis com os planos anteriores/seguintes. Preços/promoções não criam faixas adicionais.

## Ordem crescente de cadastro

- A ordem original de cadastro é definida pelo ID gerado pelo PostgreSQL; o formulário não pode escolher ID, posição ou data de criação.
- Cada novo plano ativo deve ter **preço normal maior** e **mais sessões** que todos os planos ativos já cadastrados. Preços iguais também são rejeitados. Pode pular uma faixa: 1 → 2 → 4 é válido; cadastrar 3 depois de 4 não é permitido.
- Ao editar ou reativar um plano, seu preço normal e suas sessões devem ficar entre os valores dos planos ativos anteriores e seguintes. A posição original permanece a mesma. Um cadastro inativo mais novo não pode ser ativado depois como uma faixa inferior para contornar a regra.
- A comparação usa o preço normal total pelo período cadastrado, sem normalizar por meses. Descontos e preços promocionais não mudam a sequência. Os demais limites do plano continuam com suas validações individuais.
- Super admin, landing e contratação recebem os planos na ordem de preço normal, com desempate por ID. Em um catálogo válido, essa ordem acompanha a sequência de criação e sessões.
- O Rails aplica a regra sob `pg_advisory_xact_lock`, antes das validações e dentro da transação do `save`. O mesmo lock protege criações, edições e reativações entre processos, inclusive quando não existe plano ainda. Planos persistidos são recarregados sob o lock, preservando as entradas editadas antes da conversão de tipo, para validar campos atuais e rejeitar entradas inválidas.

Exemplo válido, apenas ilustrativo: R$ 50 com 1 sessão → R$ 100 com 2 → R$ 200 com 4. Um plano novo de R$ 150 com 3 sessões depois dessa sequência é rejeitado. Para reorganizar ofertas existentes, edite/inative os planos envolvidos respeitando seus vizinhos; o sistema não reajusta preços nem benefícios automaticamente.

A ordenação entre registros é uma validação do model durante gravações normais. O banco mantém CHECK 1..4 e exclusividade, mas não possui uma constraint própria para a relação de ordem entre duas linhas. SQL administrativo, `update_all`, `update_columns` e `save(validate: false)` ignoram a validação de ordem; não devem ser usados para cadastrar ou editar ofertas em produção. A API não expõe esses atalhos.

O limite aparece na landing page, na contratação e no retorno da assinatura. O campo configura um benefício; não implementa pagamento ou cobrança adicional. O controller atual de contratação ativa a assinatura diretamente, sem confirmação de pagamento de um provedor. Para vender esse benefício com cobrança real, a ativação precisa depender da confirmação de pagamento verificada pelo servidor, nunca de um valor ou flag de pagamento enviados pelo navegador.

O proprietário acessa **Dispositivos conectados** (`/admin/dispositivos`) para consultar suas sessões, sair deste aparelho, encerrar um acesso específico ou todos os outros. A tela não aceita ID de outro usuário como autoridade.

## Regra de limite

- O limite é global por conta owner. Não se somam quatro vagas para cada empresa.
- Para cada estabelecimento ativo pertencente ao owner, seleciona-se a assinatura iniciada mais recente, por criação/ID, desconsiderando tentativas `pending` e início futuro. Depois, ela só concede benefício se tiver status `active` ou `canceled` e período vigente. Uma assinatura vencida/inadimplente mais nova não faz o contrato substituído reaparecer. Cancelamento mantém o benefício até o fim do período, se não houver substituição.
- Entre essas empresas, vale o **maior limite** encontrado, até 4. Membership em empresa de outro proprietário não concede vagas à conta owner.
- Upgrade Standard → Plus muda 1 para 2; Plus → Pro muda 2 para 3; Pro → Ultra muda 3 para 4. Nunca resulta em 1 + 2 + 3 + 4. Renovações/contratos substituídos não acumulam vagas. A consulta da assinatura atual e a troca de plano usam a mesma regra de vigência.
- Sem assinatura utilizável, o limite é **1**. Assinaturas futuras, vencidas e empresas inativas não concedem benefício.
- Cada sessão válida ocupa uma vaga. Mesmo IP não significa mesmo aparelho; contas atrás do mesmo Wi-Fi não são agrupadas pelo IP.
- Entrar novamente com senha/OTP válidos no mesmo navegador substitui sua sessão anterior, usando o hash do identificador de dispositivo. O token anterior é revogado; isso não multiplica acessos.
- O identificador de navegador não é comprovação física de hardware. Cloná-lo pode substituir a sessão anterior, mas não permite ultrapassar o número de sessões válidas nem elimina a autenticação. Limpar storage ou mudar de navegador passa a representar outro acesso.
- Logout/revogação e expiração liberam vagas. Fechar a aba não revoga a sessão no servidor.
- Ao atingir o limite, o login seguinte recebe **409**, sem emitir token e sem derrubar sessões válidas. A tela não trata esse evento como senha errada.
- Na redução de plano/expiração, são preservadas as sessões mais recentemente criadas até o novo limite. O próximo processamento de autenticação remove as excedentes sob lock; ampliar o plano depois não restaura tokens já removidos.
- Sessões legadas sem `issued_at` usam desempate estável pelo ID interno, sem promessa de ordem cronológica. Sem `device_digest`, não há reconhecimento para substituir a sessão antiga do mesmo navegador: encerre o acesso legado em outro aparelho, aguarde a expiração ou use a recuperação de senha para revogar os acessos.

Cada funcionário herda o maior benefício vigente dos proprietários aos quais está vinculado ativamente, entre 1 e 4, sem somar planos. A quota é independente por pessoa. Super admin tem cinco vagas e clientes têm sessões próprias sem teto de aparelhos. Nenhum deles consome vagas do proprietário. Vínculo/empresa/proprietário inativo não concede benefício; sem contrato válido, fallback 1.

## Contratos da API

Login continua em `POST /api/devise_users/sign_in`. O cliente **não escolhe** limite, owner, role, assinatura ou estabelecimento para obter vagas.

Resposta quando as vagas estão ocupadas, após autenticação de senha/OTP:

```json
{
  "code": "OWNER_SESSION_LIMIT_REACHED",
  "limit": 4,
  "errors": ["Seu plano permite até 4 sessões simultâneas do proprietário. Em outro aparelho, abra Dispositivos conectados e encerre um acesso para entrar."]
}
```

`GET /api/me/sessions` exige autenticação e retorna `sessions`, `limit` e `active_count`. Para owner, só lista sessões permitidas e não expiradas. Cada entrada contém `client_id`, `is_current`, `device`, `ip`, `user_agent`, `created_at`, `last_seen_at` e `expires_at`; não contém access token, hash de token ou `device_digest`.

- `DELETE /api/me/sessions/:client_id`: encerra uma sessão da própria conta; ID pertencente a outra conta retorna 404.
- `DELETE /api/me/sessions`: encerra os outros acessos e preserva o atual.
- `DELETE /api/devise_users/sign_out`: logout do acesso atual, usando o helper central do frontend.

O `client_id` identifica a sessão e sozinho não autentica uma chamada. O token e demais credenciais continuam obrigatórios. A API de sessões existente permanece disponível aos demais perfis staff para gerenciarem seus próprios acessos, sem acesso à configuração de planos.

## Implementação e concorrência

| Arquivo | Responsabilidade |
| --- | --- |
| [owner_session_policy.rb](../backend/app/services/owner_session_policy.rb) | Resolver assinatura/limite e selecionar sessões permitidas |
| [owner_session_tokens.rb](../backend/app/models/concerns/owner_session_tokens.rb) | Aplicar limite sob lock, substituir acesso do mesmo navegador e preservar metadados na rotação da gem |
| [user.rb](../backend/app/models/core/user.rb) | Validar e remover sessões excedentes/expiradas antes de autorizar o token |
| [sessions_controller.rb](../backend/app/controllers/devise_users/sessions_controller.rb) | Login, hash do identificador observado e resposta 409 sem credenciais |
| [users_controller.rb](../backend/app/controllers/account/users_controller.rb) | Listagem/revogação limitada a `current_user` |
| [plan.rb](../backend/app/models/financial/plan.rb) | Validação do benefício, sequência de cadastro, lock do catálogo e recarga de campos atuais |
| [migração](../backend/db/migrate/20261009130000_add_owner_session_limit_to_plans.rb) | Coluna, default, NOT NULL e CHECK 1..4 |
| [migração do catálogo](../backend/db/migrate/20261009140000_enforce_unique_active_plan_session_limits.rb) | Índice único dos limites dos planos ativos e verificação de conflitos existentes |
| [subscription.rb](../backend/app/models/financial/subscription.rb) | Contrato iniciado atual para contratação/consulta, sem recuperar assinatura substituída |
| [SuperAdminPlansPage.vue](../frontend/src/views/super-admin/PlansPage/SuperAdminPlansPage.vue) | Configuração das faixas, ordem crescente e bloqueio de criação após a faixa de quatro sessões |
| [AdminSessionsPage.vue](../frontend/src/views/admin/SessionsPage/AdminSessionsPage.vue) | Consulta e encerramento dos acessos, com proteção contra troca de conta durante respostas pendentes |

A gem define `create_token` diretamente na classe dentro de seu `included`. O módulo utiliza `prepend` para envolver a implementação original, sem copiar o algoritmo de emissão da gem. Tanto emissão quanto rotação usam `with_lock` da linha do owner, incluindo a leitura anterior e o save final. A contagem e a criação da nova sessão ficam na mesma transação; dois logins concorrentes não podem reservar a última vaga simultaneamente.

O hash do dispositivo é calculado no servidor a partir do identificador validado por `LoginInput`; não vem de `params[:device_digest]`. `issued_at` permanece estável na rotação. O token bruto não é salvo em auditoria; o evento de limite atingido registra apenas o limite e os metadados já tratados pelo logger.

Esta etapa utiliza **Devise Token Auth e `User.tokens` existentes**. Não executa a futura padronização de todas as roles para cookies HttpOnly, nem cria uma tabela unificada de sessões. Ao fazer essa evolução, mantenha `max_owner_sessions` e a resolução do benefício; substitua o armazenamento/contagem preservando as mesmas garantias de lock, autorização e revogação.

## Revisão de segurança da feature

Achados confirmados e tratados no fluxo alterado:

| Severidade | Arquivo/linha | Evidência e impacto | Correção |
| --- | --- | --- | --- |
| Média | `backend/app/models/financial/plan.rb:60` | O plano não tinha limite próprio de sessões owner; o único teto era de cinco clients para todos os perfis staff. | Campo 1..4 validado pelo model/banco e aplicado no servidor; não confiar no payload de login. |
| Média | `backend/app/models/concerns/owner_session_tokens.rb:4` | A rotação da gem substitui a entrada de tokens e descartava os metadados registrados no login. | Preservar os campos permitidos, data original e hash do navegador ao rotacionar. |
| Média | `backend/app/controllers/account/users_controller.rb:255` | A listagem incluía entradas expiradas e não informava vagas/plano. | Listar somente sessões permitidas/vigentes, com limite e contagem obtidos no servidor. |
| Média | `backend/app/models/financial/plan.rb:63` | Apenas o intervalo 1..4 era validado; era possível repetir faixas e criar mais de quatro planos ativos. | Exclusividade no model e índice único parcial, incluindo reativação; tratar conflito concorrente como 422. |
| Média | `backend/app/services/owner_session_policy.rb:26` | Filtrar validade antes de escolher a assinatura mais recente permitia reutilizar o benefício de um contrato cancelado e substituído quando o novo vencesse. | Selecionar primeiro o contrato iniciado mais recente e depois verificar validade/status. |
| Média | `backend/app/models/financial/plan.rb:110` | A configuração permitia planos posteriores com preço menor ou menos sessões, contrariando a progressão das ofertas. | Validar crescimento de preço normal e sessões conforme ID, inclusive edição/reativação; listar em ordem crescente. |

Riscos de implementação prevenidos, sem classificá-los como falhas exploradas na versão anterior: corrida entre contagem e emissão, uso de assinatura de outro owner, restauração de sessões removidas, aumento de limite pelo frontend, revogação por ID de terceiro, inversão de faixas por gravações concorrentes e validação de uma reativação com campos desatualizados.

Categorias verificadas no escopo desta feature:

- **Autorização:** edição de plano exclusiva de super admin; login/limite continuam no servidor. Funcionário e cliente não controlam o benefício.
- **IDOR:** consulta/revogação partem de `current_user`; resolução das assinaturas parte do `owner_id` da conta autenticada. Testes negam uso de empresa/membership/ID de terceiros.
- **Segredos/bundle:** não foram introduzidas chaves privadas ou credenciais hardcoded; a lista não devolve tokens ou hashes. Arquivos `.env` reais ficaram fora da revisão, conforme solicitado.
- **Entrada/uploads:** campo numérico obrigatório 1..4, exclusividade entre planos ativos, preço/sessões crescentes no model, strong parameters, CHECK e índice único no PostgreSQL. ID/data de cadastro não são campos permitidos. Senha/OTP preservam a validação existente. Esta feature não adiciona upload.
- **Privacidade:** tela restrita à própria conta; dados de sessão não expostos na API pública de planos. Novos logs não incluem senha, OTP ou token. Retenção e armazenamento de IP/user agent seguem a política descrita no guia de autenticação.

## Testes e publicação

- Verificação original dos planos: **92 testes Rails, 578 assertions, zero falhas/erros**, incluindo autenticação, exclusão de clientes, isolamento, catálogos parciais, quatro faixas, criação crescente e concorrência. A atualização por perfil foi validada com **116 testes/787 assertions**, conforme [política de sessões](session-policy.md).
- Verificação focada dos planos/sessões: **37 testes Rails, 289 assertions, zero falhas/erros**. Build/checagem de tipos e dez testes de autenticação do frontend aprovados novamente. Brakeman: zero warnings/errors.
- [plan_session_catalog_test.rb](../backend/test/integration/plan_session_catalog_test.rb): quatro faixas, catálogos parciais 1/2/3 e 1/2/4 sem exigir quatro planos, duplicados negados, edição/reativação, permissões e conflito concorrente com resposta segura.
- [plan_concurrent_catalog_test.rb](../backend/test/models/plan_concurrent_catalog_test.rb): duas conexões PostgreSQL disputam a mesma faixa ou tentam criar/editar valores que se inverteriam; somente uma das gravações incompatíveis é aceita.
- [plan_catalog_ordering_test.rb](../backend/test/integration/plan_catalog_ordering_test.rb): criação crescente, preços iguais/menores, tentativa de inserir uma faixa inferior depois, edição, reativação, draft inativo, promoções, campos desatualizados e ordem das APIs.
- [owner_session_limits_test.rb](../backend/test/integration/owner_session_limits_test.rb): quatro acessos, quinto negado, mesmo navegador, OTP, logout, expiração, rotação, upgrade pelas quatro faixas, downgrade, múltiplas empresas sem soma, plano vencido, assinatura substituída, permissões, validação e IDOR.
- [owner_concurrent_sessions_test.rb](../backend/test/models/owner_concurrent_sessions_test.rb): duas conexões PostgreSQL e threads disputando a última vaga; exatamente uma emissão aceita.
- [plan_test.rb](../backend/test/models/plan_test.rb): limites inválidos e restrição no banco.
- Frontend: dez testes existentes de autenticação aprovados. Build e checagem de tipos aprovados. Brakeman: zero warnings/errors.

Migrações aplicadas **somente no banco de testes local**. Na VM, execute o deploy com migrações antes de carregar este código; não publique o backend que lê o campo com schema antigo. Rollback da coluna exige também reverter o código dependente; sessões já revogadas não são recuperadas pelo rollback.

**Catálogo existente:** a migração que adiciona a coluna atribui 1 a todos os registros antigos. Se houver vários planos ativos, configure limites distintos antes de concluir a migração do índice único. Ela interrompe com uma mensagem explicativa se encontrar duplicados; não redistribui benefícios por preço nem inativa planos automaticamente. Confira `Plan.order(:id).pluck(:id, :name, :active, :max_owner_sessions)` em um console Rails administrativo após a criação da coluna. Configure cada plano com `Plan.find(ID).update!(max_owner_sessions: LIMITE)` (1..4); se houver mais de quatro ativos, escolha quais inativar com `update!(active: false)`, preservando o histórico. Depois repita `db:migrate`. Não execute `db:seed` ou reset do banco para resolver isso.

A regra crescente não acrescenta coluna ou migração. Antes de publicar, confira também `Plan.where(active: true).order(:id).pluck(:id, :price, :max_owner_sessions)`. Tanto preços quanto sessões devem crescer. Se o catálogo antigo já está invertido, revise as ofertas; pode ser necessário inativar os registros envolvidos, configurar seus valores e reativar em sequência. Assinaturas existentes são preservadas. Não há reajuste ou reorganização automática.

Validação manual pendente no ambiente publicado: selecionar plano com quatro vagas, entrar em quatro navegadores/aparelhos, conferir negativa no quinto e liberar uma vaga pela tela. Testes de login/OTP compartilham limites por IP/e-mail: respeite a janela do Rack::Attack em testes no mesmo Wi-Fi. Não foram feitos deploy, teste visual no navegador nem confirmação real de pagamento nesta entrega.

Referências: [OWASP — sessões simultâneas e gerenciamento pelo usuário](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html#simultaneous-session-logons), [Rails — pessimistic locking e with_lock](https://api.rubyonrails.org/classes/ActiveRecord/Locking/Pessimistic.html), [Rails — transação do save e callbacks](https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html), [PostgreSQL — índice único parcial](https://www.postgresql.org/docs/current/indexes-partial.html), [PostgreSQL — advisory locks](https://www.postgresql.org/docs/current/explicit-locking.html#ADVISORY-LOCKS) e [Stripe — benefícios vigentes em upgrades/downgrades](https://docs.stripe.com/billing/entitlements?dashboard-or-api=api). A regra comercial de faixas exclusivas, crescentes e máximo de quatro sessões é uma decisão do EasySlotting, não uma exigência dessas referências. Stripe é referência para a futura integração de cobrança, não uma integração feita nesta entrega.
