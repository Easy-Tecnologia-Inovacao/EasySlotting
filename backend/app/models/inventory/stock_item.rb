class StockItem < ApplicationRecord
  belongs_to :establishment
  belongs_to :owner_user, class_name: 'User', optional: true

  before_validation :sanitize_data

  validates :name, presence: true, length: { minimum: 2, maximum: 120 }
  validates :sale_price, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999999 }
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 999999 }
  validates :minimum_stock, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 999999 }
  validates :stock_scope, inclusion: { in: %w[loja funcionario] }

  scope :active, -> { where(active: true) }

  # Reduz o estoque de forma atômica
  def decrement_stock!(qty)
    qty = qty.to_i
    return if qty <= 0

    transaction do
      lock! # Bloqueio pessimista (FOR UPDATE)
      
      if quantity < qty
        raise "Estoque insuficiente para o produto '#{name}' (Disponível: #{quantity})."
      end

      self.quantity -= qty
      save!
    end
  end

  # Aumenta o estoque de forma atômica com bloqueio pessimista
  def increment_stock!(qty)
    qty = qty.to_i
    raise ArgumentError, 'A quantidade de entrada deve ser maior que zero' if qty <= 0

    transaction do
      lock! # Bloqueio pessimista (FOR UPDATE)
      self.quantity = [quantity + qty, 999_999].min
      save!
    end
  end

  private

  def sanitize_data
    if name.present?
      # Remove tags HTML, caracteres de controle e espaços extras
      clean_name = ActionView::Base.full_sanitizer.sanitize(name).to_s
      clean_name = clean_name.gsub(/[\x00-\x1f\x7f]/, '').strip
      self.name = clean_name
    end
  end
end