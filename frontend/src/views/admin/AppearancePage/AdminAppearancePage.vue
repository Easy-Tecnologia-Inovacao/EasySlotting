<template>
  <AdminLayout>
    <div class="container-fluid px-0">
      <div class="row g-0 aparencia-container">
        
        <div class="col-lg-3 border-end bg-body-tertiary custom-scrollbar sidebar-panel">
          <div class="p-4 d-flex flex-column gap-3">
            
            <div>
              <h5 class="fw-bold mb-1 text-body">Ajustes Visuais</h5>
              <p class="small mb-0 text-body-secondary">Personalize a aparência da sua Home</p>
            </div>

            <div v-if="!isOwner" class="alert alert-warning rounded-4 mb-2 shadow-sm d-flex align-items-center gap-2">
              <i class="bi bi-shield-lock-fill fs-5 text-warning flex-shrink-0"></i>
              <span class="small">Visualização restrita: Apenas o proprietário do estabelecimento pode alterar a aparência visual.</span>
            </div>

            <div class="admin-card bg-body border shadow-sm">
              <label class="small fw-bold mb-3 d-block text-uppercase text-primary">Página em Edição</label>
              <select class="form-select form-select-sm rounded-3 bg-body text-body border" v-model="activePreviewPage">
                <option value="home">Página Inicial (Home)</option>
                <option value="agendamento">Página de Agendamento</option>
              </select>
            </div>

            <div class="admin-card bg-body border shadow-sm">
              <div class="d-flex align-items-center gap-2 mb-3">
                <i class="bi bi-palette2 text-primary"></i>
                <label class="small fw-bold text-uppercase text-primary mb-0">Marca</label>
              </div>
              <p class="extra-small text-muted mb-3">Cor da identidade visual do estabelecimento</p>
              <div>
                <div class="color-row mb-2">
                  <div>
                    <span class="small fw-medium text-body d-block">Cor da Logo</span>
                    <span class="color-hint">{{ colorHints.logo }}</span>
                  </div>
                  <input type="color" class="form-control-color" :value="store.themeConfig.logoColor" @input="onColorInput('logo', $event)">
                </div>
              </div>
            </div>

            <div class="admin-card bg-body border shadow-sm">
              <div class="d-flex align-items-center gap-2 mb-3">
                <i class="bi bi-hand-index-thumb text-primary"></i>
                <label class="small fw-bold text-uppercase text-primary mb-0">Botões</label>
              </div>
              <p class="extra-small text-muted mb-3">Aparencia dos botões de ação e interação</p>
              <div class="d-grid gap-3">
                <div>
                  <div class="color-row mb-2">
                    <div>
                      <span class="small fw-medium text-body d-block">Fundo do Botão</span>
                      <span class="color-hint">Agendar, Confirmar, Criar Conta</span>
                    </div>
                    <input type="color" class="form-control-color" :value="store.themeConfig.buttonBg" @input="onColorInput('buttonBg', $event)">
                  </div>
                </div>
                <div>
                  <div class="color-row mb-2">
                    <div>
                      <span class="small fw-medium text-body d-block">Hover do Botão</span>
                      <span class="color-hint">Estado ao passar o mouse</span>
                    </div>
                    <input type="color" class="form-control-color" :value="store.themeConfig.buttonHover" @input="onColorInput('buttonHover', $event)">
                  </div>
                </div>
              </div>
            </div>

            <div class="admin-card bg-body border shadow-sm">
              <div class="d-flex align-items-center gap-2 mb-3">
                <i class="bi bi-brush text-primary"></i>
                <label class="small fw-bold text-uppercase text-primary mb-0">Ícones</label>
              </div>
              <p class="extra-small text-muted mb-3">Cor dos elementos decorativos e informativos</p>
              <div>
                <div class="color-row mb-2">
                  <div>
                    <span class="small fw-medium text-body d-block">Cor dos Ícones</span>
                    <span class="color-hint">Redes sociais, endereço, telefone, serviços</span>
                  </div>
                  <input type="color" class="form-control-color" :value="store.themeConfig.iconColor" @input="onColorInput('icon', $event)">
                </div>
              </div>
            </div>

            <div class="admin-card bg-body border shadow-sm">
              <div class="d-flex align-items-center gap-2 mb-3">
                <i class="bi bi-circle-half text-primary"></i>
                <label class="small fw-bold text-uppercase text-primary mb-0">Modo Dark/Light</label>
              </div>
              <p class="extra-small text-muted mb-3">Cor de fundo ao alternar entre claro e escuro</p>
              <div>
                <div class="color-row mb-2">
                  <div>
                    <span class="small fw-medium text-body d-block">Fundo do Tema</span>
                    <span class="color-hint">Cor de fundo do toggle dark/light</span>
                  </div>
                  <input type="color" class="form-control-color" :value="store.themeConfig.backgroundLight" @input="onColorInput('background', $event)">
                </div>
              </div>
            </div>

            <div class="admin-card bg-body border shadow-sm">
              <div class="d-flex align-items-center gap-2 mb-3">
                <i class="bi bi-file-earmark-text text-primary"></i>
                <label class="small fw-bold text-uppercase text-primary mb-0">Fundo</label>
              </div>
              <p class="extra-small text-muted mb-3">Cores de fundo da estrutura do site</p>
              <div>
                <div class="color-row mb-2">
                  <div>
                    <span class="small fw-medium text-body d-block">Fundo da Navbar</span>
                    <span class="color-hint">Barra de navegacao no topo</span>
                  </div>
                  <input type="color" class="form-control-color" :value="navbarLightHex" @input="onColorInput('navbar', $event)">
                </div>
              </div>
            </div>

            <div class="admin-card bg-body border shadow-sm">
              <div class="d-flex align-items-center gap-2 mb-3">
                <i class="bi bi-fonts text-primary"></i>
                <label class="small fw-bold text-uppercase text-primary mb-0">Texto</label>
              </div>
              <p class="extra-small text-muted mb-3">Cor do conteudo textual do site</p>
              <div>
                <div class="color-row mb-2">
                  <div>
                    <span class="small fw-medium text-body d-block">Cor do Texto</span>
                    <span class="color-hint">Titulos, paragrafos, labels, descricoes</span>
                  </div>
                  <input type="color" class="form-control-color" :value="store.themeConfig.textLight" @input="onColorInput('text', $event)">
                </div>
              </div>
            </div>

            <div class="admin-card bg-body border shadow-sm">
              <label class="small fw-bold mb-3 d-block text-uppercase text-primary">Tipografia Global</label>
              <div class="mb-3">
                <div class="address-label text-body-secondary">Família da Fonte</div>
                <select
                  class="form-select form-select-sm rounded-3 bg-body text-body border"
                  :value="store.themeConfig.fontFamily"
                  @change="onFontChange"
                >
                  <optgroup label="Sans Serif — Corpo de texto">
                    <option value="'Inter', sans-serif">Inter</option>
                    <option value="'Plus Jakarta Sans', sans-serif">Plus Jakarta Sans</option>
                    <option value="'Poppins', sans-serif">Poppins</option>
                    <option value="'Roboto', sans-serif">Roboto</option>
                    <option value="'Open Sans', sans-serif">Open Sans</option>
                    <option value="'Lato', sans-serif">Lato</option>
                    <option value="'Montserrat', sans-serif">Montserrat</option>
                    <option value="'Nunito', sans-serif">Nunito</option>
                    <option value="'Work Sans', sans-serif">Work Sans</option>
                    <option value="'Rubik', sans-serif">Rubik</option>
                  </optgroup>
                  <optgroup label="Serif — Editorial e elegante">
                    <option value="'Playfair Display', serif">Playfair Display</option>
                    <option value="'Merriweather', serif">Merriweather</option>
                    <option value="'Lora', serif">Lora</option>
                    <option value="'EB Garamond', serif">EB Garamond</option>
                    <option value="'Bitter', serif">Bitter</option>
                    <option value="'Libre Baskerville', serif">Libre Baskerville</option>
                  </optgroup>
                  <optgroup label="Display — Destaque e titulos">
                    <option value="'Bebas Neue', sans-serif">Bebas Neue</option>
                    <option value="'Anton', sans-serif">Anton</option>
                    <option value="'Fredoka', sans-serif">Fredoka</option>
                  </optgroup>
                  <optgroup label="Manuscrita — Assinatura e criatividade">
                    <option value="'Pacifico', cursive">Pacifico</option>
                    <option value="'Dancing Script', cursive">Dancing Script</option>
                    <option value="'Caveat', cursive">Caveat</option>
                  </optgroup>
                  <optgroup label="Monospace — Codigo e tecnico">
                    <option value="'Fira Code', monospace">Fira Code</option>
                    <option value="'JetBrains Mono', monospace">JetBrains Mono</option>
                    <option value="'Space Mono', monospace">Space Mono</option>
                  </optgroup>
                </select>
                <div class="form-text extra-small text-muted mt-1">
                  Estilo de letra que será utilizado em todo o seu site.
                </div>
              </div>

              <div>
                <div class="address-label text-body-secondary mb-1">Tamanho do Texto</div>
                <div class="d-flex align-items-center gap-2">
                  <input
                    type="range"
                    class="form-range"
                    min="12"
                    max="24"
                    :value="parseInt(store.themeConfig.fontSize)"
                    @input="onFontSizeInput"
                  >

                  <div class="input-group input-group-sm" style="width: 70px;">
                    <input
                      type="number"
                      class="form-control text-center px-1"
                      min="12"
                      max="24"
                      :value="parseInt(store.themeConfig.fontSize)"
                      @input="onFontSizeInput"
                    >
                  </div>
                </div>
                <div class="form-text extra-small text-muted mt-1">
                  Tamanho base das letras de leitura do site (entre 12px e 24px).
                </div>
              </div>
            </div>

            <button
              class="btn btn-primary rounded-pill fw-bold py-2 shadow-sm mt-2"
              @click="salvarAparencia"
              :disabled="isSaving || !isOwner"
            >
              <span v-if="isSaving" class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
              {{ isSaving ? 'Salvando...' : (!isOwner ? 'Restrito ao Proprietário' : 'Salvar Alterações') }}
            </button>
            <button
              class="btn btn-outline-danger rounded-pill fw-bold py-2 shadow-sm mb-4"
              @click="resetarAparencia"
              :disabled="isSaving || !isOwner"
            >
              <i class="bi bi-arrow-counterclockwise me-2"></i> Restaurar Padrão
            </button>
          </div>
        </div>

        <div class="col-lg-9 position-relative p-0 d-flex flex-column align-items-center justify-content-center overflow-hidden preview-panel" style="background-color: var(--bs-secondary-bg);">
          
          <div
            class="preview-window w-100 h-100 pb-5 transition-all bg-body"
            :style="previewStyles"
            data-bs-theme="light"
          >
            
            <nav class="navbar navbar-expand-lg position-sticky top-0 preview-navbar">
              <div class="container d-flex align-items-center">
                <a class="navbar-brand fw-bold fs-3 custom-logo m-0" href="#">{{ store.salonConfig.nome }}</a>

                <div class="collapse navbar-collapse d-none d-lg-block" id="navContent">
                  <ul class="navbar-nav me-auto"></ul>
                  <div class="d-flex flex-wrap align-items-center gap-2 gap-lg-3 mt-3 mt-lg-0 ms-auto">
                    <div class="d-flex align-items-center gap-2">
                      <a href="#" class="btn btn-link text-decoration-none fw-bold small dynamic-text">Entrar</a>
                      <a href="#" class="btn btn-sm rounded-pill fw-bold px-3 py-2 border-2 custom-outline-btn">Criar conta</a>
                    </div>
                  </div>
                </div>

                <div class="d-flex align-items-center gap-3 ms-auto ms-lg-4">
                  <label class="theme-switch mb-0 shadow-sm">
                    <div class="ball"></div>
                    <i class="bi bi-sun-fill text-warning"></i>
                    <i class="bi bi-moon-stars-fill text-secondary opacity-75"></i>
                  </label>
                </div>
              </div>
            </nav>

            <div v-if="activePreviewPage === 'home'">
              <section
                class="hero-section d-flex align-items-center justify-content-center"
                :style="{ backgroundImage: `url(${safeImageUrl(heroConfig.backgroundImage, 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?q=80&w=2070')})` }"
              >
                <div class="container text-center hero-content">
                  <h1 class="display-3 fw-bold text-white">{{ heroConfig.title }}</h1>
                  <p class="lead fw-semibold text-white mb-4">{{ heroConfig.subtitle }}</p>
                  <button class="btn btn-primary btn-lg rounded-pill fw-bold px-5 py-3 shadow text-decoration-none custom-btn">
                    <i class="bi bi-calendar-check me-2"></i> {{ heroConfig.buttonText }}
                  </button>
                </div>
              </section>

              <div class="container search-container">
                <div class="featured-panel position-relative">
                  <div class="d-flex justify-content-between align-items-center mb-4">
                    <h4 class="fw-bold m-0 dynamic-text">O que nossos clientes dizem</h4>
                  </div>

                  <button
                    type="button"
                    aria-label="Voltar depoimentos"
                    class="shadow-sm position-absolute z-3 carousel-nav-btn carousel-nav-left"
                    @click="scrollManual(-1)"
                  >
                    <i class="bi bi-chevron-left fw-bold"></i>
                  </button>

                  <button
                    type="button"
                    aria-label="Avançar depoimentos"
                    class="shadow-sm position-absolute z-3 carousel-nav-btn carousel-nav-right"
                    @click="scrollManual(1)"
                  >
                    <i class="bi bi-chevron-right fw-bold"></i>
                  </button>

                  <div class="testimonial-viewport">
                    <div
                      ref="scrollContainer"
                      class="testimonial-track"
                      @mouseenter="pauseAutoScroll"
                      @mouseleave="startAutoScroll"
                      @touchstart="pauseAutoScroll"
                      @touchend="startAutoScroll"
                    >
                      <div
                        v-for="(testimonial, index) in carouselTestimonials"
                        :key="`${testimonial.id}-${index}`"
                        class="carousel-item-custom"
                      >
                        <div class="company-card p-4 d-flex flex-column align-items-center text-center">
                          <img
                            :src="testimonial.foto"
                            class="rounded-circle mb-3 shadow-sm"
                            style="width: 90px; height: 90px; object-fit: cover;"
                            :alt="testimonial.nome"
                          >
                          <h5 class="fw-bold mb-1 dynamic-text">{{ testimonial.nome }}</h5>
                          <p class="small mb-3 dynamic-text" style="opacity: 0.8;">{{ testimonial.servico }}</p>

                          <div class="mb-3 text-warning">
                            <i v-for="i in Math.floor(testimonial.rating)" :key="`full-${index}-${i}`" class="bi bi-star-fill"></i>
                            <i v-if="testimonial.rating % 1 !== 0" class="bi bi-star-half"></i>
                            <i v-for="i in (5 - Math.ceil(testimonial.rating))" :key="`empty-${index}-${i}`" class="bi bi-star"></i>
                          </div>

                          <p class="small fst-italic dynamic-text testimonial-text" style="opacity: 0.7;">{{ testimonial.texto }}</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div v-else-if="activePreviewPage === 'agendamento'">
              <div class="container-fluid p-0">
                <div
                  class="profile-cover"
                  :style="{ backgroundImage: 'linear-gradient(rgba(0,0,0,0.3), rgba(0,0,0,0.7)), url(' + safeImageUrl(store.salonConfig.imagens.capaUrl) + ')' }"
                ></div>
              </div>

              <div class="container mb-5">
                <div class="row">
                  <div class="col-lg-8">

                    <div class="d-flex flex-column flex-md-row align-items-md-end gap-3 mb-5 position-relative">
                      <img
                        :src="safeImageUrl(store.salonConfig.imagens.avatarUrl)"
                        class="profile-avatar bg-body"
                        style="border-color: var(--bs-body-bg) !important;"
                      >
                      <div class="pb-2 flex-grow-1">
                        <div class="d-flex align-items-center gap-2 mb-1">
                          <h2 class="fw-800 mb-0 dynamic-text">{{ store.salonConfig.nome }}</h2>
                          <i class="bi bi-patch-check-fill fs-4 custom-icon" title="Empresa Verificada"></i>
                        </div>
                        <div class="d-flex flex-wrap align-items-center gap-3">
                          <p class="mb-0 small dynamic-text opacity-75">
                            <i class="bi bi-geo-alt-fill me-1 custom-icon"></i>{{ store.salonConfig.contato.endereco }}
                          </p>
                          <span class="badge bg-success bg-opacity-10 text-success rounded-pill px-3 border border-success-subtle">Aberto para agendamento</span>
                          <div class="d-flex gap-3 ms-md-auto mt-2 mt-md-0">
                            <a
                              v-if="store.salonConfig.contato.instagram"
                              :href="safeExternalUrl('https://instagram.com/' + store.salonConfig.contato.instagram)"
                              target="_blank"
                              rel="noopener noreferrer"
                              class="text-decoration-none small fw-bold dynamic-text transition-all hover-opacity-100 opacity-75"
                            >
                              <i class="bi bi-instagram me-1 custom-icon"></i>Instagram
                            </a>
                            <a
                              v-if="store.salonConfig.contato.whatsapp"
                              :href="safeExternalUrl('https://wa.me/55' + (store.salonConfig.contato.whatsapp ? store.salonConfig.contato.whatsapp.replace(/\D/g, '') : ''))"
                              target="_blank"
                              rel="noopener noreferrer"
                              class="text-decoration-none small fw-bold dynamic-text transition-all hover-opacity-100 opacity-75"
                            >
                              <i class="bi bi-whatsapp me-1 custom-icon"></i>WhatsApp
                            </a>
                          </div>
                        </div>
                      </div>
                    </div>

                    <section class="mb-5">
                      <label class="small fw-bold mb-3 text-uppercase dynamic-text opacity-75">1. Como deseja agendar?</label>
                      <div class="booking-mode-toggle">
                        <button
                          class="mode-btn"
                          :class="{ active: previewBookingMode === 'service' }"
                          @click="previewBookingMode = 'service'"
                        >
                          <i class="bi bi-scissors me-2"></i>Serviço Avulso
                        </button>
                        <button
                          class="mode-btn"
                          :class="{ active: previewBookingMode === 'package' }"
                          @click="previewBookingMode = 'package'"
                        >
                          <i class="bi bi-star me-2"></i>Pacote Mensal
                        </button>
                      </div>
                    </section>

                    <section class="mb-5" id="secao-profissionais">
                      <label class="small fw-bold mb-3 text-uppercase dynamic-text opacity-75">2. Escolha o Profissional</label>
                      <div class="colab-container pb-2">
                        <div
                          v-for="pro in profissionais"
                          :key="pro.id"
                          class="colab-select-card shadow-sm"
                          :class="{ 'active': selectedProfessional?.id === pro.id }"
                          @click="selectedProfessional = pro"
                        >
                          <div class="avatar-placeholder fs-4"><i :class="pro.icone"></i></div>
                          <span class="fw-bold small mb-1 dynamic-text colab-text">{{ pro.nome }}</span>
                          <span class="small dynamic-text opacity-75 colab-text" style="font-size: 0.75rem;">{{ pro.cargo }}</span>
                        </div>
                      </div>
                    </section>

                    <section class="mb-5" id="secao-servicos">
                      <label class="small fw-bold mb-3 text-uppercase dynamic-text opacity-75">3. Selecione o Serviço</label>
                      <div class="d-flex flex-column gap-3">

                        <div
                          v-for="service in servicesList"
                          :key="service.id"
                          class="service-selection-card p-3 d-flex align-items-center justify-content-between shadow-sm"
                          :class="{ 'selected': selectedService === service.name }"
                          @click="selectService(service.name, formatCurrency(service.price))"
                        >
                          <div class="d-flex align-items-center gap-3">
                            <div class="rounded-3 p-3 icon-box-dynamic"><i class="bi bi-scissors fs-4"></i></div>
                            <div>
                              <h6 class="fw-bold mb-0 dynamic-text">{{ service.name }}</h6>
                              <small class="dynamic-text opacity-75">
                                {{ service.duration_minutes }} min
                                <span v-if="service.description" class="ms-2 d-none d-md-inline">· {{ service.description }}</span>
                              </small>
                            </div>
                          </div>
                          <div class="fw-bold" style="color: var(--button-bg);">R$ {{ formatCurrency(service.price) }}</div>
                        </div>

                        <div v-if="servicesList.length === 0" class="text-muted small">
                          Nenhum serviço cadastrado ainda.
                        </div>
                      </div>
                    </section>

                    <section class="mb-5" id="secao-data">
                      <div class="d-flex justify-content-between align-items-center mb-3">
                        <label class="small fw-bold text-uppercase dynamic-text opacity-75 mb-0">4. Escolha o Dia</label>
                        <button class="btn btn-sm rounded-pill fw-bold px-4 py-1 custom-outline-btn shadow-sm" @click="goToToday()">Hoje</button>
                      </div>

                      <div class="d-flex align-items-center gap-2 gap-md-3">
                        <button class="btn shadow-sm scroll-arrow flex-shrink-0" @click="scrollListDays(-1)"><i class="bi bi-chevron-left fs-5"></i></button>

                        <div class="date-container pb-2 flex-grow-1" id="calendar" ref="dateScrollRef">
                          <div
                            v-for="(date, index) in filteredDates"
                            :key="index"
                            class="date-card shadow-sm flex-shrink-0"
                            :class="{ 'active': selectedDate === date.fullString }"
                            @click="selectedDate = date.fullString"
                          >
                            <span class="small dynamic-text date-text opacity-75 mb-1">{{ date.weekDay }}</span>
                            <span class="fw-bold fs-4 dynamic-text date-text lh-1">{{ date.dayNumber }}</span>
                            <span class="small dynamic-text date-text opacity-75 mt-1">{{ date.monthName }}</span>
                          </div>
                        </div>

                        <button class="btn shadow-sm scroll-arrow flex-shrink-0" @click="scrollListDays(1)"><i class="bi bi-chevron-right fs-5"></i></button>
                      </div>
                    </section>

                    <section class="mb-5" id="secao-horario">
                      <label class="small fw-bold mb-3 text-uppercase dynamic-text opacity-75">5. Escolha a Hora</label>
                      <div class="hours-grid" id="hoursGrid">
                        <div
                          v-for="(time, index) in filteredTimes"
                          :key="index"
                          class="hour-item shadow-sm dynamic-text"
                          :class="{ 'active': selectedTime === time }"
                          @click="selectedTime = time"
                        >
                          {{ time }}
                        </div>
                      </div>
                    </section>

                  </div>

                    <div class="col-lg-4 mt-lg-5">
                    <div class="card border-0 shadow-sm rounded-4 p-4 sticky-summary" style="background: var(--bs-tertiary-bg); border: 1px solid var(--card-border) !important;">
                      <h5 class="fw-bold mb-4 dynamic-text">Resumo da Reserva</h5>
                      <div class="d-grid gap-3 small dynamic-text">
                        <div class="d-flex justify-content-between"><span class="opacity-75">Serviço:</span><strong class="text-end">{{ selectedService }}</strong></div>
                        <div class="d-flex justify-content-between"><span class="opacity-75">Profissional:</span><strong class="text-end">{{ selectedProfessional?.nome }}</strong></div>
                        <div class="d-flex justify-content-between"><span class="opacity-75">Data:</span><strong class="text-end">{{ selectedDate }}</strong></div>
                        <div class="d-flex justify-content-between"><span class="opacity-75">Hora:</span><strong class="text-end">{{ selectedTime }}</strong></div>
                        <div class="d-flex justify-content-between border-top border-secondary-subtle pt-3 mt-1">
                          <span class="opacity-75 pt-1">Total:</span>
                          <strong class="fs-5" style="color: var(--button-bg);">R$ {{ selectedPrice }}</strong>
                        </div>
                      </div>

                      <div class="mt-4 p-3 rounded-4 bg-info bg-opacity-10 border border-info border-opacity-25">
                        <div class="d-flex align-items-center gap-2 text-info">
                          <i class="bi bi-info-circle-fill fs-5"></i>
                          <span class="small fw-bold">Informação de Pagamento</span>
                        </div>
                        <p class="small mb-0 mt-1 opacity-75 dynamic-text">
                          O pagamento do serviço será realizado no estabelecimento no dia do atendimento.
                        </p>
                      </div>

                      <button class="btn custom-btn w-100 rounded-pill fw-bold py-3 mt-4 shadow-sm" :disabled="!isFormValid">Confirmar Agora</button>
                    </div>
                  </div>

                </div>
              </div>
            </div>

            <footer class="mt-5 py-5" style="background: var(--glass-bg); backdrop-filter: blur(15px); border-top: 1px solid rgba(0,0,0,0.05); transition: background 0.4s;">
              <div class="container">
                <div class="row g-4">
                  <div class="col-lg-4 col-md-6">
                    <a class="fw-bold fs-4 custom-logo text-decoration-none d-block text-wrap text-break mb-2" href="#">{{ store.salonConfig.nome }}</a>
                    <p class="mt-3 dynamic-text" style="max-width: 300px; opacity: 0.8;">
                      {{ store.salonConfig.descricao }}
                    </p>
                    <div class="d-flex gap-3 mt-4">
                      <a
                        v-if="store.salonConfig.contato.instagram"
                        :href="safeExternalUrl('https://instagram.com/' + store.salonConfig.contato.instagram)"
                        target="_blank"
                        rel="noopener noreferrer"
                        class="btn btn-outline-primary btn-sm rounded-circle custom-icon-btn"
                      ><i class="bi bi-instagram"></i></a>
                      <a
                        v-if="store.salonConfig.contato.facebook"
                        :href="safeExternalUrl(store.salonConfig.contato.facebook)"
                        target="_blank"
                        rel="noopener noreferrer"
                        class="btn btn-outline-primary btn-sm rounded-circle custom-icon-btn"
                      ><i class="bi bi-facebook"></i></a>
                      <a
                        v-if="store.salonConfig.contato.whatsapp"
                        :href="safeExternalUrl('https://wa.me/55' + (store.salonConfig.contato.whatsapp ? store.salonConfig.contato.whatsapp.replace(/\D/g, '') : ''))"
                        target="_blank"
                        rel="noopener noreferrer"
                        class="btn btn-outline-primary btn-sm rounded-circle custom-icon-btn"
                      ><i class="bi bi-whatsapp"></i></a>
                    </div>
                  </div>

                  <div class="col-lg-4 col-md-6">
                    <h6 class="fw-bold mb-4 dynamic-text">Informações</h6>
                    <ul class="list-unstyled d-grid gap-2">
                      <li><span class="small dynamic-text" style="opacity: 0.8;"><i class="bi bi-geo-alt-fill me-2 custom-icon"></i>{{ store.salonConfig.contato.endereco }}</span></li>
                      <li><span class="small dynamic-text" style="opacity: 0.8;"><i class="bi bi-telephone-fill me-2 custom-icon"></i>{{ store.salonConfig.contato.telefone }}</span></li>
                      <li><span class="small dynamic-text" style="opacity: 0.8;"><i class="bi bi-whatsapp me-2 custom-icon"></i>{{ store.salonConfig.contato.whatsapp }}</span></li>
                      <li><span class="small dynamic-text" style="opacity: 0.8;"><i class="bi bi-clock-fill me-2 custom-icon"></i>{{ store.salonConfig.funcionamento?.horariosTexto || '' }}</span></li>
                    </ul>
                  </div>

                  <div class="col-lg-4 col-md-12">
                    <h6 class="fw-bold mb-4 dynamic-text">Facilidades</h6>
                    <div class="d-flex flex-wrap gap-2 mb-4">
                      <span
                        v-for="(amenity, index) in (store.salonConfig.facilidades?.comodidades || [])"
                        :key="index"
                        class="badge bg-secondary bg-opacity-10 dynamic-text border border-secondary-subtle"
                        style="opacity: 0.8;"
                      >{{ amenity }}</span>
                    </div>
                    <h6 class="fw-bold mb-3 small dynamic-text">Aceitamos</h6>
                    <div class="d-flex gap-3 opacity-75">
                      <i v-if="store.salonConfig.facilidades?.pagamentos?.includes('pix')" class="bi bi-qr-code fs-4 custom-icon" title="Pix"></i>
                      <i v-if="store.salonConfig.facilidades?.pagamentos?.includes('cartao')" class="bi bi-credit-card fs-4 custom-icon" title="Cartão"></i>
                      <i v-if="store.salonConfig.facilidades?.pagamentos?.includes('dinheiro')" class="bi bi-cash fs-4 custom-icon" title="Dinheiro"></i>
                    </div>
                  </div>
                </div>

                <div class="row mt-4 pt-4 border-top">
                  <div class="col-12">
                    <div class="d-flex flex-wrap justify-content-center gap-3 gap-lg-4">
                      <a href="#" class="small text-decoration-none dynamic-text" style="opacity: 0.6;"><i class="bi bi-shield-lock me-1"></i>Política de Privacidade</a>
                      <a href="#" class="small text-decoration-none dynamic-text" style="opacity: 0.6;"><i class="bi bi-file-earmark-text me-1"></i>Termos de Uso</a>
                      <a href="#" class="small text-decoration-none dynamic-text" style="opacity: 0.6;"><i class="bi bi-cookie me-1"></i>Política de Cookies</a>
                      <a href="#" class="small text-decoration-none dynamic-text" style="opacity: 0.6;"><i class="bi bi-info-circle me-1"></i>Quem Somos</a>
                      <a href="#" class="small text-decoration-none dynamic-text" style="opacity: 0.6;"><i class="bi bi-question-circle me-1"></i>Perguntas Frequentes</a>
                      <a href="#" class="small text-decoration-none dynamic-text" style="opacity: 0.6;"><i class="bi bi-envelope me-1"></i>Contato</a>
                    </div>
                  </div>
                </div>

                <hr class="my-4 opacity-10">
                <p class="text-center small mb-0 dynamic-text" style="opacity: 0.7;">© 2026 {{ store.salonConfig.nome }} - Todos os direitos reservados. Feito com EasySloting.</p>
              </div>
            </footer>

          </div>
        </div>

      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, watch } from 'vue'
