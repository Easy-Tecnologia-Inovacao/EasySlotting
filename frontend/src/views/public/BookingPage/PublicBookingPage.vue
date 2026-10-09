<template>
  <div
    :data-bs-theme="store.isDarkMode ? 'dark' : 'light'"
    class="bg-body text-body min-vh-100 pb-5 page-offset"
    :style="pageThemeVars"
  >
    <nav class="navbar navbar-expand-lg sticky-top shadow-sm">
      <div class="container d-flex align-items-center">
        <router-link :to="`/empresa/${route.params.slug}`" class="navbar-brand fw-bold fs-3 custom-logo m-0">
          {{ store.salonConfig.nome }}
        </router-link>

        <div class="collapse navbar-collapse" id="navContent">
          <ul class="navbar-nav me-auto"></ul>

          <div class="d-flex flex-wrap align-items-center gap-2 gap-lg-3 mt-3 mt-lg-0">
            <div v-if="!isAuthenticated" class="d-flex flex-wrap align-items-center gap-2">
              <router-link
                :to="{ path: `/empresa/${route.params.slug}/login`, query: { redirect: route.fullPath } }"
                class="btn btn-link text-decoration-none fw-bold small dynamic-text"
              >
                Entrar
              </router-link>

              <router-link
                :to="`/empresa/${route.params.slug}/cadastro`"
                class="btn btn-sm rounded-pill fw-bold px-3 py-2 border-2 custom-outline-btn"
              >
                Criar conta
              </router-link>
            </div>

            <div v-else class="d-flex flex-wrap align-items-center gap-2">
              <button
                type="button"
                class="btn btn-sm rounded-pill fw-bold px-4 py-2 custom-btn"
                @click="goToMyAccount"
              >
                Minha Conta
              </button>

              <button
                type="button"
                class="btn btn-sm rounded-pill fw-bold px-3 py-2 border-2 custom-outline-btn"
                @click="logout"
              >
                Sair
              </button>
            </div>
          </div>
        </div>

        <div class="d-flex align-items-center gap-3 ms-auto ms-lg-4">
          <input type="checkbox" id="darkToggle" class="d-none" v-model="store.isDarkMode">
          <label for="darkToggle" class="theme-switch mb-0 shadow-sm">
            <div class="ball"></div>
            <i class="bi bi-sun-fill text-warning"></i>
            <i class="bi bi-moon-stars-fill text-secondary opacity-75"></i>
          </label>
          <button
            class="navbar-toggler border-0 shadow-none p-0"
            type="button"
            data-bs-toggle="collapse"
            data-bs-target="#navContent"
          >
            <i class="bi bi-list fs-2 dynamic-text"></i>
          </button>
        </div>
      </div>
    </nav>

    <div class="container-fluid p-0">
      <div
        class="profile-cover"
        :style="{
          backgroundImage:
            'linear-gradient(rgba(0,0,0,0.3), rgba(0,0,0,0.7)), url(' +
            (store.salonConfig.imagens.capaUrl || getDefaultBannerUrl()) +
            ')'
        }"
      ></div>
    </div>

    <div class="container mb-5">
      <div class="row">
        <div class="col-lg-8">
          <div class="d-flex flex-column flex-md-row align-items-md-end gap-3 mb-5 position-relative">
            <img
              :src="store.salonConfig.imagens.avatarUrl || getDefaultAvatarUrl()"
              class="profile-avatar bg-body"
              alt="Avatar do Estabelecimento"
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

                <span class="badge bg-success bg-opacity-10 text-success rounded-pill px-3 border border-success-subtle">
                  Aberto para agendamento
                </span>

                <div class="d-flex gap-3 ms-md-auto mt-2 mt-md-0">
                  <a
                    v-if="store.salonConfig.contato.instagram"
                    :href="'https://instagram.com/' + store.salonConfig.contato.instagram"
                    target="_blank"
                    class="text-decoration-none small fw-bold dynamic-text transition-all hover-opacity-100 opacity-75"
                  >
                    <i class="bi bi-instagram me-1 custom-icon"></i>Instagram
                  </a>

                  <a
                    v-if="store.salonConfig.contato.whatsapp"
                    :href="'https://wa.me/55' + onlyDigits(store.salonConfig.contato.whatsapp)"
                    target="_blank"
                    class="text-decoration-none small fw-bold dynamic-text transition-all hover-opacity-100 opacity-75"
                  >
                    <i class="bi bi-whatsapp me-1 custom-icon"></i>WhatsApp
                  </a>
                </div>
              </div>
            </div>
          </div>

          <!-- Toggle: Modo de Agendamento -->
          <section class="mb-5">
            <label class="small fw-bold mb-3 text-uppercase dynamic-text opacity-75">
              1. Como deseja agendar?
            </label>

            <div class="booking-mode-toggle">
              <button
                class="mode-btn"
                :class="{ active: bookingMode === 'service' }"
                @click="setBookingMode('service')"
              >
                <i class="bi bi-scissors me-2"></i>Serviço Avulso
              </button>
              <button
                class="mode-btn"
                :class="{ active: bookingMode === 'package' }"
                @click="setBookingMode('package')"
              >
                <i class="bi bi-star me-2"></i>Pacote Mensal
              </button>
            </div>
          </section>

          <!-- Seção de Profissionais -->
          <section class="mb-5" id="secao-profissionais">
            <label class="small fw-bold mb-3 text-uppercase dynamic-text opacity-75">
              2. Escolha o Profissional
            </label>

            <div class="colab-container pb-2">
              <div
                v-for="pro in profissionais"
                :key="pro.id"
                class="colab-select-card shadow-sm"
                :class="{ 
                  active: selectedProfessional?.id === pro.id,
                  'opacity-50 pointer-events-none': packageAppointments.length > 0 && selectedProfessional?.id !== pro.id
                }"
                @click="selectProfessional(pro)"
              >
                <div class="avatar-placeholder fs-4">
                  <i class="bi" :class="pro.id === 'any' ? 'bi-people' : 'bi-person'"></i>
                </div>

                <span class="fw-bold small mb-1 dynamic-text colab-text">
                  {{ pro.name }}
                </span>

                <span class="small dynamic-text opacity-75 colab-text" style="font-size: 0.75rem;">
                  {{ pro.role_label || pro.role || 'Profissional' }}
                </span>
              </div>
            </div>

            <div v-if="profissionais.length === 0 && !loadingBookingData" class="small text-muted mt-2">
              Nenhum profissional encontrado.
            </div>
          </section>

          <!-- Seção de Serviços Avulsos -->
          <section v-if="bookingMode === 'service'" class="mb-5" id="secao-servicos">
            <label class="small fw-bold mb-3 text-uppercase dynamic-text opacity-75">
              3. Selecione o Serviço
            </label>

            <div v-if="loadingBookingData" class="text-center py-4">
              <div class="spinner-border spinner-border-sm text-primary" role="status"></div>
              <p class="small dynamic-text opacity-75 mt-2 mb-0">Carregando serviços...</p>
            </div>

            <div v-else class="d-flex flex-column gap-3">
              <div
                v-for="service in filteredServices"
                :key="service.id"
                class="service-selection-card p-3 d-flex align-items-center justify-content-between shadow-sm"
                :class="{ selected: selectedService?.id === service.id }"
                @click="selectService(service)"
              >
                <div class="d-flex align-items-center gap-3">
                  <div class="rounded-3 p-3 icon-box-dynamic">
                    <i class="bi bi-scissors fs-4"></i>
                  </div>

                  <div>
                    <h6 class="fw-bold mb-0 dynamic-text">{{ service.name }}</h6>
                    <small class="dynamic-text opacity-75">
                      {{ service.duration_minutes }} min
                      <span v-if="service.description" class="ms-2 d-none d-md-inline">· {{ service.description }}</span>
                    </small>
                  </div>
                </div>

                <div class="fw-bold" style="color: var(--button-bg);">
                  R$ {{ formatCurrency(service.price) }}
                </div>
              </div>

              <div v-if="selectedProfessional && filteredServices.length === 0" class="text-center py-4">
                <i class="bi bi-calendar-x fs-2 opacity-50 d-block mb-2"></i>
                <p class="small dynamic-text opacity-75 mb-0">Nenhum serviço disponível para este profissional.</p>
              </div>

              <div v-if="!selectedProfessional && filteredServices.length === 0 && !loadingBookingData" class="text-center py-4">
                <i class="bi bi-calendar-x fs-2 opacity-50 d-block mb-2"></i>
                <p class="small dynamic-text opacity-75 mb-0">Nenhum serviço disponível no momento.</p>
              </div>
            </div>
          </section>

          <!-- Seção de Pacotes Mensais -->
          <section v-if="bookingMode === 'package'" class="mb-5" id="secao-servicos">
            <label class="small fw-bold mb-3 text-uppercase dynamic-text opacity-75">
              3. Selecione o Pacote
            </label>

            <div v-if="loadingPackages" class="text-center py-4">
              <div class="spinner-border spinner-border-sm text-primary" role="status"></div>
              <p class="small dynamic-text opacity-75 mt-2 mb-0">Carregando pacotes...</p>
            </div>

            <div v-else-if="filteredPackages.length > 0" class="d-flex flex-column gap-3">
              <div
                v-for="pkg in filteredPackages"
                :key="pkg.id"
                class="service-selection-card p-3 d-flex align-items-center justify-content-between shadow-sm"
                :class="{ 
                  selected: selectedPackage?.id === pkg.id,
                  'opacity-50 pointer-events-none': packageAppointments.length > 0 && selectedPackage?.id !== pkg.id
                }"
                @click="selectPackage(pkg)"
              >
                <div class="d-flex align-items-center gap-3">
                  <div class="rounded-3 p-3 icon-box-dynamic">
                    <i class="bi bi-star fs-4"></i>
                  </div>
                  <div>
                    <div class="d-flex align-items-center gap-2 flex-wrap">
                      <h6 class="fw-bold mb-0 dynamic-text">{{ pkg.name }}</h6>
                      <span v-if="pkg.service_name" class="badge rounded-pill px-2" style="background: rgba(13,110,253,0.12); color: var(--button-bg); font-size: 0.72rem;">
                        {{ pkg.service_name }}
                      </span>
                    </div>
                    <small class="dynamic-text opacity-75">
                      {{ pkg.sessions_total }} sessões · {{ pkg.duration_minutes }} min cada
                    </small>
                  </div>
                </div>

                <div class="text-end">
                  <div class="fw-bold" style="color: var(--button-bg);">
                    R$ {{ formatCurrency(pkg.total_price) }}
                  </div>
                </div>
              </div>
            </div>

            <div v-else-if="selectedProfessional && filteredPackages.length === 0" class="text-center py-4">
              <i class="bi bi-star fs-2 opacity-50 d-block mb-2"></i>
              <p class="small dynamic-text opacity-75 mb-0">Nenhum pacote disponível para este profissional.</p>
            </div>

            <div v-else class="text-center py-4">
              <i class="bi bi-star fs-2 opacity-50 d-block mb-2"></i>
              <p class="small dynamic-text opacity-75 mb-0">Este estabelecimento ainda não possui pacotes disponíveis.</p>
            </div>
          </section>

          <section class="mb-5" id="secao-data">
            <!-- Mensagem de conclusão quando todas as sessões foram selecionadas -->
            <div v-if="bookingMode === 'package' && !canAddMoreSessions && packageAppointments.length > 0" class="alert-inline alert-inline--success mb-3 p-3 rounded-4">
              <div class="d-flex align-items-center gap-3 w-100">
                <div class="flex-shrink-0">
                  <i class="bi bi-check-circle-fill text-success" style="font-size: 1.8rem;"></i>
                </div>
                <div class="flex-grow-1">
                  <p class="fw-bold mb-1">Todas as {{ packageAppointments.length }} sessões foram adicionadas!</p>
                  <p class="small mb-0 opacity-75">Revise as sessões ao lado e clique em <strong>CONFIRMAR</strong> para finalizar o agendamento.</p>
                </div>
              </div>
            </div>

            <!-- Seleção de data (bloqueada quando pacote completo) -->
            <template v-if="bookingMode !== 'package' || canAddMoreSessions">
              <div class="d-flex justify-content-between align-items-center mb-3">
                <label class="small fw-bold text-uppercase dynamic-text opacity-75 mb-0">
                  4. Escolha o Dia <span v-if="bookingMode === 'package'" class="text-primary">(Sessão {{ packageAppointments.length + 1 }}/{{ selectedPackage?.sessions_total || 1 }})</span>
                </label>

                <button
                  class="btn btn-sm rounded-pill fw-bold px-4 py-1 custom-outline-btn shadow-sm"
                  @click="goToToday()"
                >
                  Hoje
                </button>
              </div>

              <div class="d-flex align-items-center gap-2 gap-md-3">
                <button class="btn shadow-sm scroll-arrow flex-shrink-0" @click="scrollList(dateScrollRef, -1)">
                  <i class="bi bi-chevron-left fs-5"></i>
                </button>

                <div class="date-container pb-2 flex-grow-1" ref="dateScrollRef">
                  <div
                    v-for="(date, index) in availableDates"
                    :key="index"
                    class="date-card shadow-sm flex-shrink-0"
                    :class="{ 
                      active: selectedDate === date.apiDate,
                      'opacity-25 pointer-events-none': 
                        occupiedWeeks.has(getSundayOfDate(date.apiDate)) ||
                        (minDateForNextSession && date.apiDate <= minDateForNextSession)
                    }"
                    @click="selectDate(date.apiDate)"
                  >
                    <span class="small dynamic-text date-text opacity-75 mb-1">{{ date.weekDay }}</span>
                    <span class="fw-bold fs-4 dynamic-text date-text lh-1">{{ date.dayNumber }}</span>
                    <span class="small dynamic-text date-text opacity-75 mt-1">{{ date.monthName }}</span>
                  </div>
                </div>

                <button class="btn shadow-sm scroll-arrow flex-shrink-0" @click="scrollList(dateScrollRef, 1)">
                  <i class="bi bi-chevron-right fs-5"></i>
                </button>
              </div>

              <div v-if="hasSelectedBookingItem && selectedProfessional && availableDates.length === 0" class="small text-muted mt-3">
                Nenhum dia disponível para este serviço/profissional.
              </div>
            </template>

            <!-- Botão de adicionar sessão se for modo dia -->
            <div v-if="store.salonConfig?.booking_mode === 'day' && bookingMode === 'package' && canAddMoreSessions && selectedDate" class="mt-4 text-end">
              <button 
                class="btn custom-btn rounded-pill px-4 fw-bold shadow-sm" 
                @click="addPackageSession"
                :disabled="!canAddMoreSessions"
              >
                <i class="bi bi-plus-circle me-1"></i> 
                {{ canAddMoreSessions ? `Adicionar Sessão ${packageAppointments.length + 1}` : 'Limite de Sessões Atingido' }}
              </button>
            </div>
          </section>

          <section class="mb-5" id="secao-horario" v-if="store.salonConfig?.booking_mode !== 'day' && (bookingMode !== 'package' || canAddMoreSessions)">
            <label class="small fw-bold mb-3 text-uppercase dynamic-text opacity-75">
              5. Escolha a Hora
            </label>

            <div class="hours-grid">
              <div
                v-for="(time, index) in allTimesForDisplay"
                :key="index"
                class="hour-item shadow-sm dynamic-text"
                :class="{
                  active: selectedTime === time,
                  occupied: occupiedTimes.includes(time),
                  past: isPastTimeForSelectedDate(time)
                }"
                @click="canSelectTime(time) && (selectedTime = time)"
              >
                {{ time }}
              </div>
            </div>

            <div v-if="selectedDate && allTimesForDisplay.length === 0 && !loadingAvailability" class="small text-muted mt-3">
              Nenhum horário disponível para a seleção atual.
            </div>

            <div v-if="loadingAvailability" class="small text-muted mt-3">
              Carregando horários...
            </div>

            <!-- Botão de adicionar sessão se for modo com horário -->
            <div v-if="bookingMode === 'package' && canAddMoreSessions && selectedDate && selectedTime" class="mt-4 text-end">
              <button 
                class="btn custom-btn rounded-pill px-4 fw-bold shadow-sm" 
                @click="addPackageSession"
                :disabled="!canAddMoreSessions"
              >
                <i class="bi bi-plus-circle me-1"></i> 
                {{ canAddMoreSessions ? `Adicionar Sessão ${packageAppointments.length + 1}` : 'Limite de Sessões Atingido' }}
              </button>
            </div>
          </section>
        </div>

        <div class="col-lg-4 mt-lg-5">
          <div
            class="card border-0 shadow-sm rounded-4 p-4 sticky-top"
            style="top: 100px; background: var(--bs-tertiary-bg); border: 1px solid var(--card-border) !important;"
          >
            <h5 class="fw-bold mb-4 dynamic-text">Resumo da Reserva</h5>

            <div class="d-grid gap-3 small dynamic-text">
              <!-- Linha de Serviço/Pacote -->
              <div class="d-flex justify-content-between">
                <span class="opacity-75">{{ bookingMode === 'package' ? 'Pacote:' : 'Serviço:' }}</span>
                <strong class="text-end">
                  {{ bookingMode === 'package'
                    ? (selectedPackage?.name || '-')
                    : (selectedService?.name || '-') }}
                </strong>
              </div>

              <!-- Serviço base do pacote -->
              <div v-if="bookingMode === 'package' && selectedPackage?.service_name" class="d-flex justify-content-between">
                <span class="opacity-75">Serviço:</span>
                <strong class="text-end">{{ selectedPackage.service_name }}</strong>
              </div>

              <div class="d-flex justify-content-between">
                <span class="opacity-75">Profissional:</span>
                <strong class="text-end">
                  {{ selectedProfessional?.name || '-' }}
                </strong>
              </div>

              <div v-if="bookingMode !== 'package'">
                <div class="d-flex justify-content-between">
                  <span class="opacity-75">Data:</span>
                  <strong class="text-end">{{ formatDisplayDate(selectedDate) }}</strong>
                </div>

                <div class="d-flex justify-content-between" v-if="store.salonConfig?.booking_mode !== 'day'">
                  <span class="opacity-75">Hora:</span>
                  <strong class="text-end">{{ selectedTime || '-' }}</strong>
                </div>
              </div>

              <div v-else>
                <div class="d-flex justify-content-between border-top border-secondary-subtle pt-3 mt-1 mb-2">
                  <span class="opacity-75 fw-bold">Sessões Selecionadas ({{ packageAppointments.length }}/{{ selectedPackage?.sessions_total || 1 }}):</span>
                </div>
                <div class="d-flex flex-column gap-2">
                  <div v-for="(appt, index) in packageAppointments" :key="index" class="d-flex justify-content-between align-items-center p-2 rounded" style="background: rgba(100,100,100,0.1);">
                    <span class="small fw-bold">
                      {{ index + 1 }}ª — {{ formatDisplayDate(appt.date) }} <span v-if="store.salonConfig?.booking_mode !== 'day'">às {{ appt.time }}</span>
                    </span>
                    <button class="btn btn-sm text-danger p-0" @click="removePackageSession(index)"><i class="bi bi-x-circle fs-6"></i></button>
                  </div>
                  <div v-if="packageAppointments.length === 0" class="small opacity-50 fst-italic">
                    Nenhuma sessão escolhida ainda. Selecione uma data e horário.
                  </div>
                </div>
              </div>

              <div class="d-flex justify-content-between border-top border-secondary-subtle pt-3 mt-1">
                <span class="opacity-75 pt-1">Total:</span>
                <strong class="fs-5" style="color: var(--button-bg);">
                  R$ {{
                    bookingMode === 'package'
                      ? (selectedPackage ? formatCurrency(selectedPackage.total_price) : '0,00')
                      : (selectedService ? formatCurrency(selectedService.price) : '0,00')
                  }}
                </strong>
              </div>
            </div>


            <div v-if="bookingError" class="alert-inline alert-inline--error mt-3">
              <i class="bi bi-exclamation-circle-fill me-2"></i>{{ bookingError }}
            </div>

            <div v-if="bookingSuccess" class="alert-inline alert-inline--success mt-3">
              <i class="bi bi-check-circle-fill me-2"></i>{{ bookingSuccess }}
            </div>

            <!-- Aviso de Pagamento -->
            <div class="mt-4 p-3 rounded-4 bg-info bg-opacity-10 border border-info border-opacity-25">
              <div class="d-flex align-items-center gap-2 text-info">
                <i class="bi bi-info-circle-fill fs-5"></i>
                <span class="small fw-bold">Informação de Pagamento</span>
              </div>
              <p class="small mb-0 mt-1 opacity-75 dynamic-text">
                <span v-if="bookingMode === 'package'">
                  O pagamento integral do pacote será realizado no estabelecimento durante a sua <strong>primeira sessão</strong>.
                </span>
                <span v-else>
                  O pagamento do serviço será realizado no estabelecimento no dia do atendimento.
                </span>
              </p>
            </div>

            <button
              class="btn custom-btn w-100 rounded-pill fw-bold py-3 mt-4 shadow-sm"
              :disabled="!isFormValid || loadingSubmit"
              @click="confirmarAgendamento"
            >
              <span v-if="loadingSubmit" class="spinner-border spinner-border-sm me-2" role="status"></span>
              {{ loadingSubmit ? 'Confirmando...' : 'Confirmar Agora' }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <footer
      class="mt-5 py-5"
      style="background: var(--glass-bg); backdrop-filter: blur(15px); border-top: 1px solid rgba(0,0,0,0.05); transition: background 0.4s;"
    >
      <div class="container">
        <!-- Primeira fileira: Logo + Informações + Facilidades -->
        <div class="row g-4">
          <div class="col-lg-4 col-md-6">
            <router-link :to="`/empresa/${route.params.slug}`" class="fw-bold fs-4 custom-logo m-0 text-decoration-none d-block text-wrap text-break mb-2">
              {{ store.salonConfig.nome }}
            </router-link>

            <p class="mt-3 dynamic-text" style="max-width: 300px; opacity: 0.8;">
              {{ store.salonConfig.descricao }}
            </p>

            <div class="d-flex gap-3 mt-4">
              <a
                v-if="store.salonConfig.contato.instagram"
                :href="'https://instagram.com/' + store.salonConfig.contato.instagram"
                target="_blank"
                class="btn btn-outline-primary btn-sm rounded-circle custom-icon-btn"
              >
                <i class="bi bi-instagram"></i>
              </a>

              <a
                v-if="store.salonConfig.contato.facebook"
                :href="store.salonConfig.contato.facebook"
                target="_blank"
                class="btn btn-outline-primary btn-sm rounded-circle custom-icon-btn"
              >
                <i class="bi bi-facebook"></i>
              </a>

              <a
                v-if="store.salonConfig.contato.whatsapp"
                :href="'https://wa.me/55' + onlyDigits(store.salonConfig.contato.whatsapp)"
                target="_blank"
                class="btn btn-outline-primary btn-sm rounded-circle custom-icon-btn"
              >
                <i class="bi bi-whatsapp"></i>
              </a>
            </div>
          </div>

          <div class="col-lg-4 col-md-6">
            <h6 class="fw-bold mb-4 dynamic-text">Informações</h6>
            <ul class="list-unstyled d-grid gap-2">
              <li><span class="small dynamic-text" style="opacity: 0.8;"><i class="bi bi-geo-alt-fill me-2 custom-icon"></i>{{ store.salonConfig.contato.endereco }}</span></li>
              <li><span class="small dynamic-text" style="opacity: 0.8;"><i class="bi bi-telephone-fill me-2 custom-icon"></i>{{ store.salonConfig.contato.telefone }}</span></li>
              <li><span class="small dynamic-text" style="opacity: 0.8;"><i class="bi bi-whatsapp me-2 custom-icon"></i>{{ store.salonConfig.contato.whatsapp }}</span></li>
              <li><span class="small dynamic-text" style="opacity: 0.8;"><i class="bi bi-clock-fill me-2 custom-icon"></i>{{ store.salonConfig.funcionamento.horariosTexto }}</span></li>
            </ul>
          </div>

          <div class="col-lg-4 col-md-12">
            <h6 class="fw-bold mb-4 dynamic-text">Facilidades</h6>

            <div class="d-flex flex-wrap gap-2 mb-4">
              <span
                v-for="(amenity, index) in store.salonConfig.facilidades.comodidades"
                :key="index"
                class="badge bg-secondary bg-opacity-10 dynamic-text border border-secondary-subtle"
                style="opacity: 0.8;"
              >
                {{ amenity }}
              </span>
            </div>

            <h6 class="fw-bold mb-3 small dynamic-text">Aceitamos</h6>
            <div class="d-flex gap-3 opacity-75">
              <i v-if="store.salonConfig.facilidades.pagamentos.includes('pix')" class="bi bi-qr-code fs-4 custom-icon" title="Pix"></i>
              <i v-if="store.salonConfig.facilidades.pagamentos.includes('cartao')" class="bi bi-credit-card fs-4 custom-icon" title="Cartão"></i>
              <i v-if="store.salonConfig.facilidades.pagamentos.includes('dinheiro')" class="bi bi-cash fs-4 custom-icon" title="Dinheiro"></i>
            </div>
          </div>
        </div>

        <!-- Segunda fileira: Links Legais -->
        <div class="row mt-4 pt-4 border-top">
          <div class="col-12">
            <div class="d-flex flex-wrap justify-content-center gap-3 gap-lg-4">
              <router-link v-if="legalPages.privacy_policy" :to="`/empresa/${route.params.slug}/privacy_policy`" class="small text-decoration-none dynamic-text" style="opacity: 0.6;">
                <i class="bi bi-shield-lock me-1"></i>Política de Privacidade
              </router-link>
              <router-link v-if="legalPages.terms_of_use" :to="`/empresa/${route.params.slug}/terms_of_use`" class="small text-decoration-none dynamic-text" style="opacity: 0.6;">
                <i class="bi bi-file-earmark-text me-1"></i>Termos de Uso
              </router-link>
              <router-link v-if="legalPages.cookie_policy" :to="`/empresa/${route.params.slug}/cookie_policy`" class="small text-decoration-none dynamic-text" style="opacity: 0.6;">
                <i class="bi bi-cookie me-1"></i>Política de Cookies
              </router-link>
              <router-link v-if="legalPages.about_us" :to="`/empresa/${route.params.slug}/about_us`" class="small text-decoration-none dynamic-text" style="opacity: 0.6;">
                <i class="bi bi-info-circle me-1"></i>Quem Somos
              </router-link>
              <router-link v-if="legalPages.faq" :to="`/empresa/${route.params.slug}/faq`" class="small text-decoration-none dynamic-text" style="opacity: 0.6;">
                <i class="bi bi-question-circle me-1"></i>Perguntas Frequentes
              </router-link>
              <router-link v-if="legalPages.contact_info" :to="`/empresa/${route.params.slug}/contact_info`" class="small text-decoration-none dynamic-text" style="opacity: 0.6;">
                <i class="bi bi-envelope me-1"></i>Contato
              </router-link>
            </div>
          </div>
        </div>

        <hr class="my-4 opacity-10">
        <p class="text-center small mb-0 dynamic-text" style="opacity: 0.7;">
          © 2026 {{ store.salonConfig.nome }} - Todos os direitos reservados. Feito com EasySlotting.
        </p>
      </div>
    </footer>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, nextTick } from 'vue'
