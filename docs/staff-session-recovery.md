# Recuperação de sessão staff após atualizar a página

Data: 10/10/2026. Perfis: `owner`, `employee` e `super_admin`.
Skills locais aplicadas: autenticação, revisão de segurança e implementação segura.

## Comportamento

Antes, F5 apagava o token em memória e o guard enviava o usuário para o login,
embora o registro no servidor ainda pudesse ocupar uma vaga do plano.
Agora, o Vue recupera a mesma sessão no servidor antes de liberar a rota.
O access token continua fora de `localStorage` e `sessionStorage`.

Não há alteração no protocolo JWT/refresh de clientes, nas quotas ou no OTP.
Owner/funcionário continuam com 1 a 4 vagas por conta conforme a política de plano;
super admin continua com 5. A recuperação preserva `client` e `issued_at`, não
substitui o login com senha e não registra um novo aparelho confiável.

## Login e armazenamento

Somente depois de senha e, quando exigido, OTP válidos:

- O servidor cria um segredo aleatório de 256 bits e um CSRF independente.
- `users.tokens[client]` guarda `recovery_digest` e `recovery_csrf_digest` em SHA256.
- O cookie `staff_session_recovery` contém user ID, client e o segredo, em JSON
  criptografado/autenticado pelo Rails. O segredo não vai para o JSON da resposta.
- O cookie é HttpOnly, SameSite Strict, sem Domain, restrito a `/api/devise_users`
  e Secure em HTTPS ou production. É um cookie de sessão, sem prazo persistente
  adicional. Sua presença não mantém um registro expirado válido.
- O JSON de login entrega `staff_csrf_token`; Vue guarda CSRF, client, uid e perfil
  em `sessionStorage`. O access token DTA permanece na memória.

Os hashes são preservados na rotação normal do DTA. Não são incluídos na listagem
de aparelhos. Não introduzimos chaves privadas em componentes nem lemos `.env`
reais durante a revisão.

## Contrato de recuperação

`POST /api/devise_users/restore_session`, corpo vazio, cookies habilitados:

```text
X-Staff-Client: identificador da sessão na aba
X-Staff-Uid: uid da conta na aba
X-CSRF-Token: CSRF recebido no login
```

Esses headers não são autoridade para escolher outra conta. O servidor busca
somente o usuário identificado pelo cookie criptografado e compara client/uid,
segredo e CSRF com a sessão daquele usuário. O ID ou role do payload não autoriza.
Valores de headers têm limites de comprimento; segredos/CSRF têm formato exato.

Sob lock, verifica role staff, conta ativa/desbloqueada, expiração e quota atuais,
compara hashes em tempo constante e emite um novo access token **no mesmo client**.
Sessões excedentes/expiradas são podadas definitivamente, inclusive se a recuperação
for recusada; um upgrade posterior não as ressuscita.

Respostas:

| Status | Significado |
| --- | --- |
| 200 | Headers DTA `access-token`, `client`, `uid`, `expiry` e JSON `data` atualizado |
| 401 | Cookie inválido/ausente, identidade divergente, sessão expirada/revogada ou conta não permitida |
| 403 | CSRF ausente/incorreto para a sessão identificada |
| 429 | Mais de 20 recuperações por minuto no mesmo IP; demais limitadores continuam válidos |

As respostas usam `no-store`. Falhas de recuperação não apagam o cookie de outra
identidade compartilhada por abas. Não habilitamos a autenticação automática por
cookie da gem DTA; as demais APIs continuam exigindo seus headers e permissões.

## Vue, logout e respostas atrasadas

O guard assíncrono aguarda recuperação em `/`, `/admin`, `/super-admin` e
`/sistema/login`. Na landing page, isso acontece antes de renderizar os botões:
sessão válida mostra “Minha conta” e “Sair”, inclusive após F5, sem redirecionar
automaticamente ao painel. Visitantes, sessões recusadas e falhas de rede mantêm
a home pública com “Entrar” e “Criar conta”, sem autenticar por metadados locais.
Chamadas concorrentes compartilham a mesma promessa por versão
local da sessão. O perfil vem da resposta do servidor antes da decisão de navegação.
O frontend não substitui a autorização Rails.

