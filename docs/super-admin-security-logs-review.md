# Revisão de Logs de Segurança

Data: 10/10/2026. Escopo: `/super-admin/logs-seguranca`, listagem e resumo Rails, autorização, serialização, filtros e consumo Vue. Aplicada a skill local `easyslotting-security-review`.

## Correções implementadas após a revisão

Os sete achados abaixo registram o comportamento anterior. Foram corrigidos na implementação e receberam testes de regressão:

- Listagem com campos explicitamente permitidos. `details`, `email_attempted` e `reason` deixam de ser enviados. Localização aceita apenas cidade, região e país como textos limitados; detalhes históricos malformados não quebram a consulta.
- Parâmetros escalares validados: página de 1 a 500, tamanho de 1 a 200, IDs positivos dentro de bigint, datas ISO válidas e intervalo ordenado. Valores inválidos retornam 422. Resultados ordenados por data e ID; quando há mais de 500 páginas, `pagination.truncated` orienta refinar filtros. O total continua refletindo todos os resultados.
- Catálogo de ações fornecido pelo backend ao frontend. O filtro de senha aceita tanto `password_change` quanto `password_changed` e pesquisa os dois nomes históricos. Revogações e `staff_session_limit_reached` também têm opções próprias. Eventos fora do catálogo continuam visíveis em “Todas”, mas filtros desconhecidos são rejeitados.
- Interface diferencia falha, carregamento e lista vazia, apaga resultados anteriores ao recarregar, mostra indicadores desconhecidos como travessão e permite repetir consultas. Não registra objetos de erro Axios no console.
- Controle de versão independente para listagem, resumo e opções. Respostas antigas ou posteriores à desmontagem são ignoradas. Aplicar filtros reinicia na página 1; paginação usa os filtros efetivamente aplicados.
- Novo GET `/api/super_admin/audit_logs/filter_options`, protegido por autenticação e role. Recebe `q` opcional de até 100 caracteres; retorna até 50 estabelecimentos, somente ID/nome, `has_more` e catálogo de ações. Busca trata `%` e `_` literalmente. A tela permite refinar a busca pelo nome e preserva a opção selecionada.
- Resumo contém somente `generated_at` e os três indicadores consumidos. Contagem distinta de IPs ocorre no banco; IPs, rankings e logs duplicados deixam de ser enviados. Cache de dois minutos usa chave v2 para não reutilizar o contrato antigo.

### Publicação e compatibilidade

Publicar backend e frontend juntos. Não há migração, alteração de registros existentes nem reset do banco. Consumidores externos que utilizem os campos removidos precisam adaptar-se ao contrato reduzido. A interface informa a data do resumo e o limite de consulta; acesso global continua exclusivo do super admin.

### Evidências da correção

- `backend/test/integration/security_logs_test.rb` e testes existentes de AuditLog: **10 testes, 76 assertivas, zero falhas**.
- `frontend/tests/security-logs.test.mjs`: **7 testes, zero falhas**, incluindo respostas fora de ordem, desmontagem, falha com credenciais sintéticas, resposta malformada e recuperação.
- Build Vite e verificação de tipos executados; aviso de bundle acima de 500 kB permanece.
- Brakeman: **zero erros e zero alertas de segurança**. Isso não é garantia de ausência de vulnerabilidades.
- Reinspeção de autorização, serialização, consultas parametrizadas e saída Vue nos arquivos alterados. Não houve validação visual na VM nem teste de carga. Avisos locais de VIPS e deprecações Rails permanecem fora deste escopo.

## Achados

### 1. Média — contrato de saída permite detalhes arbitrários

Referência: `backend/app/controllers/super_admin/audit_logs_controller.rb:142`.

O serializer remove apenas algumas chaves no primeiro nível e retorna o restante de `details`. Um teste com dados exclusivamente sintéticos confirmou a devolução de `nested.password` e `otp_code`, embora `password` no primeiro nível seja removido. A tela nem utiliza `details`, `email_attempted` ou `reason`.

Impacto: campos pessoais ou segredos adicionados por produtores futuros podem chegar ao navegador do administrador. Não foi demonstrada existência de credenciais reais nesses registros nem acesso público aos dados.

Correção: definir contrato explícito de campos necessários, tipos e limites de comprimento; evitar retornar o objeto genérico. Aplicar minimização também na gravação dos eventos.

### 2. Média — paginação não valida tipo dos parâmetros

Referência: `backend/app/controllers/super_admin/audit_logs_controller.rb:47`.

`page: ['1']` reproduziu `NoMethodError` em `.to_i`, em vez de resposta de validação. O mesmo padrão existe em `per_page`. Há teto de 200 itens, mas não limite explícito para o deslocamento calculado.

Impacto: uma requisição autenticada malformada interrompe a consulta. Não foi demonstrada indisponibilidade geral.

Correção: aceitar apenas inteiros escalares dentro de faixas documentadas, devolver 400/422 para parâmetros inválidos e limitar deslocamento ou adotar cursor. Validar datas ISO e ordem do intervalo, em vez de ignorar silenciosamente datas inválidas.

### 3. Média — filtros de eventos não correspondem aos produtores

Referências: `backend/app/controllers/super_admin/audit_logs_controller.rb:15`, `backend/app/controllers/account/users_controller.rb:229` e `frontend/src/views/super-admin/SecurityLogsPage/SuperAdminSecurityLogsPage.vue:47`.

O produtor de alteração de senha grava `password_changed`, enquanto o filtro aceita `password_change`. O teste confirmou que solicitar `password_changed` ignora o filtro e retorna também eventos `logout`. Eventos de revogação de sessão também não constam no catálogo aceito. Valores não reconhecidos ampliam silenciosamente a consulta.

