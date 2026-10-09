# app/models/core/address.rb
# Modelo de endereço físico do estabelecimento.
#
# LGPD: campos de endereço podem conter dados pessoais/localizáveis do proprietário.
# SEGURANÇA (5.1): Todos os campos de texto passam por sanitização HTML antes da gravação
# para evitar Stored XSS, pois o endereço é retornado publicamente via Public::EstablishmentsController.
class Address < ApplicationRecord
  belongs_to :establishment

  before_validation :sanitize_data

  # Limites de tamanho por campo para prevenir payload excessivo e estouro de layout
  validates :street,        length: { maximum: 200 }, allow_blank: true
  validates :number,        length: { maximum:  20 }, allow_blank: true
  validates :neighborhood,  length: { maximum: 100 }, allow_blank: true
  validates :city,          length: { maximum: 100 }, allow_blank: true
  validates :state,         length: { maximum:  50 }, allow_blank: true
  validates :zip_code,      length: { maximum:  20 }, allow_blank: true
  validates :complement,    length: { maximum: 100 }, allow_blank: true
  validates :country,       length: { maximum:  50 }, allow_blank: true

  private

  # Remove todas as tags HTML e caracteres de controle de cada campo de texto.
  # Utiliza o mesmo sanitizador adotado no restante da aplicação (full_sanitizer).
  def sanitize_data
    %i[street number neighborhood city state zip_code complement country].each do |attr|
      val = send(attr)
      next if val.blank?

      cleaned = ActionView::Base.full_sanitizer.sanitize(val.to_s)
                                               .gsub(/[\x00-\x1f\x7f]/, '') # remove chars de controle
                                               .strip
      send(:"#{attr}=", cleaned)
    end
  end
end