import AdminLayout from '@/views/admin/Layout/AdminLayout.vue'
import { useThemeStore } from '@/stores/themeStore'
import { api } from '@/services/api'
import { loadFontIfValid, sanitizeFontName, isValidFont, ALLOWED_FONT_FAMILIES } from '@/utils/fontLoader'

const store = useThemeStore()
const activePreviewPage = ref('home')
const isSaving = ref(false)
const previewBookingMode = ref<'service' | 'package'>('service')
let lastSaveTimestamp = 0

const isOwner = computed(() => {
  let role = localStorage.getItem('role') || sessionStorage.getItem('role')
  if (!role) {
    const userStr = localStorage.getItem('user') || sessionStorage.getItem('user')
    if (userStr) {
      try { role = JSON.parse(userStr).role } catch { role = '' }
    }
  }
  return role === 'owner' || role === 'super_admin'
})

const isValidHex = (color: string): boolean => /^#[0-9A-Fa-f]{6}$/.test(color)

function isSafeUrl(url: string): boolean {
  if (!url) return false
  const trimmed = url.trim().toLowerCase()
  if (trimmed.startsWith('javascript:') || trimmed.startsWith('data:')) return false
  try {
    const parsed = new URL(url, window.location.origin)
    return ['http:', 'https:', 'mailto:', 'tel:'].includes(parsed.protocol)
  } catch {
    return url.startsWith('/') || url.startsWith('#')
  }
}

