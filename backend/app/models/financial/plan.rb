class Plan < ApplicationRecord
  has_many :subscriptions, dependent: :restrict_with_exception

  before_validation :sanitize_data
  before_validation :lock_catalog_validation, prepend: true

  scope :in_catalog_order, -> { order(:price, :id) }

  # Campos de texto — limites de comprimento e formato
  validates :name,
            presence: true,
            length: { minimum: 2, maximum: 100 }

  validates :code,
            presence: true,
            uniqueness: true,
            length: { maximum: 50 },
            format: {
              with: /\A[a-z0-9_\-]+\z/,
              message: "deve conter apenas letras minúsculas, números, hífens e underscores"
            }

  validates :description,
            length: { maximum: 500 },
            allow_blank: true

  # Campos numéricos — limites de valor
  validates :price,
            presence: true,
            numericality: { greater_than: 0, less_than: 100_000 }

  validates :duration_months,
            presence: true,
            numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 24 }

  validates :discount_percentage,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true

  validates :promotional_price,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true

  validates :promotion_duration_days,
            numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 365 },
            allow_nil: true

  validates :max_employees,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true

  validates :max_services,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true

  validates :max_appointments_per_month,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true

  validates :max_owner_sessions,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 4 }
  validates :max_owner_sessions,
            uniqueness: {
              conditions: -> { where(active: true) },
              message: 'já está em uso por outro plano ativo. Escolha um limite disponível de 1 a 4.'
            }, if: :active?

  validate :code_immutable_if_subscribed, on: :update
  validate :promotional_price_must_be_less_than_regular_price
  validate :catalog_must_increase_in_creation_order

  before_validation :calculate_promotion_end_date
  before_validation :calculate_discount_percentage
  before_validation :calculate_promotional_price

  def promotion_running?
    return false unless promotion_active?

    now = Time.current
    promotion_starts_at.present? &&
      promotion_ends_at.present? &&
      now >= promotion_starts_at &&
      now <= promotion_ends_at
  end

  def current_price
    promotion_running? && promotional_price.present? ? promotional_price : price
  end

  private

  def lock_catalog_validation
    # Save já mantém a transação até a gravação final. Com valid? isolado,
    # o lock termina na própria consulta e não reserva uma futura gravação.
    # Funciona mesmo com catálogo vazio e serializa os saves entre processos.
    self.class.connection.execute('SELECT pg_advisory_xact_lock(1163086932, 1347174734)')
    if persisted?
      # O controller pode ter lido esta linha antes de outro editor terminar.
      # Atualiza campos não editados sem converter entradas inválidas (ex.: 2.5).
      pending_names = attribute_names.select do |name|
        public_send("#{name}_came_from_user?") || will_save_change_to_attribute?(name)
      end
      pending_attributes = attributes_before_type_cast.slice(*pending_names)
      reload
      assign_attributes(pending_attributes)
    end
  end

  def catalog_must_increase_in_creation_order
    return unless active? && errors[:price].empty? && errors[:max_owner_sessions].empty?

    others = self.class.where(active: true).where.not(id: id)
    # IDs são atribuídos pelo banco: o payload não escolhe a posição do plano.
    previous_plans = persisted? ? others.where('id < ?', id) : others
    following_plans = persisted? ? others.where('id > ?', id) : others.none
    if previous_plans.where('price >= ?', price).exists?
      errors.add(:price, 'deve ser maior que o preço normal dos planos ativos cadastrados antes deste.')
    end
    if following_plans.where('price <= ?', price).exists?
      errors.add(:price, 'deve ser menor que o preço normal dos planos ativos cadastrados depois deste.')
    end
    if previous_plans.where('max_owner_sessions >= ?', max_owner_sessions).exists?
      errors.add(:max_owner_sessions, 'deve ser maior que a quantidade dos planos ativos cadastrados antes deste.')
    end
    if following_plans.where('max_owner_sessions <= ?', max_owner_sessions).exists?
      errors.add(:max_owner_sessions, 'deve ser menor que a quantidade dos planos ativos cadastrados depois deste.')
    end
  end

  def code_immutable_if_subscribed
    if code_changed? && subscriptions.exists?
      errors.add(:code, "não pode ser alterado pois já existem assinaturas vinculadas a este plano")
    end
  end

  def promotional_price_must_be_less_than_regular_price
    return unless promotion_active? && promotional_price.present? && price.present?

    if promotional_price.to_f >= price.to_f
      errors.add(:promotional_price, "deve ser estritamente menor que o preço normal do plano")
    end
  end

  def sanitize_data
    self.name = ActionView::Base.full_sanitizer.sanitize(name).to_s.strip if name.present?
    # code: força minúsculas e remove espaços — sem tags HTML permitidas
    self.code = code.to_s.downcase.strip if code.present?
    self.description = ActionView::Base.full_sanitizer.sanitize(description).to_s.strip if description.present?
  end

  def calculate_promotion_end_date
    return unless promotion_starts_at.present? && promotion_duration_days.present?

    self.promotion_ends_at = promotion_starts_at + promotion_duration_days.days
  end

  def calculate_discount_percentage
    return unless price.present? && promotional_price.present? && price.to_f > 0

    self.discount_percentage = (((price - promotional_price) / price) * 100).round
  end

  def calculate_promotional_price
    return unless price.present? && discount_percentage.present? && promotional_price.blank?

    self.promotional_price = price - (price * discount_percentage / 100.0)
  end
end
