class EstablishmentMembership < ApplicationRecord
  belongs_to :user
  belongs_to :establishment

  has_many :commissions, foreign_key: :membership_id, dependent: :nullify
  has_many :commission_closings, foreign_key: :membership_id, dependent: :nullify

  before_validation :sanitize_data

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :establishment_id }
  validates :specialty, length: { minimum: 2, maximum: 80 }, allow_blank: true
  validates :pix_key, length: { maximum: 150 }, allow_blank: true
  validates :financial_value, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999999 }, allow_nil: true
  validates :commission_bonus_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :tipo_vinculo, inclusion: { in: %w[clt mei pj autonomo parceiro] }, allow_blank: true

  validates :financial_model,
            inclusion: { in: %w[porcentagem fixo_servico diaria] },
            allow_blank: true

  validate :validate_financial_limits
  validate :validate_pix_key_format

  # Allowlist de formatos de chave PIX suportados pelo Banco Central (LGPD - validacao de input)
  PIX_KEY_REGEX = /\A(
    \d{11}                                                               |
    \d{14}                                                               |
    [^\s@]+@[^\s@]+\.[^\s@]+                                             |
    (\+?55)?\d{10,11}                                                    |
    [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
  )\z/xi

  private

  def sanitize_data
    if specialty.present?
      # Remove tags HTML e caracteres de controle sem converter entidades legitimas
      self.specialty = ActionView::Base.full_sanitizer.sanitize(specialty).to_s
                                       .gsub(/[\x00-\x1f\x7f]/, '').strip
    end
    if pix_key.present?
      self.pix_key = ActionView::Base.full_sanitizer.sanitize(pix_key).to_s
                                     .gsub(/[\x00-\x1f\x7f]/, '').strip
    end
  end

  def validate_financial_limits
    return unless financial_model == 'porcentagem' && financial_value.present?

    if financial_value < 0 || financial_value > 100
      errors.add(:financial_value, "para comissao deve ser entre 0% e 100%")
    end
  end

  def validate_pix_key_format
    return if pix_key.blank?

    unless PIX_KEY_REGEX.match?(pix_key.strip)
      errors.add(:pix_key, 'deve ser um CPF, CNPJ, e-mail, telefone ou chave aleatoria (UUID) validos')
    end
  end
end