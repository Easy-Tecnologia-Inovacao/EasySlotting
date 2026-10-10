# Revisão do dashboard do super admin

Data: 10/10/2026. Base da revisão inicial: commit `b53b624`. As correções posteriores estão descritas abaixo; os achados e suas linhas originais foram preservados como histórico. Skills locais aplicadas: `easyslotting-security-review` e critérios de `easyslotting-secure-feature`.

## Correções implementadas após a revisão

| Achado | Correção |
| --- | --- |
| D01 | Removido o logging do objeto Axios. A interface usa mensagens locais, sem renderizar erros internos enviados pelo servidor. Testes usam credenciais fictícias para verificar que nada chega ao console. |
| D02 | Substituídos receita e tendência de receita por valor bruto contratado e tendência de valores contratados. A interface explica que não são recebimentos. A soma inclui contratos não pendentes pelo mês de cadastro, independentemente de posterior expiração/cancelamento/inadimplência. |
| D03 | Card e distribuição por plano usam somente o último contrato iniciado, não pendente, de cada estabelecimento ativo. Ele precisa estar vigente e com status active/canceled. Um contrato substituído não reaparece quando o mais novo está inadimplente ou vencido. Cancelamento conserva vigência até o último dia contratado. |
| D04 | Removida a lista de estabelecimentos e os detalhes livres dos cancelamentos da API e da tabela. A consulta seleciona apenas as propriedades exibidas. Novos logs de cancelamento não duplicam o texto livre. |
| D05 | Estados separados de carregamento, falha e sucesso. Falhas escondem indicadores, gráficos e tabela, exibem alerta acessível e botão de nova tentativa. Respostas sem o contrato esperado também são tratadas como falha. Requisições simultâneas são bloqueadas. |
| D06 | Um único instante no servidor define o dia, os meses e `generated_at`. O horário só aparece após sucesso. Os períodos são intervalos início inclusivo/fim exclusivo no fuso configurado no Rails, atualmente Brasília. |
| D07 | Removida a lista ilimitada; tendência agrupada numa única soma mensal SQL, em vez de seis consultas. Distribuição vigente agrupada por plano, sem consulta por estabelecimento. Adicionado rate limit Rails de 30/minuto pelo ID do super admin autenticado; prefixo super admin incluído no throttle administrativo por IP de 45/minuto. Respostas 429 trazem Retry-After. Mantido no-store. |

### Contrato e publicação

- `GET /api/super_admin/dashboard` continua exclusivo de super admin, sem parâmetros de tenant ou role como autoridade.
- Novo campo `generated_at`, formato ISO 8601 com fuso.
- `summary.monthly_revenue` foi substituído por `summary.monthly_contracted_value`.
- `charts.revenue_trend` foi substituído por `charts.contracted_value_trend`, com itens `{ month: "MM/YYYY", value: número }`.
- Removidos `establishments` e `recent_cancellations[].details`.
- `active_subscriptions_count` mantém o identificador, mas agora representa contratos atuais vigentes, conforme o rótulo na tela. `canceled_subscriptions_count` continua sendo total histórico por status, não cancelamentos somente do mês.
- Valor contratado é uma métrica operacional bruta: inclui contratos futuros já cadastrados e trocas de plano; não deduz pagamentos, estornos ou contratos substituídos. A interface informa isso. Nenhuma confirmação de pagamento foi criada artificialmente.
- Sem migração de banco. Backend e frontend devem ser publicados juntos devido às alterações de campos; reinicie o backend para carregar os novos limites.
- Rate limit por conta usa o cache configurado do Rails (Solid Cache em produção). Cache indisponível ou substituído por NullStore não oferece a mesma garantia. Teste local usa MemoryStore para comprovar contador e identidade; não foi simulado ambiente com múltiplos servidores.
- Nenhum índice novo foi criado sem medição. O custo das contagens históricas ainda cresce com o volume; validar EXPLAIN/latência com dados representativos antes de escolher índices/cache interno.
- O instante retornado identifica a geração da resposta; não promete snapshot transacional único de todas as contagens quando há gravações concorrentes.

### Privacidade e limitações

