# Produção na Hostinger — KVM 1

Arquitetura inicial para uma pessoa usando: Ubuntu 24.04 LTS, 1 vCPU,
4 GB RAM e 50 GB NVMe. A branch de implantação é main. Staging fica na VM
local, em outra máquina e com credenciais próprias.

Um único domínio atende Vue e Rails: https://app.seudominio.com.br;
a API usa /api, os arquivos /uploads e o WebSocket /api/cable.
Caddy publica 80/443 e gerencia o certificado público. Rails e PostgreSQL
não publicam portas na VPS. SMTP é um serviço externo.

| Serviço | Configuração inicial | Limite de RAM |
| --- | --- | --- |
| web | Um processo Puma, 3 threads, pool 5 | 1 GiB |
| worker | Um processo Solid Queue, 1 thread, pool 5 | 768 MiB |
| db | PostgreSQL 17, shared_buffers 256 MB, até 60 conexões | 768 MiB |
| frontend | Vue compilado e Caddy | 128 MiB |
| prepare | Prepara os bancos antes de iniciar a aplicação | 1 GiB temporário |

Limites são tetos, não reservas nem garantia de consumo. O worker também mantém
dispatcher e scheduler. Os pools Rails são por conexão/banco e por processo.
A configuração deixa margem ao Linux; monitore possíveis OOM e ajuste após
medir. Builds não estão sujeitos a esses limites de runtime e podem usar mais RAM.

## 1. Contratar e preparar a VPS

- Escolha KVM 1 e região próxima dos usuários.
- Selecione Ubuntu 24.04 com Docker, sem outros painéis/projetos.
- Ative a proteção da conta Hostinger e backups disponíveis no painel.
- Anote o IPv4 da VPS e tenha um domínio sob seu controle.