function safeImageUrl(url: string, fallback: string = ''): string {
  if (!url || !isSafeUrl(url)) return fallback
  return url
}

function safeExternalUrl(url: string): string {
  if (!url || !isSafeUrl(url)) return '#'
  return url
}

const colorHints: Record<string, string> = {
  logo: 'Navbar, rodape, links da marca',
  buttonBg: 'Agendar, Confirmar, Criar Conta',
  buttonHover: 'Estado ao passar o mouse',
  icon: 'Redes sociais, endereco, telefone, servicos',
  background: 'Cor de fundo do toggle dark/light',
  navbar: 'Barra de navegacao no topo',
  text: 'Titulos, paragrafos, labels, descricoes'
}

function onFontChange(e: Event) {
  const val = (e.target as HTMLSelectElement).value
  const fontName = sanitizeFontName(val.replace(/',\s*\w+$/, '').replace(/^'/, ''))
  if (fontName) {
    loadFontIfValid(fontName)
  }
  store.setFont(val)
}

function onFontSizeInput(e: Event) {
  const val = parseInt((e.target as HTMLInputElement).value)
  if (val >= 12 && val <= 24) {
    store.setFontSize(`${val}px`)
  }
}

let colorDebounceTimers: Record<string, ReturnType<typeof setTimeout>> = {}

