# Exclusão lógica da própria conta. Recebe somente o Customer autenticado,
# nunca um ID do formulário, e mantém as alterações de banco na mesma transação.
class CustomerAccountDeletion
  class InvalidConfirmation < StandardError; end
  class InvalidPassword < StandardError; end
  class AccountLocked < StandardError; end
  class InvalidSession < StandardError; end

  def self.call(customer:, session_id:, confirmation:, password:, ip:, user_agent:)
    result = customer.with_lock do
      raise InvalidSession unless customer.valid_auth_session?(session_id)
      raise InvalidConfirmation unless confirmation.strip.downcase == customer.email

      if customer.access_locked?
        next :locked
      elsif !customer.authenticate(password)
        customer.increment_failed_attempts!
        AuditLogger.log(action: 'account_deletion_failed', user: customer,
                        establishment: customer.establishment, ip: ip, user_agent: user_agent,
                        details: { reason: 'invalid_current_password' })
        # O resultado sai do lock sem rollback do contador de tentativas.
        next :invalid_password
      end

      avatar = customer.image
      now = Time.current
      customer.appointments.where(status: %w[pending confirmed]).update_all(
        status: 'canceled', canceled_at: now,
        cancellation_reason: 'Conta do cliente excluída.', updated_at: now
      )
      customer.appointments.update_all(customer_name_snapshot: 'Conta Excluída', updated_at: now)
      customer.service_package_sales.where(status: 'active').update_all(
        status: 'canceled', cancellation_reason: 'Conta do cliente excluída.', updated_at: now
      )

      customer.update!(
        name: 'Conta Excluída',
        email: "deleted_#{customer.id}_#{SecureRandom.hex(8)}@deleted.local",
        phone: nil, cellphone: nil, image: nil, active: false,
        # O schema exige digest não nulo. Substituir pelo hash de um segredo
        # aleatório descarta a senha antiga sem desabilitar validações/callbacks.
        password_digest: BCrypt::Password.create(SecureRandom.hex(32)).to_s,
        auth_session_id: nil, refresh_token: nil, refresh_token_expires_at: nil,
        reset_password_token: nil, reset_password_sent_at: nil,
        login_otp_code: nil, login_otp_sent_at: nil, login_otp_attempts: 0,
        trusted_ips: [], first_login_at: nil, failed_attempts: 0, locked_at: nil,
        consent_terms_at: nil, consent_privacy_at: nil
      )

      # Aqui a auditoria é parte da transação e falha junto com a exclusão.
      # Não copiar nome/e-mail originais para um novo registro de auditoria.
      AuditLog.create!(action: 'account_deleted', auditable: customer,
                       establishment: customer.establishment, ip_address: ip,
                       details: { event: 'account_deleted', user_agent: user_agent.to_s[0, 500] })
      { avatar: avatar }
    end

    raise AccountLocked if result == :locked
    raise InvalidPassword if result == :invalid_password
    result
  end
end