import { useThemeStore } from '@/stores/themeStore'
import { useRouter, useRoute } from 'vue-router'
import { api } from '@/services/api'
import { isCustomerLoggedIn, getCustomerData, clearCustomerSession } from '@/services/customerAuth'

const store = useThemeStore()
const router = useRouter()
const route = useRoute()

type ServiceItem = {
  id: number
  name: string
  description?: string
  price: string | number
  duration_minutes: number
}

type ServicePackageItem = {
  id: number
  name: string
  description?: string
  included_items?: string
  sessions_total?: number
  duration_minutes: number
  total_price: number
  service_id?: number | null
  service_name?: string | null
}

type BookingMode = 'service' | 'package'

type EmployeeItem = {
  id: number | string
  name: string
  role_label?: string
  role?: string
}

type EmployeeServiceRelation = {
  employee_id: number
  service_id: number
}

interface DateItem {
  dayNumber: number
  monthName: string
  weekDay: string
  apiDate: string
}

const pageThemeVars = computed(() => ({
  '--logo-color': store.themeConfig.logoColor,
  '--button-bg': store.themeConfig.buttonBg,
  '--button-hover': store.themeConfig.buttonHover,
  '--icon-color': store.themeConfig.iconColor,
  '--custom-font': store.themeConfig.fontFamily,
  '--glass-bg': store.isDarkMode ? store.themeConfig.navbarDark : store.themeConfig.navbarLight,
  '--bs-tertiary-bg': store.isDarkMode ? store.themeConfig.backgroundDark : store.themeConfig.backgroundLight,
  '--card-border': store.isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)',
  '--custom-text-color': store.isDarkMode ? store.themeConfig.textDark : store.themeConfig.textLight,
  fontFamily: store.themeConfig.fontFamily,
  fontSize: store.themeConfig.fontSize,
  backgroundColor: store.isDarkMode ? store.themeConfig.backgroundDark : store.themeConfig.backgroundLight,
  color: store.isDarkMode ? store.themeConfig.textDark : store.themeConfig.textLight
}))

