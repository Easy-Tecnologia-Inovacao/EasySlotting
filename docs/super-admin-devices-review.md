# Revisão de Dispositivos conectados do super admin

Data: 10/10/2026. Base da revisão: commit `b8ab706`. Skills aplicadas: `easyslotting-security-review` e, na correção, `easyslotting-secure-feature`. A URL indicada identifica o fluxo; não houve inspeção visual no navegador nem teste contra a instância em execução.

## Correções implementadas após a revisão

Os achados D01 a D04 foram corrigidos na árvore de trabalho. As seções seguintes preservam a fotografia anterior e os números de linha da base revisada.

| Achado | Correção |
| --- | --- |
| D01 | Removido o throttle de account baseado em HTTP_UID. `Account::UsersController` aplica rate_limit de 30/min após authenticate_user!, por current_user.id, com 429 e Retry-After de 60 segundos. O throttle geral por IP permanece. |
| D02 | Cargas e mutações são serializadas nos handlers. Nenhuma ação inicia durante GET/DELETE pendente; a carga após DELETE só começa após sua confirmação. Respostas após desmontagem ou troca de conta são descartadas. |
| D03 | Limite inicia desconhecido, sem presumir uma sessão. Lista e contagem são ocultadas durante atualização ou após falha. Respostas passam por validação de estrutura, tipos, IDs únicos, datas, limite e contagem; falhas oferecem retry. Falha de DELETE também exige recarregar o inventário antes de agir novamente. |
| D04 | Listagem retorna somente client_id, is_current, device, ip, last_seen_at e expires_at. Novos eventos usam revoked_client_digest com SHA256 de `staff-session:` + client_id; o identificador integral não é copiado para details. DELETE valida formato/tamanho do identificador antes da consulta ao hash da conta. |

O componente é compartilhado pelo super admin, proprietário e funcionário. A quantidade permitida de sessões não mudou: cinco para super admin e política de plano para os demais. A listagem de clientes usa outro fluxo e não foi alterada.

Validação da correção: **68 testes Rails, 576 assertions**, zero falhas/erros, em duas execuções direcionadas (40 testes de gestão/limites/recuperação e 28 de autenticação). **42 testes frontend aprovados**, incluindo seis novos cenários do componente real. Type-check e build passaram; Brakeman com zero alertas e zero erros. Permanecem avisos locais existentes de Vips, depreciações Rails, fork no Windows e tamanho de bundle. Não foi feita validação visual nem publicação na VM/VPS.

Publicação: atualizar backend e frontend e reiniciar o backend para carregar o initializer alterado. Não há migration ou reset de banco. Cache compartilhado entre processos é necessário para que o rate_limit seja agregado; produção já configura Solid Cache. A API deixou de retornar user_agent/created_at, sem uso pelos consumidores locais; integrações externas que os usem precisam se adaptar. Logs antigos não foram apagados e o identificador continua no caminho do DELETE: retenção de logs e configuração de proxy seguem as observações de governança abaixo. Nenhum prazo de retenção ou duração absoluta de sessão foi escolhido automaticamente nesta correção.

## Histórico da revisão inicial

A revisão inicial apenas reproduziu os problemas; as evidências abaixo não descrevem o estado corrigido.

## Escopo e resultado

Fluxo: rota Vue `/super-admin/dispositivos` → `SuperAdminSessionsPage` → componente compartilhado `StaffSessionsPanel` → Axios → GET `/api/me/sessions`, DELETE `/api/me/sessions/:client_id`, DELETE `/api/me/sessions` e logout staff → `Account::UsersController`, User, OwnerSessionPolicy, OwnerSessionTokens e StaffSessionRecovery. Foram examinados recuperação por cookie, rotação da gem, auditoria, cache e throttle relacionados.

Não foi demonstrado bypass de autenticação ou acesso a sessões de outra conta. O super admin tem cinco sessões; owner/funcionário usam suas políticas próprias. Foram confirmados os quatro achados abaixo. O problema de throttle é a prioridade de segurança; os problemas da interface não ressuscitam credenciais no servidor.

## Achados confirmados

### D01 — Média: header não autenticado permite bloquear a quota de outra conta

- **Arquivo/linha:** `backend/config/initializers/rack_attack.rb:99` a regra `account/user` usa `HTTP_UID` diretamente.
- **Evidência:** com cache MemoryStore e tempo congelado no banco de testes, 30 GETs sem token, apenas com o UID da conta fictícia, retornaram 401. O GET autenticado seguinte, de outro IP, recebeu 429. A contagem acontece antes da autenticação. O mesmo prefixo abrange revogação, não apenas listagem.
- **Impacto:** quem conhece o UID/e-mail pode causar indisponibilidade temporária da gestão de sessões da vítima, inclusive na hora de encerrar um acesso suspeito. Não concede acesso nem revoga sessões; o bloqueio demonstrado respeita a janela de um minuto e pode ser renovado com novas requisições. Não foi realizado ataque na aplicação real.
- **Correção:** manter limite por IP para tráfego não autenticado e aplicar quota por identidade somente depois da validação do token, usando o ID obtido no servidor. Não usar UID, user_id ou role informados pelo cliente como autoridade para atribuir consumo a terceiros. Testar que tráfego inválido não consome a quota da vítima e que requisições válidas de IPs diferentes compartilham sua própria quota.

