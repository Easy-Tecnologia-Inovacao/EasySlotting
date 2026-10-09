ç# 📅 Agendamento — Plataforma SaaS de Agendamento Online

> Sistema completo de agendamento para estabelecimentos de beleza e estética (barbearias, salões, clínicas e similares).  
> Arquitetura **multi-tenant** com backend **Ruby on Rails 8 API** + frontend **Vue 3 + TypeScript**.

Referências de autenticação: [guia técnico de login, sessão, OTP e logout](docs/authentication.md) e [relatório de revisão de segurança](docs/authentication-security-review.md). O guia descreve os contratos atuais e como ampliar o sistema.

Para criar novas opções de exclusão, consulte a [referência de exclusão de contas por perfil](docs/account-deletion.md), com o fluxo dos clientes e pendências de owner/funcionário.

O [guia de sessões simultâneas por plano](docs/owner-sessions.md) descreve as faixas exclusivas, preços/sessões crescentes e limites de 1 a 4 por conta do proprietário ou funcionário. A [política por perfil](docs/session-policy.md) cobre super admin único com cinco sessões e clientes sem teto de aparelhos.

---

## 🗂️ Sumário

- [Visão Geral](#-visão-geral)
- [Stack Tecnológica](#-stack-tecnológica)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Módulos Prontos](#-módulos-prontos)
- [Roles e Permissões](#-roles-e-permissões)
- [Segurança em Camadas](#-segurança-em-camadas)
- [Rotas do Frontend](#-rotas-do-frontend)
- [Rotas da API](#-rotas-da-api)
- [Banco de Dados — Modelos](#-banco-de-dados--modelos)
- [Como Rodar Localmente](#-como-rodar-localmente)
- [Skills de IA do Projeto](#-skills-de-ia-do-projeto)
- [Status do Projeto](#-status-do-projeto)
- [Deploy / Produção](#-deploy--produção)

---

## 🌐 Visão Geral

O **Agendamento** é uma plataforma SaaS multi-tenant que permite que qualquer estabelecimento tenha seu **próprio portal público de agendamento** acessado via slug único (`/empresa/meu-salao`).

```
Cliente final         →  /empresa/:slug           (público, sem login)
Cliente cadastrado    →  /empresa/:slug/minha-conta
Dono / Funcionário    →  /admin/*
Super Administrador   →  /super-admin/*
```

Cada empresa contratante assina um **plano mensal** e gerencia sua equipe, serviços, horários e clientes de forma totalmente isolada. Clientes de estabelecimentos diferentes não se misturam, mesmo que usem o mesmo e-mail.

---

## 🛠️ Stack Tecnológica

### Backend — `agendamento/api/`

| Tecnologia            | Versão | Uso                                   |
| --------------------- | ------ | ------------------------------------- |
| **Ruby on Rails**     | 8.1.2  | Framework principal (API-only)        |
| **PostgreSQL**        | latest | Banco de dados relacional             |
| **Devise**            | latest | Autenticação base para staff          |
| **Devise Token Auth** | ~1.2.6 | Tokens opacos para staff, com rotação  |
| **JWT (`jwt` gem)**   | ~2.8   | Auth JWT própria para clientes        |
| **BCrypt**            | ~3.1.7 | Hash de senhas de clientes            |
| **Rack::CORS**        | latest | Controle de origens cruzadas          |
| **Rack::Attack**      | latest | Rate limiting e proteção contra abuso |
| **Solid Queue**       | latest | Fila de jobs em background            |
| **Solid Cache**       | latest | Cache com banco                       |
| **Puma**              | >= 5.0 | Servidor web                          |
| **Kamal**             | latest | Deploy automatizado via Docker        |
| **Brakeman**          | latest | Análise estática de segurança         |
| **Holidays**          | latest | Verificação de feriados nacionais     |

### Frontend — `agendamento/frontend/`

| Tecnologia                 | Versão  | Uso                                  |
| -------------------------- | ------- | ------------------------------------ |
| **Vue 3**                  | ^3.5.29 | Framework reativo                    |
| **TypeScript**             | ~5.9.3  | Tipagem estática                     |
| **Vite**                   | ^7.3.1  | Build tool e dev server              |
| **Pinia**                  | ^3.0.4  | Gerenciamento de estado global       |
| **Vue Router**             | ^5.0.3  | Guards de navegação; autorização no Rails |
| **Bootstrap 5**            | ^5.3.8  | Componentes e grid system            |
| **Bootstrap Icons**        | ^1.13.1 | Biblioteca de ícones                 |
| **Chart.js + vue-chartjs** | ^4.5.1  | Gráficos financeiros interativos     |
| **Axios**                  | ^1.14.0 | Cliente HTTP                         |

---

## 📁 Estrutura do Projeto

```
Agendamento/
├── .skills/                          ← Skills de IA (ver seção abaixo)
│   ├── 00_orquestrador_geral.md
│   ├── criar_feature_fullstack.md
│   ├── criar_feature_vue.md
│   ├── criar_componente_vue.md
│   ├── tecnico_de_frontend.md
│   ├── tecnico_de_seguranca.md
│   ├── pentester_de_seguranca.md
│   ├── dba_postgres.md
│   ├── gerar_commit.md
│   ├── analista_de_codigo.md
│   ├── ceo.md
│   └── cto.md
│
└── agendamento/
    ├── estrutura.md                  ← Listagem completa de todos os arquivos
    │
    ├── api/                          ← Backend Rails
    │   ├── app/
    │   │   ├── controllers/
    │   │   │   ├── admin/            ← Painel admin da empresa
    │   │   │   ├── customer/         ← Portal do cliente logado
    │   │   │   ├── customer_auth/    ← Registro e login de clientes
    │   │   │   ├── devise_users/     ← Auth de staff
    │   │   │   ├── financial/        ← Módulo financeiro
    │   │   │   ├── public/           ← Endpoints públicos (sem auth)
    │   │   │   ├── account/          ← Perfil e conta do staff
    │   │   │   └── super_admin/      ← Gestão da plataforma
    │   │   ├── models/
    │   │   │   ├── core/             ← User, Customer, Establishment...
    │   │   │   ├── scheduling/       ← Appointment, Service, Package...
    │   │   │   ├── team/             ← WorkingHour, Exception, Archive...
    │   │   │   ├── financial/        ← Plan, Subscription, Commission...
    │   │   │   └── inventory/        ← StockItem
    │   │   ├── services/
    │   │   │   ├── scheduling/       ← Slots disponíveis, criação, reagendamento
    │   │   │   └── financial/        ← Comissões, receitas, relatórios
    │   │   ├── policies/             ← Políticas de acesso (Service, Package)
    │   │   └── mailers/              ← Email de boas-vindas ao funcionário
    │   ├── config/
    │   │   ├── initializers/
    │   │   │   ├── rack_attack.rb    ← 11 regras de rate limiting
    │   │   │   ├── content_security_policy.rb
    │   │   │   ├── cors.rb
    │   │   │   └── devise_token_auth.rb
    │   │   ├── routes.rb             ← Todas as rotas versionadas sob /api
    │   │   └── recurring.yml         ← Jobs recorrentes (Solid Queue)
    │   └── db/
    │       ├── schema.rb
    │       ├── seeds.rb
    │       └── migrate/              ← 30+ migrações versionadas
    │
    └── frontend/
        └── src/
            ├── views/
            │   ├── landing/          ← Landing + Login/Cadastro do staff
            │   ├── public/           ← Página pública da empresa + Booking
            │   ├── customer/         ← Portal do cliente autenticado
            │   ├── admin/            ← Painel admin da empresa
            │   └── super-admin/      ← Dashboard e planos da plataforma
            ├── router/index.ts       ← Guards de rota por role e permissão
            ├── stores/
            │   ├── themeStore.ts     ← Tema dinâmico por estabelecimento
            │   └── counter.ts
            └── services/
                ├── api.ts            ← Instância Axios configurada
                └── customerAuth.ts   ← Helpers de JWT do cliente
```

---

## ✅ Módulos Prontos

### 🔐 1. Autenticação Dupla (Staff + Cliente)

#### Staff — Dono, Funcionários e Super Admin

- Login/logout via **Devise Token Auth** (tokens no header `access-token`)
- Token em memória, metadados em `sessionStorage` e rotação nas chamadas; recarregar completamente a página exige novo login
- Owner e cada funcionário: de 1 a 4 sessões conforme o plano do proprietário, com quotas independentes e sem somar benefícios. Super admin: uma conta no sistema, até cinco sessões. Listagem/revogação das próprias sessões no servidor
- Recuperação e redefinição de senha por e-mail
- Política atual de senha: **90 dias**; o Rails bloqueia escritas quando expirada, com exceções para manutenção da conta/autenticação
- Primeiro login válido registra confiança; IP ou dispositivo desconhecido nos seguintes exige OTP por e-mail
- Cadastro cria owner sem sessão automática; super admin é configurado explicitamente no bootstrap

#### Clientes — Isolados por Estabelecimento

- Autenticação própria com **BCrypt + JWT** sem Devise
- Registro em `/api/customer_auth/:slug/sign_up` — o slug do estabelecimento faz parte da URL
- Unicidade de e-mail composta: `[email + establishment_id]` — mesmo e-mail pode existir em múltiplos estabelecimentos
- Access JWT de 15 minutos em `sessionStorage`; refresh em cookie criptografado HttpOnly de sete dias, com rotação e CSRF
- **Múltiplas sessões por cliente, sem teto comercial**: novo login preserva outros aparelhos; logout revoga apenas a sessão atual. Refresh com rotação e prazo absoluto de sete dias
- Política atual de senha: **90 dias**; troca/redefinição e logout revogam também o access JWT pelo estado de sessão no banco
- Serviço `CustomerJsonWebToken` verifica assinatura, emissor, audiência, expiração e tipo; o servidor também confere conta, estabelecimento e `sid`
- Cadastro encaminha para login; primeiro acesso e OTP seguem a regra compartilhada com staff

Veja os fluxos, exceções e contratos no [guia de autenticação](docs/authentication.md). TOTP ainda está inativo; as proteções implementadas não representam certificação LGPD/OWASP.

#### Força de Senha (válida para ambos)

```
✓ Mínimo 8 caracteres
✓ Pelo menos 1 letra maiúscula
✓ Pelo menos 1 letra minúscula
✓ Pelo menos 1 número
✓ Pelo menos 1 caractere especial
✗ Não pode conter o primeiro nome quando ele tem ao menos 4 caracteres
✗ Não pode conter o prefixo do e-mail quando ele tem ao menos 4 caracteres
✗ Não pode conter termos óbvios (admin, senha, 123456, agendamento...)
✗ Não pode ser igual à senha anterior (comparação via BCrypt)
```

---

### 🏢 2. Multi-Tenant por Slug

Cada estabelecimento tem um slug único gerado no cadastro:

```
/empresa/barbearia-do-joao               ← Página de apresentação
/empresa/barbearia-do-joao/agendamento   ← Fluxo de booking
/empresa/barbearia-do-joao/cadastro      ← Cadastro de cliente
/empresa/barbearia-do-joao/login         ← Login de cliente
/empresa/barbearia-do-joao/minha-conta   ← Área logada do cliente
```

- O slug da sessão de cliente fica em `sessionStorage`; o slug da página pública é um contexto separado
- Todos os dados do estabelecimento retornam com o tema customizado
- O servidor limita o acesso de clientes à conta e ao estabelecimento autenticados; testes cobrem tentativas de acesso cruzado

---

### 📆 3. Agendamentos

**Ciclo de vida:**

```
pending → confirmed → checked_in → completed
    ↘               ↘            ↘
   canceled        canceled      canceled
```

**Funcionalidades prontas:**

- ✅ **Slots disponíveis** — `available_slots_service.rb` calcula horários livres considerando: horário de funcionamento do funcionário, exceções de agenda, agendamentos existentes e duração do serviço
- ✅ **Dias disponíveis** — endpoint `available_days` retorna dias com pelo menos 1 slot livre
- ✅ **Criar agendamento** com validação de conflito de horário
- ✅ **Reagendamento** com novo slot sem conflito
- ✅ **Check-in** do cliente ao chegar
- ✅ **Concluir agendamento** dispara geração de comissão e transação financeira automaticamente
- ✅ **Cancelamento** pelo admin ou pelo próprio cliente
- ✅ **Auto-cancelamento de no-shows** — agendamentos de dias anteriores com status `pending/confirmed/checked_in` são cancelados automaticamente
- ✅ **Auto-cancelamento de pacotes** — se o cliente não compareceu à primeira sessão, a venda do pacote é cancelada e demais agendamentos vinculados são cancelados
- ✅ **Semanas ocupadas do pacote** — endpoint `package_occupied_weeks` retorna semanas que já têm sessão agendada
- ✅ **Snapshots imutáveis** — nome do cliente, serviço, funcionário e preço são capturados no momento do agendamento e não mudam em edições futuras

---

### 👥 4. Equipe

- ✅ Cadastro de funcionários com envio de e-mail de boas-vindas (`UserMailer`)
- ✅ Especialidade e chave Pix por funcionário
- ✅ Definição dos serviços que cada funcionário realiza (`EmployeeService`)
- ✅ **Horários individuais de trabalho** por dia da semana (`EmployeeWorkingHour`)
  - Suporte a **horário partido** (ex: 08h–12h e 14h–18h no mesmo dia)
- ✅ **Exceções de agenda** (`EmployeeScheduleException`) — folgas, férias, dias especiais
- ✅ **Atualização em lote** de horários — `PATCH /admin/team/:id/schedule` e `bulk_schedule` para múltiplos
- ✅ **Arquivamento de funcionários** (`ArchivedEmployee`) com histórico e motivo do desligamento
- ✅ **Permissões granulares** por funcionário — configuráveis individualmente (ver seção Roles)

---

### 💰 5. Financeiro

#### Dashboard

- ✅ Visão geral de receitas, agendamentos e métricas do período

#### Relatórios

- ✅ Gerador de relatórios por período (`financial/reports/generator.rb`)
- ✅ Relatório de pacotes de serviços vendidos e utilizados

#### Comissões

- ✅ Três modelos configuráveis por funcionário:

| Modelo         | Descrição                        |
| -------------- | -------------------------------- |
| `porcentagem`  | % do valor do serviço (0–100%)   |
| `fixo_servico` | Valor fixo por serviço concluído |
| `diaria`       | Valor fixo por dia trabalhado    |

- ✅ Cálculo automático ao concluir agendamento (`commission_calculator.rb`)
- ✅ Registro de pagamento de comissões (`commission_payout.rb`)
- ✅ Validação de limites (porcentagem entre 0% e 100%)

#### Transações

- ✅ `FinancialTransaction` — registro de todas as movimentações
- ✅ Criação automática de receita ao concluir agendamento (`appointment_revenue_creator.rb`)

---

### 📦 6. Pacotes de Serviços

- ✅ Pacotes com múltiplas sessões (`sessions_total`, máximo 100 sessões)
- ✅ Venda de pacote vinculada a cliente (`ServicePackageSale`)
- ✅ Controle de uso por sessão concluída (`ServicePackageUsage`)
- ✅ Rastreamento do ciclo: sessões ativas + concluídas por venda
- ✅ Método `cycle_appointments` — retorna todos os agendamentos de um ciclo de pacote
- ✅ **Soft delete** de pacotes (`deleted_at`) — remove sem apagar histórico
- ✅ Endpoint `available` no portal do cliente — pacotes disponíveis para compra
- ✅ Cancelamento de venda de pacote pelo cliente

---

### 🗃️ 7. Estoque

- ✅ Cadastro de itens com nome, quantidade, preço de venda e quantidade mínima
- ✅ Escopo: `loja` ou `funcionario`
- ✅ **Decremento atômico** com **lock pessimista** (`FOR UPDATE`) — sem race conditions
- ✅ Validação de estoque suficiente antes de decrementar
- ✅ Alerta de estoque abaixo do mínimo (`minimum_stock`)
- ✅ Filtro `active` — apenas itens ativos

---

### 💳 8. Planos e Assinaturas

#### Super Admin — Gestão de Planos

- ✅ Criar/editar planos com código único (formato `slug`)
- ✅ Limites por plano: `max_employees`, `max_services`, `max_appointments_per_month`
- ✅ Preço com promoção:
  - `promotional_price` e `discount_percentage` calculados automaticamente
  - `promotion_starts_at` + `promotion_duration_days` → `promotion_ends_at` calculado
  - Método `promotion_running?` verifica se está no período ativo
  - Método `current_price` retorna o preço correto (normal ou promocional)

#### Estabelecimentos — Assinaturas

- ✅ `Subscription` com `status: active`
- ✅ `active_subscription?` verifica validade pela data de fim
- ✅ `subscribed_plan` retorna o plano atual
- ✅ Cancelamento com motivo registrado (`SubscriptionCancellation`)
- ✅ Portal do cliente exibe planos disponíveis para compra

---

### 🎨 9. Aparência Customizável

Cada estabelecimento personaliza o visual do seu portal público via `/admin/aparencia`:

| Campo                         | Tipo        | Validação                                            |
| ----------------------------- | ----------- | ---------------------------------------------------- |
| Cores (primary, bg, hover...) | hex ou rgba | Regex server-side                                    |
| `fontFamily`                  | string      | Whitelist: Inter, Poppins, Roboto, Plus Jakarta Sans |
| `fontSize`                    | string (px) | Entre 12px e 24px                                    |
| `horarios_texto`              | texto       | Sanitizado (anti-XSS)                                |

- ✅ `themeStore` no frontend aplica o tema dinamicamente em CSS variables
- ✅ Modo claro/escuro controlado pelo store

---

### 👤 10. Portal do Cliente

Área autenticada (JWT) acessível em `/empresa/:slug/`:

| Rota                | Tela                | Funcionalidades                                    |
| ------------------- | ------------------- | -------------------------------------------------- |
| `minha-conta`       | Perfil              | Dados pessoais, alteração de senha, upload de foto |
| `meus-agendamentos` | Agendamentos ativos | Cancelar, reagendar                                |
| `historico`         | Histórico           | Agendamentos concluídos + avaliação                |
| `planos`            | Planos e Pacotes    | Ver e comprar pacotes disponíveis                  |

- ✅ **Feedback** de agendamentos concluídos (`AppointmentFeedback`)
- ✅ Cancelamento de agendamentos pelo próprio cliente
- ✅ Reagendamento pelo cliente

---

### 🌍 11. Página Pública do Estabelecimento

Sem necessidade de login — acessível a qualquer visitante:

- ✅ Dados da empresa: nome, descrição, endereço, telefone, WhatsApp, Instagram, Facebook
- ✅ Fluxo de agendamento completo:
  1. Seleção do serviço
  2. Seleção do funcionário
  3. Seleção da data (apenas dias com slots disponíveis)
  4. Seleção do horário
  5. Login/cadastro do cliente (se necessário)
  6. Confirmação do agendamento
- ✅ Visualização de dados de booking: serviços, funcionários, horários (`booking_data`)
- ✅ Pacotes de serviços disponíveis ao público

---

### 🛡️ 12. Super Admin

Painel para gerenciar toda a plataforma SaaS:

- ✅ **Dashboard** com visão geral do sistema
- ✅ **Gestão de planos** — criar, editar planos com limites e promoções
- ✅ Acesso irrestrito a qualquer estabelecimento via header `X-Establishment-ID`

---

## 👮 Roles e Permissões

### Roles do sistema

| Role          | Descrição                   | Área de acesso                       |
| ------------- | --------------------------- | ------------------------------------ |
| `super_admin` | Administrador da plataforma | `/super-admin/*`                     |
| `owner`       | Dono do estabelecimento     | `/admin/*` (acesso total)            |
| `employee`    | Funcionário                 | `/admin/*` (restrito por permissões) |
| `customer`    | Cliente do estabelecimento  | `/empresa/:slug/*`                   |

### Permissões granulares para `employee`

Cada `EstablishmentMembership` tem flags independentes configuradas pelo dono:

| Permissão                  | Protege as rotas                             |
| -------------------------- | -------------------------------------------- |
| `can_manage_establishment` | `/admin/estabelecimento`, `/admin/aparencia` |
| `can_manage_schedule`      | `/admin/horarios`                            |
| `can_manage_services`      | `/admin/servicos`, `/admin/planos`           |
| `can_manage_team`          | `/admin/equipe`                              |
| `can_manage_stock`         | `/admin/estoque`                             |
| `can_manage_financial`     | `/admin/financeiro/*`                        |

> As permissões são validadas **em dupla camada**:
>
> - **Frontend** — router guard lê `establishment-permissions` do storage e bloqueia antes de renderizar
> - **Backend** — `before_action :require_financial_access!` (e similares) no controller

---

## 🔒 Segurança em Camadas

### Rack::Attack — Regras principais de Rate Limiting

Resumo das regras; a lista completa está em `backend/config/initializers/rack_attack.rb`. Limites por IP são compartilhados pelos aparelhos na mesma rede.

| Regra                    | Limite       | Período | Proteção                         |
| ------------------------ | ------------ | ------- | -------------------------------- |
| `req/ip`                 | 100 req      | 1 min   | DoS genérico                     |
| `logins/staff`           | 5 tentativas | 1 min   | Brute force no login do staff    |
| `logins/staff/email`     | 5 tentativas | 1 min   | Tentativas por conta staff       |
| `logins/customer/ip`     | 5 tentativas | 1 min   | Brute force no login do cliente  |
| `logins/customer/email`  | 5 tentativas | 1 min   | Tentativas por conta/slug        |
| `customer_refresh/ip`    | 10 req       | 1 min   | Abuso de renovação de sessão     |
| `password_resets/ip`     | 3 req        | 5 min   | Email flooding (reset de senha)  |
| `change_password/ip`     | 5 req        | 10 min  | Tentativas de troca de senha     |
| `uploads/ip`             | 5 req        | 1 min   | DoS por upload massivo           |
| `admin/ip`               | 45 req       | 1 min   | Scraping de endpoints admin      |
| `services_write/ip`      | 15 req       | 1 min   | Cadastros automatizados massivos |
| `appointments_create/ip` | 10 req       | 1 min   | Spam de reservas                 |
| `subscriptions_write/ip` | 5 req        | 1 min   | Automações em planos             |
| `onboarding/ip`          | 3 req        | 1 hora  | Bots criando contas em massa     |
| `customer_signup/ip`     | 5 req        | 10 min  | Bots cadastrando clientes        |

Resposta customizada ao bloquear: `HTTP 429` com header `Retry-After` e mensagem em português.

### Content Security Policy

- `default_src: none` — bloqueia tudo por padrão
- `script_src: self` — apenas scripts do próprio domínio
- `frame_ancestors: none` — sem iframes externos (proteção anti-clickjacking)
- `upgrade_insecure_requests` ativado em produção (força HTTPS)
- Modo `report_only` em desenvolvimento (não bloqueia, apenas reporta)

### Sanitização de Dados (Anti-XSS)

`User` e `Customer` sanitizam campos de perfil selecionados em callbacks. Senhas não passam por sanitização HTML ou remoção de espaços no backend de login. Cada nova entrada precisa de validação no servidor; sanitização não substitui autorização, validação de formato nem renderização segura no Vue.

### Auditoria Estática

- **Brakeman** integrado ao processo de desenvolvimento — `brakeman.json` com relatório de segurança

### Tokens seguros

- Respostas JSON nunca expõem `encrypted_password`, `tokens`, `confirmation_token`, `reset_password_token`, `password_digest` (via `as_json`)
- Credenciais de sessão na query string são rejeitadas; respostas sensíveis usam `Cache-Control: no-store`
- Logout, troca de senha e respostas atrasadas são tratados no servidor e nos helpers Vue; consulte [revogação e limites](docs/authentication.md#logout-e-revogação)

### Lock Pessimista no Estoque

- `StockItem#decrement_stock!` usa `lock!` (`SELECT FOR UPDATE`) para garantir consistência em acessos concorrentes

---

## 🗺️ Rotas do Frontend

Todas as rotas têm guards automáticos no `router.beforeEach`:

### Landing (Sistema)

| Rota                   | Página                              |
| ---------------------- | ----------------------------------- |
| `/`                    | Landing page do sistema             |
| `/sistema/criar-conta` | Cadastro de estabelecimento + owner |
| `/sistema/login`       | Login de staff                      |

### Área Pública (por empresa)

| Rota                         | Página                            |
| ---------------------------- | --------------------------------- |
| `/empresa/:slug`             | Página pública do estabelecimento |
| `/empresa/:slug/agendamento` | Fluxo completo de agendamento     |
| `/empresa/:slug/cadastro`    | Cadastro de cliente               |
| `/empresa/:slug/login`       | Login de cliente                  |

### Portal do Cliente (requer JWT)

| Rota                               | Página                    |
| ---------------------------------- | ------------------------- |
| `/empresa/:slug/minha-conta`       | Perfil e dados do cliente |
| `/empresa/:slug/meus-agendamentos` | Agendamentos ativos       |
| `/empresa/:slug/historico`         | Histórico de agendamentos |
| `/empresa/:slug/planos`            | Pacotes de serviços       |

### Painel Admin (requer token Devise)

| Rota                           | Página                    | Permissão necessária       |
| ------------------------------ | ------------------------- | -------------------------- |
| `/admin/estabelecimento`       | Dados da empresa          | `can_manage_establishment` |
| `/admin/aparencia`             | Personalização visual     | `can_manage_establishment` |
| `/admin/servicos`              | Serviços cadastrados      | `can_manage_services`      |
| `/admin/estoque`               | Controle de estoque       | `can_manage_stock`         |
| `/admin/equipe`                | Gestão de equipe          | `can_manage_team`          |
| `/admin/horarios`              | Horários de funcionamento | `can_manage_schedule`      |
| `/admin/agendamentos`          | Agenda do dia             | _(todos)_                  |
| `/admin/planos`                | Pacotes de serviços       | `can_manage_services`      |
| `/admin/financeiro/dashboard`  | Dashboard financeiro      | `can_manage_financial`     |
| `/admin/financeiro/relatorios` | Relatórios                | `can_manage_financial`     |
| `/admin/financeiro/comissoes`  | Comissões da equipe       | `can_manage_financial`     |
| `/admin/financeiro/pacotes`    | Vendas de pacotes         | `can_manage_financial`     |

### Super Admin

| Rota                     | Página                    |
| ------------------------ | ------------------------- |
| `/super-admin/dashboard` | Visão geral da plataforma |
| `/super-admin/planos`    | Gestão de planos SaaS     |

---

## 🔌 Rotas da API

Todas as rotas estão sob o prefixo `/api`.

### Autenticação Staff (Devise Token Auth)

```
POST   /api/devise_users/sign_in
DELETE /api/devise_users/sign_out
POST   /api/devise_users/password     ← Solicitar reset de senha
PUT    /api/devise_users/password     ← Redefinir senha
POST   /api/register                  ← Cadastro de owner
```

### Onboarding

```
POST   /api/owner_onboarding          ← Cria owner, estabelecimento e vínculo em uma transação
```

### Conta do Usuário

```
PATCH  /api/me/change_password
GET    /api/me/sessions
DELETE /api/me/sessions/:client_id
DELETE /api/me/sessions               ← Revoga outras sessões staff
GET    /api/me/subscription
```

### Assinaturas

```
POST   /api/subscriptions
PATCH  /api/subscriptions/:id/cancel
```

### Auth de Clientes (por slug do estabelecimento)

```
POST   /api/customer_auth/:slug/sign_up
POST   /api/customer_auth/:slug/sign_in
POST   /api/customer_auth/:slug/refresh
DELETE /api/customer_auth/:slug/sign_out
POST   /api/customer_auth/:slug/forgot_password
PUT    /api/customer_auth/:slug/reset_password
```

### Admin — Estabelecimento

```
GET    /api/admin/establishment
PATCH  /api/admin/establishment
POST   /api/admin/establishment/upload_logo
POST   /api/admin/establishment/upload_banner
```

### Admin — Equipe

```
GET    /api/admin/team
POST   /api/admin/team
PATCH  /api/admin/team/:id
DELETE /api/admin/team/:id
GET    /api/admin/team/:id/schedule
PATCH  /api/admin/team/:id/schedule
PATCH  /api/admin/team/bulk_schedule
```

### Admin — Agendamentos

```
GET    /api/appointments
GET    /api/appointments/available_slots
GET    /api/appointments/:id
POST   /api/appointments
PATCH  /api/appointments/:id/complete
PATCH  /api/appointments/:id/check_in
PATCH  /api/appointments/:id/cancel
PATCH  /api/appointments/:id/reschedule
GET    /api/appointments/:id/package_occupied_weeks
DELETE /api/appointments/:id
```

### Admin — Serviços, Pacotes e Estoque

```
GET/POST/PATCH/DELETE   /api/services
GET/POST/PATCH/DELETE   /api/service_packages
GET/POST/PATCH/DELETE   /api/stock_items
```

### Admin — Clientes e Feedbacks

```
GET    /api/admin/customers
GET    /api/admin/feedbacks
```

### Portal do Cliente (JWT)

```
GET    /api/customer/profile
PATCH  /api/customer/profile
POST   /api/customer/profile/upload_image

GET    /api/customer/appointments
POST   /api/customer/appointments
PATCH  /api/customer/appointments/:id/cancel
PATCH  /api/customer/appointments/:id/reschedule
GET    /api/customer/appointments/history
POST   /api/customer/appointments/:id/feedback

GET    /api/customer/service_packages
GET    /api/customer/service_packages/available
PATCH  /api/customer/service_packages/:id/cancel
```

### Público (sem autenticação)

```
GET    /api/public/establishments/:slug
GET    /api/public/establishments/:slug/booking_data
GET    /api/public/establishments/:slug/available_days
GET    /api/public/establishments/:slug/available_slots
GET    /api/public/establishments/:slug/service_packages
GET    /api/plans
```

### Financeiro

```
GET    /api/financial/dashboard
GET    /api/financial/reports
GET    /api/financial/packages
GET    /api/financial/commissions
POST   /api/financial/commissions/pay
```

### Super Admin

```
GET    /api/super_admin/dashboard
GET    /api/super_admin/plans
POST   /api/super_admin/plans
PATCH  /api/super_admin/plans/:id
```

---

## 🗄️ Banco de Dados — Modelos

### Namespace `core`

| Model                     | Tabela                      | Descrição                                        |
| ------------------------- | --------------------------- | ------------------------------------------------ |
| `User`                    | `users`                     | Staff: owner, employee, super_admin — Devise     |
| `Customer`                | `customers`                 | Clientes — isolados por `establishment_id`       |
| `Establishment`           | `establishments`            | Empresa contratante com slug único               |
| `EstablishmentMembership` | `establishment_memberships` | Vínculo user ↔ empresa com permissões granulares |
| `Address`                 | `addresses`                 | Endereço do estabelecimento                      |
| `BusinessHour`            | `business_hours`            | Horários de funcionamento da empresa             |
| `AuditLog`                | `audit_logs`                | Log de auditoria de ações sensíveis              |

### Namespace `scheduling`

| Model                 | Tabela                   | Descrição                                   |
| --------------------- | ------------------------ | ------------------------------------------- |
| `Appointment`         | `appointments`           | Agendamento com snapshots + ciclo de status |
| `AppointmentFeedback` | `appointment_feedbacks`  | Avaliação pós-atendimento                   |
| `Service`             | `services`               | Serviços com preço e duração                |
| `ServicePackage`      | `service_packages`       | Pacote com N sessões (soft delete)          |
| `ServicePackageSale`  | `service_package_sales`  | Venda de pacote para cliente                |
| `ServicePackageUsage` | `service_package_usages` | Registro de uso de cada sessão              |

### Namespace `team`

| Model                       | Tabela                         | Descrição                                             |
| --------------------------- | ------------------------------ | ----------------------------------------------------- |
| `EmployeeWorkingHour`       | `employee_working_hours`       | Horário por funcionário/dia (suporta horário partido) |
| `EmployeeScheduleException` | `employee_schedule_exceptions` | Exceções de agenda individuais                        |
| `EmployeeService`           | `employee_services`            | Serviços habilitados por funcionário                  |
| `ArchivedEmployee`          | `archived_employees`           | Histórico de funcionários desligados                  |

### Namespace `financial`

| Model                      | Tabela                       | Descrição                                   |
| -------------------------- | ---------------------------- | ------------------------------------------- |
| `Plan`                     | `plans`                      | Planos SaaS com limites e preço promocional |
| `Subscription`             | `subscriptions`              | Assinatura ativa de um estabelecimento      |
| `SubscriptionCancellation` | `subscription_cancellations` | Motivo de cancelamento                      |
| `Commission`               | `commissions`                | Comissão por agendamento concluído          |
| `FinancialTransaction`     | `financial_transactions`     | Movimentação financeira                     |

### Namespace `inventory`

| Model       | Tabela        | Descrição                                     |
| ----------- | ------------- | --------------------------------------------- |
| `StockItem` | `stock_items` | Item com decremento atômico (lock pessimista) |

---

## 🚀 Como Rodar Localmente

### Pré-requisitos

- Ruby 3.x (ver `.ruby-version`)
- Node.js >= 20.19.0
- PostgreSQL rodando localmente

### 1. Backend (API)

```bash
cd agendamento/api

# Instalar dependências
bundle install

# Configurar variáveis de ambiente
cp .env.production.example .env
# Edite o .env com suas credenciais do banco e chaves secretas

# Criar banco e rodar todas as migrações
rails db:create db:migrate

# (Opcional) Popular com dados de seed
rails db:seed

# Iniciar servidor na porta 3000 (acessível na rede)
bundle exec rails s -b 0.0.0.0 -p 3000
```

### 2. Frontend

```bash
cd agendamento/frontend

# Instalar dependências
npm install

# Configurar variável de ambiente
cp .env.example .env
# Defina: VITE_API_URL=http://localhost:3000

# Iniciar dev server (acessível na rede local)
npm run dev -- --host 0.0.0.0
```

Acesse em `http://localhost:5173`

### Outros comandos úteis

```bash
# Frontend
npm run build          # Build de produção
npm run type-check     # Verificação TypeScript
npm run format         # Formatar código com Prettier

# Backend
bundle exec brakeman   # Auditoria de segurança estática
rails routes           # Ver todas as rotas registradas
```

### Variáveis de Ambiente (`.env`)

```env
# Backend
DATABASE_URL=postgresql://usuario:senha@localhost/agendamento_dev
SECRET_KEY_BASE=...
DEVISE_JWT_SECRET_KEY=...
CUSTOMER_JWT_SECRET=...
RAILS_ENV=development

# Frontend (.env)
VITE_API_URL=http://localhost:3000
```

---

## 🤖 Skills de IA do Projeto

Este projeto possui **12 skills especializadas** em `.skills/` que podem ser acionadas via IA para automatizar tarefas recorrentes de desenvolvimento. As skills são prompts pré-configurados com contexto completo do projeto.

| Skill                        | Função                                                             |
| ---------------------------- | ------------------------------------------------------------------ |
| `00_orquestrador_geral.md`   | Coordena múltiplas skills para tarefas complexas e multi-etapas    |
| `criar_feature_fullstack.md` | Cria features completas: migration → model → controller → view Vue |
| `criar_feature_vue.md`       | Cria páginas e fluxos completos no frontend Vue 3                  |
| `criar_componente_vue.md`    | Cria componentes Vue isolados e reutilizáveis                      |
| `tecnico_de_frontend.md`     | Especialista em Vue 3, Pinia, Bootstrap e UX                       |
| `tecnico_de_seguranca.md`    | Implementa boas práticas de segurança                              |
| `pentester_de_seguranca.md`  | Simula ataques e identifica vulnerabilidades                       |
| `dba_postgres.md`            | Migrations, queries e modelagem de banco                           |
| `gerar_commit.md`            | Gera mensagens de commit no padrão Conventional Commits            |
| `analista_de_codigo.md`      | Analisa qualidade, padrões e débito técnico                        |
| `ceo.md`                     | Visão de produto, priorização e estratégia de negócio              |
| `cto.md`                     | Decisões técnicas de arquitetura e escalabilidade                  |

> **Como usar:** Mencione a skill no início da sua instrução.
>
> _Exemplo: "Como `criar_feature_fullstack`, adicione o módulo de notificações por WhatsApp"_

---

## 📋 Status do Projeto

| Módulo                                        | Status         |
| --------------------------------------------- | -------------- |
| Autenticação Staff (Devise Token Auth)        | ✅ Completo    |
| Autenticação Cliente (JWT próprio + BCrypt)   | ✅ Completo    |
| Validação de força de senha e política de 90 dias | ✅ Implementado |
| Multi-tenant por Slug                         | ✅ Completo    |
| Portal Público do Estabelecimento             | ✅ Completo    |
| Fluxo completo de Agendamento (cliente)       | ✅ Completo    |
| Auto-cancelamento de no-shows                 | ✅ Completo    |
| Painel Admin — Agendamentos                   | ✅ Completo    |
| Painel Admin — Serviços                       | ✅ Completo    |
| Painel Admin — Equipe + Permissões            | ✅ Completo    |
| Painel Admin — Horários (com horário partido) | ✅ Completo    |
| Painel Admin — Estoque (lock pessimista)      | ✅ Completo    |
| Painel Admin — Aparência customizável         | ✅ Completo    |
| Financeiro — Dashboard                        | ✅ Completo    |
| Financeiro — Relatórios                       | ✅ Completo    |
| Financeiro — Comissões (3 modelos)            | ✅ Completo    |
| Pacotes de Serviços com sessões               | ✅ Completo    |
| Planos SaaS + Assinaturas                     | ✅ Completo    |
| Portal do Cliente (área logada)               | ✅ Completo    |
| Feedback de Agendamentos                      | ✅ Completo    |
| Upload de logo, banner e foto do cliente      | ✅ Completo    |
| Super Admin — Dashboard + Planos              | ✅ Completo    |
| Rate Limiting — 11 regras (Rack::Attack)      | ✅ Completo    |
| Content Security Policy                       | ✅ Completo    |
| Sanitização de dados (anti-XSS)               | ✅ Completo    |
| Permissões granulares (frontend + backend)    | ✅ Completo    |
| Email de boas-vindas ao funcionário           | ✅ Completo    |
| Deploy via Docker + Kamal                     | 🔧 Configurado |
| Testes automatizados                          | 🔲 Pendente    |
| Notificações por WhatsApp/Email               | 🔲 Pendente    |

---

## 🚢 Deploy / Produção

> **Este checklist é obrigatório antes de colocar o sistema em produção.**
> Nada aqui precisa ser feito em desenvolvimento — apenas no momento do deploy.

### 1. Segurança — Credenciais

#### 1.1. Remover `.env` do repositório

- [ ] Verificar que `.env` está no `.gitignore` (regra `/.env*` já existe)
- [ ] **Nunca commitar** `.env` com credenciais reais
- [ ] Criar `.env.example` com valores placeholder

#### 1.2. Rotacionar todas as credenciais

- [ ] Rotacionar `SECRET_KEY_BASE` (gerar novo com `rails secret`)
- [ ] Rotacionar `CUSTOMER_JWT_SECRET` (gerar novo com `SecureRandom.hex(64)`)
- [ ] Rotacionar `CUSTOMER_JWT_REFRESH_SECRET` (gerar novo com `SecureRandom.hex(64)`)
- [ ] Rotacionar `EMAIL_PASSWORD` (senha de app Gmail)
- [ ] Rotacionar `DB_PASSWORD`

#### 1.3. Variáveis de ambiente em produção

- [ ] Configurar todas as variáveis do `.env` como variáveis de ambiente no servidor/Docker
- [ ] Usar Docker Secrets ou variáveis de ambiente do provedor (nunca arquivos `.env` em produção)

### 2. Segurança — Configurações Rails

#### 2.1. SSL / HTTPS

- [ ] Adicionar `config.assume_ssl = true` em `config/environments/production.rb` (antes de `config.force_ssl = true`)
- [ ] Verificar se o proxy/load balancer envia `X-Forwarded-Proto: https`
- [ ] Configurar `config.ssl_options = { redirect: { exclude: ->(r) { r.path == "/up" } } }`

#### 2.2. CORS em Produção

- [ ] Definir `ALLOWED_ORIGINS` com o domínio real (ex: `https://seudominio.com.br`)
- [ ] Remover `localhost` das origens permitidas em produção

#### 2.3. Host Authorization

- [ ] Configurar `config.hosts` com os domínios reais do sistema
- [ ] Adicionar domínio do frontend e API

### 3. Segurança — Banco de Dados

#### 3.1. Usuário do banco

- [ ] Criar usuário PostgreSQL com permissões **apenas de leitura/escrita** (sem `SUPERUSER`)
- [ ] Conceder apenas `SELECT, INSERT, UPDATE, DELETE` nas tabelas necessárias
- [ ] Revogar `CREATE`, `DROP`, `ALTER` se não necessário

#### 3.2. Backups

- [ ] Configurar backup automático diário do PostgreSQL (pg_dump ou pg_basebackup)
- [ ] Testar restauração de backup
- [ ] Manter backups por pelo menos 30 dias
- [ ] Armazenar backups em local seguro (fora do servidor principal)

#### 3.3. Criptografia em repouso

- [ ] Habilitar criptografia de disco no servidor de banco (se aplicável)
- [ ] Considerar criptografia de colunas sensíveis (emails, telefones) se necessário

### 4. Segurança — Aplicação

#### 4.1. Rate Limiting

- [ ] Verificar se `Rack::Attack` está lendo `X-Forwarded-For` corretamente atrás de proxy
- [ ] Configurar `config.action_dispatch.trusted_proxy` se necessário

#### 4.2. Logging

- [ ] Verificar que `config.log_level` não está em `debug` em produção
- [ ] Configurar log rotation (já feito em development, verificar production)
- [ ] Monitorar logs de erros (configurar Sentry/Rollbar ou similar)

#### 4.3. Email (SMTP)

- [ ] Configurar SMTP de produção (não usar Gmail para volume alto)
- [ ] Recomendação: Mailgun, SendGrid, Amazon SES, ou Postmark
- [ ] Configurar domínio de envio com SPF, DKIM, DMARC

#### 4.4. Upload de imagens

- [ ] Considerar armazenamento em S3/R2 em produção (não filesystem local)
- [ ] Configurar antivírus para uploads (ClamAV ou similar)

### 5. Deploy / Infraestrutura

#### 5.1. Docker

- [ ] Configurar `Dockerfile` para produção (multi-stage build)
- [ ] Configurar `docker-compose.yml` para produção
- [ ] Expor apenas porta 443 (HTTPS)

#### 5.2. Kamal Deploy (se aplicável)

- [ ] Configurar `config/deploy.yml` com servidor real
- [ ] Configurar variáveis de ambiente no deploy
- [ ] Configurar health checks

#### 5.3. Process Manager

- [ ] Configurar Solid Queue para background jobs em produção
- [ ] Verificar que `recurring.yml` está sendo executado (via Solid Queue recurring)
- [ ] Configurar monitoramento do queue

### 6. LGPD — Antes de Lançar

#### 6.1. Páginas legais

- [ ] Criar página de **Política de Privacidade** completa
- [ ] Criar página de **Termos de Uso** completa
- [ ] Criar página de **Política de Cookies** (se usar cookies de rastreamento)
- [ ] Linkar nos formulários de cadastro

#### 6.2. Consentimento

- [ ] Verificar que `consent_terms_at` e `consent_privacy_at` são preenchidos no signup
- [ ] Criar checkbox obrigatório de aceite nos formulários de cadastro

#### 6.3. DPO (Encarregado)

- [ ] Definir quem é o Encarregado de Dados (DPO)
- [ ] Incluir contato do DPO na Política de Privacidade
- [ ] Criar canal de contato para solicitações LGPD

#### 6.4. Relatório de Impacto

- [ ] Criar Relatório de Impacto à Proteção de Dados Pessoais (RIPD)
- [ ] Documentar quais dados são coletados e por quê

### 7. Monitoramento

#### 7.1. Health Checks

- [ ] Configurar endpoint `/up` para monitoramento
- [ ] Configurar alertas de downtime (UptimeRobot, BetterStack, etc.)

#### 7.2. Erros

- [ ] Integrar Sentry ou Rollbar para captura de erros
- [ ] Configurar alertas por email/Slack para erros críticos

#### 7.3. Performance

- [ ] Monitorar queries lentas (configurar `slow_query_log` no PostgreSQL)
- [ ] Monitorar uso de memória/CPU do servidor

### 8. SEO / Analytics

#### 8.1. Google Analytics

- [ ] Configurar GA4 (se aplicável)
- [ ] Respeitar consentimento LGPD antes de ativar cookies de analytics

#### 8.2. Google Search Console

- [ ] Verificar domínio no Search Console
- [ ] Submeter sitemap

---

## 📄 Licença

Projeto privado. Todos os direitos reservados.
