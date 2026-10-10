# Revisão de login, sessão e logout

Data: 09/10/2026. Escopo: autenticação de proprietários, funcionários, super admins e clientes; registro do primeiro dispositivo, OTP, renovação, revogação, logout e integração das telas Vue com as APIs Rails. Skills locais utilizadas: `easyslotting-security-review`, `easyslotting-secure-feature` e `easyslotting-authentication`.

Para arquitetura, contratos, operação e instruções de extensão, consulte o [guia técnico de autenticação](authentication.md). Este relatório preserva os achados e a validação da revisão.

A correção de 10/10/2026 para manter a sessão staff após F5 está em
[recuperação segura de sessão](staff-session-recovery.md), com contrato,
revisão de autorização/IDOR/CSRF e evidência dos testes específicos.

A revisão complementar de cobertura por role e exclusão de contas está em [account-deletion.md](account-deletion.md), incluindo os ajustes posteriores no fluxo de clientes e pendências do endpoint staff legado.

A evolução de limite simultâneo owner por plano, seus testes de concorrência e sua revisão específica estão em [owner-sessions.md](owner-sessions.md).

Os itens abaixo foram confirmados por leitura do código e corrigidos. As linhas indicam a implementação corrigida nesta revisão. Os testes de regressão ficam em `backend/test/integration/authentication_sessions_test.rb`, `backend/test/models/login_protection_test.rb` e `frontend/tests/authentication.test.mjs`.

## Achados e correções