// ─── Modo de agendamento ─────────────────────────────────────────────────────
const bookingMode = ref<BookingMode>('service')

const isAuthenticated = ref(false)
const user = ref<any | null>(null)
const loadingSubmit = ref(false)
const loadingAvailability = ref(false)
const loadingBookingData = ref(false)
const loadingAvailableDays = ref(false)
const loadingPackages = ref(false)
const bookingError = ref('')
const bookingSuccess = ref('')

const dateScrollRef = ref<HTMLElement | null>(null)

const services = ref<ServiceItem[]>([])
const packages = ref<ServicePackageItem[]>([])
const allEmployees = ref<EmployeeItem[]>([])
const employeeServices = ref<EmployeeServiceRelation[]>([])
const profissionais = ref<EmployeeItem[]>([])
const availableTimes = ref<string[]>([])
const occupiedTimes = ref<string[]>([])
const availableDaysFromApi = ref<string[]>([])

const selectedService = ref<ServiceItem | null>(null)
const selectedPackage = ref<ServicePackageItem | null>(null)
const selectedProfessional = ref<EmployeeItem | null>(null)
const selectedDate = ref('')
const selectedTime = ref('')
const packageAppointments = ref<{date: string, time: string}[]>([])

const addPackageSession = () => {
  if (selectedDate.value && (store.salonConfig?.booking_mode === 'day' || selectedTime.value)) {
    packageAppointments.value.push({
      date: selectedDate.value,
      time: store.salonConfig?.booking_mode === 'day' ? '00:00' : selectedTime.value
    })
    selectedDate.value = ''
    selectedTime.value = ''
  }
}

