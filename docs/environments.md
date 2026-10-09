# Ambientes do EasySlotting

| Branch | Execução | Rails | Gems |
| --- | --- | --- | --- |
| developing | PC local | development | Desenvolvimento e testes disponíveis |
| staging | Homologação | production | Sem grupos development/test |
| main | Produção | production | Sem grupos development/test |

Branch não muda RAILS_ENV automaticamente. O mesmo código e Gemfile são promovidos
entre as branches. Este commit configura o projeto, sem provisionar servidores.

## Desenvolvimento

Copie backend/.env.example para backend/.env somente em uma instalação nova.
Não sobrescreva seu .env existente. Preencha senha e chaves locais. Execute
bundle install no backend e npm ci no frontend. Letter Opener abre e-mails no PC;
os jobs usam o adaptador async. Os bancos locais continuam app_development/app_test.
O frontend usa frontend/.env.example como modelo. VITE_* é público no bundle.

## Staging e produção

Use backend/.env.staging.example ou backend/.env.production.example como modelo.
Ambos usam RAILS_ENV=production, com bancos, chaves e SMTP independentes. Nunca
reutilize credenciais de produção em staging. Gere cada chave com
`bundle exec rails secret` em um ambiente de desenvolvimento confiável.

Em instalação direta no Linux, configure BUNDLE_WITHOUT=development:test antes
que bundle install seja executado. Injete RAILS_ENV e as demais variáveis pelo
serviço/systemd, plataforma de deploy ou Docker --env-file. A gem dotenv-rails
fica apenas em development/test: copiar um .env.production não carrega suas
variáveis no processo. Nunca versione os arquivos reais.

O Dockerfile do backend instala somente gems de runtime. Durante o build, usa
valores fictícios temporários para compilar assets; chaves reais entram apenas
na execução. O build não precisa copiar .env ou master.key.

DB_HOST/PORT/USER/PASSWORD configuram as conexões. Em containers, DB_HOST deve
ser o nome/endereço do serviço PostgreSQL, não localhost. DB_DATABASE e os nomes
QUEUE_DB_DATABASE, CACHE_DB_DATABASE e CABLE_DB_DATABASE separam os quatro bancos.
Configure um usuário autorizado a prepará-los, ou peça ao administrador para
criá-los previamente. Com as variáveis injetadas, execute `bin/rails db:prepare`
antes do worker. O entrypoint Docker também prepara os bancos ao iniciar o servidor.
Não aponte staging para bancos de produção.

ALLOWED_HOSTS contém os hosts da API, sem protocolo/porta. ALLOWED_ORIGINS contém
as URLs completas do frontend para CORS. FRONTEND_URL gera links de e-mail.
Staging e produção exigem HTTPS, com TLS terminado por um proxy confiável. O proxy
precisa encaminhar corretamente a requisição HTTPS. Não exponha Puma diretamente
sem a configuração de proxy correspondente.

Produção usa o provedor SMTP configurado em SMTP_ADDRESS/PORT/DOMAIN, com
SMTP_AUTHENTICATION=login e STARTTLS habilitado. EMAIL_USER/PASSWORD autenticam;
EMAIL_FROM identifica o remetente. Confirme domínio/remetente no provedor.
O exemplo pressupõe STARTTLS na porta 587, não TLS implícito na porta 465.

Staging usa captura SMTP em localhost:1025 (por exemplo Mailpit), sem autenticação
nem TLS apenas na rede local isolada. Provisione esse serviço; em Docker use o nome
do serviço em SMTP_ADDRESS. E-mails ficam na caixa de captura, sem entrega externa.

Execute `bin/jobs` em um worker separado, com as mesmas variáveis do backend.
SOLID_QUEUE_IN_PUMA=false realmente desativa o supervisor embutido; true/1 ativa.
Não ative ambos os modos sem planejar o processamento. Em Windows, mantenha o modo
local de desenvolvimento; valide os serviços de produção em Linux/WSL2/Docker.

O frontend de staging/produção deve ser compilado com VITE_API_URL do respectivo
ambiente e servido por um servidor estático/proxy. npm run dev é para desenvolvimento.
Persista /rails/storage e os uploads gerados em /rails/public/uploads, preservando
as imagens padrão; esses dados não fazem parte do Git. Faça backup dos bancos,
uploads e credenciais separadamente. Não execute reset/drop em produção.

## Promoção e validação

Faça commit em developing. Promova por pull request developing -> staging;
após homologação, staging -> main. Mantenha o mesmo código entre ambientes e mude
somente as variáveis injetadas. Antes de publicar, valide migrações, HTTPS, login,
permissões, upload, processamento dos jobs e captura/entrega de e-mails.

## Verificações desta configuração

- bundle check e validação de sintaxe Ruby concluídos.
- 9 testes de segurança existentes passaram (22 assertions).
- Inicialização de staging e produção validada com valores fictícios temporários,
  sem envio de e-mail e sem conectar aos bancos de produção: quatro conexões de
  banco isoladas, SMTP, HTTPS, hosts permitidos e ausência de gems de desenvolvimento.
- Todos os mailers respeitam EMAIL_FROM, separado do usuário de autenticação SMTP.
- Senhas PostgreSQL com caracteres especiais preservadas pela configuração YAML.
- Alternância do worker verificada com false/0/true/1.
- Entrypoints versionados como executáveis e com LF para Linux; Docker também
  aplica chmod antes da compilação.
- O build completo da imagem e a entrega SMTP real precisam ser validados no
  ambiente Linux/Docker de destino. Docker não está instalado na máquina atual.

## Produção na VPS Hostinger

Consulte [o guia KVM 1](hostinger-vps.md) para preparar main com Compose,
HTTPS público, SMTP, backup e atualização. Use compose.production.yaml e
backend/.env.production privado; não reutilize o arquivo de staging.