| Severidade | Arquivo e linha | Evidência e impacto anterior | Correção aplicada |
| --- | --- | --- | --- |
| Alta | `backend/app/controllers/customer_auth/sessions_controller.rb:167`; `backend/app/models/core/customer.rb:44` | O logout e a troca de senha apagavam o refresh token, mas o access JWT permanecia aceito por até 15 minutos. | Access e refresh tokens agora incluem um identificador conferido com o estado da sessão no banco. Logout e troca de senha invalidam esse estado imediatamente. |
| Alta | `backend/app/models/concerns/login_protection.rb:31`; `backend/app/controllers/devise_users/sessions_controller.rb:19` | Bastava compartilhar um IP registrado para ser considerado confiável. O histórico de auditoria também era usado para dispensar OTP, permitindo que outro aparelho na mesma rede evitasse a verificação. | Confiança exige IP observado pelo servidor e identificador de dispositivo registrado. O primeiro login fica marcado no banco; acessos seguintes de IP ou dispositivo desconhecido exigem OTP. Não há exceção para LAN. |
| Alta | `backend/app/models/concerns/login_protection.rb:60` | OTP não tinha limite próprio de erros nem consumo atômico, permitindo tentativas repetidas e condições de corrida. | Limite de cinco erros, expiração em dez minutos, comparação segura e consumo único sob lock. O código fica vinculado à conta, IP e dispositivo. |
| Média | `backend/app/models/concerns/login_protection.rb:48`; `backend/config/application.rb:32` | OTP era armazenado em texto puro e impresso explicitamente em desenvolvimento. Jobs de e-mail também podiam registrar o código nos argumentos. | O campo do model guarda HMAC, logs explícitos de OTP foram removidos e argumentos de jobs deixaram de ser registrados. Reenvios têm intervalo mínimo de 60 segundos. |
| Alta | `frontend/src/services/api.ts:43`; `frontend/src/services/api.ts:149`; `frontend/src/services/staffAuth.ts:10` | Respostas de rotação ou refresh ainda em andamento podiam repor o token depois da limpeza do logout. | Logout captura as credenciais e limpa o estado local imediatamente. Respostas e retries verificam a versão da sessão; respostas de sessões encerradas não restauram tokens. |
| Média | `frontend/src/services/api.ts:43` | Cada chamada podia iniciar um refresh antecipado independente; rotação concorrente podia causar perda de sessão. | As chamadas compartilham uma única promessa de refresh por sessão. Uma requisição antiga também não pode ser repetida usando outra conta. |
| Média | `backend/app/controllers/customer_auth/sessions_controller.rb:135` | O refresh comparava e substituía o hash sem lock. Uma tentativa com token antigo podia apagar um refresh mais recente. | Comparação, verificação de sessão/expiração e rotação ocorrem sob lock. Token obsoleto é rejeitado sem revogar a sessão mais recente. |
| Média | `backend/app/controllers/customer_auth/sessions_controller.rb:167` | Logout por cookie não verificava CSRF nem o estabelecimento indicado pela rota. | Logout exige Bearer válido para aquela conta/estabelecimento ou cookie com CSRF válido. A consulta por cliente parte do estabelecimento autorizado. |
| Alta | `backend/app/models/core/user.rb:73`; `backend/app/controllers/application_controller.rb:91`; `backend/app/controllers/application_controller.rb:147` | Tokens já emitidos não verificavam o estado ativo do usuário; vínculos desativados ainda podiam participar da autorização do estabelecimento. | O servidor verifica conta ativa, role de staff e estabelecimento/vínculo ativo em cada acesso protegido. Permissões Vue permanecem apenas controles de interface. |
| Média | `backend/app/controllers/account/users_controller.rb:274`; `backend/app/controllers/devise_users/sessions_controller.rb:209` | Metadados e revogação de sessões regravavam o mapa inteiro de tokens sem lock, podendo sobrescrever mudanças concorrentes. | Atualização, logout e revogação usam lock e o estado atual da conta. Consultas continuam limitadas ao usuário autenticado. |
| Média | `backend/app/controllers/concerns/login_input.rb:10`; `backend/config/initializers/rack_attack.rb:5` | Tipos/tamanhos de entrada não eram conferidos consistentemente. O throttle por e-mail consultava `req.params`, que não interpreta o JSON enviado pelo Vue. O responder também tratava `Rack::Request` como Hash. | Tipos, e-mail, tamanhos, OTP e dispositivo são validados antes da autenticação. Rate limiting lê JSON limitado, restaura o stream, usa e-mail normalizado com hash e devolve 429 corretamente. Staff e clientes têm limites por IP e por conta. |
| Média | `backend/app/services/customer_json_web_token.rb:58` | JWT validava assinatura e tipo, mas não exigia emissor, audiência nem todas as claims obrigatórias. | Algoritmo, emissor `easyslotting`, audiência `customer`, expiração, tipo, IDs e identificador de sessão são verificados. Bearer tem formato estrito. |
| Média | `backend/app/controllers/application_controller.rb:14`; `backend/app/controllers/application_controller.rb:21` | Devise Token Auth aceita credenciais por query string, que pode vazar em histórico/logs. Respostas sensíveis nem sempre proibiam cache. | Credenciais de sessão em URL são rejeitadas e respostas autenticadas/de autenticação usam `Cache-Control: no-store`. Links de redefinição continuam usando o parâmetro próprio de recuperação. |
| Média | `frontend/src/views/admin/Layout/AdminLayout.vue:276`; `frontend/src/views/customer/Layout/CustomerLayout.vue:238` | As telas de troca obrigatória não coletavam a senha atual exigida pelo backend, e não encerravam imediatamente a sessão após a troca. | Formulários coletam/enviam senha atual e encaminham para novo login após a revogação. Atualizar o perfil também deixou de reiniciar a expiração local ou descartar o CSRF. |
| Média | `backend/app/controllers/devise_users/registrations_controller.rb:39`; `backend/app/controllers/customer_auth/registrations_controller.rb:20` | Cadastro podia emitir tokens fora do fluxo explícito de login/OTP. O onboarding empresarial gravava estado de autenticação vazio no navegador. | Cadastro cria a conta e encaminha para login. Tokens/dispositivos só são atribuídos na autenticação. Payload não seleciona role privilegiada. |

## Categorias verificadas