Detalhes originais de cancelamento permanecem no registro de origem para não destruir histórico sem uma política aprovada. Eles não são entregues ao dashboard. Logs antigos que já continham detalhes não foram apagados. Definir finalidade, base legal, prazo de retenção e eventual eliminação desse acervo continua sendo uma decisão de governança; o código não permite concluir conformidade LGPD integral. Os dados agregados não exigem adicionar um consentimento genérico ao painel.

### Verificação das correções

- Rails: **7 testes, 63 assertions**, sem falhas/erros, incluindo autenticação, roles forjadas, Customer JWT, no-store, vigência, substituição, contrato pendente, fronteira mensal de Brasília, dados minimizados, limitação por identidade autenticada e auditoria sem texto livre.
- Frontend: **32 testes aprovados**, incluindo falha após sucesso, retry, resposta incompatível, 429, requisições concorrentes e ausência de logging de credenciais.
- Build TypeScript/Vite aprovado; permanece aviso de chunks acima de 500 kB.
- Brakeman após as alterações: **zero alertas e zero erros**. `git diff --check` aprovado.
- Sem teste visual no navegador, alteração de banco real, commit, push ou deploy nesta etapa.

## Histórico da revisão inicial

Escopo: rota Vue `/super-admin/dashboard`, componente, layout, service Axios, rota Rails `GET /api/super_admin/dashboard`, autenticação/autorização herdadas, models de contratos/cancelamentos, origem dos indicadores e limitações de requisições. Revisão de código e testes locais; não houve teste no navegador, ataque ao servidor da VM ou alteração de dados reais.

## Conclusão

O endpoint exige super admin no servidor. Os testes não encontraram bypass por usuário anônimo, owner, funcionário ou role forjada na requisição. Entretanto, há problemas confirmados de lógica, minimização e tratamento de erros, além de um risco de exposição de credenciais no console. Não se deve interpretar o resultado como certificação OWASP ou conformidade jurídica integral com a LGPD.

## Achados

### D01 — Média: objeto de erro pode levar credenciais ao console

- **Arquivo/linha:** `frontend/src/views/super-admin/DashboardPage/SuperAdminDashboardPage.vue:239`.
- **Evidência:** `console.error` recebe o objeto completo do erro Axios. O service acrescenta `access-token`, `client` e `uid` à requisição (`frontend/src/services/api.ts:140`). O diagnóstico executou o script real com uma falha e confirmou que o objeto com um token fictício chega ao logger.
- **Impacto:** quem consultar/copiar o console, ou uma futura integração que capture console, pode receber credenciais. Não foi demonstrado envio atual a um serviço externo nem vazamento de token real.
- **Correção:** remover o objeto bruto; registrar somente código/status e identificador de correlação permitido. Nunca serializar `config.headers`, request ou response inteiros. Testar explicitamente a ausência de tokens no logger.

### D02 — Média, integridade: “receita” não representa pagamentos confirmados

- **Arquivo/linha:** `backend/app/controllers/super_admin/dashboard_controller.rb:19` e `:25`; origem em `backend/app/controllers/account/subscriptions_controller.rb:31` e `:36`.
- **Evidência:** a soma considera `price_paid`, status active/canceled e mês de `created_at`. A contratação grava esse preço e ativa o contrato sem verificar pagamento de um provedor. Um contrato futuro criado hoje aumentou o total e o gráfico do mês em R$ 50 no teste.
- **Impacto:** indicadores podem ser interpretados como dinheiro recebido sem que haja liquidação. Alterar o status de um contrato antigo também muda retrospectivamente o total exibido; contratos anuais entram integralmente no mês de cadastro. Isso é uma métrica de contratos, não uma contabilidade de caixa ou competência.
- **Correção:** enquanto não existir pagamento confirmado, renomear a métrica para valor contratado, explicando sua base temporal. Para receita recebida, usar registros de transações confirmadas, data de liquidação e tratamento de estornos. Definir caixa ou competência antes de implementar o cálculo; não criar confirmação fictícia de pagamento.

### D03 — Média, lógica: contagem de ativas ignora vigência e substituição