function onColorInput(type: string, e: Event) {
  const val = (e.target as HTMLInputElement).value
  if (!isValidHex(val)) return

  if (colorDebounceTimers[type]) {
    clearTimeout(colorDebounceTimers[type])
  }

  colorDebounceTimers[type] = setTimeout(() => {
    applyColorChange(type, val)
  }, 16)
}

function applyColorChange(type: string, color: string) {
  switch (type) {
    case 'logo':
      store.setLogoColor(color)
      break
    case 'buttonBg':
      store.setButtonColor(color, darkenColor(color, 10))
      break
    case 'buttonHover':
      store.themeConfig.buttonHover = color
      break
    case 'icon':
      store.setIconColor(color)
      break
    case 'background':
      store.themeConfig.backgroundLight = color
      break
    case 'navbar':
      store.themeConfig.navbarLight = hexToRgba(color, 0.9)
      break
    case 'text':
      store.themeConfig.textLight = color
      break
  }
}

function hexToRgba(hex: string, alpha: number): string {
  const r = parseInt(hex.slice(1, 3), 16)
  const g = parseInt(hex.slice(3, 5), 16)
  const b = parseInt(hex.slice(5, 7), 16)
  return `rgba(${r}, ${g}, ${b}, ${alpha})`
}

function darkenColor(hex: string, percent: number): string {
  const r = Math.max(0, parseInt(hex.slice(1, 3), 16) - Math.round(255 * percent / 100))
  const g = Math.max(0, parseInt(hex.slice(3, 5), 16) - Math.round(255 * percent / 100))
  const b = Math.max(0, parseInt(hex.slice(5, 7), 16) - Math.round(255 * percent / 100))
  return `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`
}

