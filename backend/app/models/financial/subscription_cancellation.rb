class SubscriptionCancellation < ApplicationRecord
  belongs_to :subscription

  before_validation :sanitize_data

  REASONS = [
    "preco_muito_alto",
    "nao_estou_usando",
    "encontrei_outra_plataforma",
    "faltam_funcionalidades",
    "dificuldade_de_uso",
    "atendimento_suporte",
    "problema_tecnico",
    "outro"
  ].freeze

  CANCELED_BY_ROLES = %w[owner super_admin].freeze

  validates :reason, inclusion: { in: REASONS }
  validates :canceled_by_role, inclusion: { in: CANCELED_BY_ROLES }
  validates :details, length: { maximum: 500 }, allow_blank: true

  private

  def sanitize_data
    self.details = ActionView::Base.full_sanitizer.sanitize(details).to_s.strip if details.present?
  end
end