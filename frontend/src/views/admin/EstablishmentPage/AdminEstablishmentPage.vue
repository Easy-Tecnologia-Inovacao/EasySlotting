<template>
  <AdminLayout>
    <div v-if="loading" class="text-center py-5">
      Carregando configurações...
    </div>

    <div v-else>
      <div v-if="usandoExemplo" class="alert alert-info mb-4">
        Esses são dados de exemplo para te ajudar a preencher. Salve suas configurações para substituir pelos dados reais.
      </div>

      <section class="page-shell">
        <div class="page-content">
          <!-- Header com visual premium -->
          <div class="dashboard-header mb-4 p-4 rounded-4 shadow-sm position-relative overflow-hidden">
            <div class="header-overlay"></div>
            <div class="d-flex align-items-center justify-content-between flex-wrap gap-3 position-relative z-index-1">
              <div class="d-flex align-items-center gap-3">
                <div class="header-icon-container bg-primary bg-opacity-10 text-primary rounded-3 d-flex align-items-center justify-content-center border shadow-sm">
                  <i class="bi bi-shop fs-3"></i>
                </div>
                <div>
                  <h1 class="h3 fw-800 mb-1 tracking-tight text-gradient">Configurações das Páginas</h1>
                  <p class="text-muted mb-0 small-text-responsive">Personalize as informações públicas da sua empresa.</p>
                </div>
              </div>
            </div>
          </div>

          <div class="admin-card shadow-sm mb-4">
            <div class="d-flex justify-content-between align-items-center mb-4 border-bottom pb-3 flex-wrap gap-3">
              <h5 class="fw-bold mb-0 text-body">
                <i class="bi bi-image me-2 text-primary"></i>Imagens Principais
              </h5>
            </div>

            <div class="row g-4 align-items-stretch">
              <div class="col-md-4">
                <input
                  ref="logoInput"
                  type="file"
                  accept="image/png,image/jpeg,image/jpg,image/webp"
                  class="d-none"
                  @change="onLogoSelected"
                >

                <div class="avatar-upload-box h-100 text-center">
                  <div class="position-relative d-inline-block avatar-container transition-all">
                    <img
                      :src="perfil.imagens.avatarUrl"
                      alt="Avatar do Estabelecimento"
                      class="avatar-preview rounded-circle shadow-sm border border-3 border-body"
                    >


                  </div>

                  <div class="mt-3">
                    <h6 class="fw-bold mb-1">Logo / Avatar</h6>
                    <p class="small text-muted mb-1">Formato quadrado (1:1)</p>
                    <p class="small text-muted mb-1">
                      Ideal: <strong>600x600px</strong>
                    </p>
                    <p class="small text-muted mb-3">
                      Mínimo: 400x400px
                    </p>
                    <p class="small text-muted mb-4">
                      PNG, JPG ou WEBP
                    </p>
                  </div>

                  <button
                    type="button"
                    class="btn btn-outline-primary rounded-pill fw-bold px-4 py-2 shadow-sm transition-all hover-lift"
                    @click="abrirSeletorLogo"
                    :disabled="uploadingLogo"
                  >
                    <i class="bi bi-upload me-2"></i>
                    {{ uploadingLogo ? 'Enviando...' : 'Trocar Foto' }}
                  </button>
                </div>
              </div>

              <div class="col-md-8">
                <input
                  ref="bannerInput"
                  type="file"
                  accept="image/png,image/jpeg,image/jpg,image/webp"
                  class="d-none"
                  @change="onBannerSelected"
                >

                <div class="avatar-upload-box h-100 text-center">
                  <div class="w-100 mb-3">
                    <img
                      v-if="perfil.imagens.capaUrl"
                      :src="perfil.imagens.capaUrl"
                      alt="Prévia da capa"
                      class="img-fluid rounded-4 border shadow-sm"
                      style="max-height: 220px; object-fit: cover; width: 100%;"
                    >
                  </div>

                  <div class="mt-2 mb-4">
                    <h6 class="fw-bold mb-1">Capa (Home e Agenda)</h6>
                    <p class="small text-muted mb-1">Proporção recomendada: <strong>1920x600px</strong></p>
                    <p class="small text-muted mb-0">PNG, JPG ou WEBP</p>
                  </div>

                  <button
                    type="button"
                    class="btn btn-outline-primary rounded-pill fw-bold px-4 py-2 shadow-sm transition-all hover-lift"
                    @click="abrirSeletorBanner"
                    :disabled="uploadingBanner"
                  >
                    <i class="bi bi-upload me-2"></i>
                    {{ uploadingBanner ? 'Enviando...' : 'Trocar Capa' }}
                  </button>
                </div>
              </div>
            </div>
          </div>

          <form @submit.prevent="salvarEstabelecimento">
            <div class="admin-card shadow-sm mb-4">
              <div class="d-flex justify-content-between align-items-center mb-4 border-bottom pb-3">
                <h5 class="fw-bold mb-0 text-body">
                  <i class="bi bi-info-circle me-2 text-primary"></i>Informações Básicas (Sobre)
                </h5>
              </div>

              <div class="row g-4">
                <div class="col-md-12 mb-2">
                  <label class="form-label small fw-bold text-muted mb-2 d-block ps-1">
                    Nome do Estabelecimento
                  </label>
                  <input
                    type="text"
                    class="form-control custom-input shadow-sm"
                    v-model="perfil.nome"
                    required
                    maxlength="100"
                  >
                  <div class="form-text small text-muted mt-1 ps-1">
                    O nome comercial da sua empresa que será exibido no topo do site e na aba do navegador.
                  </div>
                </div>

                <div class="col-md-12">
                  <label class="form-label small fw-bold text-muted mb-2 d-block ps-1">
                    Sobre (Aparece na Home e Rodapé)
                  </label>
                  <textarea
                    class="form-control custom-input shadow-sm"
                    rows="3"
                    v-model="perfil.descricao"
                    maxlength="500"
                  ></textarea>
                  <div class="form-text small text-muted mt-1 ps-1">
                    Uma breve descrição sobre a sua empresa, história e diferenciais. Exibida na página inicial e no rodapé.
                  </div>
                </div>
              </div>
            </div>

            <div class="admin-card shadow-sm mb-4">
              <div class="section-header mb-4 border-bottom pb-3">
                <h5 class="fw-bold mb-0 text-body">
                  <i class="bi bi-layout-text-window-reverse me-2 text-primary"></i>Rodapé e Contatos
                </h5>
                <span class="badge bg-secondary bg-opacity-10 text-secondary border">
                  Usado nas páginas
                </span>
              </div>

              <div class="row g-4">
                <div class="col-md-12 mb-2">
                  <label class="form-label small fw-bold text-muted mb-2 d-block ps-1">
                    Endereço Completo
                  </label>
                  <input
                    type="text"
                    class="form-control custom-input shadow-sm"
                    placeholder="Ex: Av. Paulista, 1000 - Centro, SP"
                    v-model="perfil.contato.endereco"
                    required
                    maxlength="200"
                  >
                  <div class="form-text small text-muted mt-1 ps-1">
                    O endereço físico do estabelecimento para indicar aos clientes onde comparecer no dia agendado.
                  </div>
                </div>

                <div class="col-md-12 mb-2">
                  <label class="form-label small fw-bold text-muted mb-2 d-block ps-1">
                    Horário de Funcionamento (Texto)
                  </label>
                  <input
                    type="text"
                    class="form-control custom-input shadow-sm"
                    placeholder="Ex: Terça a Sábado: 09h às 20h"
                    v-model="perfil.funcionamento.horariosTexto"
                    required
                    maxlength="100"
                  >
                  <div class="form-text small text-muted mt-1 ps-1">
                    Texto informativo com os dias e horários gerais de atendimento comercial. Exibido no rodapé do site.
                  </div>
                </div>

                <div class="col-md-6 mb-2">
                  <label class="form-label small fw-bold text-muted mb-2 d-block ps-1">
                    Telefone Fixo
                  </label>
                  <input
                    type="tel"
                    class="form-control custom-input shadow-sm"
                    placeholder="(11) 3333-3333"
                    :value="perfil.contato.telefone"
                    @input="handleTelefoneInput"
                    maxlength="15"
                  >
                  <div class="form-text small text-muted mt-1 ps-1">
                    Telefone fixo para contato comercial e dúvidas gerais dos clientes.
                  </div>
                </div>

                <div class="col-md-6 mb-2">
                  <label class="form-label small fw-bold text-muted mb-2 d-flex align-items-center ps-1">
                    <i class="bi bi-whatsapp me-2 text-success"></i> WhatsApp
                  </label>
                  <input
                    type="tel"
                    class="form-control custom-input shadow-sm"
                    placeholder="(11) 98888-7777"
                    :value="perfil.contato.whatsapp"
                    @input="handleWhatsappInput"
                    maxlength="15"
                  >
                  <div class="form-text small text-muted mt-1 ps-1">
                    WhatsApp para contato comercial. Cria um botão no rodapé para os clientes iniciarem uma conversa direta.
                  </div>
                </div>

                <div class="col-md-6 mb-2">
                  <label class="form-label small fw-bold text-muted mb-2 d-flex align-items-center ps-1">
                    <i class="bi bi-instagram me-2 text-primary"></i> Instagram
                  </label>
                  <div class="input-group shadow-sm border-0 rounded-3 custom-input-group">
                    <span class="input-group-text bg-body-tertiary border-end-0 text-muted px-3 fw-bold">@</span>
                    <input
                      type="text"
                      class="form-control custom-input border-start-0 ps-0 shadow-none"
                      placeholder="perfil"
                      v-model="perfil.contato.instagram"
                      maxlength="50"
                    >
                  </div>
                  <div class="form-text small text-muted mt-1 ps-1">
                    Insira apenas o seu nome de usuário (Ex: minha.empresa), sem a barra ou link completo.
                  </div>
                </div>

                <div class="col-md-6 mb-2">
                  <label class="form-label small fw-bold text-muted mb-2 d-flex align-items-center ps-1">
                    <i class="bi bi-facebook me-2 text-primary"></i> Facebook (Link)
                  </label>
                  <input
                    type="url"
                    class="form-control custom-input shadow-sm"
                    placeholder="https://facebook.com/seu.perfil"
                    v-model="perfil.contato.facebook"
                    maxlength="150"
                  >
                  <div class="form-text small text-muted mt-1 ps-1">
                    Link completo da página comercial da sua empresa (Ex: https://facebook.com/minha.empresa).
                  </div>
                </div>
              </div>
            </div>

            <div class="admin-card shadow-sm mb-4">
              <div class="d-flex justify-content-between align-items-center mb-4 border-bottom pb-3">
                <h5 class="fw-bold mb-0 text-body">
                  <i class="bi bi-stars me-2 text-primary"></i>Facilidades do Local
                </h5>
              </div>

              <div class="row g-5">
                <div class="col-md-6">
                  <label class="form-label small fw-bold text-muted mb-1 d-block ps-1">
                    Comodidades Oferecidas
                  </label>
                  <p class="small text-muted mb-3 ps-1">
                    Marque os diferenciais de conforto e conveniência que o seu espaço oferece para os clientes.
                  </p>

                  <div class="d-flex flex-wrap gap-3 mb-3">
                    <div
                      class="checkbox-box custom-input shadow-sm position-relative pe-5"
                      v-for="item in listaComodidades"
                      :key="item"
                    >
                      <label class="cursor-pointer mb-0 d-flex align-items-center w-100">
                        <input
                          type="checkbox"
                          :value="item"
                          v-model="perfil.facilidades.comodidades"
                          class="form-check-input me-2"
                        >
                        {{ item }}
                      </label>

                      <button
                        type="button"
                        class="btn btn-link btn-sm text-danger position-absolute top-50 end-0 translate-middle-y p-0 pe-2 text-decoration-none opacity-75 hover-opacity-100"
                        @click.stop.prevent="removerComodidade(item)"
                        title="Remover comodidade"
                      >
                        <i class="bi bi-x-circle-fill fs-6"></i>
                      </button>
                    </div>
                  </div>

                  <div class="custom-input-group d-flex align-items-center shadow-sm" style="max-width: 300px;">
                    <input
                      type="text"
                      class="form-control custom-input border-0 shadow-none"
                      placeholder="Nova comodidade..."
                      v-model="novaComodidade"
                      @keyup.enter.prevent="adicionarComodidade"
                    >
                    <button
                      class="btn btn-light bg-transparent border-0 px-3 text-primary transition-all hover-scale"
                      type="button"
                      @click.prevent="adicionarComodidade"
                      title="Adicionar"
                    >
                      <i class="bi bi-plus-circle-fill fs-5"></i>
                    </button>
                  </div>
                </div>

                <div class="col-md-6 border-start border-opacity-25">
                  <label class="form-label small fw-bold text-muted mb-1 d-block ps-1">
                    Formas de Pagamento Aceitas
                  </label>
                  <p class="small text-muted mb-3 ps-1">
                    Selecione quais métodos de pagamento os clientes podem utilizar ao finalizar o serviço diretamente no local.
                  </p>

                  <div class="d-flex flex-wrap gap-3">
                    <label
                      class="checkbox-box custom-input shadow-sm cursor-pointer"
                      v-for="pag in listaPagamentos"
                      :key="pag.id"
                    >
                      <input
                        type="checkbox"
                        :value="pag.id"
                        v-model="perfil.facilidades.pagamentos"
                        class="form-check-input me-2"
                      >
                      <i :class="pag.icon" class="me-1"></i> {{ pag.nome }}
                    </label>
                  </div>
                </div>
              </div>
            </div>

            <div class="admin-card shadow-sm mb-4">
              <div class="d-flex justify-content-between align-items-center mb-4 border-bottom pb-3">
                <h5 class="fw-bold mb-0 text-body">
                  <i class="bi bi-chat-quote me-2 text-primary"></i>Depoimentos
                </h5>

                <button
                  type="button"
                  class="btn btn-sm btn-outline-primary rounded-pill fw-bold"
                  data-bs-toggle="modal"
                  data-bs-target="#modalDepoimentosBanco"
                  @click="carregarFeedbacksDoBanco"
                >
                  <i class="bi bi-plus-circle me-1"></i> Adicionar Depoimento
                </button>
              </div>

              <div class="row g-3">
                <div class="col-md-6 col-lg-4" v-for="(dep, index) in perfil.depoimentos" :key="dep.id">
                  <div
                    class="p-3 border rounded-4 bg-body-tertiary position-relative h-100"
                    :class="{ 'border-primary shadow-sm': dep.exibirNaHome }"
                  >
                    <div class="form-check form-switch position-absolute top-0 start-0 m-2 mt-3 ms-3">
                      <input
                        class="form-check-input cursor-pointer"
                        type="checkbox"
                        role="switch"
                        :id="'switch-' + index"
                        v-model="dep.exibirNaHome"
                      >
                      <label class="form-check-label small text-muted ms-1 cursor-pointer" :for="'switch-' + index">
                        Exibir na Home
                      </label>
                    </div>

                    <button
                      type="button"
                      class="btn btn-sm btn-danger position-absolute top-0 end-0 m-2 rounded-circle px-2 py-1"
                      @click="removerDepoimentoDaLista(dep.id)"
                    >
                      <i class="bi bi-trash"></i>
                    </button>

                    <div class="d-flex align-items-center gap-2 mb-2 mt-4">
                      <img :src="buildFileUrl(dep.foto)" class="rounded-circle" style="width: 40px; height: 40px; object-fit: cover;">
                      <div>
                        <h6 class="mb-0 fw-bold small">{{ dep.nome }}</h6>
                        <small class="text-muted" style="font-size: 0.7rem;">{{ dep.servico }}</small>
                      </div>
                    </div>

                    <div class="text-warning mb-1 small">
                      <i class="bi bi-star-fill" v-for="n in Math.floor(dep.rating)" :key="'full-' + n"></i>
                      <i v-if="dep.rating % 1 !== 0" class="bi bi-star-half"></i>
                      <i v-for="n in (5 - Math.ceil(dep.rating))" :key="'empty-' + n" class="bi bi-star"></i>
                    </div>

                    <p class="small mb-0 fst-italic opacity-75">"{{ dep.texto }}"</p>
                  </div>
                </div>

                <div v-if="perfil.depoimentos.length === 0" class="col-12 text-center py-4 text-muted">
                  <p class="mb-0 small">Nenhum depoimento selecionado para exibição.</p>
                </div>
              </div>
            </div>

            <!-- Páginas Legais -->
            <div v-if="canEditOwnerSettings" class="admin-card shadow-sm mb-4">
              <div class="d-flex justify-content-between align-items-center mb-4 border-bottom pb-3">
                <h5 class="fw-bold mb-0 text-body">
                  <i class="bi bi-file-earmark-text me-2 text-primary"></i>Páginas Legais
                </h5>
                <span class="badge bg-info bg-opacity-10 text-info border border-info border-opacity-25">
                  <i class="bi bi-info-circle me-1"></i>LGPD
                </span>
              </div>

              <p class="small text-muted mb-4">
                Configure as páginas legais do seu site. Essas páginas aparecerão no rodapé para seus clientes.
              </p>

              <div class="row g-3">
                <!-- Política de Privacidade -->
                <div class="col-md-4 col-lg-2">
                  <button
                    type="button"
                    class="btn w-100 p-3 border rounded-4 bg-body-tertiary text-start h-100 position-relative"
                    @click="openLegalEditor('privacy_policy')"
                  >
                    <i class="bi bi-shield-lock text-primary fs-4 d-block mb-2"></i>
                    <h6 class="fw-bold mb-1 small">Política de Privacidade</h6>
                    <p class="small text-muted mb-0" style="font-size: 0.7rem;">LGPD</p>
                    <span v-if="perfil.legal_pages.privacy_policy" class="badge bg-success bg-opacity-10 text-success mt-2" style="font-size: 0.65rem;">
                      <i class="bi bi-check-circle me-1"></i>Preenchido
                    </span>
                  </button>
                </div>

                <!-- Termos de Uso -->
                <div class="col-md-4 col-lg-2">
                  <button
                    type="button"
                    class="btn w-100 p-3 border rounded-4 bg-body-tertiary text-start h-100 position-relative"
                    @click="openLegalEditor('terms_of_use')"
                  >
                    <i class="bi bi-file-earmark-text text-primary fs-4 d-block mb-2"></i>
                    <h6 class="fw-bold mb-1 small">Termos de Uso</h6>
                    <p class="small text-muted mb-0" style="font-size: 0.7rem;">Regras</p>
                    <span v-if="perfil.legal_pages.terms_of_use" class="badge bg-success bg-opacity-10 text-success mt-2" style="font-size: 0.65rem;">
                      <i class="bi bi-check-circle me-1"></i>Preenchido
                    </span>
                  </button>
                </div>

                <!-- Política de Cookies -->
                <div class="col-md-4 col-lg-2">
                  <button
                    type="button"
                    class="btn w-100 p-3 border rounded-4 bg-body-tertiary text-start h-100 position-relative"
                    @click="openLegalEditor('cookie_policy')"
                  >
                    <i class="bi bi-cookie text-primary fs-4 d-block mb-2"></i>
                    <h6 class="fw-bold mb-1 small">Política de Cookies</h6>
                    <p class="small text-muted mb-0" style="font-size: 0.7rem;">Cookies</p>
                    <span v-if="perfil.legal_pages.cookie_policy" class="badge bg-success bg-opacity-10 text-success mt-2" style="font-size: 0.65rem;">
                      <i class="bi bi-check-circle me-1"></i>Preenchido
                    </span>
                  </button>
                </div>

                <!-- Quem Somos -->
                <div class="col-md-4 col-lg-2">
                  <button
                    type="button"
                    class="btn w-100 p-3 border rounded-4 bg-body-tertiary text-start h-100 position-relative"
                    @click="openLegalEditor('about_us')"
                  >
                    <i class="bi bi-info-circle text-primary fs-4 d-block mb-2"></i>
                    <h6 class="fw-bold mb-1 small">Quem Somos</h6>
                    <p class="small text-muted mb-0" style="font-size: 0.7rem;">Sobre</p>
                    <span v-if="perfil.legal_pages.about_us" class="badge bg-success bg-opacity-10 text-success mt-2" style="font-size: 0.65rem;">
                      <i class="bi bi-check-circle me-1"></i>Preenchido
                    </span>
                  </button>
                </div>

                <!-- FAQ -->
                <div class="col-md-4 col-lg-2">
                  <button
                    type="button"
                    class="btn w-100 p-3 border rounded-4 bg-body-tertiary text-start h-100 position-relative"
                    @click="openLegalEditor('faq')"
                  >
                    <i class="bi bi-question-circle text-primary fs-4 d-block mb-2"></i>
                    <h6 class="fw-bold mb-1 small">Perguntas Frequentes</h6>
                    <p class="small text-muted mb-0" style="font-size: 0.7rem;">FAQ</p>
                    <span v-if="perfil.legal_pages.faq" class="badge bg-success bg-opacity-10 text-success mt-2" style="font-size: 0.65rem;">
                      <i class="bi bi-check-circle me-1"></i>Preenchido
                    </span>
                  </button>
                </div>

                <!-- Contato -->
                <div class="col-md-4 col-lg-2">
                  <button
                    type="button"
                    class="btn w-100 p-3 border rounded-4 bg-body-tertiary text-start h-100 position-relative"
                    @click="openLegalEditor('contact_info')"
                  >
                    <i class="bi bi-envelope text-primary fs-4 d-block mb-2"></i>
                    <h6 class="fw-bold mb-1 small">Contato</h6>
                    <p class="small text-muted mb-0" style="font-size: 0.7rem;">Dados</p>
                    <span v-if="perfil.legal_pages.contact_info" class="badge bg-success bg-opacity-10 text-success mt-2" style="font-size: 0.65rem;">
                      <i class="bi bi-check-circle me-1"></i>Preenchido
                    </span>
                  </button>
                </div>
              </div>
            </div>

            <div class="d-flex justify-content-end align-items-center mt-4 mb-5 border-top pt-4">
              <button 
                type="submit" 
                class="btn btn-primary btn-lg rounded-pill px-5 py-3 fw-bold shadow hover-lift transition-all"
                :disabled="loadingSubmit || uploadingLogo || uploadingBanner"
              >
                <i v-if="loadingSubmit" class="spinner-border spinner-border-sm me-2" role="status"></i>
                <i v-else class="bi bi-check2-circle me-2"></i>
                {{ loadingSubmit ? 'Salvando...' : 'Salvar Configurações' }}
              </button>
            </div>
          </form>
        </div>
      </section>
    </div>

      <div class="modal fade" id="modalDepoimentosBanco" tabindex="-1" aria-hidden="true">
      <div class="modal-dialog modal-dialog-centered modal-dialog-scrollable modal-lg">
        <div class="modal-content border-0 shadow-lg rounded-4" style="background: var(--glass-bg); backdrop-filter: blur(15px);">
          <div class="modal-header border-bottom border-opacity-10">
            <h5 class="modal-title fw-bold">
              <i class="bi bi-cloud-download me-2 text-primary"></i> Selecionar Depoimentos do Banco
            </h5>
            <button type="button" class="btn-close shadow-none" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>

          <div class="modal-body p-4">
            <p class="small text-muted mb-4">
              Avaliações dos seus clientes. Adicione as que deseja exibir na página inicial.
            </p>

            <!-- Loading -->
            <div v-if="loadingFeedbacks" class="text-center py-4">
              <div class="spinner-border text-primary spinner-border-sm" role="status"></div>
              <p class="small text-muted mt-2 mb-0">Carregando avaliações...</p>
            </div>

            <!-- Nenhum feedback -->
            <div v-else-if="!feedbacksDoBanco.length" class="text-center py-4 text-muted">
              <i class="bi bi-chat-square-dots fs-2"></i>
              <p class="small mt-2 mb-0">Nenhuma avaliação com comentário encontrada ainda.</p>
            </div>

            <div v-else class="d-flex flex-column gap-3">
              <div
                v-for="depBanco in feedbacksDoBanco"
                :key="depBanco.id"
                class="p-3 border rounded-3 d-flex justify-content-between align-items-center transition-all bg-body-tertiary"
                :class="{ 'border-primary shadow-sm': isDepoimentoNaLista(depBanco.id) }"
              >
                <div class="d-flex align-items-center gap-3">
                  <img :src="buildFileUrl(depBanco.foto)" class="rounded-circle" style="width: 50px; height: 50px; object-fit: cover;">
                  <div>
                    <h6 class="mb-0 fw-bold">
                      {{ depBanco.nome }}
                      <span class="badge bg-secondary bg-opacity-10 text-body fw-normal ms-2 border">
                        {{ depBanco.data }}
                      </span>
                    </h6>

                    <div class="text-warning small my-1">
                      <i class="bi bi-star-fill" v-for="n in Math.floor(depBanco.rating)" :key="'mod-full-' + n"></i>
                      <i v-if="depBanco.rating % 1 !== 0" class="bi bi-star-half"></i>
                      <i v-for="n in (5 - Math.ceil(depBanco.rating))" :key="'mod-empty-' + n" class="bi bi-star"></i>
                      <span class="text-muted ms-2" style="font-size: 0.75rem;">{{ depBanco.servico }}</span>
                    </div>

                    <p class="small mb-0 opacity-75 text-truncate" style="max-width: 400px;">
                      "{{ depBanco.texto }}"
                    </p>
                  </div>
                </div>

                <div>
                  <button
                    v-if="!isDepoimentoNaLista(depBanco.id)"
                    class="btn btn-sm btn-outline-primary rounded-pill fw-bold"
                    @click="adicionarDepoimentoDoBanco(depBanco)"
                  >
                    Adicionar
                  </button>

                  <button v-else class="btn btn-sm btn-success rounded-pill fw-bold disabled">
                    <i class="bi bi-check2"></i> Adicionado
                  </button>
                </div>
              </div>
            </div>
          </div>

          <div class="modal-footer border-top border-opacity-10">
            <button type="button" class="btn btn-light rounded-pill fw-bold px-4 border shadow-sm" data-bs-dismiss="modal">
              Fechar
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal Unificado de Edição de Páginas Legais & Live Preview -->
    <LegalPageEditorModal
      :show="showLegalEditorModal"
      :initial-page="activeLegalEditorPage"
      v-model:legal-pages="perfil.legal_pages"
      :establishment-name="perfil.nome"
      :establishment-email="perfil.email"
      :establishment-phone="perfil.whatsapp"
      @close="showLegalEditorModal = false"
      @save="salvarEstabelecimento"
    />

  </AdminLayout>
</template>

<script setup>
import AdminLayout from '@/views/admin/Layout/AdminLayout.vue'
import LegalPageEditorModal from '@/components/admin/LegalPageEditorModal.vue'
import { ref, onMounted, nextTick } from 'vue'
import { api } from '@/services/api'
import { useThemeStore } from '@/stores/themeStore'
import { useRoute, useRouter } from 'vue-router'
import { Modal } from 'bootstrap'
import DOMPurify from 'dompurify'

const showLegalEditorModal = ref(false)
const activeLegalEditorPage = ref('privacy_policy')

function openLegalEditor(pageKey) {
  activeLegalEditorPage.value = pageKey
  showLegalEditorModal.value = true
}

const store = useThemeStore()
const route = useRoute()
const router = useRouter()

const listaComodidades = ref(['Ar Condicionado', 'Wi-Fi', 'Mesa de Sinuca', 'Bebidas', 'Estacionamento'])
const novaComodidade = ref('')

const listaPagamentos = [
  { id: 'cartao', nome: 'Cartão de Crédito/Débito', icon: 'bi-credit-card' },
  { id: 'pix', nome: 'Pix', icon: 'bi-qr-code' },
  { id: 'dinheiro', nome: 'Dinheiro', icon: 'bi-cash' }
]

const depoimentosDoBancoMock = ref([
  { id: 101, nome: 'Carlos Mendes', servico: 'Corte Degradê', foto: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200', rating: 5, texto: 'Melhor fade da cidade! Atendimento excelente, ambiente top.', data: '12/02/2026' },
  { id: 102, nome: 'Lucas Ferreira', servico: 'Corte e Barba', foto: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200', rating: 5, texto: 'O serviço de toalha quente é sensacional. Profissionais de primeira!', data: '05/03/2026' },
  { id: 103, nome: 'Rafael Souza', servico: 'Barboterapia', foto: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200', rating: 4.5, texto: 'Fui dar um trato na barba e curti muito. Chegar na hora certa não tem preço.', data: '28/02/2026' },
  { id: 104, nome: 'Marcos Silva', servico: 'Corte Clássico', foto: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200', rating: 5, texto: 'Difícil achar quem corte bem na tesoura hoje em dia, mas aqui os caras manjam muito.', data: '10/01/2026' },
  { id: 105, nome: 'Thiago Alves', servico: 'Nevou', foto: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=200', rating: 3.5, texto: 'Mandei o nevou pro final de ano e o resultado ficou insano.', data: '20/12/2025' }
])

const logoInput = ref(null)
const bannerInput = ref(null)
const uploadingLogo = ref(false)
const uploadingBanner = ref(false)
const loadingSubmit = ref(false)
const canEditOwnerSettings = ref(false)

function sanitizeText(text) {
  if (typeof text !== 'string') return ''
  return text
    .replace(/<[^>]*>/g, '') // Remove HTML tags
    .replace(/[&<>"']/g, (m) => {
      const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#x27;'
      }
      return map[m] || m
    })
    .trim()
}

// 🔒 SEGURANÇA: Sanitização robusta com DOMPurify para páginas legais (Stored XSS mitigation)
function sanitizeLegalHtml(text) {
  if (typeof text !== 'string') return ''
  return DOMPurify.sanitize(text, {
    ALLOWED_TAGS: [
      'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'br', 'ul', 'ol', 'li',
      'strong', 'em', 'b', 'i', 'u', 's', 'strike', 'a', 'span', 'div',
      'blockquote', 'table', 'thead', 'tbody', 'tr', 'th', 'td', 'hr', 'mark'
    ],
    ALLOWED_ATTR: ['href', 'class', 'target', 'rel', 'title'],
    ALLOW_DATA_ATTR: false
  }).trim()
}

function sanitizePhone(phone) {
  if (!phone) return ''
  return phone.replace(/[^\d()-\s]/g, '').trim()
}

function validateUrl(url) {
  if (!url) return true
  try {
    const parsed = new URL(url)
    return parsed.protocol === 'http:' || parsed.protocol === 'https:'
  } catch {
    return false
  }
}

function formatarTelefone(value) {
  if (!value) return ''
  const val = value.replace(/\D/g, '')
  if (val.length <= 10) {
    return val
      .replace(/^(\d{2})(\d)/, '($1) $2')
      .replace(/(\d{4})(\d)/, '$1-$2')
      .substring(0, 14)
  }
  return val
    .replace(/^(\d{2})(\d)/, '($1) $2')
    .replace(/(\d{5})(\d)/, '$1-$2')
    .substring(0, 15)
}

function handleTelefoneInput(e) {
  perfil.value.contato.telefone = formatarTelefone(e.target.value)
}

function handleWhatsappInput(e) {
  perfil.value.contato.whatsapp = formatarTelefone(e.target.value)
}

function getApiBaseUrl() {
  return (api.defaults.baseURL || '').replace(/\/api\/?$/, '')
}

function getDefaultAvatarUrl() {
  return `${getApiBaseUrl()}/uploads/establishments/Avatar-Padrao.jpg`
}

function getDefaultBannerUrl() {
  return `${getApiBaseUrl()}/uploads/establishments/Capa-Padrao.jpg`
}

const perfilVazio = () => ({
  nome: '',
  descricao: '',
  imagens: {
    avatarUrl: getDefaultAvatarUrl(),
    capaUrl: getDefaultBannerUrl()
  },
  contato: {
    endereco: '',
    telefone: '',
    whatsapp: '',
    instagram: '',
    facebook: ''
  },
  funcionamento: {
    horariosTexto: ''
  },
  facilidades: {
    comodidades: [],
    pagamentos: []
  },
  depoimentos: [],
  legal_pages: {
    privacy_policy: `<h2>Política de Privacidade</h2>

<p>A EasySlotting, em conjunto com os estabelecimentos parceiros, compromete-se a proteger a privacidade e os dados pessoais de seus clientes e visitantes, em conformidade com a Lei Geral de Proteção de Dados (LGPD - Lei nº 13.709/2018).</p>

<h2>1. Controlador dos Dados</h2>
<p>O controlador dos dados pessoais é o estabelecimento parceiro onde você realizou seu cadastro. A EasySlotting atua como operadora de dados, processando informações em nome do estabelecimento.</p>

<h2>2. Dados Coletados</h2>
<p>Coletamos as seguintes informações durante o uso dos nossos serviços:</p>
<ul>
  <li><strong>Dados de cadastro:</strong> Nome, e-mail, telefone e celular</li>
  <li><strong>Dados de agendamento:</strong> Data, horário, serviço selecionado e profissional</li>
  <li><strong>Dados de navegação:</strong> Informações de acesso (IP, dispositivo, navegador) para fins de segurança</li>
  <li><strong>Feedbacks:</strong> Avaliações e comentários (sempre anônimos)</li>
</ul>

<h2>3. Finalidade do Tratamento</h2>
<p>Seus dados são utilizados para:</p>
<ul>
  <li>Processar e confirmar agendamentos</li>
  <li>Enviar notificações sobre seus atendimentos</li>
  <li>Gerenciar pacotes mensais e assinaturas</li>
  <li>Garantir a segurança da sua conta</li>
  <li>Melhorar a qualidade dos serviços</li>
  <li>Cumprir obrigações legais e fiscais</li>
</ul>

<h2>4. Base Legal</h2>
<p>O tratamento dos seus dados é realizado com base em:</p>
<ul>
  <li><strong>Execução de contrato:</strong> Prestação dos serviços de agendamento</li>
  <li><strong>Consentimento:</strong> Para comunicações de marketing (quando aplicável)</li>
  <li><strong>Legítimo interesse:</strong> Para segurança e melhoria dos serviços</li>
</ul>

<h2>5. Compartilhamento de Dados</h2>
<p>Não compartilhamos seus dados pessoais com terceiros para fins de marketing. Seus dados podem ser compartilhados apenas quando:</p>
<ul>
  <li>Necessário para cumprir obrigação legal ou regulatória</li>
  <li>Autorizado por você de forma expressa</li>
  <li>Necessário para a prestação do serviço contratado (ex: profissional do estabelecimento)</li>
  <li>Proteção dos direitos do estabelecimento ou da EasySlotting</li>
</ul>

<h2>6. Segurança dos Dados</h2>
<p>Implementamos medidas de segurança técnicas e organizacionais robustas:</p>
<ul>
  <li>Criptografia de dados em trânsito (HTTPS/TLS)</li>
  <li>Senhas armazenadas com hash bcrypt (irrecuperáveis)</li>
  <li>Controle de acesso por autenticação JWT</li>
  <li>Registro de auditoria de todas as ações sensíveis</li>
  <li>Rate limiting para prevenir abusos</li>
</ul>

<h2>7. Retenção dos Dados</h2>
<p>Seus dados são mantidos pelo tempo necessário para cumprir as finalidades descritas nesta política, salvo quando houver obrigação legal de retenção superior.</p>

<h2>8. Seus Direitos (LGPD)</h2>
<p>Conforme a Lei Geral de Proteção de Dados, você tem direito a:</p>
<ul>
  <li><strong>Confirmação:</strong> Saber se tratamos seus dados</li>
  <li><strong>Acesso:</strong> Obter cópia dos seus dados</li>
  <li><strong>Correção:</strong> Corrigir dados incompletos ou desatualizados</li>
  <li><strong>Anonimização/Bloqueio/Exclusão:</strong> De dados desnecessários ou excessivos</li>
  <li><strong>Portabilidade:</strong> Solicitar transferência dos seus dados</li>
  <li><strong>Eliminação:</strong> Solicitar a exclusão dos dados tratados com consentimento</li>
  <li><strong>Revogação:</strong> Revogar o consentimento a qualquer momento</li>
  <li><strong>Oposição:</strong> Opor-se ao tratamento em certainas hipóteses</li>
</ul>

<h2>9. Cookies</h2>
<p>Utilizamos cookies essenciais para o funcionamento do site. Para mais detalhes, consulte nossa <a href="/privacy_policy">Política de Cookies</a>.</p>

<h2>10. Transferência Internacional</h2>
<p>Seus dados não são transferidos para fora do Brasil, salvo quando estritamente necessário e com as garantias legais exigidas pela LGPD.</p>

<h2>11. Menores de Idade</h2>
<p>Nossos serviços são destinados a maiores de 18 anos. Em caso de necessidade de tratamento de dados de menores, o consentimento deverá ser dado pelo responsável legal.</p>

<h2>12. Alterações nesta Política</h2>
<p>Esta Política de Privacidade pode ser atualizada periodicamente. Recomendamos que você consulte esta página regularmente.</p>

<h2>13. Canal de Comunicação</h2>
<p>Para exercer seus direitos ou esclarecer dúvidas sobre esta política, entre em contato com o estabelecimento diretamente pelo painel do cliente ou pelos canais de contato disponíveis no site.</p>

<p><em>Última atualização: 21/06/2026</em></p>
<p><em>Política gerenciada pela plataforma EasySlotting em conformidade com a LGPD.</em></p>`,

    terms_of_use: `<h2>Termos de Uso</h2>

<p>Ao utilizar o site e os serviços disponibilizados pela EasySlotting em parceria com o estabelecimento, você concorda com os seguintes Termos de Uso.</p>

<h2>1. Definições</h2>
<ul>
  <li><strong>Plataforma:</strong> Sistema EasySlotting de agendamento online</li>
  <li><strong>Estabelecimento:</strong> Empresa parceira que utiliza a plataforma</li>
  <li><strong>Cliente:</strong> Usuário que realiza cadastro e agendamentos</li>
  <li><strong>Serviço:</strong> Atendimento oferecido pelo estabelecimento</li>
</ul>

<h2>2. Cadastro</h2>
<ul>
  <li>Para utilizar a plataforma, é necessário criar uma conta com informações verdadeiras e atualizadas</li>
  <li>O cliente é responsável por manter a confidencialidade de sua senha</li>
  <li>É proibido o cadastro com dados falsos ou de terceiros</li>
  <li>O estabelecimento pode recusar ou cancelar cadastros que violem estes termos</li>
</ul>

<h2>3. Agendamentos</h2>
<ul>
  <li>Agendamentos estão sujeitos à disponibilidade de horários e profissionais</li>
  <li>A confirmação do agendamento é enviada por e-mail após a conclusão</li>
  <li>O cliente deve chegar no horário agendado. Atrasos superiores a 15 minutos podem resultar no cancelamento</li>
  <li>Em caso de não comparecimento (no-show), o estabelecimento poderá aplicar restrições futuras</li>
</ul>

<h2>4. Cancelamentos e Reagendamentos</h2>
<ul>
  <li>O cliente pode cancelar ou reagendar pela plataforma</li>
  <li>Cancelamentos devem ser feitos com antecedência mínima de 2 horas</li>
  <li>Reagendamentos estão sujeitos à disponibilidade</li>
  <li>Cancelamentos repetidos podem resultar em restrições de agendamento</li>
</ul>

<h2>5. Pacotes Mensais</h2>
<ul>
  <li>Pacotes mensais oferecem múltiplas sessões por valor reduzido</li>
  <li>As sessões devem ser agendadas respeitando a regra de uma sessão por semana</li>
  <li>Sessões não utilizadas no prazo não são acumuladas</li>
  <li>O cancelamento de pacotes segue política específica disponível no painel do cliente</li>
</ul>

<h2>6. Pagamentos</h2>
<ul>
  <li>Os preços são definidos pelo estabelecimento e podem ser alterados sem aviso prévio</li>
  <li>O pagamento é realizado diretamente no estabelecimento na data do atendimento</li>
  <li>A EasySlotting não processa pagamentos online nesta versão</li>
</ul>

<h2>7. Propriedade Intelectual</h2>
<ul>
  <li>Todo o conteúdo da plataforma (código, design, textos, logotipos) é de propriedade da EasySlotting</li>
  <li>O conteúdo fornecido pelo estabelecimento (fotos, descrições) é de propriedade do estabelecimento</li>
  <li>É proibida a reprodução, distribuição ou modificação não autorizada</li>
</ul>

<h2>8. Conduta do Cliente</h2>
<p>Ao utilizar a plataforma, o cliente compromete-se a:</p>
<ul>
  <li>Tratar profissionais e outros clientes com respeito</li>
  <li>Não utilizar a plataforma para fins ilícitos</li>
  <li>Não tentar acessar áreas restritas ou contas de outros usuários</li>
  <li>Comunicar qualquer problema ou vulnerabilidade encontrada</li>
</ul>

<h2>9. Limitação de Responsabilidade</h2>
<ul>
  <li>A EasySlotting atua como intermediadora de agendamentos</li>
  <li>A qualidade do serviço é responsabilidade do estabelecimento</li>
  <li>A EasySlotting não se responsabiliza por danos diretos ou indiretos decorrentes do uso dos serviços</li>
  <li>Em caso de disputa, o cliente deve entrar em contato diretamente com o estabelecimento</li>
</ul>

<h2>10. Suspensão ou Cancelamento de Conta</h2>
<p>A EasySlotting ou o estabelecimento podem suspender ou cancelar contas que:</p>
<ul>
  <li>Violem estes Termos de Uso</li>
  <li>Apresentem comportamento fraudulento</li>
  <li>Causem danos a outros usuários ou ao estabelecimento</li>
</ul>

<h2>11. Alterações nos Termos</h2>
<p>Estes Termos de Uso podem ser alterados a qualquer momento. O uso continuado da plataforma após alterações constitui aceitação dos novos termos.</p>

<h2>12. Legislação Aplicável</h2>
<p>Estes termos são regidos pelas leis da República Federativa do Brasil. Fica eleito o foro da comarca de [CIDADE DO ESTABELECIMENTO] para dirimir quaisquer questões.</p>

<h2>13. Canal de Suporte</h2>
<p>Em caso de dúvidas, entre em contato com o suporte da EasySlotting ou diretamente com o estabelecimento pelos canais disponíveis no site.</p>

<p><em>Última atualização: 21/06/2026</em></p>
<p><em>Termos gerenciados pela plataforma EasySlotting.</em></p>`,

    cookie_policy: `<h2>Política de Cookies</h2>

<p>Esta Política de Cookies descreve como a EasySlotting utiliza cookies e tecnologias similares quando você acessa e utiliza nossa plataforma de agendamento online.</p>

<h2>1. O que são Cookies?</h2>
<p>Cookies são pequenos arquivos de texto armazenados no seu dispositivo (computador, tablet ou smartphone) quando você visita um site. Eles permitem que o site reconheça sua visita e melhore sua experiência de navegação.</p>

<h2>2. Cookies que Utilizamos</h2>

<h3>2.1 Cookies Essenciais</h3>
<p><strong>Necessários para o funcionamento básico da plataforma. Não podem ser desativados.</strong></p>
<table>
  <tr><th>Cookie</th><th>Finalidade</th><th>Duração</th></tr>
  <tr><td>session_id</td><td>Mantém sua sessão ativa durante a navegação</td><td>Sessão</td></tr>
  <tr><td>csrf_token</td><td>Protege contra ataques de falsificação de solicitações (CSRF)</td><td>Sessão</td></tr>
  <tr><td>refresh_token</td><td>Armazena o token de renovação de sessão (httpOnly, inacessível via JavaScript)</td><td>7 dias</td></tr>
  <tr><td>customer-access-token</td><td>Token de autenticação do cliente (JWT)</td><td>15 minutos</td></tr>
</table>

<h3>2.2 Cookies de Preferências</h3>
<p><strong>Permitem que a plataforma lembre suas preferências de personalização.</strong></p>
<table>
  <tr><th>Cookie</th><th>Finalidade</th><th>Duração</th></tr>
  <tr><td>easyslotting_theme</td><td>Armazena sua preferência de tema visual (claro/escuro)</td><td>Indefinida</td></tr>
  <tr><td>site-slug</td><td>Identifica o estabelecimento acessado</td><td>Sessão</td></tr>
</table>

<h3>2.3 Cookies de Funcionalidade</h3>
<p><strong>Auxiliam no funcionamento da plataforma e coleta de dados anônimos de uso.</strong></p>
<table>
  <tr><th>Cookie</th><th>Finalidade</th><th>Duração</th></tr>
  <tr><td>customer-data</td><td>Dados básicos do cliente para exibição na interface</td><td>Sessão ou 30 dias</td></tr>
  <tr><td>public-establishment-*</td><td>Cache de dados do estabelecimento para carregamento mais rápido</td><td>Indefinida</td></tr>
</table>

<h2>3. Cookies de Terceiros</h2>
<p>A EasySlotting não utiliza cookies de terceiros para fins de rastreamento ou publicidade. Todos os cookies são第一party (primeira parte) e estão sob nosso controle direto.</p>

<h2>4. Segurança dos Cookies</h2>
<ul>
  <li><strong>HttpOnly:</strong> Cookies sensíveis (como refresh_token) são marcados como HttpOnly, impossibilitando acesso via JavaScript</li>
  <li><strong>Secure:</strong> Em produção, todos os cookies são transmitidos apenas via HTTPS</li>
  <li><strong>SameSite:</strong> Cookies utilizam SameSite=Strict para prevenir ataques CSRF</li>
  <li><strong>Criptografia:</strong> Cookies sensíveis são criptografados pelo servidor Rails</li>
</ul>

<h2>5. Como Gerenciar Cookies</h2>
<p>Você pode gerenciar cookies através das configurações do seu navegador:</p>
<ul>
  <li><strong>Google Chrome:</strong> Configurações → Privacidade e Segurança → Cookies e outros dados do site</li>
  <li><strong>Mozilla Firefox:</strong> Configurações → Privacidade e Segurança → Cookies e Dados do Site</li>
  <li><strong>Safari:</strong> Preferências → Privacidade → Gerenciar Cookies e dados do site</li>
  <li><strong>Microsoft Edge:</strong> Configurações → Privacidade, Pesquisa e Serviços → Cookies e permissões do site</li>
</ul>

<p><strong>Atenção:</strong> Desativar cookies essenciais pode comprometer o funcionamento da plataforma, incluindo login e agendamentos.</p>

<h2>6. Cookies e a LGPD</h2>
<p>Esta política está em conformidade com a Lei Geral de Proteção de Dados (LGPD). O uso de cookies essenciais é necessário para a prestação do serviço. Cookies opcionais só serão utilizados com seu consentimento.</p>

<h2>7. Alterações nesta Política</h2>
<p>Esta Política de Cookies pode ser atualizada periodicamente. Recomendamos que você consulte esta página regularmente para se manter informado.</p>

<h2>8. Canal de Comunicação</h2>
<p>Em caso de dúvidas sobre esta política, entre em contato com o estabelecimento ou com o suporte da EasySlotting.</p>

<p><em>Última atualização: 21/06/2026</em></p>
<p><em>Política gerenciada pela plataforma EasySlotting em conformidade com a LGPD.</em></p>`,

    about_us: `<h2>Quem Somos</h2>

<p>Conheça um pouco mais sobre o nosso estabelecimento e o que nos motiva a oferecer o melhor serviço aos nossos clientes.</p>

<h2>Nossa História</h2>
<p>[Conte a história do seu estabelecimento. Quando foi fundado, como surgiu a ideia, qual era o sonho inicial dos fundadores. Exemplo: "Fundado em 2020, o [NOME] nasceu da paixão do seu fundador por [SERVIÇO]. Começando como um pequeno espaço, hoje atendemos centenas de clientes satisfeitos."]</p>

<h2>Nossa Missão</h2>
<p>[Descreva a missão do seu estabelecimento. O que vocês fazem e por quê. Exemplo: "Nossa missão é proporcionar uma experiência única e personalizada, onde cada cliente se sinta especial e saia satisfeito com o resultado."]</p>

<h2>Nossos Valores</h2>
<ul>
  <li><strong>[Valor 1]:</strong> [Descreva o valor. Ex: Qualidade - Buscamos a excelência em cada atendimento]</li>
  <li><strong>[Valor 2]:</strong> [Descreva o valor. Ex: Compromisso - Cumprimos o que prometemos]</li>
  <li><strong>[Valor 3]:</strong> [Descreva o valor. Ex: Respeito - Tratamos cada cliente com dignidade]</li>
  <li><strong>[Valor 4]:</strong> [Descreva o valor. Ex: Inovação - Estamos sempre atualizados]</li>
</ul>

<h2>Nossa Equipe</h2>
<p>[Apresente sua equipe. Exemplo: "Contamos com uma equipe de [NÚMERO] profissionais qualificados e experientes, todos certificados e em constante atualização para oferecer o melhor serviço."]</p>

<h2>Diferenciais</h2>
<ul>
  <li>[Diferencial 1 - Ex: Atendimento personalizado]</li>
  <li>[Diferencial 2 - Ex: Produtos de primeira linha]</li>
  <li>[Diferencial 3 - Ex: Ambiente climatizado e aconchegante]</li>
  <li>[Diferencial 4 - Ex: Estacionamento gratuito]</li>
</ul>

<h2>Localização</h2>
<p>[Endereço completo do estabelecimento]</p>

<h2>Horário de Funcionamento</h2>
<p>[Dias e horários de funcionamento]</p>`,

    faq: `<h2>Perguntas Frequentes</h2>

<p>Encontre respostas para as dúvidas mais comuns sobre nossos serviços e agendamentos.</p>

<h2>Como faço um agendamento?</h2>
<p>É muito simples! Acesse nosso site pelo link que o estabelecimento forneceu, selecione o profissional desejado, escolha o serviço, data e horário disponíveis. Você receberá uma confirmação por e-mail.</p>

<h2>Preciso de cadastro para agendar?</h2>
<p>Sim! É necessário criar uma conta gratuita com seu nome, e-mail e telefone. O cadastro é rápido e seguro.</p>

<h2>Posso cancelar ou reagendar?</h2>
<p>Sim! Você pode cancelar ou reagendar diretamente pela sua conta no site, na seção "Meus Agendamentos". Recomendamos fazer com antecedência mínima de 2 horas.</p>

<h2>O que acontece se eu não comparecer?</h2>
<p>Casos de não comparecimento (no-show) podem resultar em restrições para futuros agendamentos. Recomendamos sempre cancelar com antecedência se não puder comparecer.</p>

<h2>Quais formas de pagamento são aceitas?</h2>
<p>O pagamento é realizado diretamente no estabelecimento. As formas de pagamento aceitas são informadas no site do estabelecimento.</p>

<h2>Como funciona o pacote mensal?</h2>
<p>O pacote mensal oferece múltiplas sessões por um valor mais acessível. As sessões devem ser utilizadas dentro do período de vigência e respeitam a regra de uma sessão por semana.</p>

<h2>Posso trocar de profissional?</h2>
<p>Sim, você pode escolher o profissional de sua preferência ao fazer o agendamento. Caso deseje trocar após já ter agendado, basta reagendar.</p>

<h2>O feedback que envio é anônimo?</h2>
<p>Sim! Suas avaliações e feedbacks são sempre anônimos. Seu nome não é exposto ao profissional ou outros clientes.</p>

<h2>Como entro em contato com o estabelecimento?</h2>
<p>[Descreva os canais de contato do estabelecimento. Ex: "Você pode nos contatar pelo WhatsApp em [NÚMERO], por e-mail em [E-MAIL], ou pelos telefones [TELEFONE]."]</p>

<h2>Meus dados estão seguros?</h2>
<p>Sim! Utilizamos criptografia e seguimos rigorosamente a Lei Geral de Proteção de Dados (LGPD). Consulte nossa Política de Privacidade para mais detalhes.</p>

<h2>Posso acessar pelo celular?</h2>
<p>Sim! Nossa plataforma é totalmente responsiva e funciona em qualquer dispositivo (celular, tablet ou computador).</p>`,

    contact_info: `<h2>Informações de Contato</h2>

<p>Estamos à disposição para atender você. Confira abaixo nossos canais de comunicação.</p>

<h2>[NOME DO SEU ESTABELECIMENTO]</h2>

<h2>Endereço</h2>
<p>[Rua/Av.], [NÚMERO] - [BAIRRO]</p>
<p>[CIDADE] - [ESTADO]</p>
<p>CEP: [CEP]</p>

<h2>Telefone</h2>
<p>[NÚMERO DO TELEFONE FIXO]</p>

<h2>WhatsApp</h2>
<p>[NÚMERO DO WHATSAPP COM CÓDIGO DO PAÍS]</p>
<p><em>Clique no link para iniciar uma conversa pelo WhatsApp.</em></p>

<h2>E-mail</h2>
<p>[ENDEREÇO DE E-MAIL]</p>

<h2>Horário de Funcionamento</h2>
<p>[Dias da semana]: [HORÁRIO DE ABERTURA] às [HORÁRIO DE FECHAMENTO]</p>
<p>Exemplo: Segunda a Sábado: 09h às 20h | Domingo: Fechado</p>

<h2>Redes Sociais</h2>
<ul>
  <li><strong>Instagram:</strong> [NOME DO USUÁRIO]</li>
  <li><strong>Facebook:</strong> [LINK DA PÁGINA]</li>
</ul>

<h2>Como Chegar</h2>
<p>[Descreva como chegar ao estabelecimento. Ex: "Ficamos localizados na [RUA], próximo à [REFERÊNCIA]. Estacionamento disponível na frente. Facilidade de acesso por transporte público - estação [NOME] a [X] minutos a pé."]</p>

<h2>Estacionamento</h2>
<p>[Informações sobre estacionamento. Ex: "Vagas gratuitas na frente do estabelecimento" ou "Estacionamento parceiro a [X] metros"]</p>`
  }
})

const perfilExemplo = () => ({
  nome: 'Vintage Barber Club',
  descricao: 'Especialistas em cortes modernos, fade perfeito e barboterapia. O lugar ideal para cuidar do seu estilo com navalha afiada.',
  imagens: {
    avatarUrl: 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?q=80&w=500',
    capaUrl: getDefaultBannerUrl()
  },
  contato: {
    endereco: 'Av. Paulista, 1000 - Centro, SP',
    telefone: '(11) 3333-3333',
    whatsapp: '(11) 98888-7777',
    instagram: 'vintagebarberclub',
    facebook: 'https://facebook.com/vintagebarberclub'
  },
  funcionamento: {
    horariosTexto: 'Terça a Sábado: 09h às 20h'
  },
  facilidades: {
    comodidades: ['Ar Condicionado', 'Wi-Fi', 'Bebidas'],
    pagamentos: ['cartao', 'pix', 'dinheiro']
  },
  depoimentos: [
    {
      id: 101,
      nome: 'Carlos Mendes',
      servico: 'Corte Degradê',
      foto: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200',
      rating: 5,
      texto: 'Melhor fade da cidade! Atendimento excelente.',
      exibirNaHome: true
    },
    {
      id: 102,
      nome: 'Lucas Ferreira',
      servico: 'Corte e Barba',
      foto: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200',
      rating: 5,
      texto: 'O serviço de toalha quente é sensacional.',
      exibirNaHome: true
    }
  ]
})

const perfil = ref(perfilVazio())
const loading = ref(true)
const usandoExemplo = ref(false)

// ─── Feedbacks do banco (para o modal de depoimentos) ─────────────────────────
const feedbacksDoBanco   = ref([])
const loadingFeedbacks   = ref(false)

async function carregarFeedbacksDoBanco() {
  if (feedbacksDoBanco.value.length > 0) return  // já carregou, não refaz
  loadingFeedbacks.value = true
  try {
    const response = await api.get('/admin/feedbacks')
    feedbacksDoBanco.value = response.data
  } catch (error) {
    console.error('Erro ao carregar feedbacks:', error)
  } finally {
    loadingFeedbacks.value = false
  }
}

function buildFileUrl(path) {
  if (!path) return ''
  if (path.startsWith('http://') || path.startsWith('https://')) return path
  return `${getApiBaseUrl()}${path}`
}

function getRelativePath(path) {
  if (!path) return ''
  try {
    const url = new URL(path)
    return url.pathname
  } catch {
    return path
  }
}



function abrirSeletorLogo() {
  if (uploadingLogo.value || loadingSubmit.value) return
  logoInput.value?.click()
}

function abrirSeletorBanner() {
  if (uploadingBanner.value || loadingSubmit.value) return
  bannerInput.value?.click()
}

async function onLogoSelected(event) {
  const file = event.target.files?.[0]
  if (!file) return

  // 🔒 SEGURANÇA: Validação client-side de tipo e tamanho (defesa em profundidade)
  const allowedTypes = ['image/jpeg', 'image/png', 'image/webp']
  if (!allowedTypes.includes(file.type)) {
    alert('Formato de arquivo inválido. Envie apenas imagens .jpg, .png ou .webp.')
    event.target.value = ''
    return
  }

  const maxBytes = 5 * 1024 * 1024 // 5 MB
  if (file.size > maxBytes) {
    alert('Arquivo muito grande. O limite máximo permitido é de 5MB.')
    event.target.value = ''
    return
  }

  try {
    uploadingLogo.value = true

    const formData = new FormData()
    formData.append('file', file)

    const response = await api.post('/admin/establishment/upload_logo', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })

    const path = response.data?.path || response.data?.logo
    perfil.value.imagens.avatarUrl = buildFileUrl(path)
  } catch (error) {
    const message =
      error.response?.data?.errors?.join(', ') ||
      error.response?.data?.error ||
      'Erro ao enviar logo.'

    alert(message)
    console.error(error)
  } finally {
    uploadingLogo.value = false
    event.target.value = ''
  }
}

async function onBannerSelected(event) {
  const file = event.target.files?.[0]
  if (!file) return

  // 🔒 SEGURANÇA: Validação client-side de tipo e tamanho (defesa em profundidade)
  const allowedTypes = ['image/jpeg', 'image/png', 'image/webp']
  if (!allowedTypes.includes(file.type)) {
    alert('Formato de arquivo inválido. Envie apenas imagens .jpg, .png ou .webp.')
    event.target.value = ''
    return
  }

  const maxBytes = 5 * 1024 * 1024 // 5 MB
  if (file.size > maxBytes) {
    alert('Arquivo muito grande. O limite máximo permitido é de 5MB.')
    event.target.value = ''
    return
  }

  try {
    uploadingBanner.value = true

    const formData = new FormData()
    formData.append('file', file)

    const response = await api.post('/admin/establishment/upload_banner', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })

    const path = response.data?.path || response.data?.banner
    perfil.value.imagens.capaUrl = buildFileUrl(path)
  } catch (error) {
    const message =
      error.response?.data?.errors?.join(', ') ||
      error.response?.data?.error ||
      'Erro ao enviar capa.'

    alert(message)
    console.error(error)
  } finally {
    uploadingBanner.value = false
    event.target.value = ''
  }
}

function temConfiguracaoReal(data) {
  return !!(
    data.name ||
    data.description ||
    data.logo ||
    data.banner ||
    data.phone ||
    data.whatsapp ||
    data.instagram ||
    data.facebook ||
    (data.amenities && data.amenities.length > 0) ||
    (data.payment_methods && data.payment_methods.length > 0) ||
    (data.testimonials && data.testimonials.length > 0) ||
    data.address?.street ||
    data.address?.city ||
    data.public_settings?.horarios_texto
  )
}

function formatarPerfilDoBanco(data) {
  // Templates padrão para páginas legais
  const defaultLegalPages = perfilVazio().legal_pages

  return {
    nome: data.name || '',
    descricao: data.description || '',
    imagens: {
      avatarUrl: data.logo
        ? buildFileUrl(data.logo)
        : getDefaultAvatarUrl(),
      capaUrl: data.banner
        ? buildFileUrl(data.banner)
        : getDefaultBannerUrl()
    },
    contato: {
      endereco: [
        data.address?.street,
        data.address?.number,
        data.address?.neighborhood,
        data.address?.city,
        data.address?.state
      ].filter(Boolean).join(', '),
      telefone: formatarTelefone(data.phone || ''),
      whatsapp: formatarTelefone(data.whatsapp || ''),
      instagram: data.instagram || '',
      facebook: data.facebook || ''
    },
    funcionamento: {
      horariosTexto: data.public_settings?.horarios_texto || ''
    },
    facilidades: {
      comodidades: data.amenities || [],
      pagamentos: data.payment_methods || []
    },
    depoimentos: data.testimonials || [],
    legal_pages: {
      privacy_policy: data.legal_pages?.privacy_policy || defaultLegalPages.privacy_policy,
      terms_of_use: data.legal_pages?.terms_of_use || defaultLegalPages.terms_of_use,
      cookie_policy: data.legal_pages?.cookie_policy || defaultLegalPages.cookie_policy,
      about_us: data.legal_pages?.about_us || defaultLegalPages.about_us,
      faq: data.legal_pages?.faq || defaultLegalPages.faq,
      contact_info: data.legal_pages?.contact_info || defaultLegalPages.contact_info
    }
  }
}

function adicionarComodidade() {
  const valor = novaComodidade.value.trim()
  if (valor && !listaComodidades.value.includes(valor)) {
    listaComodidades.value.push(valor)
    perfil.value.facilidades.comodidades.push(valor)
    novaComodidade.value = ''
  }
}

function removerComodidade(itemParaRemover) {
  listaComodidades.value = listaComodidades.value.filter(item => item !== itemParaRemover)
  perfil.value.facilidades.comodidades = perfil.value.facilidades.comodidades.filter(item => item !== itemParaRemover)
}

function isDepoimentoNaLista(id) {
  return perfil.value.depoimentos.some(dep => dep.id === id)
}

function adicionarDepoimentoDoBanco(depBanco) {
  if (!isDepoimentoNaLista(depBanco.id)) {
    // exibirNaHome: true por padrão — se o admin escolheu, quer exibir na Home
    perfil.value.depoimentos.push({ ...depBanco, exibirNaHome: true })
  }
}

function removerDepoimentoDaLista(id) {
  perfil.value.depoimentos = perfil.value.depoimentos.filter(dep => dep.id !== id)
}

function montarAddress(endereco) {
  return {
    street: endereco?.trim() || '',
    number: '',
    neighborhood: '',
    city: '',
    state: '',
    zip_code: '',
    complement: '',
    country: 'Brasil'
  }
}

async function salvarEstabelecimento() {
  if (loadingSubmit.value) return

  const nomeSanitizado = sanitizeText(perfil.value.nome)
  if (!nomeSanitizado || nomeSanitizado.length < 2 || nomeSanitizado.length > 100) {
    alert('O nome do estabelecimento é obrigatório e deve ter entre 2 e 100 caracteres.')
    return
  }

  const descSanitizada = sanitizeText(perfil.value.descricao)
  if (descSanitizada && descSanitizada.length > 500) {
    alert('A descrição "Sobre" não pode ultrapassar 500 caracteres.')
    return
  }

  const enderecoSanitizado = sanitizeText(perfil.value.contato.endereco)
  if (!enderecoSanitizado) {
    alert('O endereço completo é obrigatório.')
    return
  }

  const facebookUrl = sanitizeText(perfil.value.contato.facebook)
  if (facebookUrl && !validateUrl(facebookUrl)) {
    alert('Por favor, informe uma URL do Facebook válida (ex: https://facebook.com/suapagina).')
    return
  }

  try {
    loadingSubmit.value = true

    const payload = {
      establishment: {
        name: nomeSanitizado,
        description: descSanitizada,
        phone: perfil.value.contato.telefone ? perfil.value.contato.telefone.replace(/\D/g, '') : '',
        whatsapp: perfil.value.contato.whatsapp ? perfil.value.contato.whatsapp.replace(/\D/g, '') : '',
        instagram: sanitizeText(perfil.value.contato.instagram).replace(/[@]/g, ''),
        facebook: facebookUrl,
        amenities: (perfil.value.facilidades.comodidades || []).map(sanitizeText),
        payment_methods: perfil.value.facilidades.pagamentos || [],
        testimonials: (perfil.value.depoimentos || []).map(t => ({
          ...t,
          nome: sanitizeText(t.nome),
          servico: sanitizeText(t.servico),
          texto: sanitizeText(t.texto)
        })),
        public_settings: {
          horarios_texto: sanitizeText(perfil.value.funcionamento?.horariosTexto || '')
        },
        ...(canEditOwnerSettings.value ? { legal_pages: {
          privacy_policy: sanitizeLegalHtml(perfil.value.legal_pages?.privacy_policy || ''),
          terms_of_use: sanitizeLegalHtml(perfil.value.legal_pages?.terms_of_use || ''),
          cookie_policy: sanitizeLegalHtml(perfil.value.legal_pages?.cookie_policy || ''),
          about_us: sanitizeLegalHtml(perfil.value.legal_pages?.about_us || ''),
          faq: sanitizeLegalHtml(perfil.value.legal_pages?.faq || ''),
          contact_info: sanitizeLegalHtml(perfil.value.legal_pages?.contact_info || '')
        } } : {})
      },
      address: montarAddress(enderecoSanitizado),
      business_hours: []
    }

    const response = await api.put('/admin/establishment', payload)
    const data = response.data.establishment

    const perfilFormatado = formatarPerfilDoBanco(data)
    localStorage.setItem('establishment-data', JSON.stringify(perfilFormatado))

    if (data?.slug) {
      localStorage.setItem('site-slug', data.slug)
      // Invalida o cache público da HomeView para que os depoimentos apareçam imediatamente
      localStorage.removeItem(`public-establishment-${data.slug}`)
    }

    store.setSalonConfig(perfilFormatado)
    perfil.value = perfilFormatado

    alert('Configurações das páginas salvas com sucesso!')
  } catch (error) {
    const message =
      error.response?.data?.errors?.join(', ') ||
      error.response?.data?.error ||
      'Erro ao salvar configurações.'

    alert(message)
    console.error(error)
  } finally {
    loadingSubmit.value = false
  }
}

onMounted(async () => {
  document.body.style.overflowY = 'auto'
  loading.value = true
  usandoExemplo.value = false
  perfil.value = perfilVazio()

  const cache = localStorage.getItem('establishment-data')

  if (cache) {
    try {
      const parsed = JSON.parse(cache)
      perfil.value = parsed
      store.setSalonConfig(parsed)
    } catch (e) {
      console.warn('Erro ao ler cache do estabelecimento')
      localStorage.removeItem('establishment-data')
    }
  }

  try {
    const response = await api.get('/admin/establishment')
    const data = response.data
    canEditOwnerSettings.value = data.can_edit_owner_settings === true

    // 🔒 SEGURANÇA: Bloqueio de renderização para funcionários sem permissão de gerenciamento
    if (data?.permissions && data.permissions.can_manage_establishment === false) {
      router.replace('/admin/agendamentos')
      return
    }

    if (temConfiguracaoReal(data)) {
      perfil.value = formatarPerfilDoBanco(data)

      localStorage.setItem('establishment-data', JSON.stringify(perfil.value))

      const itensExtras = (data.amenities || []).filter(
        (item) => !listaComodidades.value.includes(item)
      )
      listaComodidades.value.push(...itensExtras)

      store.setSalonConfig(perfil.value)
    } else {
      if (!cache) {
        perfil.value = perfilExemplo()
        usandoExemplo.value = true
      }
    }
  } catch (error) {
    console.error('Erro ao carregar estabelecimento:', error)

    if (cache) {
      try {
        const parsed = JSON.parse(cache)
        perfil.value = parsed
        store.setSalonConfig(parsed)
      } catch {}
    } else {
      perfil.value = perfilExemplo()
      usandoExemplo.value = true
    }
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
/* Ajuste de Layout Tela Cheia */
.page-content {
  max-width: 100% !important;
}

/* Header Premium */
.dashboard-header {
  background: rgba(var(--bs-body-bg-rgb), 0.4) !important;
  border: 1px solid var(--card-border) !important;
  backdrop-filter: blur(12px) !important;
  position: relative;
  border-radius: 20px !important;
}

.header-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: radial-gradient(circle at top right, rgba(13, 110, 253, 0.08), transparent 70%);
  pointer-events: none;
}

.header-icon-container {
  width: 54px;
  height: 54px;
  border-color: var(--card-border) !important;
  flex-shrink: 0;
}

.text-gradient {
  background: linear-gradient(135deg, var(--logo-color, var(--bs-primary)), #00c6ff);
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
  font-weight: 800;
}

.cursor-pointer { cursor: pointer; }

.admin-card {
  background: var(--glass-bg);
  border: 1px solid var(--card-border);
  border-radius: 20px;
  padding: 1.5rem 2rem;
  backdrop-filter: blur(15px);
}

.upload-area {
  background-color: var(--upload-bg);
  border: 2px dashed var(--card-border);
  outline: none;
}
.upload-area:hover, .upload-area:focus {
  border-color: var(--bs-primary);
  background-color: var(--upload-hover-bg);
  transform: translateY(-3px);
  box-shadow: 0 .5rem 1rem rgba(13, 110, 253, .1)!important;
}

.avatar-container img { transition: transform 0.3s; }
.avatar-container:hover img { transform: scale(1.03); box-shadow: 0 .5rem 1.5rem rgba(0,0,0,.15)!important; }

.custom-input, .input-group-text {
  border-radius: 12px;
  padding: 12px 18px;
  border: 1px solid var(--card-border);
  background-color: var(--bs-tertiary-bg);
  color: var(--bs-body-color);
  transition: all 0.2s;
  font-weight: 500;
}

.custom-input-group {
  border-radius: 12px;
  border: 1px solid var(--card-border) !important;
  transition: all 0.2s;
  overflow: hidden;
}

.custom-input-group .input-group-text {
  border: none;
  background-color: var(--bs-tertiary-bg);
  border-top-right-radius: 0;
  border-bottom-right-radius: 0;
}
.custom-input-group .custom-input {
  border: none;
  background-color: var(--bs-tertiary-bg);
  border-radius: 0;
}

.custom-input:focus, .custom-input-group:focus-within {
  border-color: var(--bs-primary) !important;
  box-shadow: 0 0 0 0.25rem rgba(13, 110, 253, 0.15) !important;
  background-color: var(--bs-body-bg);
}
.custom-input:focus { background-color: var(--bs-body-bg); }

.checkbox-box {
  display: inline-flex;
  align-items: center;
  padding: 8px 16px;
  border-radius: 50px;
}
.checkbox-box:hover {
  border-color: var(--bs-primary);
  background-color: var(--bs-body-bg);
}

.transition-all { transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1); }
.hover-scale:hover { transform: scale(1.15) !important; }
.hover-lift:hover { transform: translateY(-3px); box-shadow: 0 10px 20px rgba(13, 110, 253, 0.2) !important; }
.hover-opacity-100:hover { opacity: 1 !important; }

[data-bs-theme="light"] {
  --upload-bg: rgba(0, 0, 0, 0.02);
  --upload-hover-bg: rgba(13, 110, 253, 0.04);
}
[data-bs-theme="dark"] {
  --upload-bg: rgba(255, 255, 255, 0.02);
  --upload-hover-bg: rgba(13, 110, 253, 0.1);
}

.avatar-upload-box {
  background: var(--upload-bg);
  border: 1px solid var(--card-border);
  border-radius: 20px;
  padding: 1.5rem 1.25rem;
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.avatar-preview {
  width: 160px;
  height: 160px;
  object-fit: cover;
  background: var(--bs-tertiary-bg);
}

.avatar-container {
  width: 160px;
  height: 160px;
}
</style>
