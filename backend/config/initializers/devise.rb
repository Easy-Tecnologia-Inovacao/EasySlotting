# frozen_string_literal: true

Devise.setup do |config|
  config.paranoid = true
  config.mailer_sender = ENV.fetch('EMAIL_FROM', 'noreply@easysloting.com.br')

  require 'devise/orm/active_record'

  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.reconfirmable = false
  config.password_length = 8..128
  config.reset_password_within = 30.minutes
  config.sign_out_via = :delete
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other

  # Lockable — bloqueia conta após 5 tentativas, desbloqueia após 30 min
  config.lock_strategy = :failed_attempts
  config.unlock_keys = [:email]
  config.unlock_strategy = :time
  config.unlock_in = 30.minutes
  config.maximum_attempts = 5
end