Logout captura headers/CSRF e limpa memória e storage imediatamente. O servidor
revoga o client. Se o token de memória já sumiu, o logout aceita o cookie somente
com client/uid e CSRF correspondentes. Um cookie de outra conta nunca é usado
para deslogar essa outra conta. A exclusão do cookie usa o mesmo path da emissão.

Uma recuperação que chega após logout ou troca de conta é descartada pela versão
local; não repõe credenciais. 401/403 removem referências locais inválidas. Falhas
de rede/5xx não removem o material necessário para tentar novamente, mas também
não liberam uma rota protegida sem autenticação.

Logout, troca/redefinição de senha, revogação manual, desativação, mudança para
role não staff, expiração ou redução de quota continuam impedindo a recuperação.
Excluir um client remove os hashes junto com o token DTA.

## Revisão de segurança

| Severidade | Arquivo e linha | Achado confirmado e correção |
| --- | --- | --- |
| Média | `frontend/src/services/staffAuth.ts:2`; `frontend/src/router/index.ts:282` | Access token só em memória e guard síncrono causavam saída no F5 sem revogação no servidor. Recuperação server-side aguardada antes da rota, sem colocar access token em storage. |
| Média, disponibilidade da sessão | `frontend/src/services/api.ts:12`; `frontend/vite.config.ts:19` | Print de desenvolvimento mostra a página em `172.16.0.2:5173` e recuperação em `localhost:3000` com 401. Misturar esses hosts impede o envio do cookie SameSite Strict. Desenvolvimento passa a usar `/api` na origem da página, com proxy Vite para Rails; override antigo com localhost é ignorado. O endpoint mantém autenticação e CSRF. |
| Baixa, interface inconsistente | `frontend/src/router/index.ts:289` | O guard não recuperava a sessão na rota `/`. Após F5, a landing exibia “Entrar”/“Criar conta”, embora clicar em login recuperasse a sessão e abrisse o painel. A home agora aguarda a mesma validação no servidor; metadados isolados continuam insuficientes para mostrar estado autenticado. |
| Alta, risco da implementação | `backend/app/services/staff_session_recovery.rb:51` | Aceitar somente cookie, ID ou uid permitiria recuperação sem proteção de intenção/identidade. Exige cookie autenticado, segredo e CSRF da mesma sessão; consulta e autorização sob lock. |
| Alta, risco da implementação | `frontend/src/services/api.ts:59` | Resposta de recuperação atrasada poderia repor uma sessão encerrada. Versão local impede restauração após logout/troca de conta. |

As duas linhas de severidade alta descrevem riscos prevenidos nesta implementação, não
vulnerabilidades observadas no código anterior.

- **Autorização:** role, atividade, quota e validade conferidas no servidor;
  nenhuma página Vue decide permissão de API.
- **IDOR:** a recuperação deriva a conta do cookie autenticado, sem aceitar ID
  arbitrário. Divergências de identidade são recusadas; logout de outra aba não
  afeta a conta atual do cookie.
- **Segredos/bundle:** segredo aleatório somente no cookie HttpOnly; hashes no
  banco; nenhum segredo de aplicação adicionado ao bundle. CSRF não é credencial
  suficiente sem o cookie. Arquivos `.env` excluídos da inspeção.
- **Input:** formato e tamanho limitados, consulta parametrizada por ID do cookie,
  comparação segura de hashes e rate limiting. Upload não participa deste fluxo;
  seus validadores não foram alterados.
- **LGPD:** reaproveita o registro existente sem coletar IP, user agent ou outros
  identificadores adicionais neste mecanismo. Logs não recebem segredo/CSRF.

## Publicação, limites e validação