const resetarAparencia = () => {
  if (!isOwner.value) {
    alert('Acesso negado: Apenas o proprietário pode restaurar o tema padrão.')
    return
  }
  if (confirm('Tem certeza que deseja restaurar as cores para o padrão original? Isso apagará as cores atuais.')) {
    store.resetStandard()
    alert('Cores restauradas com sucesso. Lembre-se de "Salvar Alterações" para aplicar no site.')
  }
}

const navbarLightHex = computed(() => {
  const rgba = store.themeConfig.navbarLight
  const match = rgba.match(/\d+/g)

  if (!match || match.length < 3) return '#ffffff'

  return (
    '#' +
    [0, 1, 2]
      .map((i) => Number(match[i] ?? 255))
      .map((v: number) => v.toString(16).padStart(2, '0'))
      .join('')
  )
})

const previewStyles = computed(() => ({
  '--logo-color': store.themeConfig.logoColor,
  '--button-bg': store.themeConfig.buttonBg,
  '--button-hover': store.themeConfig.buttonHover,
  '--icon-color': store.themeConfig.iconColor,
  '--custom-font': store.themeConfig.fontFamily,
  '--custom-text-color': store.themeConfig.textLight,
  '--glass-bg': store.themeConfig.navbarLight,
  '--card-border': 'rgba(0,0,0,0.08)',
  '--toggle-bg': store.themeConfig.backgroundLight,
  fontFamily: store.themeConfig.fontFamily,
  fontSize: store.themeConfig.fontSize,
  color: store.themeConfig.textLight
}))

const setCustomButtonColor = (e: Event) => {
  const color = (e.target as HTMLInputElement).value
  if (isValidHex(color)) {
    store.setButtonColor(color, darkenColor(color, 10))
  }
}



