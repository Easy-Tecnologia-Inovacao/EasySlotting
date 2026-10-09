# Staging em uma instância Linux local

Esta configuração usa a branch staging e RAILS_ENV=production, com PostgreSQL,
worker, frontend HTTPS e Mailpit em containers. O Gemfile é compartilhado:
gems de development/test ficam fora da imagem. Os dados e segredos de staging
são independentes do desenvolvimento e da produção.

O repositório oficial desta instalação é
`git@github.com:easytecnologiainovacao/EasySlotting.git`. As branches publicadas
são `developing`, `staging` e `main`.

## Preparar a máquina

Use uma VM Ubuntu Server 24.04 LTS no Windows com a mesma capacidade do plano
Hostinger KVM 1 usado como referência: 1 vCPU, 4 GB de RAM fixa e disco virtual
de 50 GB. A VM não reproduz a franquia de 4 TB nem garante o mesmo desempenho da
VPS; ela serve para validar a instalação, os containers e o comportamento de
produção. A rede deve permitir acesso do Windows à VM. O Hyper-V Default Switch
é suficiente para a primeira instalação; para um IP LAN estável, use um
comutador externo e reserve o endereço no roteador. Não encaminhe portas do
roteador para essa VM.

### Criar a VM no Hyper-V

No PowerShell como administrador, habilite o Hyper-V, reinicie o Windows e crie
uma VM de geração 2 com memória não dinâmica:

~~~powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
# reinicie o Windows antes de continuar

$vmName = "EasySlotting-Staging"
$vmPath = "C:\VMs\EasySlotting-Staging"
New-Item -ItemType Directory -Path $vmPath -Force | Out-Null
New-VM -Name $vmName -Generation 2 -MemoryStartupBytes 4GB `
  -NewVHDPath "$vmPath\disco.vhdx" -NewVHDSizeBytes 50GB `
  -Path $vmPath -SwitchName "Default Switch"
Set-VMProcessor -VMName $vmName -Count 1
Set-VMMemory -VMName $vmName -DynamicMemoryEnabled $false
Set-VMFirmware -VMName $vmName -EnableSecureBoot On `
  -SecureBootTemplate MicrosoftUEFICertificateAuthority
~~~

Conecte o ISO `ubuntu-24.04.x-live-server-amd64.iso` ao DVD virtual, inicie a
VM e escolha Ubuntu Server sem drivers de terceiros. Use o particionamento
automático do disco virtual de 50 GB.

### Abrir e controlar a VM no Windows

Os arquivos da VM ficam fora do repositório, em `C:\VMs\EasySlotting-Staging`.
O disco virtual é `disco.vhdx`; não o mova nem o abra diretamente enquanto a VM
estiver ligada. Não é necessário criar uma pasta ou executável na área de
trabalho. Use o PowerShell como administrador:

~~~powershell
# Iniciar a VM e abrir o console
Start-VM -Name "EasySlotting-Staging"
vmconnect.exe localhost "EasySlotting-Staging"

# Abrir o console se a VM já estiver ligada
vmconnect.exe localhost "EasySlotting-Staging"

# Conferir estado e endereço do console Hyper-V
Get-VM -Name "EasySlotting-Staging" | Select-Object Name, State, Status

# Desligamento normal solicitado pelo sistema convidado
Stop-VM -Name "EasySlotting-Staging"

# Desligamento forçado somente se a VM estiver travada
Stop-VM -Name "EasySlotting-Staging" -TurnOff
~~~

Para verificar a configuração equivalente ao KVM 1:

~~~powershell
Get-VM -Name "EasySlotting-Staging" |
  Select-Object Name, State, ProcessorCount, MemoryStartup
Get-VHD -Path "C:\VMs\EasySlotting-Staging\disco.vhdx" |
  Select-Object Path, Size, FileSize
~~~

O `vmconnect.exe` é instalado com o Hyper-V e normalmente fica em
`C:\Windows\System32\vmconnect.exe`. O console abre um terminal Ubuntu sem
interface gráfica; entre com o usuário `deploy`. Para acessar por SSH depois,
use o IPv4 mostrado por `hostname -I` dentro da VM:

~~~powershell
ssh deploy@IP_DA_VM
~~~

O `Default Switch` do Hyper-V pode trocar o IP após reiniciar. Use o IP atual
para o SSH e para o navegador, ou configure um comutador externo se precisar de
um endereço LAN estável.

### Problema de rede no instalador Hyper-V

Em algumas redes, o instalador fica repetindo **Ubuntu archive mirror
configuration** ou expira durante o download. Nesta VM, o DNS funcionou e o
HTTP para `archive.ubuntu.com` respondeu, mas o download com MTU 1500 expirou.
O download passou ao reduzir temporariamente a MTU da interface para 1400:

~~~bash
ip link show eth0
ip link set dev eth0 mtu 1400
curl -4 -m 30 -o /dev/null \
  http://archive.ubuntu.com/ubuntu/dists/noble-updates/InRelease
~~~

O resultado esperado é `100` por cento recebido. Volte ao instalador com
`exit` e use o espelho oficial `http://archive.ubuntu.com/ubuntu/`; avance
somente quando a tela informar **This mirror location passed tests**.