const removePackageSession = (index: number) => {
  packageAppointments.value.splice(index, 1)
}

const currentSlug = computed(() => String(route.params.slug || ''))

const legalPages = computed(() => store.salonConfig?.legal_pages || {})
const availableDates = ref<DateItem[]>([])
const months: string[] = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez']
const weekDays: string[] = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']

const syncAuthState = () => {
  isAuthenticated.value = isCustomerLoggedIn()
  user.value            = getCustomerData()
}

function getApiBaseUrl() {
  return (api.defaults.baseURL || '').replace(/\/api\/?$/, '')
}

function buildFileUrl(path: string) {
  if (!path) return ''
  if (path.startsWith('http://') || path.startsWith('https://')) return path
  return `${getApiBaseUrl()}${path}`
}

function getDefaultAvatarUrl() {
  return `${getApiBaseUrl()}/uploads/establishments/Avatar-Padrao.jpg`
}

function getDefaultBannerUrl() {
  return `${getApiBaseUrl()}/uploads/establishments/Capa-Padrao.jpg`
}

function onlyDigits(value: string) {
  return String(value || '').replace(/\D/g, '')
}

function getTodayString() {
  const now = new Date()
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`
}

function getCurrentTimeHHMM() {
  const now = new Date()
  return `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
}