const salvarAparencia = async () => {
  if (!isOwner.value) {
    alert('Acesso negado: Apenas o proprietário pode alterar as configurações de aparência.')
    return
  }

  const now = Date.now()
  if (now - lastSaveTimestamp < 2000) {
    alert('Aguarde antes de salvar novamente.')
    return
  }
  lastSaveTimestamp = now

  try {
    isSaving.value = true

    const theme = sanitizeThemePayload(store.themeConfig)

    const payload = {
      establishment: {
        public_settings: {
          horarios_texto: String(store.salonConfig.funcionamento?.horariosTexto || '').slice(0, 200),
          theme
        }
      }
    }
    await api.put('/admin/establishment', payload)

    const cache = localStorage.getItem('establishment-data')
    if (cache) {
      try {
        const parsed = JSON.parse(cache)
        if (parsed && typeof parsed === 'object') {
          parsed.public_settings = parsed.public_settings || {}
          parsed.public_settings.theme = theme
          localStorage.setItem('establishment-data', JSON.stringify(parsed))
        }
      } catch { /* ignore parse errors */ }
    }

    alert('Configurações aplicadas com sucesso!')
  } catch (error: any) {
    console.error('Erro ao salvar tema:', error)
    const msg = error?.response?.data?.error || 'Erro ao salvar as configurações de aparência.'
    alert(msg)
  } finally {
    isSaving.value = false
  }
}

function sanitizeThemePayload(config: Record<string, any>): Record<string, string> {
  const sanitized: Record<string, string> = {}
  const allowedKeys = [
    'logoColor', 'buttonBg', 'buttonHover', 'iconColor',
    'fontFamily', 'fontSize', 'backgroundLight', 'textLight',
    'navbarLight', 'cardLight', 'backgroundDark', 'textDark',
    'navbarDark', 'cardDark'
  ]
  for (const key of allowedKeys) {
    if (typeof config[key] !== 'string') continue
    const val = config[key]
    if (key === 'fontFamily') {
      const fontName = sanitizeFontName(val.replace(/',\s*\w+$/, '').replace(/^'/, ''))
      sanitized[key] = isValidFont(fontName)
        ? `'${fontName}', sans-serif`
        : "'Inter', sans-serif"
    } else if (key === 'fontSize') {
      const size = parseInt(val)
      sanitized[key] = (size >= 12 && size <= 24) ? `${size}px` : '16px'
    } else if (key.endsWith('Light') || key.endsWith('Dark')) {
      if (key.includes('navbar')) {
        sanitized[key] = /^rgba\(\d{1,3},\s*\d{1,3},\s*\d{1,3},\s*[\d.]+\)$/.test(val)
          ? val.slice(0, 60) : 'rgba(255, 255, 255, 0.9)'
      } else {
        sanitized[key] = isValidHex(val) ? val : '#ffffff'
      }
    } else {
      sanitized[key] = isValidHex(val) ? val : '#0d6efd'
    }
  }
  return sanitized
}

const heroConfig = ref({
  title: 'Estilo e tradição em cada corte',
  subtitle: 'Cortes no padrão, degradê perfeito e barba na toalha quente. Agende seu horário e evite filas.',
  buttonText: 'AGENDAR HORÁRIO',
  backgroundImage: 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?q=80&w=2070'
})

const testimonials = ref([
  { id: 1, nome: 'Lucas Machado', servico: 'Corte Degradê', rating: 5, texto: 'Excelente atendimento, corte impecável! Recomendo muito.', foto: 'https://i.pravatar.cc/150?u=11' },
  { id: 2, nome: 'Marcos Paulo', servico: 'Barba Terapia', rating: 5, texto: 'Ambiente sensacional, toalha quente faz toda a diferença.', foto: 'https://i.pravatar.cc/150?u=22' },
  { id: 3, nome: 'João Fernandes', servico: 'Corte + Barba', rating: 4.5, texto: 'Ótimo profissional, muito atencioso e rápido.', foto: 'https://i.pravatar.cc/150?u=33' }
])

const visibleCards = computed(() => {
  if (typeof window === 'undefined') return 3
  if (window.innerWidth <= 767) return 1
  if (window.innerWidth <= 991) return 2
  return 3
})

const cloneCount = computed(() => Math.min(visibleCards.value, testimonials.value.length))

const carouselTestimonials = computed(() => {
  if (!testimonials.value.length) return []
  const startClones = testimonials.value.slice(-cloneCount.value)
  const endClones = testimonials.value.slice(0, cloneCount.value)
  return [...startClones, ...testimonials.value, ...endClones]
})

const scrollContainer = ref<HTMLElement | null>(null)
const timer = 8000
let autoScrollInterval: any = null
let isScrolling = false

function scrollToSmoothly(element: HTMLElement, target: number, duration: number) {
  if (isScrolling) return
  isScrolling = true
  element.style.scrollBehavior = 'auto'
  const start = element.scrollLeft
  const change = target - start
  const startTime = performance.now()

  function animateScroll(currentTime: number) {
    const timeElapsed = currentTime - startTime
    let t = timeElapsed / (duration / 2)
    let progress = t < 1
      ? change / 2 * t * t + start
      : -change / 2 * ((t - 1) * (t - 3) - 1) + start

    element.scrollLeft = progress

    if (timeElapsed < duration) {
      requestAnimationFrame(animateScroll)
    } else {
      element.scrollLeft = target
      isScrolling = false
    }
  }

  requestAnimationFrame(animateScroll)
}

function scrollManual(direction: number) {
  if (autoScrollInterval) {
    clearInterval(autoScrollInterval)
    autoScrollInterval = null
  }

  if (isScrolling || !scrollContainer.value) return

  const gap = parseInt(window.getComputedStyle(scrollContainer.value).gap) || 20
  const step = (scrollContainer.value.querySelector('.carousel-item-custom')?.getBoundingClientRect().width || 0) + gap

  scrollToSmoothly(scrollContainer.value, scrollContainer.value.scrollLeft + (direction * step), 900)
}

function startAutoScroll() {
  if (!autoScrollInterval && testimonials.value.length > 0) {
    autoScrollInterval = setInterval(() => scrollManual(1), timer)
  }
}

function pauseAutoScroll() {
  if (autoScrollInterval) {
    clearInterval(autoScrollInterval)
    autoScrollInterval = null
  }
}

const dateScrollRef = ref<HTMLElement | null>(null)

const profissionais = ref<any[]>([
  { id: 'sem', nome: 'Qualquer um', cargo: 'Disponível', icone: 'bi-people', agenda: { horarios: ['08:00', '09:00', '10:00', '13:00'], bloqueados: [] } }
])
const servicesList = ref<any[]>([])

