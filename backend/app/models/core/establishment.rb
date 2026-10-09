class Establishment < ApplicationRecord
  before_validation :sanitize_data

  belongs_to :owner, class_name: 'User'

  has_one :address, dependent: :destroy
  has_many :business_hours, dependent: :destroy
  has_many :services, dependent: :destroy
  has_many :service_packages, dependent: :destroy
  has_many :stock_items, dependent: :destroy
  has_many :appointments, dependent: :destroy

  # Customers são isolados por estabelecimento (tabela própria)
  has_many :customers, dependent: :destroy

  has_many :establishment_memberships, dependent: :destroy
  has_many :users, through: :establishment_memberships

  has_many :subscriptions, dependent: :destroy
  has_one :current_subscription,
          -> { where(status: 'active').order(created_at: :desc) },
          class_name: 'Subscription'

  has_many :financial_transactions, dependent: :destroy
  has_many :commissions, dependent: :destroy
  has_many :commission_closings, dependent: :destroy
  has_many :service_package_sales, dependent: :destroy
  has_many :archived_employees, dependent: :destroy
  has_many :notifications, dependent: :destroy

  accepts_nested_attributes_for :address, update_only: true

  # Allowlist de categorias (5b — validação de input)
  ALLOWED_CATEGORIES = %w[Barbearia Salão Estética Clínica Outro].freeze

  # Allowlist de páginas legais e formatação segura de HTML (5.1 — proteção contra Stored XSS)
  ALLOWED_LEGAL_PAGES = %w[
    privacy_policy terms_of_use cookie_policy about_us faq contact_info
  ].freeze

  LEGAL_PAGE_ALLOWED_TAGS = %w[
    h1 h2 h3 h4 h5 h6 p br ul ol li strong em b i u s strike
    a span div blockquote table thead tbody tr th td hr mark
  ].freeze

  LEGAL_PAGE_ALLOWED_ATTRIBUTES = %w[href class target rel title].freeze
  LEGAL_PAGE_MAX_LENGTH = 100_000

  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true, uniqueness: true
  validates :booking_mode, inclusion: { in: %w[time day] }, allow_nil: true
  validates :description, length: { maximum: 500 }, allow_blank: true
  validates :phone, length: { maximum: 15 }, allow_blank: true
  validates :whatsapp, length: { maximum: 15 }, allow_blank: true
  validates :instagram, length: { maximum: 50 }, allow_blank: true
  validates :facebook, length: { maximum: 150 }, allow_blank: true
  validate :validate_facebook_url
  validate :validate_public_settings
  validates :instagram, format: { with: /\A[a-zA-Z0-9._]+\z/ }, allow_blank: true

  # (5b) Categoria deve pertencer à allowlist
  validates :category,
            inclusion: { in: ALLOWED_CATEGORIES, message: 'categoria inválida' },
            allow_blank: true

  # (5a) CNPJ: 14 dígitos numéricos + dígitos verificadores
  validates :cnpj,
            format: { with: /\A\d{14}\z/, message: 'deve conter 14 dígitos numéricos' },
            allow_blank: true
  validate :validate_cnpj_digits, if: -> { cnpj.present? }

  def active_subscription?
    current_subscription.present? && current_subscription.end_date >= Date.current
  end

  def subscribed_plan
    current_subscription&.plan
  end

  # Mascara CNPJ para exibição (ex: 12.345.678/0001-**)
  def cnpj_masked
    return nil if cnpj.blank?
    digits = cnpj.gsub(/\D/, '')
    "#{digits[0..1]}.#{digits[2..4]}.#{digits[5..7]}/#{digits[8..11]}-**"
  end

  def as_json(options = {})
    super(options.merge(except: [:cnpj]))
  end

  private

  def validate_facebook_url
    return if facebook.blank?

    uri = URI.parse(facebook)
    unless %w[http https].include?(uri.scheme) && uri.host.present? && uri.userinfo.nil?
      errors.add(:facebook, 'deve ser uma URL HTTP ou HTTPS válida')
    end
  rescue URI::InvalidURIError
    errors.add(:facebook, 'deve ser uma URL HTTP ou HTTPS válida')
  end

  def validate_public_settings
    unless public_settings.nil? || public_settings.is_a?(Hash)
      errors.add(:public_settings, 'deve ser um objeto')
      return
    end
    if public_settings.is_a?(Hash)
      hours = public_settings['horarios_texto']
      if !hours.nil? && (!hours.is_a?(String) || hours.length > 100)
        errors.add(:public_settings, 'horário deve conter até 100 caracteres')
      end
    end
  end

  def sanitize_data
    self.name        = ActionView::Base.full_sanitizer.sanitize(name).to_s.strip        if name.present?
    self.description = ActionView::Base.full_sanitizer.sanitize(description).to_s.strip if description.present?
    self.phone       = ActionView::Base.full_sanitizer.sanitize(phone).to_s.strip       if phone.present?
    self.whatsapp    = ActionView::Base.full_sanitizer.sanitize(whatsapp).to_s.strip    if whatsapp.present?
    self.instagram   = ActionView::Base.full_sanitizer.sanitize(instagram).to_s.strip   if instagram.present?
    self.facebook    = ActionView::Base.full_sanitizer.sanitize(facebook).to_s.strip    if facebook.present?
    # Normaliza category para o formato correto da allowlist (case-insensitive)
    if category.present?
      normalized = ALLOWED_CATEGORIES.find { |c| c.casecmp(category.to_s.strip).zero? }
      self.category = normalized || category
    end
    # (5a) Garante que o CNPJ seja armazenado apenas como dígitos
    self.cnpj        = cnpj.to_s.gsub(/\D/, '')                                         if cnpj.present?

    # (5.1) Sanitização HTML robusta para páginas legais (Stored XSS mitigation)
    if legal_pages.is_a?(Hash)
      cleaned_pages = {}
      ALLOWED_LEGAL_PAGES.each do |page_key|
        raw_val = legal_pages[page_key] || legal_pages[page_key.to_sym]
        next if raw_val.nil?

        cleaned_pages[page_key] = ActionController::Base.helpers.sanitize(
          raw_val.to_s,
          tags: LEGAL_PAGE_ALLOWED_TAGS,
          attributes: LEGAL_PAGE_ALLOWED_ATTRIBUTES
        ).to_s.strip.truncate(LEGAL_PAGE_MAX_LENGTH)
      end
      self.legal_pages = cleaned_pages
    end

    if public_settings.is_a?(Hash)
      if public_settings['horarios_texto'].present?
        public_settings['horarios_texto'] = ActionView::Base.full_sanitizer.sanitize(public_settings['horarios_texto']).to_s.strip
      end
      if public_settings['theme'].is_a?(Hash)
        theme = public_settings['theme']
        color_regex = /\A#(?:[0-9a-fA-F]{3}){1,2}\z|\Argba\(\d{1,3},\s*\d{1,3},\s*\d{1,3},\s*(?:0|1|0?\.\d+)\)\z/
        theme.each do |key, val|
          if key.to_s.downcase.include?('color') || key.to_s.downcase.include?('bg') || key.to_s.downcase.include?('hover') || key.to_s.downcase.include?('light') || key.to_s.downcase.include?('dark')
            val_str = val.to_s.strip
            unless val_str.match?(color_regex)
              theme[key] = '#ffffff'
            end
          elsif key.to_s == 'fontFamily'
            allowed_fonts = [
              "'Inter', sans-serif",
              "'Plus Jakarta Sans', sans-serif",
              "'Poppins', sans-serif",
              "'Roboto', sans-serif",
              "'Open Sans', sans-serif",
              "'Lato', sans-serif",
              "'Montserrat', sans-serif",
              "'Nunito', sans-serif",
              "'Work Sans', sans-serif",
              "'Rubik', sans-serif",
              "'Playfair Display', serif",
              "'Merriweather', serif",
              "'Lora', serif",
              "'EB Garamond', serif",
              "'Bitter', serif",
              "'Libre Baskerville', serif",
              "'Bebas Neue', sans-serif",
              "'Anton', sans-serif",
              "'Fredoka', sans-serif",
              "'Pacifico', cursive",
              "'Dancing Script', cursive",
              "'Caveat', cursive",
              "'Fira Code', monospace",
              "'JetBrains Mono', monospace",
              "'Space Mono', monospace"
            ]
            unless allowed_fonts.include?(val.to_s.strip)
              theme[key] = "'Inter', sans-serif"
            end
          elsif key.to_s == 'fontSize'
            size_match = val.to_s.strip.match(/\A(\d+)px\z/)
            if size_match
              size_num = size_match[1].to_i
              theme[key] = '16px' if size_num < 12 || size_num > 24
            else
              theme[key] = '16px'
            end
          else
            theme[key] = ActionView::Base.full_sanitizer.sanitize(val.to_s).to_s.strip
          end
        end
      end
    end
  end

  # (5a) Valida os dois dígitos verificadores do CNPJ (Módulo 11)
  def validate_cnpj_digits
    nums = cnpj.to_s.gsub(/\D/, '')
    return if nums.length != 14

    # CNPJ com todos os dígitos iguais é inválido (ex: 00000000000000)
    if nums.chars.uniq.size == 1
      errors.add(:cnpj, 'inválido')
      return
    end

    d1 = cnpj_check_digit(nums[0..11].chars.map(&:to_i), [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2])
    d2 = cnpj_check_digit(nums[0..12].chars.map(&:to_i), [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2])

    unless nums[12] == d1.to_s && nums[13] == d2.to_s
      errors.add(:cnpj, 'inválido')
    end
  end

  def cnpj_check_digit(digits, factors)
    sum = digits.zip(factors).sum { |d, f| d * f }
    remainder = sum % 11
    remainder < 2 ? 0 : 11 - remainder
  end
end
