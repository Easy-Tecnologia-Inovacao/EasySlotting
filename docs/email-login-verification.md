# Verificação de login por e-mail

Data: 10/10/2026. Escopo: `owner`, `employee`, `super_admin` e `Customer`.
Skills locais aplicadas: autenticação, revisão de segurança e implementação segura.
Complementa o [guia de autenticação](authentication.md) e a [política de sessões](session-policy.md).

## Regra do produto

| Situação | Comportamento nos quatro perfis |
| --- | --- |
| Primeiro login, com senha correta e conta ativa | Exige código enviado ao e-mail da conta |
| Novo login por um IP já reconhecido | Exige senha; não pede código novamente |
| Novo login por IP desconhecido | Exige senha e código por e-mail |
| Outro navegador/aparelho no mesmo IP reconhecido | Não gera desafio somente pela troca de aparelho |
| F5 com uma sessão existente válida | Recupera a sessão; não é um novo login nem reconhece um novo IP |
| Senha errada, conta inativa ou bloqueada | Não libera sessão nem registra confiança no IP |

A decisão de dispensar desafios posteriores usa **somente o IP observado pelo servidor**. Não há lista nova de aparelhos confiáveis, aplicativo autenticador, TOTP nem opção “Em breve”. A opção anterior “Lembrar este dispositivo” foi removida das duas telas porque não corresponde a essa política.

O IP não autentica sozinho: é necessário fornecer a senha em cada novo login. Sessões já emitidas continuam usando os tokens, cookies, prazos e verificações de autorização existentes. Mudar de rede durante uma sessão válida não provoca, por esta alteração, outro desafio; o IP é avaliado ao fazer login.

## Implementação e armazenamento

- `LoginProtection.login_otp_required?` exige desafio se `first_login_at` estiver vazio ou o IP não estiver em `trusted_ips`. A mesma concern atende `User` e `Customer`.
- O endereço vem de `request.remote_ip`. Campos `ip`, `trusted_ips`, `verified`, role ou ID enviados pelo cliente não confirmam o login nem concedem privilégios.
- `trusted_ips` guarda até 30 IPs individuais normalizados com `IPAddr`, sem faixas CIDR. Os mais antigos saem quando a lista ultrapassa o limite; esses IPs voltam a exigir código. Não há prazo automático de confiança.
- Entradas antigas `device:<hash>` não dispensam o código e são descartadas no próximo login concluído. IPs válidos de contas com primeiro login já concluído continuam reconhecidos: não há reconfirmação global de contas existentes.
- O IP e `first_login_at` só são registrados ao concluir a autenticação. Um desafio pendente ou inválido não cria sessão, token, cookie de autenticação nem ocupa vaga do plano.
- Não há alteração de schema, migration ou reset do banco nesta entrega.

`device_token` continua sendo um valor aleatório do navegador, enviado ao pedir e confirmar o código. Ele vincula o desafio à tentativa original e permite que staff substitua a própria sessão do mesmo navegador sem consumir outra vaga. O hash em metadados das sessões mantém essa finalidade; **não é uma lista persistente de confiança de aparelhos**. Clientes continuam com sessões independentes sem teto comercial.

## Contrato e sequência

As rotas permanecem:

```text
POST /api/devise_users/sign_in
POST /api/customer_auth/:slug/sign_in
```

1. A tela envia e-mail, senha e `device_token`.
2. Rails valida entrada, credenciais, conta e acesso. Para clientes, busca a conta dentro do estabelecimento ativo indicado pelo slug.
3. Quando o código é necessário, enfileira `SecurityAlertMailer.login_verification_code` e responde HTTP 200 com `requires_verification: true`, `email_masked` e somente `methods: [{ id: 'email', name: 'Código via E-mail', active: true }]`.
4. A tela abre o modal sem salvar uma sessão. Repete a chamada com as mesmas credenciais, IP e `device_token`, acrescentando `otp_code` como string de seis dígitos.
5. O servidor consome o código válido sob lock, revalida a conta/senha na emissão e cria a sessão conforme os limites existentes. Só o sucesso com credenciais permite salvar a sessão e navegar ao painel.

Se a quota staff estiver cheia, um código correto não concede vagas adicionais: o login retorna 409. A confirmação do código é de uso único, inclusive se uma etapa posterior impedir o login. A conta pode solicitar outro desafio conforme o cooldown.

## Proteções concretas

| Controle | Regra |
| --- | --- |
| Código | Seis dígitos aleatórios, preservando zeros à esquerda |
| Validade | Dez minutos |
| Reenvio | Intervalo mínimo de 60 segundos no servidor |
| Tentativas | Até cinco erros por código; reenviar durante o cooldown não zera erros |
| Persistência | HMAC SHA256; código puro não fica no campo do model |
| Vínculo do HMAC | Classe e ID da conta, código, IP e `device_token` do desafio |
| Consumo | Único, com verificação e limpeza sob lock |
| Mensagem | Código no corpo; assunto genérico sem o código |
| Interface | Somente e-mail, sem sessão antes da confirmação; nova tentativa após erro e bloqueio de envios duplicados durante a requisição |

Permanecem a validação de tipos/tamanhos, filtros de parâmetros sensíveis, rate limiting por IP/conta, bloqueio por falhas de senha, `no-store`, cookies HttpOnly e as proteções de revogação/CSRF dos fluxos existentes. Os timers do modal são limpos ao fechar ou desmontar o componente.