- **Arquivo/linha:** `backend/app/controllers/super_admin/dashboard_controller.rb:8`; regra existente em `backend/app/models/financial/subscription.rb:12`.
- **Evidência:** a contagem filtra somente `status = active`. No teste, um contrato vencido e outro com início futuro resultaram em duas assinaturas “ativas”. A regra de acesso usa o contrato iniciado mais recente e verifica a vigência, incluindo cancelados ainda disponíveis.
- **Impacto:** o painel não reflete necessariamente empresas com benefício atual. Um contrato substituído também pode gerar ambiguidade conforme seu status. Não foi identificado bypass de sessões por esse cálculo: o dashboard é somente leitura.
- **Correção:** definir se o card representa status cadastral, contratos vigentes ou empresas com benefício e rotular claramente. Para benefício vigente, reutilizar a semântica do contrato atual por estabelecimento, sem somar contratos substituídos e sem consultas N+1.

### D04 — Baixa, privacidade: carga desnecessária e texto livre no resumo

- **Arquivo/linha:** `backend/app/controllers/super_admin/dashboard_controller.rb:57`, `:64` e `:85`.
- **Evidência:** a API envia todos os estabelecimentos com ID/nome/slug, mas o componente não lê esse campo. Também envia detalhes integrais dos oito últimos cancelamentos. O teste confirmou que texto contendo contato fictício chega sem redução ao resumo. O model remove HTML e limita a 500 caracteres; isso não anonimiza dados pessoais.
- **Impacto:** aumenta a quantidade de informação entregue ao navegador sem necessidade demonstrada. Texto livre pode conter dados pessoais. O destinatário é autorizado; não foi identificado acesso por outra role nem demonstrada infração legal por esse fato isolado.
- **Correção:** remover a lista não usada. Priorizar motivos agregados no dashboard; disponibilizar detalhes em fluxo específico, com finalidade, acesso e retenção definidos. Orientar o preenchimento para evitar dados pessoais desnecessários e revisar a cópia de detalhes em auditoria (`backend/app/controllers/account/subscriptions_controller.rb:125`). Não exigir consentimento genérico como solução automática: a base legal precisa corresponder à finalidade.

### D05 — Média, confiabilidade: erro de carga se parece com resultado vazio

- **Arquivo/linha:** `frontend/src/views/super-admin/DashboardPage/SuperAdminDashboardPage.vue:32`, `:179`, `:212` e `:242`.
- **Evidência:** os indicadores começam em zero; o `finally` remove loading mesmo após erro, e o `v-else` renderiza cards, gráficos e “Nenhum cancelamento registrado”. O diagnóstico do script confirmou zero/array vazio e mensagem de erro simultâneos após falha.
- **Impacto:** uma indisponibilidade pode ser interpretada como ausência de clientes, receita ou cancelamentos. A mensagem aparece depois dos indicadores, podendo ficar fora da área visível.
- **Correção:** estados distintos de carregamento, sucesso e falha; exibir erro com `role="alert"` e opção de tentar novamente antes de renderizar métricas. Se mantiver dados anteriores, marcar explicitamente que estão desatualizados.

### D06 — Baixa: horário exibido não é o instante dos dados

- **Arquivo/linha:** `frontend/src/views/super-admin/DashboardPage/SuperAdminDashboardPage.vue:20`; `backend/app/controllers/super_admin/dashboard_controller.rb:25`.
- **Evidência:** “Atualizado em” usa `new Date()` durante renderização, inclusive após erro, sem registrar sucesso da carga. Não há atualização automática. O backend lê o relógio várias vezes ao compor períodos; uma execução na virada do mês pode usar limites inconsistentes.
- **Impacto:** falsa impressão de atualização contínua e possível divergência entre card e gráfico na virada de período. A divergência de virada é uma hipótese derivada do código, não reproduzida no teste.
- **Correção:** capturar um instante único no servidor e retornar `generated_at`; só atualizar a marca da tela após resposta bem-sucedida. Usar intervalos fechados no início e abertos no fim, com fuso definido e teste de fronteira mensal.

### D07 — Baixa, escalabilidade: resposta sem limite de estabelecimentos