Esse ajuste feito no shell do instalador é temporário e desaparece ao reiniciar.
Depois do primeiro boot, teste novamente `apt update`. Se o problema retornar,
torne a MTU persistente no Netplan, ajustando o nome da interface:

~~~yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
      mtu: 1400
~~~

Salve em `/etc/netplan/99-easyslotting-mtu.yaml`, aplique com
`sudo netplan try` e confirme com `sudo netplan apply`. Se a rede funcionar
com MTU 1500 após a instalação, não mantenha 1400 sem necessidade. O problema
é específico do caminho de rede local/Hyper-V e não deve ser copiado para a VPS
sem teste.

Dentro da VM, atualize o Ubuntu e instale somente as ferramentas do host. Não
instale Ruby, Node ou PostgreSQL diretamente: essas dependências serão instaladas
nas imagens Docker da aplicação.

~~~bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y git ca-certificates curl openssh-server
sudo apt install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
sudo usermod -aG docker deploy
~~~

Saia e entre novamente no usuário `deploy` para que o grupo Docker seja aplicado.
Confira:

~~~bash
git --version
docker version
docker compose version
~~~

Docker Desktop não é necessário dentro do Linux. Se a instalação do Docker vier
de outra fonte, siga a [documentação oficial para Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
e mantenha apenas uma instalação ativa.

Se a senha de `deploy` for esquecida, inicialize temporariamente pelo ISO do
Ubuntu, abra **Help > Enter shell**, identifique o volume com `lsblk -f` e monte
o volume lógico instalado. No layout criado pelo instalador, o comando é:

~~~bash
mkdir -p /target
mount /dev/mapper/ubuntu--vg-ubuntu--lv /target
chroot /target /bin/bash
passwd deploy
exit
umount /target
exit
~~~

Desconecte o ISO antes de reiniciar a VM para que ela volte a iniciar pelo disco
virtual. A senha não deve ser armazenada no repositório nem compartilhada em
mensagens.

Clone o repositório privado dentro do disco Linux (autentique com sua conta,
sem gravar token na URL), selecionando staging:

~~~bash
git clone --branch staging --single-branch git@github.com:easytecnologiainovacao/EasySlotting.git
cd EasySlotting
hostname -I
~~~

Os arquivos desta configuração precisam estar publicados na branch remota para
o clone recebê-los. Se ainda estiverem apenas locais, transfira as alterações
revisadas ou publique o commit antes de clonar.

## Criar a configuração privada na VM

Na raiz do projeto, substitua o IP abaixo pelo IPv4 LAN da VM:

~~~bash
bash scripts/prepare-staging.sh 192.168.1.50
~~~

O script gera backend/.env.staging com permissão 600, segredos independentes,
senha de banco e senha de administrador aleatórias. Não imprime credenciais e
recusa sobrescrever um arquivo existente. Esse arquivo está ignorado pelo Git
e pelo build Docker. Consulte as credenciais somente no arquivo privado da VM.

O script configura o HTTPS, os hosts Rails, as origens CORS e a publicação da
porta 8443 para o mesmo IP. Mantenha esse IP estável. Se ele mudar, atualize juntos
STAGING_HOST, STAGING_BIND_ADDRESS, FRONTEND_URL, API_URL, ALLOWED_HOSTS e
ALLOWED_ORIGINS e recrie os containers. Não regenere as senhas de um banco
existente: trocar DB_PASSWORD no arquivo não altera a senha dentro do PostgreSQL.

Para um arquivo já existente, ajuste essas seis variáveis manualmente. O .env
de desenvolvimento não é alterado. Rails production não carrega .env sozinho:
o Compose injeta explicitamente backend/.env.staging.

## Iniciar e acessar pelo Windows

~~~bash
sudo docker compose --env-file backend/.env.staging -f compose.staging.yaml config --quiet
sudo docker compose --env-file backend/.env.staging -f compose.staging.yaml up -d --build
sudo docker compose --env-file backend/.env.staging -f compose.staging.yaml ps --all
~~~

Abra https://192.168.1.50:8443 no Windows (usando o IP real). O Compose espera
PostgreSQL saudável, executa db:prepare e inicia backend, worker e frontend.
O serviço prepare deve terminar com código 0. O banco começa separado e vazio.
O bootstrap cria o plano mensal e o administrador indicado no arquivo privado;
não apaga dados existentes e não usa os seeds de demonstração.

Depois do primeiro acesso, pode remover BOOTSTRAP_ADMIN_EMAIL e
BOOTSTRAP_ADMIN_PASSWORD do arquivo e recriar web/worker para retirar as
credenciais de seus ambientes. A conta criada permanece no banco.

A aplicação publica somente 8443 no IP escolhido. PostgreSQL, Rails e SMTP
ficam na rede interna Docker. Mailpit publica 8025 apenas no loopback Linux.
Para ver os e-mails capturados no navegador Windows, abra um túnel PowerShell:

~~~powershell
ssh -N -L 8025:127.0.0.1:8025 usuario@192.168.1.50
~~~

Mantenha o túnel aberto e acesse http://localhost:8025. E-mails não são enviados
a destinatários reais. Acesso SSH precisa estar habilitado na VM.
Restrinja o acesso à rede local; portas Docker publicadas exigem regras próprias
e não devem depender somente do UFW, conforme a documentação Docker.

## Confiar no HTTPS local

Caddy gera uma autoridade certificadora privada de staging. Depois de subir:

~~~bash
sudo docker compose --env-file backend/.env.staging -f compose.staging.yaml cp frontend:/data/caddy/pki/authorities/local/root.crt staging-root.crt
~~~

Copie somente esse certificado público para o Windows:

~~~powershell
scp usuario@192.168.1.50:~/EasySlotting/staging-root.crt .
~~~

Ajuste o caminho se clonou em outro diretório. Importe staging-root.crt nas
Autoridades de Certificação Raiz Confiáveis do usuário Windows (certmgr.msc).
Não exporte root.key. O certificado exportado é ignorado no Git. Certificados
e chave interna persistem no volume Caddy. Confira a origem do certificado antes
de confiar nele. Esta configuração não usa certificado público de domínio.

## Atualizar e manter os dados

~~~bash
git pull --ff-only origin staging
sudo docker compose --env-file backend/.env.staging -f compose.staging.yaml up -d --build --force-recreate
sudo docker compose --env-file backend/.env.staging -f compose.staging.yaml logs --tail=100 prepare web worker frontend
~~~

A recriação executa a preparação do banco para aplicar novas migrações. Faça
backup antes de alterações de schema. Não execute seeds de development aqui.
Os serviços contínuos usam restart: unless-stopped; habilite Docker na
inicialização do Linux para que os containers voltem após reiniciar a VM.

~~~bash
sudo systemctl enable --now docker
sudo docker compose --env-file backend/.env.staging -f compose.staging.yaml down
~~~

## Deploy automático pela branch `staging`

O workflow `.github/workflows/deploy-staging.yml` executa o deploy a cada push
em `staging`. Como a VM usa um IP privado, o workflow usa um runner
auto-hospedado instalado na própria VM com as labels `self-hosted`, `linux` e
`staging`. O script exige uma árvore Git limpa, atualiza com `git pull
--ff-only`, valida o Compose, recria os serviços e aguarda o healthcheck do
serviço `web`.

No GitHub, abra **Settings > Actions > Runners > New self-hosted runner** e
execute na VM os comandos Linux mostrados pelo GitHub. Durante o cadastro,
selecione as labels `linux` e `staging`, instale o runner como serviço e deixe-o
iniciar com o sistema. O usuário do runner precisa acessar o Docker; prefira
adicioná-lo ao grupo `docker`. Se usar `sudo`, o script detecta essa alternativa
com `sudo -n`, que exige uma regra sem senha.

Teste na VM com:

```bash
bash ~/EasySlotting/scripts/deploy-staging.sh
```

Down para os serviços e preserva os volumes de banco, uploads, e-mails e
certificados. Não use down -v para preservar os dados. Os volumes da VM não são
um backup: copie banco e uploads para um armazenamento separado periodicamente.

## Limites e validação

A configuração prepara homologação em VM local por IP, sem publicar na internet.
Para uma VPS pública, configure domínio e certificado público e reveja portas,
captura de e-mails, backups e credenciais antes de expor o serviço.
As tags das imagens são por versão principal; fixe versões/digests após validar.

Os testes Rails e o build frontend da preparação anterior passaram. As alterações
para Linux foram verificadas estaticamente e o gerador foi exercitado em diretório
temporário. Docker não está disponível nesta máquina Windows; o build das imagens,
a inicialização conjunta e o acesso HTTPS precisam ser validados na VM.