function isPastTimeForSelectedDate(time: string) {
  if (!selectedDate.value) return false
  if (selectedDate.value !== getTodayString()) return false
  return time < getCurrentTimeHHMM()
}

function canSelectTime(time: string) {
  return !occupiedTimes.value.includes(time) && !isPastTimeForSelectedDate(time)
}


const myAccountRoute = computed<string>(() => {
  return currentSlug.value
    ? `/empresa/${currentSlug.value}/minha-conta`
    : '/empresa/minha-conta'
})

const goToMyAccount = () => {
  router.push(myAccountRoute.value)
}

const allTimesForDisplay = computed<string[]>(() => {
  const unique = [...new Set([...availableTimes.value, ...occupiedTimes.value])]
  return unique.sort((a, b) => a.localeCompare(b))
})

// ─── COMPUTEDS DE MODO DE AGENDAMENTO ────────────────────────────────
// Retorna o service_id ativo independente do modo (avulso ou pacote)
const currentServiceId = computed<number | null>(() => {
  if (bookingMode.value === 'package') {
    return selectedPackage.value?.service_id
      ? Number(selectedPackage.value.service_id)
      : null
  }
  return selectedService.value?.id
    ? Number(selectedService.value.id)
    : null
})

// Verdadeiro se o cliente já escolheu um item válido no passo 2 (serviço ou pacote com serviço)
const hasSelectedBookingItem = computed<boolean>(() => {
  if (bookingMode.value === 'package') {
    return !!selectedPackage.value && !!currentServiceId.value
  }
  return !!selectedService.value
})

const filteredServices = computed<ServiceItem[]>(() => {
  if (!selectedProfessional.value) return services.value
  if (selectedProfessional.value.id === 'any') return services.value

  const proId = Number(selectedProfessional.value.id)
  const serviceIds = employeeServices.value
    .filter((es) => Number(es.employee_id) === proId)
    .map((es) => Number(es.service_id))

  return services.value.filter((s) => serviceIds.includes(Number(s.id)))
})

const filteredPackages = computed<ServicePackageItem[]>(() => {
  if (!selectedProfessional.value) return packages.value
  if (selectedProfessional.value.id === 'any') return packages.value

  const proId = Number(selectedProfessional.value.id)
  const serviceIds = employeeServices.value
    .filter((es) => Number(es.employee_id) === proId)
    .map((es) => Number(es.service_id))

  return packages.value.filter((p) =>
    !p.service_id || serviceIds.includes(Number(p.service_id))
  )
})

const logout = async () => {
  try {
    // Invalida o refresh token no backend
    await api.delete(`/customer_auth/${currentSlug.value}/sign_out`)
  } catch {
    // Ignora erro — limpa local mesmo assim
  }
  clearCustomerSession()
  syncAuthState()
  router.push(currentSlug.value ? `/empresa/${currentSlug.value}` : '/')
}

const formatCurrency = (value: string | number) => {
  const numberValue = Number(value || 0)
  return numberValue.toLocaleString('pt-BR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  })
}

const formatDisplayDate = (date: string) => {
  if (!date) return '-'

  const [year, month, day] = date.split('-')
  if (!year || !month || !day) return date

  return `${day}/${month}/${year}`
}

const scrollList = (elementRef: HTMLElement | null, direction: number) => {
  if (elementRef) {
    elementRef.scrollBy({ left: direction * 200, behavior: 'smooth' })
  }
}

const buildAvailableDates = () => {
  const result: DateItem[] = []

  for (const apiDate of availableDaysFromApi.value) {
    const parts = apiDate.split('-')

    if (parts.length !== 3) continue

    const year = Number(parts[0])
    const month = Number(parts[1])
    const day = Number(parts[2])

    if (
      Number.isNaN(year) ||
      Number.isNaN(month) ||
      Number.isNaN(day)
    ) {
      continue
    }

    const d = new Date(year, month - 1, day)

    result.push({
      dayNumber: d.getDate(),
      monthName: months[d.getMonth()] ?? '',
      weekDay: weekDays[d.getDay()] ?? '',
      apiDate
    })
  }

  availableDates.value = result
}

const goToToday = async () => {
  if (availableDates.value.length > 0) {
    const today = getTodayString()
    const todayExists = availableDates.value.find((d) => d.apiDate === today)
    const firstAvailableDate = availableDates.value[0]

    if (todayExists) {
      selectedDate.value = today
    } else if (firstAvailableDate) {
      selectedDate.value = firstAvailableDate.apiDate
    }
  }

  if (dateScrollRef.value) {
    dateScrollRef.value.scrollTo({ left: 0, behavior: 'smooth' })
  }

  if (selectedDate.value) {
    await fetchAvailability()
  }
}

const formatarEmpresa = (data: any) => {
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
      telefone: data.phone || '',
      whatsapp: data.whatsapp || '',
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
    theme: data.public_settings?.theme || null,
    booking_mode: data.booking_mode || 'time'
  }
}