- **Arquivo/linha:** `backend/app/controllers/super_admin/dashboard_controller.rb:64`; `backend/config/initializers/rack_attack.rb:20` e `:92`.
- **Evidência:** carrega e serializa a lista inteira, junto a várias contagens globais e seis somas mensais. O throttle genérico de 100/minuto/IP existe, mas as regras administrativas específicas não correspondem ao prefixo `/api/super_admin/`.
- **Impacto:** custo cresce com o banco e cada recarga repete agregações. Não foi reproduzido DoS ou medida latência em volume de produção; o acesso continua restrito ao super admin.
- **Correção:** retirar a lista não usada, agrupar a tendência mensal em consulta única, medir plano de execução antes de criar índices, e avaliar limite específico por principal autenticado ou cache interno curto. A resposta HTTP sensível deve continuar `no-store`. Não usar UID arbitrário de header como identidade autenticada.

## Categorias verificadas sem falha confirmada no escopo

- **Autorização/IDOR:** autenticação e `require_super_admin!` precedem as consultas. O dashboard é global por finalidade; não depende de ID de tenant enviado pelo navegador. Guard Vue é adicional, não autoridade. Testes: anônimo 401; owner/funcionário 403 mesmo com role e user_id forjados; super admin 200. Customer JWT e sessão expirada não foram retestados especificamente nesta revisão.
- **Cache:** resposta autenticada apresentou `Cache-Control: no-store` no teste. Configuração efetiva de proxies/CDN não foi inspecionada em execução.
- **Injeção/XSS:** SQL fixo e parâmetros temporais vinculados; não há SQL montado a partir de entrada. Texto é interpolado pelo Vue, sem `v-html`; cancelamento tem sanitização e limite no model. Nenhum problema confirmado nesse caminho.
- **Segredos hardcoded:** nenhum encontrado nos arquivos do dashboard/service revisados. Não foram abertos `.env` reais. Não foi realizada varredura forense completa do histórico Git ou bundle de produção.
- **Entrada/strong parameters:** GET sem parâmetros de escrita ou upload. Strong parameters não são necessários para uma ação sem atribuição de campos. Não há upload neste fluxo.
- **LGPD:** agregações reduzem exposição individual; autenticação, acesso restrito e no-store são controles existentes. Necessidade, retenção, base legal, informação ao titular e governança exigem avaliação além do código. Não foi encontrado pedido de consentimento indevido neste dashboard.

## Evidência executada

- Diagnóstico Rails isolado no banco de testes: **4 testes, 16 assertions**, sem falhas/erros. Testes caracterizam o comportamento atual; não significam que os problemas foram corrigidos.
- Diagnóstico do script Vue real: **6 verificações**, confirmando o estado após falha e a passagem de credenciais fictícias ao logger.
- Brakeman: **zero alertas e zero erros**. O scanner não detecta automaticamente os problemas de negócio descritos.
- Scripts e logs de diagnóstico ficam em `tmp/`, ignorado pelo Git. Nenhum token real foi impresso. Sem alteração no código da aplicação, commit, push ou deploy.

## Ordem recomendada

1. Remover logging bruto e separar falha de resultado vazio.
2. Corrigir semântica e rótulos de receita e assinaturas vigentes.
3. Reduzir a resposta e definir o tratamento dos detalhes de cancelamento.
4. Estabilizar instante dos dados e otimizar consultas com medições.

## Referências primárias

- [OWASP: exposição excessiva de dados](https://owasp.org/wstg/latest/4-Web_Application_Security_Testing/12-API_Testing/03-Excessive_Data_Exposure/) — orienta comparar os campos retornados com os necessários ao consumidor.
- [OWASP API4: consumo de recursos](https://api-security.owasp.org/editions/2023/en/0xa4-unrestricted-resource-consumption/) — referência para limites e dimensionamento; a severidade aqui considera o acesso restrito e o throttle existente.
- [LGPD, texto oficial](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm) — art. 6º, necessidade e segurança; art. 46, medidas técnicas e administrativas. O relatório faz uma revisão técnica, não um parecer jurídico.
