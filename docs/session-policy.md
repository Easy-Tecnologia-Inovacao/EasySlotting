# Política de sessões por perfil

Implementação de 09/10/2026. Complementa [autenticação](authentication.md), [planos/sessões](owner-sessions.md) e [exclusão de contas](account-deletion.md).

## Regras comerciais

| Perfil | Sessões simultâneas por conta | Origem do benefício |
| --- | --- | --- |
| Proprietário (`owner`) | 1 a 4 | Maior faixa vigente entre suas empresas ativas, sem somar |
| Funcionário (`employee`) | 1 a 4 | Maior faixa vigente dos proprietários aos quais possui vínculo employee ativo em empresa ativa |
| Super admin | 5 | Configuração fixa; no máximo uma conta com essa role, inclusive inativa |
| Cliente (`Customer`) | Sem teto comercial | Sessões independentes, com prazo e revogação no servidor |

O limite do funcionário é individual: owner com plano de duas vagas pode usar dois aparelhos e cada funcionário também dois. Não é um pool compartilhado nem quantidade de funcionários cadastrados. Sem assinatura válida, a quota é uma. Quando há vários proprietários vinculados, aplica-se o maior benefício, nunca a soma. Conta de proprietário inativa/não owner, vínculo inativo ou empresa de vínculo inativa não concede benefício. A quota não concede acesso a outras empresas: permissões e memberships continuam obrigatórios em cada API.

A configuração fica no super admin em **Planos → Aparelhos simultâneos por conta da equipe**. `Plan.max_owner_sessions` mantém seu nome técnico por compatibilidade. Faixas ativas continuam exclusivas de 1 a 4, com preço normal e sessões crescentes pela ordem de criação. Nomes/preços são definidos pelo administrador.

## Equipe e super admin

[OwnerSessionPolicy](../backend/app/services/owner_session_policy.rb) e [OwnerSessionTokens](../backend/app/models/concerns/owner_session_tokens.rb) mantêm os nomes existentes e agora atendem às três roles staff. Emissão, rotação e validação consultam a mesma política sob lock de `User`. Um login excedente retorna 409 sem expulsar sessões válidas, sem emitir credencial e sem incrementar erros de senha. Repetir login no mesmo navegador após senha/OTP substitui sua sessão anterior. `device_token` não autentica nem concede mais vagas.

Downgrade/expiração reduzem o limite na próxima validação, preservando os acessos mais recentemente criados. Excedentes são removidos definitivamente do mapa, sem reaparecer no upgrade. Super admin tem cinco vagas independentemente do catálogo.

Owner e employee acessam **Dispositivos conectados** em `/admin/dispositivos`; super admin em `/super-admin/dispositivos`. Todos usam a API `/api/me/sessions`, limitada ao usuário autenticado, e o mesmo componente [StaffSessionsPanel](../frontend/src/components/StaffSessionsPanel.vue). Sessões de outra conta não podem ser revogadas por essa API, nem mesmo enviando IDs/roles no formulário.

## Clientes: vários aparelhos sem perder revogação

[CustomerSession](../backend/app/models/core/customer_session.rb) armazena um registro por login com UUID, dono, hashes SHA256 de refresh/CSRF, timestamps e prazo absoluto. Não guarda os segredos em texto puro nem novos IPs/user agents nessa tabela. `sid` é um identificador opaco da sessão, não uma credencial suficiente para autenticar.

- Access JWT dura até 15 minutos; refresh e sessão têm prazo absoluto de sete dias contado do login. Refresh não prolonga esse prazo.
- Refresh fica em cookie criptografado HttpOnly, SameSite Strict e Secure em HTTPS/produção; access permanece no armazenamento adotado pelo frontend, descrito no guia de autenticação.
- Novo login cria outro registro e preserva os anteriores. Não existe teto numérico comercial de aparelhos para clientes.
- Cada refresh exige cookie/header CSRF correspondentes **e** hash CSRF do registro. Rotação de refresh/CSRF é atômica, sob lock da conta. Reutilizar refresh antigo retorna erro sem apagar sessões vigentes.
- Logout com access válido remove só o registro autenticado. Logout por cookie exige CSRF e os hashes atuais da mesma sessão; cookie antigo não revoga credencial renovada.
- Se uma aba enviar Bearer expirado de A junto com cookie compartilhado de B, o fallback confere a identidade assinada e recusa revogar B. Aceitar a expiração apenas nessa comparação não autoriza acesso: refresh/CSRF e estado vigente continuam obrigatórios.
- Troca/redefinição de senha, desativação e exclusão da conta removem todas as sessões pelos callbacks transacionais de `Customer`. SQL direto/update_columns não acionam callbacks e não devem ser usados para essas operações sem revogação explícita.
- Linhas expiradas são removidas no próximo login daquele cliente e pelo `PurgeExpiredCustomerSessionsJob`, agendado por hora no Solid Queue. Expiração é validada mesmo se o job estiver parado.
- Sem teto de sessões não significa credenciais sem expiração ou requisições ilimitadas: OTP, bloqueio de senha e Rack::Attack continuam ativos. Aparelhos na mesma rede compartilham limites por IP.