const formatCurrency = (value: string | number) => {
  const numberValue = Number(value || 0)
  return numberValue.toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

const selectedService = ref('-')
const selectedPrice = ref('0,00')
const selectedProfessional = ref(profissionais.value[0])
const selectedDate = ref('-')
const selectedTime = ref('-')
const availableDates = ref<any[]>([])

const selectService = (serviceName: string, price: string) => {
  selectedService.value = serviceName
  selectedPrice.value = price
}

const scrollListDays = (direction: number) => {
  if (dateScrollRef.value) {
    dateScrollRef.value.scrollBy({ left: direction * 200, behavior: 'smooth' })
  }
}

const goToToday = () => {
  if (availableDates.value.length > 0) {
    selectedDate.value = availableDates.value[0].fullString
    if (dateScrollRef.value) {
      dateScrollRef.value.scrollTo({ left: 0, behavior: 'smooth' })
    }
  }
}

const filteredDates = computed(() => {
  return availableDates.value.filter(date => !selectedProfessional.value?.agenda?.bloqueados.includes(date.fullString))
})

const filteredTimes = computed(() => selectedProfessional.value?.agenda?.horarios || [])

watch(selectedProfessional, () => {
  selectedDate.value = '-'
  selectedTime.value = '-'
})

const isFormValid = computed(() => {
  return selectedService.value !== '-' && selectedDate.value !== '-' && selectedTime.value !== '-'
})

onMounted(async () => {
  try {
    const response = await api.get('/admin/establishment')
    const estData = response.data
    if (estData) {
      store.setSalonConfig(estData)
      if (estData.public_settings?.theme) {
        store.themeConfig = { ...store.themeConfig, ...estData.public_settings.theme }
      }
    }
  } catch (err) {
    console.warn('Não foi possível sincronizar o tema com o servidor:', err)
  }

  const currentFont = sanitizeFontName(store.themeConfig.fontFamily.replace(/',\s*\w+$/, '').replace(/^'/, ''))
  if (currentFont) {
    loadFontIfValid(currentFont)
  }

  setTimeout(() => {
    if (scrollContainer.value && testimonials.value.length > 0) {
      startAutoScroll()
    }
  }, 100)

  const monthsList = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez']
  const weekDaysList = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']
  for (let i = 0; i < 30; i++) {
    const d = new Date()
    d.setDate(d.getDate() + i)
    availableDates.value.push({
      dayNumber: d.getDate(),
      monthName: monthsList[d.getMonth()],
      weekDay: weekDaysList[d.getDay()],
      fullString: `${d.getDate()} de ${monthsList[d.getMonth()]}`
    })
  }

  // Dados fictícios para o Preview Visual
  servicesList.value = [
    { id: 1, name: 'Corte Degradê', duration_minutes: 40, price: '45.00' },
    { id: 2, name: 'Barba Terapia', duration_minutes: 30, price: '35.00' },
    { id: 3, name: 'Corte + Barba', duration_minutes: 70, price: '75.00' }
  ]

  const mockEmployees = [
    {
      id: 2,
      nome: 'Carlos Silva',
      cargo: 'Barbeiro Sênior',
      icone: 'bi-person',
      agenda: { horarios: ['09:00', '10:30', '14:00', '15:30', '17:00'], bloqueados: [] }
    },
    {
      id: 3,
      nome: 'Rafael Costa',
      cargo: 'Barbeiro',
      icone: 'bi-person',
      agenda: { horarios: ['09:00', '10:00', '11:00', '14:00', '16:00'], bloqueados: [] }
    }
  ]
  
  profissionais.value = [
    ...profissionais.value,
    ...mockEmployees
  ]
})

onUnmounted(() => {
  pauseAutoScroll()
  Object.values(colorDebounceTimers).forEach(clearTimeout)
  colorDebounceTimers = {}
})
</script>

<style scoped>
.admin-card { border-radius: 12px; padding: 1.25rem; transition: background-color 0.3s, border-color 0.3s; }
.color-row { display: flex; align-items: center; justify-content: space-between; }
.color-hint { font-size: 0.65rem; color: var(--bs-secondary-color); margin-top: 2px; display: block; line-height: 1.3; }
.address-label { font-size: 0.65rem; font-weight: 800; text-transform: uppercase; margin-bottom: 6px; }
.extra-small { font-size: 0.75rem; }
.form-control-color { width: 36px; height: 36px; border-radius: 8px; border: 2px solid var(--bs-border-color); padding: 2px; cursor: pointer; background: transparent; will-change: auto; }
.form-control-color:hover { border-color: var(--bs-primary); transform: scale(1.05); transition: transform 0.15s ease, border-color 0.15s ease; }
.custom-scrollbar::-webkit-scrollbar { width: 5px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: var(--bs-secondary-bg); border-radius: 10px; }

.preview-window {
  overflow-y: auto;
  overflow-x: hidden;
  transition: background-color 0.4s ease, color 0.4s ease;
  position: relative;
  z-index: 1;
}
.preview-window::-webkit-scrollbar { width: 6px; }
.preview-window::-webkit-scrollbar-thumb { background: rgba(0,0,0,0.15); border-radius: 10px; }

.preview-navbar {
  backdrop-filter: blur(15px);
  background: var(--glass-bg);
  padding: 12px 0;
  border-bottom: 1px solid rgba(0,0,0,0.05);
  box-shadow: 0 4px 12px rgba(0,0,0,0.05);
  transition: background 0.4s;
  z-index: 50 !important;
}

:deep(.navbar:not(.preview-navbar)) { z-index: 1050 !important; }

.custom-logo { color: var(--logo-color) !important; transition: color 0.3s; }
.custom-icon { color: var(--icon-color) !important; transition: color 0.3s; }
.dynamic-text { color: var(--custom-text-color) !important; transition: color 0.3s; }
.custom-btn { background-color: var(--button-bg) !important; border-color: var(--button-bg) !important; color: white !important; transition: background-color 0.3s, border-color 0.3s; }
.custom-btn:hover { background-color: var(--button-hover) !important; border-color: var(--button-hover) !important; }
.custom-outline-btn { color: var(--button-bg) !important; border-color: var(--button-bg) !important; background-color: transparent !important; transition: background-color 0.3s, color 0.3s; }
.custom-outline-btn:hover { background-color: var(--button-hover) !important; border-color: var(--button-hover) !important; color: #ffffff !important; }
.custom-icon-btn { color: var(--icon-color) !important; border-color: var(--icon-color) !important; transition: all 0.3s; }
.custom-icon-btn:hover { background-color: var(--icon-color) !important; color: #fff !important; }

.hero-section {
  position: relative;
  overflow: hidden;
  height: 600px;
  border-radius: 0 0 40px 40px;
  background-size: cover !important;
  background-position: center center;
  background-repeat: no-repeat !important;
}

.hero-section::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(to bottom, rgba(0,0,0,0.4), rgba(0,0,0,0.7));
  z-index: 1;
}

.hero-content {
  position: relative;
  z-index: 2;
}

.search-container { margin-top: -55px; position: relative; z-index: 100; }
.featured-panel { margin-top: 70px; padding: 0 119px 60px; position: relative; }

.testimonial-viewport {
  overflow: hidden;
  width: 100%;
}

.testimonial-track {
  display: flex;
  gap: 24px;
  overflow-x: hidden;
  scrollbar-width: none;
  scroll-behavior: smooth;
  padding: 12px 2px;
  box-sizing: border-box;
}

.testimonial-track::-webkit-scrollbar { display: none; }

.carousel-item-custom {
  flex: 0 0 calc((100% - 48px) / 3);
  min-width: calc((100% - 48px) / 3);
  box-sizing: border-box;
  display: flex;
  scroll-snap-align: center;
}

@media (max-width: 991px) {
  .carousel-item-custom {
    flex: 0 0 calc((100% - 24px) / 2);
    min-width: calc((100% - 24px) / 2);
  }
}

@media (max-width: 767px) {
  .carousel-item-custom {
    flex: 0 0 100%;
    min-width: 100%;
  }
}

.company-card {
  width: 100%;
  box-shadow: 0 4px 20px rgba(0,0,0,0.04);
  border-radius: 25px;
  background: var(--card-bg);
  border: 1px solid var(--card-border);
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  box-sizing: border-box;
  transform: none;
}

@media (hover: hover) and (pointer: fine) {
  .company-card:hover {
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.12);
    transform: translateY(-4px);
    border-color: var(--button-bg);
  }
}

.testimonial-text {
  max-width: 95%;
  line-height: 1.6;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 4;
  line-clamp: 4;
  -webkit-box-orient: vertical;
}

.carousel-nav-btn {
  width: 48px;
  height: 48px;
  padding: 0;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  position: absolute;
  top: 50%;
  transform: translateY(-50%) !important;
  appearance: none;
  -webkit-appearance: none;
  border: 1px solid var(--card-border);
  background: rgba(255, 255, 255, 0.92);
  color: #1f2937;
  backdrop-filter: blur(8px);
  box-shadow: 0 8px 24px rgba(0,0,0,0.12);
  transition: background 0.3s ease, color 0.3s ease, border-color 0.3s ease, box-shadow 0.3s ease, opacity 0.3s ease;
  cursor: pointer;
}

.carousel-nav-btn i {
  font-size: 1.2rem;
  line-height: 1;
  pointer-events: none;
}

.carousel-nav-btn:hover,
.carousel-nav-btn:focus,
.carousel-nav-btn:active {
  transform: translateY(-50%) !important;
  top: 50% !important;
  margin-top: 0 !important;
  outline: none !important;
  box-shadow: 0 8px 24px rgba(0,0,0,0.16);
}

.carousel-nav-left { left: 34px; }
.carousel-nav-right { right: 34px; }

.theme-switch {
  width: 55px;
  height: 30px;
  background: var(--toggle-bg, var(--bs-tertiary-bg));
  border-radius: 50px;
  border: 1px solid var(--card-border);
  position: relative;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: space-around;
  transition: background 0.3s;
}

.theme-switch .ball {
  width: 22px;
  height: 22px;
  background: #fff !important;
  border-radius: 50%;
  position: absolute;
  left: 3px;
  transition: transform 0.3s cubic-bezier(0.4, 0.0, 0.2, 1);
  z-index: 2;
  box-shadow: 0 1px 3px rgba(0,0,0,0.2);
}

.profile-cover {
  position: relative;
  height: 250px;
  border-radius: 0 0 40px 40px;
  overflow: hidden;
  background-size: cover;
  background-position: center center;
  background-repeat: no-repeat;
}

.profile-avatar {
  width: 130px;
  height: 130px;
  border-radius: 22px;
  border: 5px solid;
  margin-top: -65px;
  object-fit: cover;
  box-shadow: 0 10px 25px rgba(0,0,0,0.1);
}

.transition-all { transition: all 0.3s ease; }
.hover-opacity-100:hover { opacity: 1 !important; }

.booking-mode-toggle {
  display: flex;
  gap: 0;
  background: var(--bs-tertiary-bg);
  border: 1px solid var(--card-border);
  border-radius: 50px;
  padding: 4px;
  width: fit-content;
  max-width: 100%;
}

.mode-btn {
  flex: 1;
  padding: 10px 24px;
  border: none;
  background: transparent;
  border-radius: 50px;
  font-weight: 600;
  font-size: 0.875rem;
  color: var(--custom-text-color);
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  white-space: nowrap;
  opacity: 0.65;
}

.mode-btn.active {
  background: var(--button-bg);
  color: #fff;
  opacity: 1;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.mode-btn:hover:not(.active) {
  opacity: 0.85;
  background: rgba(0, 0, 0, 0.04);
}

.service-selection-card { border: 1px solid var(--card-border); border-radius: 20px; background: var(--bs-tertiary-bg); cursor: pointer; transition: all 0.3s; position: relative; }
.service-selection-card.selected { border: 2px solid var(--button-bg); background: color-mix(in srgb, var(--button-bg) 8%, transparent); }
.icon-box-dynamic { background: color-mix(in srgb, var(--icon-color) 12%, transparent); color: var(--icon-color); }
.scroll-arrow { width: 40px; height: 40px; background: var(--glass-bg) !important; border: 1px solid var(--card-border) !important; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: var(--icon-color) !important; transition: background-color 0.2s, color 0.2s; }
.scroll-arrow:hover { background: var(--button-bg) !important; color: white !important; }
.colab-container { display: flex; gap: 15px; overflow-x: auto; padding: 10px 0; scrollbar-width: none; }
.colab-container::-webkit-scrollbar { display: none; }
.colab-select-card { min-width: 130px; padding: 15px 10px; border-radius: 18px; border: 1px solid var(--card-border); background: var(--bs-tertiary-bg); display: flex; flex-direction: column; align-items: center; justify-content: center; cursor: pointer; transition: all 0.2s; text-align: center; }
.colab-select-card.active { background: var(--button-bg); border-color: var(--button-bg); }
.colab-select-card.active .colab-text { color: white !important; opacity: 1 !important; }
.avatar-placeholder { width: 50px; height: 50px; border-radius: 50%; background: color-mix(in srgb, var(--icon-color) 10%, transparent); color: var(--icon-color); display: flex; align-items: center; justify-content: center; margin-bottom: 10px; transition: 0.2s; }
.colab-select-card.active .avatar-placeholder { background: white; color: var(--button-bg); }
.date-container { display: flex; gap: 12px; overflow-x: auto; padding: 5px 0; scrollbar-width: none; scroll-snap-type: x mandatory; scroll-behavior: smooth; }
.date-container::-webkit-scrollbar { display: none; }
.date-card { min-width: 78px; height: 90px; border-radius: 16px; border: 1px solid var(--card-border); background: var(--bs-tertiary-bg); display: flex; flex-direction: column; align-items: center; justify-content: center; cursor: pointer; transition: background-color 0.2s, border-color 0.2s; scroll-snap-align: start; }
.date-card:hover { border-color: var(--button-bg); }
.date-card.active { background: var(--button-bg); border-color: var(--button-bg); }
.date-card.active .date-text { color: white !important; opacity: 1 !important; }
.hours-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(85px, 1fr)); gap: 12px; }
.hour-item { padding: 12px 5px; border-radius: 12px; border: 1px solid var(--card-border); background: var(--bs-tertiary-bg); text-align: center; font-weight: 700; font-size: 0.95rem; cursor: pointer; transition: all 0.2s; }
.hour-item.active { background: var(--button-bg); color: white !important; border-color: var(--button-bg); }

.sticky-summary {
  position: sticky;
  top: 100px;
  z-index: 1 !important;
}

@media (min-width: 992px) {
  .aparencia-container {
    height: calc(100vh - 70px);
    overflow: hidden;
  }
  .sidebar-panel {
    height: 100%;
    overflow-y: auto;
  }
  .preview-panel {
    height: 100%;
  }
}

@media (max-width: 991px) {
  .aparencia-container {
    height: auto;
    overflow: visible;
  }
  .sidebar-panel {
    height: auto;
    overflow: visible;
  }
  .preview-panel {
    min-height: 800px;
    height: auto;
  }
  .preview-window {
    border-radius: 12px;
    margin-top: 2rem;
    box-shadow: 0 10px 25px rgba(0,0,0,0.1);
  }
  .featured-panel {
    padding: 0 20px 60px;
  }
}

:deep(.admin-content) { padding: 0 !important; overflow: hidden; z-index: 1; }
</style>