const fetchPublicEstablishment = async () => {
  const slug = currentSlug.value
  if (!slug) return

  try {
    const { data } = await api.get(`/public/establishments/${slug}`)
    store.setSalonConfig(formatarEmpresa(data))
  } catch (error) {
    console.error('Erro ao buscar estabelecimento público:', error)
  }
}

const fetchBookingData = async () => {
  const slug = currentSlug.value
  if (!slug) return

  loadingBookingData.value = true

  try {
    const { data } = await api.get(`/public/establishments/${slug}/booking_data`)

    services.value = Array.isArray(data.services) ? data.services : []
    allEmployees.value = Array.isArray(data.employees) ? data.employees : []
    employeeServices.value = Array.isArray(data.employee_services) ? data.employee_services : []
  } catch (error) {
    console.error('Erro ao buscar booking_data:', error)
    services.value = []
    allEmployees.value = []
    employeeServices.value = []
  } finally {
    loadingBookingData.value = false
  }
}

const fetchAllProfessionals = async () => {
  if (allEmployees.value.length === 0) {
    await fetchBookingData()
  }

  if (allEmployees.value.length > 0) {
    profissionais.value = [
      { id: 'any', name: 'Qualquer profissional', role_label: 'Disponível' },
      ...allEmployees.value
    ]
  } else {
    profissionais.value = []
  }
}

const fetchAvailableDays = async () => {
  if (!currentServiceId.value || !selectedProfessional.value) {
    availableDaysFromApi.value = []
    availableDates.value = []
    return
  }

  const slug = currentSlug.value
  if (!slug) return

  loadingAvailableDays.value = true

  try {
    const { data } = await api.get(`/public/establishments/${slug}/available_days`, {
      params: {
        service_id: currentServiceId.value,
        employee_id: selectedProfessional.value.id,
        days_ahead: 30
      }
    })

    availableDaysFromApi.value = Array.isArray(data.available_days)
      ? data.available_days.map((item: any) => item.date)
      : []

    buildAvailableDates()
  } catch (error) {
    console.error('Erro ao buscar dias disponíveis:', error)
    availableDaysFromApi.value = []
    availableDates.value = []
  } finally {
    loadingAvailableDays.value = false
  }
}

const fetchAvailability = async () => {
  if (!currentServiceId.value || !selectedProfessional.value || !selectedDate.value) {
    availableTimes.value = []
    occupiedTimes.value = []
    return
  }

  const slug = currentSlug.value
  if (!slug) return

  loadingAvailability.value = true

  try {
    const { data } = await api.get(`/public/establishments/${slug}/available_slots`, {
      params: {
        service_id: currentServiceId.value,
        employee_id: selectedProfessional.value.id,
        date: selectedDate.value
      }
    })

    availableTimes.value = Array.isArray(data.available_slots) ? data.available_slots : []
    occupiedTimes.value = Array.isArray(data.occupied_slots) ? data.occupied_slots : []
  } catch (error) {
    console.error('Erro ao buscar disponibilidade:', error)
    availableTimes.value = []
    occupiedTimes.value = []
  } finally {
    loadingAvailability.value = false
  }
}

const selectService = async (service: ServiceItem) => {
  selectedService.value = service
  selectedDate.value = ''
  selectedTime.value = ''
  availableTimes.value = []
  occupiedTimes.value = []
  availableDaysFromApi.value = []
  availableDates.value = []

  await fetchAvailableDays()

  if (availableDates.value.length > 0) {
    const today = getTodayString()
    const todayExists = availableDates.value.find((d) => d.apiDate === today)
    const firstAvailableDate = availableDates.value[0]

    if (todayExists) {
      selectedDate.value = today
    } else if (firstAvailableDate) {
      selectedDate.value = firstAvailableDate.apiDate
    }

    if (selectedDate.value) {
      await fetchAvailability()
    }
  }

  nextTick(() => {
    const el = document.getElementById('secao-data') || document.getElementById('secao-horario')
    el?.scrollIntoView({ behavior: 'smooth', block: 'center' })
  })
}

// ─── PACOTES ───────────────────────────────────────────────────────────
const fetchPackages = async () => {
  const slug = currentSlug.value
  if (!slug) return

  loadingPackages.value = true
  try {
    const { data } = await api.get(`/public/establishments/${slug}/service_packages`)
    packages.value = Array.isArray(data) ? data : []
  } catch (error) {
    console.error('Erro ao buscar pacotes:', error)
    packages.value = []
  } finally {
    loadingPackages.value = false
  }
}

const selectPackage = async (pkg: ServicePackageItem) => {
  bookingError.value = ''

  if (packageAppointments.value.length > 0) {
    bookingError.value = 'Remova as sessões selecionadas se desejar trocar de pacote.'
    return
  }

  if (!pkg.service_id) {
    bookingError.value = 'Este pacote ainda não foi vinculado a um serviço no painel administrativo. Por favor, entre em contato com o estabelecimento.'
    selectedPackage.value = pkg
    return
  }

  selectedPackage.value = pkg
  selectedDate.value = ''
  selectedTime.value = ''
  availableTimes.value = []
  occupiedTimes.value = []
  availableDaysFromApi.value = []
  availableDates.value = []

  await fetchAvailableDays()

  if (availableDates.value.length > 0) {
    const today = getTodayString()
    const todayExists = availableDates.value.find((d) => d.apiDate === today)
    const firstAvailableDate = availableDates.value[0]

    if (todayExists) {
      selectedDate.value = today
    } else if (firstAvailableDate) {
      selectedDate.value = firstAvailableDate.apiDate
    }

    if (selectedDate.value) {
      await fetchAvailability()
    }
  }

  nextTick(() => {
    document.getElementById('secao-data')?.scrollIntoView({ behavior: 'smooth', block: 'center' })
  })
}

const setBookingMode = (mode: BookingMode) => {
  if (bookingMode.value === mode) return

  bookingMode.value = mode

  selectedService.value = null
  selectedPackage.value = null
  selectedProfessional.value = null
  selectedDate.value = ''
  selectedTime.value = ''
  availableTimes.value = []
  occupiedTimes.value = []
  availableDaysFromApi.value = []
  availableDates.value = []
  profissionais.value = []

  fetchAllProfessionals()

  if (mode === 'package' && packages.value.length === 0) {
    fetchPackages()
  }
}

const selectProfessional = async (professional: EmployeeItem, shouldScroll = true) => {
  if (bookingMode.value === 'package' && packageAppointments.value.length > 0) {
    bookingError.value = 'Remova as sessões selecionadas se desejar trocar de profissional.'
    return
  }

  selectedProfessional.value = professional
  selectedService.value = null
  selectedPackage.value = null
  selectedDate.value = ''
  selectedTime.value = ''
  availableTimes.value = []
  occupiedTimes.value = []
  availableDaysFromApi.value = []
  availableDates.value = []

  if (shouldScroll) {
    nextTick(() => {
      document.getElementById('secao-servicos')?.scrollIntoView({ behavior: 'smooth', block: 'center' })
    })
  }
}