Impacto: investigações podem omitir eventos relevantes ou interpretar resultados sem filtro como resultados filtrados.

Correção: manter catálogo compartilhado de eventos, tratar compatibilidade com registros históricos, incluir eventos de sessão relevantes e rejeitar filtros desconhecidos explicitamente.

### 4. Média — falhas de consulta parecem ausência de eventos

Referências: `frontend/src/views/super-admin/SecurityLogsPage/SuperAdminSecurityLogsPage.vue:16`, `:99`, `:225` e `:236`.

Os indicadores usam zero como fallback; a listagem usa estado vazio sem distinguir falha. O teste confirmou que uma rejeição encerra o carregamento com lista vazia. Os catches também enviam o erro completo ao console: um objeto sintético com credencial em `config.headers` chegou intacto ao logger.

Impacto: falhas operacionais podem aparentar ausência de incidentes; objetos Axios podem expor metadados de autenticação no console e em capturas compartilhadas. Não foi demonstrado envio desses dados a terceiros.

Correção: estados separados de carregamento, sucesso, vazio e erro, opção de tentar novamente e indicador de atualização do resumo. Registrar somente informações técnicas permitidas, sem o objeto de requisição ou seus cabeçalhos.

### 5. Média — consultas concorrentes e mudança de filtros geram resultados incorretos

Referência: `frontend/src/views/super-admin/SecurityLogsPage/SuperAdminSecurityLogsPage.vue:207`.

Teste com promessas controladas confirmou que uma resposta antiga sobrescreve uma nova. Outro confirmou que aplicar filtro na página 5 continua solicitando página 5. Não há controle de versão da consulta nem descarte ao desmontar o componente.

Impacto: a tabela pode não corresponder aos filtros visíveis ou aparentar estar vazia apesar de haver resultados na primeira página.

Correção: reiniciar paginação ao filtrar, aceitar apenas a resposta da consulta atual, invalidar consultas ao sair e estabelecer ordenação estável com desempate por ID.

### 6. Baixa — seletor de estabelecimentos não recebe opções

Referências: `frontend/src/views/super-admin/SecurityLogsPage/SuperAdminSecurityLogsPage.vue:240` e `backend/app/controllers/super_admin/dashboard_controller.rb:74`.

A página espera `data.establishments` do dashboard. O contrato atual não fornece esse campo, confirmado por teste de integração; o fallback resulta em lista vazia.

Impacto: o filtro não pode ser utilizado normalmente pela interface.

Correção: fornecer busca autenticada e limitada de opções com apenas ID e nome. Não restaurar uma listagem extensa de dados pessoais no dashboard para suprir esse filtro.

### 7. Baixa — resumo transporta dados e faz agregações desnecessárias

Referência: `backend/app/controllers/super_admin/audit_logs_controller.rb:83`.

Inspeção estática: todos os IPs distintos de falhas são carregados e enviados, embora a interface utilize somente a contagem. Também são enviados logs recentes e rankings não utilizados nesta página. Rankings agrupam tudo no Ruby antes de limitar a dez resultados. Existe cache de dois minutos, mas ele não limita o trabalho em uma consulta sem cache.

Impacto: exposição desnecessária de dados e crescimento de memória/resposta conforme o volume. Não foi executado teste de carga nem demonstrado ataque de negação de serviço.

Correção: retornar somente os indicadores consumidos, contar IPs distintos no banco e, se rankings forem necessários a outro consumidor, consultar agregações ordenadas e limitadas no SQL em contrato próprio.

## Controles verificados

- Os dois endpoints exigem autenticação e super admin no servidor. Testes reproduziram 401 anônimo e 403 para owner e funcionário, inclusive com role forjada no parâmetro.
- Resposta autenticada da listagem inclui `Cache-Control: no-store`.
- Consultas dos filtros utilizam parâmetros Active Record; não foi identificado SQL construído por concatenação de entrada nesse controller.
- O acesso global aos estabelecimentos é intencional para super admin; não foi identificado IDOR no escopo revisado.
- Template usa interpolação Vue; não foi identificado `v-html` no fluxo revisado. Isso não equivale a teste de XSS da aplicação inteira.
- Não há upload nem endpoint de alteração/exclusão de auditoria nesse fluxo. Testes existentes verificam bloqueio de update/destroy pelo model; isso não comprova imutabilidade perante acesso direto ao banco.
- Não foram encontrados segredos hardcoded nos arquivos do fluxo inspecionados. Arquivos `.env`, seeds e credenciais reais não foram inspecionados.

## Validação e limites

Executados localmente, em ambiente de teste:

- Rails: cinco testes temporários desta revisão e três testes existentes de AuditLog; **8 testes, 26 assertivas, zero falhas**.
- Vue: três diagnósticos sobre o script real compilado do componente; **3 testes, zero falhas**.
- Os diagnósticos reproduzem o comportamento defeituoso atual; passarem não significa que os defeitos foram corrigidos. Artefatos locais em `tmp/security_logs_review_test.rb` e `tmp/security_logs_review.mjs`, fora do versionamento.
- Avisos de módulos opcionais VIPS ausentes e deprecações de rotas Rails não impediram os testes. O modo isolado `node --test` encontrou restrição de criação de processo; os três testes rodaram diretamente com Node.
- Não houve teste manual no navegador da VM, teste de carga, auditoria jurídica, verificação da infraestrutura de produção nem execução de Brakeman nesta revisão.

## Referências

A recomendação de reduzir dados, excluir credenciais e testar falhas de auditoria segue o [OWASP Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html). A revisão de necessidade e segurança do tratamento considera os arts. 6º e 46 da [LGPD](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm). Esta análise técnica não certifica conformidade legal: finalidade, base legal, retenção e acesso operacional precisam de avaliação própria.