Referência: [template Docker da Hostinger](https://www.hostinger.com/support/8306612-how-to-use-the-docker-vps-template-at-hostinger/).
Se a VPS já contém dados, não reinstale o sistema: reinstalação apaga o disco.

Conecte pelo PowerShell:

~~~powershell
ssh root@IP_DA_VPS
~~~

No Linux, atualize os pacotes e crie seu usuário de operação:

~~~bash
apt update
apt upgrade -y
apt install -y git openssl ca-certificates
adduser deploy
usermod -aG sudo deploy
systemctl enable --now docker
docker version
docker compose version
~~~

Se o Docker não estiver instalado, siga a
[instalação oficial para Ubuntu](https://docs.docker.com/engine/install/ubuntu/).
Use Docker Compose atual com suporte a mem_limit, healthcheck e
depends_on.condition. Os comandos deste guia usam sudo; não é necessário
adicionar deploy ao grupo docker, que permite controle equivalente a root.

## 2. Configurar SSH e firewall

No Windows, use uma chave SSH pessoal. Se ainda não tiver uma:

~~~powershell
ssh-keygen -t ed25519
~~~

Não substitua uma chave existente. Copie a chave PÚBLICA para deploy:

~~~powershell
Get-Content "$env:USERPROFILE/.ssh/id_ed25519.pub" | ssh root@IP_DA_VPS "install -d -m 700 -o deploy -g deploy /home/deploy/.ssh; cat >> /home/deploy/.ssh/authorized_keys; chown deploy:deploy /home/deploy/.ssh/authorized_keys; chmod 600 /home/deploy/.ssh/authorized_keys"
ssh deploy@IP_DA_VPS
~~~

Confirme em uma nova conexão que a chave e sudo funcionam antes de desabilitar
login root ou senhas SSH. Depois configure PermitRootLogin no e
PasswordAuthentication no no sshd, execute sudo sshd -t e recarregue ssh.
Mantenha uma sessão aberta e acesso ao console Hostinger durante essa mudança.

No firewall da VPS no hPanel:
- Permita TCP 80 e 443 para o público, em IPv4 e IPv6 se usados.
- Permita TCP 22 somente ao seu IP público, atualizando a regra se mudar.
- Negue outras entradas, especialmente 3000, 5432, 8025 e a API Docker.
- Verifique as regras antes de fechar sua sessão SSH.

Não dependa somente do UFW: portas publicadas pelo Docker podem contornar
suas regras. Consulte as [limitações oficiais do firewall Docker](https://docs.docker.com/engine/install/ubuntu/#firewall-limitations).

## 3. Apontar o domínio

Crie um registro DNS A, por exemplo app.seudominio.com.br, para o IPv4 da VPS.
Use AAAA apenas se o IPv6 da VPS estiver configurado e acessível.
Comece com DNS direto, sem proxy/CDN, para simplificar a primeira validação.
Nenhum outro serviço pode ocupar as portas 80 e 443.

O certificado será emitido quando o domínio resolver para a VPS e essas portas
estiverem acessíveis. [Como funciona o HTTPS automático do Caddy](https://caddyserver.com/docs/automatic-https).
Não importe o certificado interno usado na staging na produção.

## 4. Dar acesso da VPS ao GitHub e clonar main

O repositório de produção fica na conta `easytecnologiainovacao`:
`git@github.com:easytecnologiainovacao/EasySlotting.git`. A chave de deploy deve
ser cadastrada nesse repositório, sem permissão de escrita.

Conectado como deploy, crie uma chave exclusiva para leitura do repositório:

~~~bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "easyslotting-production-readonly"
cat ~/.ssh/id_ed25519.pub
~~~

Se já existir uma chave nesse caminho, preserve-a e configure uma chave dedicada
via ~/.ssh/config. Cadastre somente a chave pública no GitHub:
repositório > Settings > Deploy keys > Add deploy key, SEM Allow write access.
Confira a impressão digital oficial do GitHub antes de aceitar a conexão SSH.
A chave privada permanece na VPS; nunca coloque token na URL do clone.

~~~bash
git clone --branch main --single-branch git@github.com:easytecnologiainovacao/EasySlotting.git
cd ~/EasySlotting
git status --short --branch
~~~

O commit desta configuração precisa estar publicado na main para o clone recebê-lo.

## 5. Gerar ambiente privado de produção

Na raiz do projeto, substitua domínio e e-mail pelos reais:

~~~bash
bash scripts/prepare-production.sh app.seudominio.com.br voce@seudominio.com.br
nano backend/.env.production
~~~

O script cria senhas/chaves independentes, permissão 600 e recusa sobrescrever
um arquivo existente. Não imprime segredos. O domínio configura APP_DOMAIN,
FRONTEND_URL, API_URL, ALLOWED_HOSTS e ALLOWED_ORIGINS. O e-mail configura
o contato ACME e a conta administrativa inicial.

No editor, complete o SMTP real:
SMTP_ADDRESS, SMTP_PORT=587, SMTP_DOMAIN, EMAIL_USER, EMAIL_PASSWORD,
EMAIL_FROM e SUPPORT_EMAIL. Use SMTP_AUTHENTICATION=login e
SMTP_ENABLE_STARTTLS_AUTO=true para um provedor que suporte STARTTLS em 587.
Não use Mailpit, letter_opener ou SMTP sem autenticação em produção.

Se a senha tiver $, #, espaços ou outros caracteres especiais, coloque o valor
entre aspas simples no arquivo dotenv, sem usar uma senha com aspas simples
sem o escape adequado. Não execute source no arquivo. Compose lê e injeta
as variáveis; dotenv-rails não é instalado em production.
Nunca compartilhe a saída completa de docker compose config, que pode revelar
segredos. Utilize config --quiet para validar sem imprimir valores.

Configure SPF, DKIM e DMARC conforme o provedor de e-mail e valide o remetente.
Não é necessário hospedar um servidor de e-mail nesta VPS.
Se a aplicação passar a usar credenciais Rails criptografadas, injete também
RAILS_MASTER_KEY compatível, preservando-o fora do Git e da imagem.

Antes de iniciar, confirme:
- Não restou nenhum valor replace-with nem domínio example.com.
- Senhas/chaves são exclusivas desta produção.
- BOOTSTRAP_ADMIN_EMAIL é seu e-mail e a senha gerada foi guardada com segurança.
- backend/.env.production continua ignorado: git check-ignore backend/.env.production.

## 6. Primeira inicialização

~~~bash
sudo docker compose --env-file backend/.env.production -f compose.production.yaml config --quiet
sudo env COMPOSE_PARALLEL_LIMIT=1 docker compose --env-file backend/.env.production -f compose.production.yaml build
sudo docker compose --env-file backend/.env.production -f compose.production.yaml up -d
sudo docker compose --env-file backend/.env.production -f compose.production.yaml ps --all
sudo docker compose --env-file backend/.env.production -f compose.production.yaml logs --tail=100 prepare web worker frontend
~~~

O build é sequencial para reduzir concorrência na KVM 1. É uma solução inicial:
se ficar pesado, prepare imagens linux/amd64 em CI/na máquina de build e publique
em registry privado, mantendo o mesmo código de produção.
Não rode npm run dev ou instale Ruby/Node e gems manualmente no host.

O serviço prepare deve concluir com código 0. Ele prepara os quatro bancos
principal, fila, cache e cable, aplica migrações e executa o bootstrap na criação
inicial. O seed production preserva contas/dados; não cria contas de demonstração.
O worker inicia somente após essa preparação.

Abra https://app.seudominio.com.br. Teste login, permissões, agendamento,
upload, recebimento de e-mail e execução dos lembretes. Verifique que 80
redireciona para 443 e que o certificado é válido. Não considere o serviço
validado somente porque /up responde.

Após criar o administrador, remova BOOTSTRAP_ADMIN_EMAIL e
BOOTSTRAP_ADMIN_PASSWORD do arquivo e recrie web/worker para retirar as
credenciais de seus ambientes. O usuário permanece no banco. Não troque
DB_PASSWORD apenas no arquivo de um banco existente: isso não altera a senha
armazenada no PostgreSQL.

## 7. Backup e restauração

Ative backups do provedor, mas mantenha também cópias do banco e uploads fora
da VPS, com criptografia e acesso restrito. Teste restauração em uma VM isolada.
O diretório /backups está ignorado pelo Git.

Para uma cópia consistente com pouco movimento, pare temporariamente a
aplicação e o worker, mantendo o PostgreSQL ligado. No Bash, a partir da raiz:

~~~bash
set -euo pipefail
umask 077
backup_dir="$HOME/easyslotting-backups/$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$backup_dir"
sudo docker compose --env-file backend/.env.production -f compose.production.yaml stop frontend worker web
sudo docker compose --env-file backend/.env.production -f compose.production.yaml exec -T db sh -c 'pg_dumpall -U "$POSTGRES_USER"' > "$backup_dir/databases.sql"
sudo docker compose --env-file backend/.env.production -f compose.production.yaml run --rm --no-deps --entrypoint tar web -czf - -C /rails storage public/uploads > "$backup_dir/files.tar.gz"
sudo docker compose --env-file backend/.env.production -f compose.production.yaml start web worker frontend
test -s "$backup_dir/databases.sql"
test -s "$backup_dir/files.tar.gz"
~~~

O dump contém todos os bancos e informações de roles; trate-o como segredo.
Se uma etapa falhar, corrija o erro e reinicie os serviços parados. Preserve
separadamente o .env.production em armazenamento seguro, fora da VPS.
Copie os backups para fora do servidor e configure retenção e execução diária
antes de atender clientes. Esses comandos não instalam um agendamento automático.

Para testar restauração: crie uma instalação isolada, use os mesmos nomes de
bancos/usuário, restaure o SQL com psql antes de iniciar Rails e extraia
files.tar.gz nos volumes storage/uploads, preservando UID/GID 1000.
Um dump pg_dumpall pode conter CREATE ROLE para usuário já existente: resolva
esse conflito de forma planejada na restauração de teste. Não execute comandos
de restauração sobre produção sem um plano específico.

## 8. Atualizar com parada planejada

Na KVM 1, esta versão usa uma breve parada; não promete deploy sem interrupção.
Faça backup e guarde o hash atual com git rev-parse HEAD. Então:

~~~bash
sudo docker compose --env-file backend/.env.production -f compose.production.yaml stop frontend worker web
git pull --ff-only origin main
sudo env COMPOSE_PARALLEL_LIMIT=1 docker compose --env-file backend/.env.production -f compose.production.yaml build
sudo docker compose --env-file backend/.env.production -f compose.production.yaml up -d --force-recreate prepare web worker frontend
sudo docker compose --env-file backend/.env.production -f compose.production.yaml ps --all
~~~

Confira prepare e os logs antes de liberar acesso. Se build/migração falhar,
mantenha a manutenção e investigue; voltar código pode exigir restaurar banco,
pois migrações nem sempre são reversíveis. Nunca use db:reset, db:drop ou
docker compose down -v em produção. Uma atualização de PostgreSQL para outra
versão principal exige migração própria, não somente trocar a tag.

## 9. Acompanhar o consumo

~~~bash
sudo docker stats --no-stream
free -h
df -h
sudo docker compose --env-file backend/.env.production -f compose.production.yaml ps --all
~~~

Acompanhe uso sustentado de CPU/RAM, reinícios/OOM, disco, tempos de resposta
e atraso dos jobs. Os logs Docker têm rotação de 10 MB e três arquivos por
serviço. Não use docker system prune com remoção de volumes de produção.

A configuração usa tags de versão principal. Após validar as imagens, fixe
versões/digests e programe atualizações de segurança.
Uma VPS única não oferece alta disponibilidade: falha nela interrompe o serviço.

## Validação e limites

O projeto foi preparado sem Docker instalado na máquina Windows.
Passaram 12 testes Rails (31 assertions), a validação do gerador privado,
a checagem do YAML/concorrência e o boot production com valores fictícios;
build das imagens, certificado, SMTP, volumes, migrações no PostgreSQL 17 e
consumo real precisam ser validados na VPS/VM antes da utilização em produção.
Nenhum servidor foi provisionado e nenhuma credencial real de produção foi criada.