const getSundayOfDate = (dateStr: string) => {
  const d = new Date(dateStr + 'T12:00:00')
  const diff = d.getDate() - d.getDay()
  const sunday = new Date(d.setDate(diff))
  return `${sunday.getFullYear()}-${String(sunday.getMonth() + 1).padStart(2, '0')}-${String(sunday.getDate()).padStart(2, '0')}`
}

const occupiedWeeks = computed<Set<string>>(() => {
  if (bookingMode.value === 'package' && packageAppointments.value.length > 0) {
    return new Set(packageAppointments.value.map(appt => getSundayOfDate(appt.date)))
  }
  return new Set()
})

const minDateForNextSession = computed(() => {
  if (bookingMode.value === 'package' && packageAppointments.value.length > 0) {
    const lastSession = packageAppointments.value[packageAppointments.value.length - 1]
    return lastSession?.date || ''
  }
  return ''
})

const selectDate = async (date: string) => {
  if (bookingMode.value === 'package' && packageAppointments.value.length > 0) {
    const newSunday = getSundayOfDate(date)
    const hasSameWeek = packageAppointments.value.some(appt => getSundayOfDate(appt.date) === newSunday)
    
    if (hasSameWeek) {
      bookingError.value = 'Você já selecionou uma sessão para esta semana. O pacote permite apenas uma sessão por semana.'
      
      // Auto-hide error after 4 seconds
      setTimeout(() => {
        if (bookingError.value.includes('sessão por semana')) {
          bookingError.value = ''
        }
      }, 4000)
      return
    }
  }

  bookingError.value = ''
  selectedDate.value = date
  selectedTime.value = ''
  await fetchAvailability()
  
  nextTick(() => {
    document.getElementById('secao-horario')?.scrollIntoView({ behavior: 'smooth', block: 'center' })
  })
}

const confirmarAgendamento = async () => {
  bookingError.value = ''
  bookingSuccess.value = ''

  if (!isAuthenticated.value) {
    router.push({
      path: `/empresa/${currentSlug.value}/login`,
      query: { redirect: route.fullPath }
    })
    return
  }

  if (!hasSelectedBookingItem.value || !currentServiceId.value) {
    bookingError.value = 'Selecione um serviço ou pacote para continuar.'
    return
  }

  if (!selectedProfessional.value) return

  const isDayMode = store.salonConfig?.booking_mode === 'day'

  if (bookingMode.value !== 'package') {
    if (!selectedDate.value) return
    if (!isDayMode) {
      if (!selectedTime.value) return
      if (!canSelectTime(selectedTime.value)) {
        bookingError.value = 'Esse horário não está mais disponível. Escolha outro horário.'
        return
      }
    }
  }

  loadingSubmit.value = true

  try {
    let employeeId = selectedProfessional.value.id
    if (employeeId === 'any') {
      employeeId = 0
    }

    const isDayMode = store.salonConfig?.booking_mode === 'day'

    const basePayload: Record<string, any> = {
      service_id:       currentServiceId.value,
      employee_id:      employeeId
    }

    let payload: any = {}
    if (bookingMode.value === 'package' && selectedPackage.value) {
      basePayload.service_package_id = selectedPackage.value.id
      payload = {
        appointment: basePayload,
        appointments: packageAppointments.value.map(appt => ({
          appointment_date: appt.date,
          start_time: appt.time
        }))
      }
    } else {
      basePayload.appointment_date = selectedDate.value
      basePayload.start_time       = isDayMode ? '00:00' : selectedTime.value
      payload = { appointment: basePayload }
    }

    const response = await api.post('/customer/appointments', payload)

    // ─── Redirecionamento baseado no tipo de agendamento ───
    // A API retorna { appointment_id, type: 'plan' | 'single' }
    const appointmentType = response.data?.type

    bookingSuccess.value = 'Agendamento realizado com sucesso! Redirecionando...'

    // Aguarda 1.2s para o usuário ver a mensagem de sucesso antes de redirecionar
    await new Promise((resolve) => setTimeout(resolve, 1200))

    if (appointmentType === 'plan') {
      router.push(`/empresa/${currentSlug.value}/meus-pacotes`)
    } else {
      router.push(`/empresa/${currentSlug.value}/meus-agendamentos`)
    }
  } catch (error: any) {
    bookingError.value =
      error?.response?.data?.errors?.join(', ') ||
      error?.response?.data?.error ||
      'Não foi possível concluir o agendamento.'
  } finally {
    loadingSubmit.value = false
  }
}

watch(() => route.params.slug, async () => {
  selectedService.value = null
  selectedPackage.value  = null
  selectedProfessional.value = null
  selectedDate.value = ''
  selectedTime.value = ''
  bookingMode.value  = 'service'
  services.value = []
  packages.value = []
  allEmployees.value = []
  employeeServices.value = []
  profissionais.value = []
  availableTimes.value = []
  occupiedTimes.value = []
  availableDaysFromApi.value = []
  availableDates.value = []
  packageAppointments.value = []

  syncAuthState()
  await fetchPublicEstablishment()
  await fetchBookingData()
  await fetchAllProfessionals()
})

onMounted(async () => {
  syncAuthState()
  window.scrollTo(0, 0)

  await fetchPublicEstablishment()
  await fetchBookingData()
  await fetchAllProfessionals()

  const navContent = document.getElementById('navContent')
  if (navContent) {
    navContent.addEventListener('shown.bs.collapse', () => {
      document.body.style.overflow = 'hidden'
    })
    navContent.addEventListener('hidden.bs.collapse', () => {
      document.body.style.overflow = ''
    })
  }
})

const isFormValid = computed<boolean>(() => {
  const isDayMode = store.salonConfig?.booking_mode === 'day'
  
  if (bookingMode.value === 'package' && selectedPackage.value) {
    const requiredSessions = selectedPackage.value.sessions_total || 1
    return packageAppointments.value.length === requiredSessions
  }
  
  return !!(
    hasSelectedBookingItem.value &&
    currentServiceId.value &&
    selectedProfessional.value &&
    selectedDate.value &&
    (isDayMode || selectedTime.value)
  )
})

const canAddMoreSessions = computed<boolean>(() => {
  if (bookingMode.value !== 'package' || !selectedPackage.value) return false
  const limit = selectedPackage.value.sessions_total || 1
  return packageAppointments.value.length < limit
})
</script>

<style scoped>
.custom-logo {
  color: var(--logo-color) !important;
  transition: color 0.3s;
}

.custom-icon {
  color: var(--icon-color) !important;
  transition: color 0.3s;
}

.dynamic-text {
  color: var(--custom-text-color) !important;
  transition: color 0.3s;
}

.custom-btn {
  background-color: var(--button-bg) !important;
  border-color: var(--button-bg) !important;
  color: #fff !important;
  transition: background-color 0.3s, border-color 0.3s;
}

.custom-btn:hover {
  background-color: var(--button-hover) !important;
  border-color: var(--button-hover) !important;
}

.custom-outline-btn {
  color: var(--button-bg) !important;
  border-color: var(--button-bg) !important;
  background-color: transparent !important;
  transition: background-color 0.3s, color 0.3s, border-color 0.3s;
}

.custom-outline-btn:hover {
  background-color: var(--button-hover) !important;
  border-color: var(--button-hover) !important;
  color: #fff !important;
}