- **Autorização no servidor:** conta ativa, role, membership e tenant são verificados no Rails. Testes cobrem role de cliente rejeitada no login staff, conta desativada e vínculo desativado. Alterar dados locais do Vue não concede permissão no servidor.
- **IDOR:** revogação de sessões parte de `current_user`; refresh/logout de clientes são limitados à conta, sessão e estabelecimento. Testes negam revogação de sessão de outro usuário e refresh/logout por outro slug.
- **Segredos:** não foram encontrados segredos/API keys hardcoded nos arquivos de autenticação inspecionados nem nos padrões pesquisados do bundle gerado. OTP, hashes e identificador de sessão não são serializados no JSON de conta. Arquivos `.env` não foram inspecionados, conforme solicitado. A busca por padrões e o Brakeman não provam ausência de qualquer segredo ou vulnerabilidade.
- **Entrada e uploads:** login tem validação no servidor, sem alterar destrutivamente senhas. No upload autenticado de avatar, `backend/app/controllers/customer/profile_controller.rb:355` já limita tamanho, identifica MIME com Marcel, deriva a extensão do MIME, gera nome no servidor e reencoda com Vips com limite de dimensões; não foi identificada nova falha nesse fluxo. O upload utiliza `current_customer`, sem aceitar ID do cliente como autoridade.
- **Privacidade e boas práticas:** dados de cliente no navegador são reduzidos aos usados na interface; credenciais não acompanham pedidos públicos de login/cadastro; respostas sensíveis não são armazenadas em cache; OTP não é registrado nos logs explícitos ou nos argumentos dos jobs. Esta revisão técnica não equivale a certificação de conformidade LGPD.

Referências de revisão: [OWASP — gestão de sessões](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html) e [documentação do Rack::Attack](https://github.com/rack/rack-attack). O comportamento de Devise Token Auth e JWT também foi conferido no código das gems instaladas no projeto.

## Validação realizada

- Migration `20261009120000_harden_login_sessions` aplicada somente ao banco PostgreSQL de **testes** (`app_test`).
- Rails: **44 testes, 156 assertions, nenhuma falha ou erro**, executando os testes novos e as suites de segurança/isolamento de estabelecimento existentes.
- Frontend: **7 testes aprovados**, cobrindo limpeza de logout, respostas atrasadas, rotação em lote, refresh concorrente, troca de conta e preservação de expiração/CSRF ao atualizar o perfil.
- `npm run build`: type-check e build Vite aprovados. Vite mantém aviso de chunk grande, sem impedir o build.
- Brakeman: **zero alertas de segurança**, com relatório JSON gerado em `backend/tmp/authentication-brakeman.json` (arquivo local ignorado). Ruby Windows emitiu aviso de `Process.fork`; o relatório foi gerado e inspecionado.
- `git diff --check` sem erros. Não houve teste ponta a ponta na VM ou envio de e-mails reais.

## Publicação e comportamento esperado

1. Publicar frontend e backend juntos, incluindo a migration e o schema. O serviço `prepare` do Compose de staging executa `rails db:prepare` antes de web/worker. A migration não apaga contas nem estabelecimentos.
2. JWTs antigos de clientes serão rejeitados porque não têm o novo identificador de sessão e usam o emissor anterior. É necessário fazer login novamente após a atualização. OTP pendente anterior é descartado e dispositivos existentes passam novamente por verificação quando necessário.
3. Primeiro login válido registra IP/dispositivo. Nos seguintes, mudança de IP ou dispositivo exige código por e-mail. Entrega de OTP depende do worker e do serviço de e-mail do ambiente.
4. A limitação original de uma sessão de cliente foi substituída por `customer_sessions`, sem teto comercial por conta, com revogação independente. Consulte a [revisão e política por perfil](session-policy.md), que também cobre funcionários pelo plano e super admin único com cinco vagas.
5. O token staff permanece apenas em memória; recarregar completamente a aplicação exige autenticação novamente, conforme o mecanismo já adotado. Clientes usam `sessionStorage` e cookie de refresh HttpOnly.
6. Logout sem conexão limpa o navegador, mas não pode garantir revogação no servidor enquanto a requisição não chegar. Revogação remota é verificada pelos testes quando a API responde.
7. O deploy ainda precisa ser executado para que as correções cheguem à VM. Esta revisão não modificou o ambiente de staging nem constitui garantia de proteção absoluta.