### D02 — Média, integridade da interface: respostas fora de ordem podem reapresentar sessão revogada

- **Arquivo/linha:** `frontend/src/components/StaffSessionsPanel.vue:87`, `:94`, `:104` e `:131`.
- **Evidência:** `loadSessions` não impede cargas simultâneas nem identifica a geração da resposta. As funções de revogação verificam busy, mas não loading. Diagnóstico executando o script real: iniciou GET, revogou outro acesso, carregou lista nova sem ele e depois resolveu o GET antigo; o acesso removido voltou à lista. Os botões desabilitados reduzem o caminho de interação, mas não tornam as funções ou respostas consistentes em caso de trabalho concorrente.
- **Impacto:** a tela pode indicar acesso encerrado como ainda conectado, induzir nova revogação e mostrar contagem antiga. Não foi demonstrada recuperação do token revogado no servidor; os testes confirmam a negativa de autenticação/recuperação após revogação.
- **Correção:** serializar cargas e mutações ou invalidar respostas por geração; bloquear ações durante carga no handler, além do botão. Após uma mutação, descartar qualquer GET iniciado antes dela. Incluir testes com promises resolvidas fora de ordem e duas chamadas concorrentes de atualização.

### D03 — Baixa, confiabilidade: dados antigos e respostas incompatíveis são apresentados como inventário utilizável

- **Arquivo/linha:** `frontend/src/components/StaffSessionsPanel.vue:21`, `:77` e `:94`.
- **Evidência:** limite inicial é 1, inclusive para super admin. Após uma carga válida seguida de falha, sessions/limit permanecem e o componente não marca o inventário como desatualizado. Uma resposta `{ sessions: {}, limit: 'invalid' }` é atribuída sem erro nem validação de estrutura. Reproduzido no script Vue real, sem substituir a implementação.
- **Impacto:** antes da primeira carga aparece quota presumida; após falha, contagem antiga e ações continuam disponíveis. Uma API incompatível pode gerar renderização incoerente. Não há bypass de quota do servidor.
- **Correção:** distinguir carga, sucesso, sucesso vazio e falha; não exibir limite presumido como recebido do servidor. Validar array, campos necessários, limite inteiro e contagem. Em falha, esconder dados ou sinalizá-los claramente como desatualizados e bloquear ações sobre eles, oferecendo retry.

### D04 — Baixa: metadados desnecessários na resposta e identificador bruto na auditoria

- **Arquivo/linha:** `backend/app/controllers/account/users_controller.rb:266` e `:295`.
- **Evidência:** a listagem entrega `user_agent` e `created_at`, mas o componente usa somente nome amigável, IP, última atividade, expiração, client_id e is_current. Diagnóstico confirmou o retorno do user-agent detalhado e a gravação do client_id integral em `details.revoked_client_id`.
- **Impacto:** aumenta a exposição de metadados do navegador e a possibilidade de correlação com registros de sessão. Client_id sozinho não autentica e é necessário como identificador operacional da ação na API; não foi encontrado access token, hash de recuperação, OTP ou senha nessa resposta. Isso não é evidência de vazamento para outra conta nem comprovação de infração legal.
- **Correção:** remover da resposta campos sem uso; manter allowlist. Para correlação em auditoria, preferir digest/HMAC do identificador em vez do valor integral e registrar somente metadados necessários. Avaliar também logs de URL do proxy, pois o endpoint de exclusão contém o identificador no caminho. Não remover IPs ou apagar acervo sem definir a finalidade e a política de retenção.

## Governança e melhorias condicionais

