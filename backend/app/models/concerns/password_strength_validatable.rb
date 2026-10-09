# Concern compartilhado para validação de força de senha.
# Evita duplicação entre User e Customer.
module PasswordStrengthValidatable
  extend ActiveSupport::Concern

  included do
    validate :validate_password_strength, if: -> { password.present? }
  end

  private

  def validate_password_strength
    unless password.match?(/[A-Z]/)
      errors.add(:password, 'deve conter pelo menos uma letra maiúscula')
    end
    unless password.match?(/[a-z]/)
      errors.add(:password, 'deve conter pelo menos uma letra minúscula')
    end
    unless password.match?(/[0-9]/)
      errors.add(:password, 'deve conter pelo menos um número')
    end
    unless password.match?(/[^A-Za-z0-9]/)
      errors.add(:password, 'deve conter pelo menos um caractere especial (símbolo)')
    end

    if password.length < 8
      errors.add(:password, 'deve ter pelo menos 8 caracteres')
    end

    obvious_words = %w[admin senha password 123456 easysloting agendamento barbearia]
    obvious_words.each do |word|
      if password.downcase.include?(word)
        errors.add(:password, "não pode conter termos óbvios como '#{word}'")
      end
    end

    if email.present?
      email_prefix = email.split('@').first
      if email_prefix.length >= 4 && password.downcase.include?(email_prefix.downcase)
        errors.add(:password, 'não pode conter partes do seu e-mail')
      end
    end

    if name.present?
      first_name = name.split(' ').first
      if first_name.length >= 4 && password.downcase.include?(first_name.downcase)
        errors.add(:password, 'não pode conter seu nome')
      end
    end

    # Verifica reuso de senha (usando campo de digest anterior) apenas quando a senha está sendo alterada
    digest_field = respond_to?(:encrypted_password) ? :encrypted_password : :password_digest
    digest_changed = respond_to?("will_save_change_to_#{digest_field}?") ? send("will_save_change_to_#{digest_field}?") : true
    previous_digest = send("#{digest_field}_was") if respond_to?("#{digest_field}_was")
    if previous_digest.present? && digest_changed && !new_record?
      if BCrypt::Password.new(previous_digest) == password
        errors.add(:password, 'não pode ser igual à senha anterior')
      end
    end
  end
end