Sem migração ou reset: são campos extras no JSON `users.tokens` já existente.
Publique backend e frontend juntos. Contas logadas antes deste fix precisam de
um novo login para receber o cookie e o CSRF. Não force reset do banco.

### Desenvolvimento por localhost ou IP LAN

O navegador chama `/api` no mesmo host/porta da página. O Vite encaminha a chamada
para `http://127.0.0.1:3000`, sem remover `/api`, mantendo cookies, headers DTA/CSRF
e o IP encaminhado. `VITE_API_URL` só é aplicado no build de produção; um override
antigo com localhost não contorna esse proxy no desenvolvimento. HttpOnly,
SameSite Strict e as exigências de CSRF continuam iguais.

Após atualizar o código:

1. Mantenha Rails na porta 3000 da mesma máquina onde o Vite roda.
2. Pare o Vite com Ctrl+C e execute `npm run dev` na pasta `frontend`.
3. Abra o endereço usado normalmente, faça um novo login e pressione F5.
4. Em Network, a recuperação deve chamar, por exemplo,
   `http://172.16.0.2:5173/api/devise_users/restore_session`, e retornar 200 para
   uma sessão válida. Nenhuma chamada de autenticação do dev deve ir diretamente
   para `localhost:3000` no navegador.

O cookie antigo emitido para localhost não é transferido para o IP; o novo login
emite outro cookie no host correto. Backend em outra máquina exige ajustar o
target do proxy, mantendo `/api` no navegador. Esse dev server é restrito ao
desenvolvimento; staging/produção usam seu próprio proxy HTTPS.

### Prazo e evidência

O prazo continua sendo o da sessão DTA (2 horas renovadas pela rotação). Este fix
não implementa login persistente por vários dias nem modifica o checkbox de
lembrar dispositivo. Nova aba sem metadados/CSRF não recupera automaticamente;
cookies continuam compartilhados entre abas e múltiplas contas no mesmo navegador
não são uma nova funcionalidade. Restaurar abas pelo navegador pode preservar
sessionStorage/cookies de sessão: fechar o navegador não equivale a logout.

Validação executada localmente:

- 65 testes Rails direcionados, 479 assertions, sem falhas/erros/skips:
  recuperação, autenticação/OTP, quotas por plano/perfil e concorrência de sessões.
- 22 testes frontend (`npm test`), incluindo simulação de F5 com novo módulo/memória e o mesmo
  storage, recuperação concorrente, resposta atrasada, CSRF, identidade e logout.
  Também cobrem API relativa em LAN apesar de override legado, refresh de cliente,
  configuração de produção e transporte HTTP real pelo proxy Vite: path,
  headers, Set-Cookie HttpOnly/Strict/sem Domain e rejeição de chamada anônima.
  O teste de transporte usa backend simulado e não substitui o navegador real.
  O guard real é exercitado com router/componentes simulados: home aguarda
  recuperação para owner, funcionário e super admin, permanece pública para
  visitante/perfil local forjado/sessão revogada/falha de rede e respeita logout.
- Build Vite e TypeScript passaram. Aviso já existente de chunk maior que 500 kB.
- Brakeman 8.0.4: zero erros e zero avisos de segurança. O Windows informa que
  fork não é suportado, sem impedir a análise.
- Rails ainda emite avisos preexistentes de gems/DLLs opcionais do VIPS e
  depreciação das rotas DTA para Rails 8.2. Não são falhas deste fix.

Ainda é necessário testar F5, logout e revogação no navegador após publicar na VM,
com HTTPS e cookies reais. Não houve deploy ou execução na VM nesta etapa.
Reverter somente o código devolve o comportamento anterior; os hashes extras são
inertes sem o endpoint e não exigem rollback de schema.

Referências: [OWASP Session Management](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)
e [OWASP CSRF Prevention](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html).
Configuração do proxy: [Vite server.proxy](https://vite.dev/config/server-options#server-proxy).