- **Retenção:** `backend/lib/tasks/audit_retention.rake:3` remove logs após 90 dias; `backend/app/jobs/audit_log_cleanup_job.rb:9` tem default de 730 dias. Nenhum deles está agendado em `backend/config/recurring.yml`. Isso confirma duas políticas no código e ausência de agenda nesse arquivo; não prova que a VM não tenha cron externo. Unificar prazo por finalidade, documentar justificativa e testar/agendar a rotina aprovada. Não executar expurgo nesta revisão.
- **Auditoria:** AuditLogger captura falhas e não é atômico com a revogação. Se trilha obrigatória for requisito operacional, usar transação/outbox e testes de falha. Atualmente não há garantia de evento para toda mutação.
- **Expiração:** tokens staff têm duas horas renovadas com atividade; não foi identificado teto absoluto independente de `issued_at`. Definir duração absoluta e eventual reautenticação para super admin conforme risco/requisito. Não classificar automaticamente a renovação como bypass do limite de cinco sessões.
- **Revogação em andamento:** a negativa vale nas próximas verificações de autenticação. Uma ação que já passou pela autorização pode terminar; esta revisão não demonstra cancelamento de trabalho em execução.
- **IP/aparelho:** nome e user-agent são informações declaradas pelo cliente, não prova de identidade física. O IP exibido vem do login; reconhecimento por IP para OTP não é a regra de quota. Configuração de proxies confiáveis e HTTPS precisa ser verificada na VPS. Não foi alterada nesta revisão.

## Controles verificados

- **Autenticação/role/IDOR:** `authenticate_user!` protege as três ações; consultas e alterações partem de current_user.tokens sob lock. Não recebem user_id/establishment_id como autoridade. A API é compartilhada por staff para suas próprias sessões; não exigir super admin nela é intencional. A rota Vue restringe apresentação, não autorização do servidor. Payload de outro usuário não muda o escopo; client_id de outra conta recebe 404. JWT de cliente e requisição sem credenciais recebem 401.
- **Quota e concorrência:** cinco para super admin; locks da conta serializam emissão/rotação/revogação. Testes existentes confirmam rejeição da sexta sem expulsar acessos válidos, quotas independentes de owner/funcionário e poda definitiva em downgrade.
- **Revogação/recuperação:** encerrar um acesso remove seu registro de token e os hashes de recuperação; encerrar outros preserva apenas o client autenticado. Replays dos tokens e provas de recuperação removidos são rejeitados. Logout próprio usa helper que limpa o estado local antes da rede; offline não comprova revogação remota.
- **CSRF/cookies:** APIs comuns não autenticam só com cookie (`cookie_enabled = false`); exigem credenciais nos headers. Recuperação e fallback de logout exigem prova CSRF vinculada ao cookie criptografado, HttpOnly, SameSite Strict, com Secure em produção. Testes existentes exercitam cookie isolado, CSRF ausente/incorreto e identidade divergente. Não foi feita inspeção de cookies do navegador real.
- **Cache/segredos:** respostas de account usam no-store/Pragma no-cache. Serializer de sessão não entrega tokens, hashes de recuperação, device_digest, OTP ou senha. Não foram abertos arquivos `.env`, seeds com credenciais ou histórico completo do repositório. Nenhum segredo hardcoded foi identificado nos arquivos do fluxo revisado.
- **Validação/injeção:** client_id é usado como chave do hash da conta, sem SQL dinâmico; frontend usa encodeURIComponent no caminho e interpolação Vue, sem v-html. Campos de user-agent gravados no login têm limite. Nenhum SQL injection ou XSS foi confirmado neste fluxo. IDs desconhecidos recebem 404; validação explícita de formato/tamanho seria defesa adicional.
- **Uploads:** não aplicável; página e endpoints não recebem arquivos.
- **LGPD:** IPs e metadados são usados para gestão e segurança da própria conta, com acesso autenticado. Necessidade, acesso, retenção, aviso ao titular e base legal devem acompanhar a finalidade. Um consentimento genérico não resolve automaticamente esses pontos. Esta revisão não certifica conformidade LGPD.

## Evidência e limites

- Rails: **39 testes, 383 assertions**, zero falhas/erros, no banco de testes: `owner_session_limits_test.rb`, `staff_plan_sessions_test.rb`, `staff_session_recovery_test.rb` e cinco diagnósticos temporários em `tmp/devices_review_test.rb`. Os diagnósticos de throttle/metadados passam quando confirmam os defeitos atuais, não quando os corrigem.
- Frontend: script real compilado com @vue/compiler-sfc; três cenários confirmaram dados antigos, corrida de GET/revogação e resposta incompatível. Diagnóstico em `tmp/devices-review.mjs`; sem montagem de DOM ou teste visual.
- Brakeman executado nesta revisão: **zero alertas e zero erros**. O scanner não detectou automaticamente os problemas de lógica descritos. Avisos locais existentes de DLLs Vips opcionais, depreciações Rails e fork indisponível no Windows não impediram a conclusão das verificações.
- Scripts e logs de diagnóstico estão em tmp, ignorado no Git. A revisão criou somente este relatório versionável; não corrigiu código, fez commit/push, publicou ou resetou banco.

Referências: [OWASP Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html), especialmente gerenciamento/expiração, sessões simultâneas e correlação em logs; [LGPD — texto oficial](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm), necessidade e segurança no art. 6º e medidas no art. 46. O mapeamento é técnico e não substitui avaliação jurídica/operacional.