O perfil do cliente inclui **Dispositivos conectados** com início/expiração, encerramento individual e encerramento dos outros acessos. A lista tem páginas de 20 registros; isso limita a resposta, não a quantidade de aparelhos.

| Rota | Efeito |
| --- | --- |
| `GET /api/customer/sessions?page=1` | Lista somente sessões vigentes da conta autenticada; `has_more` indica a próxima página |
| `DELETE /api/customer/sessions/:uuid` | Revoga somente sessão dessa conta; inexistente/estrangeira retorna 404 |
| `DELETE /api/customer/sessions/destroy_others` | Preserva somente a sessão autenticada atual |
| `GET /api/customer/profile/sessions` | Histórico de auditoria de logins, separado da lista de sessões vigentes |

Os endpoints de revogação revalidam a sessão atual dentro do lock. As respostas não expõem refresh, hashes ou CSRF armazenado. Cookies continuam compartilhados entre abas da mesma origem: várias identidades simultâneas em abas do mesmo navegador não são uma funcionalidade desta entrega. Aparelhos/navegadores separados têm cookies e sessões independentes.

## Migrações e publicação

1. `20261009150000_create_customer_sessions`: cria tabela, FK, UUID único e índice por cliente/expiração. As colunas antigas em `customers` permanecem por compatibilidade de schema, mas não autorizam mais tokens. Clientes precisam entrar novamente após a publicação. Não remove contas ou empresas.
2. `20261009160000_enforce_single_super_admin`: verifica duplicados antes de criar índice único parcial por role. Se houver duas contas, interrompe com mensagem explicativa, sem apagar ou escolher uma automaticamente. Inativar a segunda não basta, pois a regra é uma conta com essa role; é necessário escolher administrativamente qual preservar e reclassificar a outra. Não faça reset do banco para resolver isso.

O seed de desenvolvimento passa a criar somente um super admin, sem e-mail pessoal/senha fixa. Para acessar a conta, configure `BOOTSTRAP_ADMIN_EMAIL`/`BOOTSTRAP_ADMIN_PASSWORD` antes de executar o seed. Sem senha configurada, ele gera um segredo aleatório que não é exibido. O seed runtime é idempotente e recusa tentar criar outro administrador com e-mail diferente. Não alteramos nem inspecionamos `.env` reais.

As migrações foram aplicadas apenas ao banco de testes local. A publicação exige backend, frontend, schema e worker atualizados juntos. O ambiente/VM não foi alterado e não houve commit/push nesta etapa. O primeiro deploy pode ser bloqueado por duplicados no catálogo ou pelos dois super admins antigos; isso exige resolução administrativa consciente. Os scripts de deploy não devem ignorar falha de migração.

Esta etapa altera quotas e sessões dos clientes. A equipe usa Devise Token Auth em memória com [recuperação por F5 via cookie HttpOnly e CSRF](staff-session-recovery.md); clientes usam JWT/refresh. Os protocolos continuam distintos, com quotas e revogação verificadas no servidor.

## Revisão de segurança do escopo

Achados confirmados e corrigidos; linhas apontam a implementação atual.