.custom-icon-btn {
  color: var(--icon-color) !important;
  border-color: var(--icon-color) !important;
  transition: all 0.3s;
}

.custom-icon-btn:hover {
  background-color: var(--icon-color) !important;
  color: #fff !important;
}

[data-bs-theme="light"] { --card-border: rgba(0,0,0,0.08); }
[data-bs-theme="dark"] { --card-border: rgba(255,255,255,0.1); }

/* Alertas inline no card de resumo */
.alert-inline {
  border-radius: 12px;
  padding: 10px 14px;
  font-size: 0.83rem;
  font-weight: 600;
  display: flex;
  align-items: center;
}

.alert-inline--error {
  background: rgba(220, 53, 69, 0.1);
  border: 1px solid rgba(220, 53, 69, 0.25);
  color: #dc3545;
}

[data-bs-theme="dark"] .alert-inline--error {
  background: rgba(220, 53, 69, 0.15);
  color: #f88;
}

.alert-inline--success {
  background: rgba(25, 135, 84, 0.1);
  border: 1px solid rgba(25, 135, 84, 0.25);
  color: #198754;
}

[data-bs-theme="dark"] .alert-inline--success {
  background: rgba(25, 135, 84, 0.15);
  color: #6fcf97;
}


.navbar {
  backdrop-filter: blur(15px);
  background: var(--glass-bg);
  padding: 12px 0;
  border-bottom: 1px solid var(--card-border);
  transition: background 0.4s;
}

.theme-switch {
  width: 55px;
  height: 30px;
  background: var(--bs-tertiary-bg);
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

#darkToggle:checked + .theme-switch .ball {
  transform: translateX(25px);
}

.profile-cover {
  position: relative;
  height: 600px;
  border-radius: 0 0 40px 40px;
  overflow: hidden;
  background-size: cover;
  background-position: center center;
  background-repeat: no-repeat;
}

.profile-cover::after {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: 0 0 40px 40px;
  background: linear-gradient(to bottom, rgba(0,0,0,0.1), rgba(0,0,0,0.1));
}

@media (max-width: 768px) {
  .profile-cover {
    height: 280px;
  }
}

.profile-avatar {
  width: 110px;
  height: 110px;
  border-radius: 22px;
  margin-top: -55px;
}

.service-selection-card {
  border: 1px solid var(--card-border);
  border-radius: 20px;
  background: var(--bs-tertiary-bg);
  cursor: pointer;
  transition: all 0.3s ease;
  position: relative;
}

.service-selection-card:hover {
  border-color: var(--button-bg) !important;
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.08) !important;
}

.service-selection-card.selected {
  border: 2px solid var(--button-bg) !important;
  background: color-mix(in srgb, var(--button-bg) 8%, transparent);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.1) !important;
}

.icon-box-dynamic {
  background: color-mix(in srgb, var(--icon-color) 12%, transparent);
  color: var(--icon-color);
}

.scroll-arrow {
  width: 40px;
  height: 40px;
  background: var(--glass-bg) !important;
  border: 1px solid var(--card-border) !important;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--icon-color) !important;
  padding: 0;
  transition: background-color 0.2s, color 0.2s;
}

.scroll-arrow:hover {
  background: var(--button-bg) !important;
  color: white !important;
}

@media (max-width: 768px) {
  .scroll-arrow {
    display: none !important;
  }
}

.colab-container {
  display: flex;
  gap: 15px;
  overflow-x: auto;
  padding: 10px 0;
  scrollbar-width: none;
}

.colab-container::-webkit-scrollbar {
  display: none;
}

.colab-select-card {
  min-width: 130px;
  padding: 15px 10px;
  border-radius: 18px;
  border: 1px solid var(--card-border);
  background: var(--bs-tertiary-bg);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s;
  text-align: center;
}

.colab-select-card.active {
  background: var(--button-bg);
  border-color: var(--button-bg);
}

.colab-select-card.active .colab-text {
  color: white !important;
  opacity: 1 !important;
}

.avatar-placeholder {
  width: 50px;
  height: 50px;
  border-radius: 50%;
  background: color-mix(in srgb, var(--icon-color) 10%, transparent);
  color: var(--icon-color);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 10px;
  transition: 0.2s;
}

.colab-select-card.active .avatar-placeholder {
  background: white;
  color: var(--button-bg);
}

.date-container {
  display: flex;
  gap: 12px;
  overflow-x: auto;
  padding: 5px 0;
  scrollbar-width: none;
  scroll-snap-type: x mandatory;
  scroll-behavior: smooth;
}

.date-container::-webkit-scrollbar {
  display: none;
}

.date-card {
  min-width: 78px;
  height: 90px;
  border-radius: 16px;
  border: 1px solid var(--card-border);
  background: var(--bs-tertiary-bg);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background-color 0.2s, border-color 0.2s;
  scroll-snap-align: start;
}

.date-card:hover {
  border-color: var(--button-bg);
}

.date-card.active {
  background: var(--button-bg);
  border-color: var(--button-bg);
}

.date-card.active .date-text {
  color: white !important;
  opacity: 1 !important;
}

.hours-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(85px, 1fr));
  gap: 12px;
}

.hour-item {
  padding: 12px 5px;
  border-radius: 12px;
  border: 1px solid var(--card-border);
  background: var(--bs-tertiary-bg);
  text-align: center;
  font-weight: 700;
  font-size: 0.95rem;
  cursor: pointer;
  transition: all 0.2s;
}

.hour-item.active {
  background: var(--button-bg);
  color: white !important;
  border-color: var(--button-bg);
}

.hour-item.occupied {
  background: #2f2f2f !important;
  color: #9a9a9a !important;
  border-color: #4a4a4a !important;
  cursor: not-allowed;
  opacity: 0.75;
}

.hour-item.occupied:hover {
  transform: none !important;
  background: #2f2f2f !important;
  color: #9a9a9a !important;
  border-color: #4a4a4a !important;
}

.hour-item.past {
  background: #4b4b4b !important;
  color: #b5b5b5 !important;
  border-color: #5d5d5d !important;
  cursor: not-allowed;
  opacity: 0.65;
}

.hour-item.past:hover {
  transform: none !important;
  background: #4b4b4b !important;
  color: #b5b5b5 !important;
  border-color: #5d5d5d !important;
}

[data-bs-theme="light"] .hour-item.occupied {
  background: #dcdcdc !important;
  color: #7a7a7a !important;
  border-color: #c4c4c4 !important;
}

[data-bs-theme="light"] .hour-item.occupied:hover {
  background: #dcdcdc !important;
  color: #7a7a7a !important;
  border-color: #c4c4c4 !important;
}

[data-bs-theme="light"] .hour-item.past {
  background: #e7e7e7 !important;
  color: #9a9a9a !important;
  border-color: #d3d3d3 !important;
}

[data-bs-theme="light"] .hour-item.past:hover {
  background: #e7e7e7 !important;
  color: #9a9a9a !important;
  border-color: #d3d3d3 !important;
}

.transition-all {
  transition: all 0.3s ease;
}

.hover-opacity-100:hover {
  opacity: 1 !important;
}

/* ─── Toggle Modo de Agendamento ───────────────────────────────── */
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

[data-bs-theme='dark'] .mode-btn:hover:not(.active) {
  background: rgba(255, 255, 255, 0.07);
}

@media (max-width: 480px) {
  .booking-mode-toggle {
    width: 100%;
  }
  .mode-btn {
    padding: 10px 14px;
    font-size: 0.8rem;
  }
}

</style>