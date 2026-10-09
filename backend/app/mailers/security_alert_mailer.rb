# app/mailers/security_alert_mailer.rb
# Mailer para alertas de segurança (novo login, tentativa suspeita, etc.)

class SecurityAlertMailer < ApplicationMailer

  # Alerta de novo login de dispositivo desconhecido
  def new_device_login(user:, ip:, user_agent:, device_info:, location:, login_time:)
    @user = user
    @ip = ip
    @user_agent = user_agent
    @device_info = device_info
    @location = location
    @login_time = login_time
    @support_email = ENV.fetch('SUPPORT_EMAIL', 'suporte@easysloting.com.br')

    mail(
      to: @user.email,
      subject: '🔒 Novo login detectado na sua conta - EasySloting'
    )
  end

  # Alerta de tentativa de login falha
  def failed_login_attempt(user:, ip:, user_agent:, attempt_time:)
    @user = user
    @ip = ip
    @user_agent = user_agent
    @attempt_time = attempt_time
    @support_email = ENV.fetch('SUPPORT_EMAIL', 'suporte@easysloting.com.br')

    mail(
      to: @user.email,
      subject: '⚠️ Tentativa de login na sua conta - EasySloting'
    )
  end

  # Alerta de mudança de senha
  def password_changed(user:, ip:, user_agent:, change_time:)
    @user = user
    @ip = ip
    @user_agent = user_agent
    @change_time = change_time
    @support_email = ENV.fetch('SUPPORT_EMAIL', 'suporte@easysloting.com.br')

    mail(
      to: @user.email,
      subject: '🔑 Sua senha foi alterada - EasySloting'
    )
  end

  # Alerta de conta bloqueada por tentativas falhadas
  def account_locked(user:, ip:, user_agent:, locked_at:)
    @user = user
    @ip = ip
    @user_agent = user_agent
    @locked_at = locked_at
    @support_email = ENV.fetch('SUPPORT_EMAIL', 'suporte@easysloting.com.br')

    mail(
      to: @user.email,
      subject: '🔒 Sua conta foi bloqueada - EasySloting'
    )
  end

  # Código de verificação para novo login/dispositivo (Estilo Discord)
  def login_verification_code(user:, otp_code:, ip:, user_agent:, location:)
    @user = user
    @otp_code = otp_code
    @ip = ip
    @user_agent = user_agent
    @location = location
    @support_email = ENV.fetch('SUPPORT_EMAIL', 'suporte@easysloting.com.br')

    mail(
      to: @user.email,
      subject: "🔑 #{@otp_code} é o seu código de verificação de login - EasySloting"
    )
  end
end