| Severidade | Arquivo e linha | Evidência/impacto anterior | Correção |
| --- | --- | --- | --- |
| Média | `backend/app/services/owner_session_policy.rb:24`; `backend/app/models/core/user.rb:75` | Funcionários usavam cinco vagas fixas, sem refletir assinatura. | Resolver benefício por vínculos/owners ativos e aplicar na emissão e em cada validação, com lock e fallback 1. |
| Média | `backend/app/controllers/customer_auth/sessions_controller.rb:100`; `backend/app/models/core/customer.rb:46` | Um único sid/refresh por cliente fazia novo login derrubar os demais. Remover a checagem do sid impediria revogação imediata. | Criar registros independentes e consultar dono/expiração no servidor, preservando revogação de access e refresh. |
| Média | `backend/app/controllers/customer_auth/sessions_controller.rb:149` | CSRF comparado apenas com cookie não distinguia sessões independentes. | Vincular hash de CSRF/refresh ao registro correto e rotacionar atomicamente; replay não remove sessão atual. |
| Média | `backend/app/controllers/customer_auth/sessions_controller.rb:185` | Bearer expirado de uma aba podia cair no logout por cookie de outra sessão compartilhada. | Comparar IDs/sid assinados de Bearer e refresh antes do fallback, sem dispensar CSRF ou autorizar access expirado. |
| Média | `backend/app/models/core/customer.rb:43`; `backend/app/controllers/customer/profile_controller.rb:221` | Revogação de senha/exclusão referia-se ao slot único anterior. | Callback remove todas as sessões e exclusão usa sid observado na requisição, revalidado sob lock; rollback preserva sessões em caso de falha. |
| Média | `backend/app/models/core/user.rb:14`; `backend/db/migrate/20261009160000_enforce_single_super_admin.rb:7` | Nenhuma restrição impedia múltiplos super admins. | Validação e índice único parcial, inclusive contra duas inserções concorrentes sem validação Ruby. |
| Média | `backend/db/seeds.rb:63` | Seed criava dois super admins e usava e-mail pessoal/credencial fixa. | Criar apenas um, com configuração explícita ou segredo aleatório não exibido; bootstrap não escolhe outra conta silenciosamente. |
| Baixa | `backend/app/controllers/customer/sessions_controller.rb:5` | Sessões sem teto exigem respostas e retenção limitadas. | Paginação, allowlist de página/UUID, escopo current_customer e limpeza horária por expiração. |

- **Autorização/IDOR:** regras no Rails; consultas de revogação partem do usuário/cliente autenticado. Testes negam acesso cruzado e payloads que tentam elevar quota/role.
- **Segredos/bundle:** os novos arquivos não introduzem chaves/API keys; hashes internos não são serializados. `.env` excluídos da inspeção. Senhas demonstrativas das demais contas do seed development continuam dados locais de exemplo e não são bootstrap de produção.
- **Entrada/uploads:** página/UUID/credenciais têm validação no servidor. Não há novo upload; o fluxo de avatar permanece com sua validação anterior.
- **Privacidade:** a tabela nova guarda apenas metadados temporais e verificadores. Logs de auditoria continuam no mecanismo existente, sem copiar tokens/CSRF. Não equivale a certificação de conformidade legal ou auditoria integral da aplicação.

## Validação

Resultado final: **116 testes Rails, 787 assertions, zero falhas/erros/skips**. Testes novos cobrem quotas por perfil, vínculo/owner inativo, contrato vencido, upgrade/downgrade, isolamento, sete logins de cliente simultâneos, logout independente, Bearer expirado/cookie de outra aba, CSRF/replay, expiração absoluta, paginação, exclusão/troca de senha e concorrência real com duas conexões PostgreSQL. A suíte também inclui regressões anteriores de autenticação, planos e exclusão.

Frontend: **dez testes aprovados**, checagem de tipos e build de produção aprovados (permanece o aviso de bundle maior que 500 kB). Brakeman: **zero warnings/errors** em `backend/tmp/session-policy-brakeman.json`. `git diff --check` aprovado. Teste visual/manual na VM, entrega de e-mail real e funcionamento contínuo do scheduler ainda dependem do ambiente publicado.

## Referências consultadas

- [OWASP — sessões simultâneas](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html#simultaneous-session-logons): a política de simultaneidade é uma decisão do produto; gerenciamento/revogação devem continuar disponíveis.
- [OWASP — expiração e ciclo de vida](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html#session-expiration): expiração e invalidação precisam ser impostas pelo servidor.
- [Rails — segurança e cookies/CSRF](https://guides.rubyonrails.org/security.html): cookies protegidos não substituem a validação de CSRF e autorização.
- [Devise Token Auth — configuração](https://devise-token-auth.gitbook.io/devise-token-auth/config/initialization): rotação, prazo e número de clients. A política por plano complementa a configuração global da gem.

Os números 1..4, cinco e sem teto para clientes são regras comerciais solicitadas para o EasySlotting, não valores prescritos pelas referências.
