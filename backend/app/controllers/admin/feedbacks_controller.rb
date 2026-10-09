# app/controllers/admin/feedbacks_controller.rb
# Lista os feedbacks (avaliações anônimas de customers) do estabelecimento do owner logado.
# Permite ao administrador selecionar quais quer exibir como depoimentos na Home.

class Admin::FeedbacksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_establishment
  before_action :require_employee_or_owner!
  # 🔒 SEGURANÇA: Apenas quem pode gerenciar o estabelecimento visualiza os feedbacks (depoimentos)
  before_action :require_establishment_management!

  # GET /api/admin/feedbacks
  def index
    feedbacks = AppointmentFeedback
                  .joins(appointment: :establishment)
                  .includes(appointment: [:service, :customer])
                  .where(appointments: { establishment_id: @establishment.id })
                  .where.not(comment: [nil, ''])
                  .order(created_at: :desc)
                  .limit(100)

    render json: feedbacks.map { |fb| serialize(fb) }
  end

  private

  def serialize(fb)
    appt     = fb.appointment
    customer = appt.customer
    service  = appt.service

    {
      id:         fb.id,
      rating:     fb.rating,
      comment:    fb.comment,
      created_at: fb.created_at.strftime('%d/%m/%Y'),
      # Dados exibidos anonimamente — só iniciais do nome
      nome:       anonimizar_nome(customer&.name),
      servico:    service&.name || appt.service_name_snapshot,
      foto:       avatar_url(customer),
      texto:      fb.comment,
      data:       fb.created_at.strftime('%d/%m/%Y')
    }
  end

  # Mantém apenas o primeiro nome para preservar anonimato
  def anonimizar_nome(nome)
    return 'Cliente' if nome.blank?
    partes = nome.strip.split(' ')
    partes.length > 1 ? "#{partes.first} #{partes.last[0]}." : partes.first
  end

  def avatar_url(customer)
    if customer&.image.present?
      # Retorna a foto do perfil do cliente se existir
      customer.image.start_with?('http') ? customer.image : "#{ENV.fetch('API_URL', '')}#{customer.image}"
    else
      # Fallback para o avatar genérico caso o cliente não tenha foto
      "https://ui-avatars.com/api/?name=#{URI.encode_www_form_component(anonimizar_nome(customer&.name))}&background=random&size=80"
    end
  end
end