## Revisão de segurança

As linhas abaixo identificam a implementação resultante; a evidência anterior foi conferida no diff da alteração.

| Severidade/contexto | Arquivo e linha | Evidência e impacto anterior | Ajuste |
| --- | --- | --- | --- |
| Média — regra de primeiro acesso | `backend/app/controllers/devise_users/sessions_controller.rb:66`; `backend/app/controllers/customer_auth/sessions_controller.rb:82` | Primeiro login dispensava OTP, portanto conhecer a senha bastava sem confirmar o e-mail. Era a política anterior do produto. | Primeiro login exige código nos quatro perfis antes da emissão de credenciais. |
| Baixa — disponibilidade da interface | `frontend/src/components/LoginVerificationModal.vue:124` | O modal mantinha um `loading` interno sem receber o fim da requisição; código incorreto podia deixar “Verificando...” preso. | Carregamento e reenvio vêm da tela responsável pela chamada e são liberados em `finally`. |
| Baixa — exposição em prévias | `backend/app/mailers/security_alert_mailer.rb:75` | O código aparecia no assunto, ampliando a exposição em notificações e índices de e-mail. Não foi constatado vazamento externo. | Assunto genérico; código somente no corpo. |
| Decisão de produto — risco aceito | `backend/app/models/concerns/login_protection.rb:33` | A regra anterior exigia IP e hash de aparelho conhecidos, após dispensar o primeiro login. | Confiança posterior passa a ser somente por IP, conforme solicitado. Outro aparelho no mesmo IP reconhecido não gera desafio. |

Categorias conferidas:

- **Autorização:** senha, conta ativa e role permitida são verificadas no servidor; dados locais do Vue não autorizam login. Quotas e permissões continuam independentes do IP reconhecido.
- **IDOR/tenant:** desafios de clientes pertencem à conta do estabelecimento da rota. Testes usam o mesmo e-mail em dois estabelecimentos e negam uso do código da outra conta. Revogação e exclusão de clientes também estão na suíte direcionada.
- **Segredos:** códigos não são gravados em texto puro no model nem no assunto. O filtro de parâmetros e `active_job.log_arguments = false` permanecem. Arquivos `.env` reais não foram inspecionados; não houve auditoria dos logs de provedores de e-mail.
- **Entrada:** permanecem os formatos estritos de OTP e `device_token`; IPs inválidos e faixas CIDR não viram confiança. Testes enviam flags e IP forjados no payload sem dispensar a confirmação.
- **Privacidade:** IPs continuam limitados por conta. Metadados de sessão servem ao gerenciamento/revogação, não ao cadastro de aparelhos confiáveis. O texto de segurança do login foi ajustado para descrever controles existentes, sem prometer criptografia de ponta a ponta ou logs invioláveis. Esta revisão não certifica conformidade LGPD.

## Operação e limites

Publicar frontend e backend juntos. Em desenvolvimento, `letter_opener` captura a mensagem localmente em vez de entregá-la à caixa real. Staging usa o serviço de e-mail configurado, normalmente Mailpit; produção exige SMTP válido. O envio é assíncrono: mantenha o worker e o serviço de e-mail funcionando. Falha de entrega não autoriza dispensar o desafio nem liberar a sessão.

A configuração dos proxies deve preservar o IP e restringir proxies confiáveis. Se todos os acessos chegarem ao Rails com o mesmo IP de proxy, essa política deixará de distinguir as redes dos usuários. A suíte não valida a configuração efetivamente instalada na VM.

NAT, Wi-Fi e CGNAT podem fazer pessoas/aparelhos distintos compartilharem o mesmo IP público. IP reconhecido é um sinal de contexto, não um segundo fator independente. E-mail OTP depende da segurança da caixa de e-mail e é suscetível a phishing. Essas limitações são descritas na [referência OWASP sobre MFA e IP de origem](https://cheatsheetseries.owasp.org/cheatsheets/Multifactor_Authentication_Cheat_Sheet.html). A [referência OWASP de autenticação adaptativa](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html#adaptive-or-risk-based-authentication) orienta tratar IP e características do navegador como sinais de risco, mantendo autenticação ou sessão válida para acesso privado.

## Validação realizada

- Rails: **98 testes, 1.210 assertions, nenhuma falha, erro ou skip**, na suíte direcionada de autenticação, OTP, recuperação staff, quotas owner/equipe, sessões independentes e exclusão de clientes, executada somente no banco de testes. Permanecem avisos locais de módulos opcionais Vips e deprecações das rotas para Rails 8.2.
- Frontend: **25 testes aprovados**, incluindo os scripts reais dos SFCs de login/modal, tentativas após erro, reenvio e ausência de sessão antes da confirmação; os novos testes não usam um navegador real.
- `npm run build`: TypeScript e Vite aprovados; permanece o aviso de bundle acima de 500 kB.
- Brakeman 8.0.4: **zero alertas e zero erros**, relatório local em `tmp/email-verification-brakeman.json`. O Ruby Windows avisou que `Process.fork` não está disponível, mas o relatório foi gerado.
- `git diff --check` aprovado, sem erros de whitespace.
- Os testes de e-mail executam o job com o adaptador de testes, renderizam a mensagem e verificam destinatário, corpo e assunto. Não houve entrega externa por SMTP, teste ponta a ponta na VM ou deploy nesta tarefa.

O banco de desenvolvimento não foi resetado. Contas e sessões existentes não foram apagadas.
