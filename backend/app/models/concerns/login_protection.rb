require 'ipaddr'

# Regras comuns de login, aplicadas no servidor para staff e clientes.
module LoginProtection
  extend ActiveSupport::Concern

  MAX_FAILED_ATTEMPTS = 5
  LOCK_DURATION = 30.minutes
  OTP_LIFETIME = 10.minutes
  OTP_COOLDOWN = 60.seconds
  MAX_OTP_ATTEMPTS = 5
  DEVICE_TOKEN_FORMAT = /\A[a-zA-Z0-9_-]{8,64}\z/

  def access_locked?
    locked_at.present? && locked_at > LOCK_DURATION.ago
  end

  def increment_failed_attempts!
    with_lock do
      count = locked_at.present? && !access_locked? ? 1 : failed_attempts.to_i + 1
      update_columns(failed_attempts: count, locked_at: count >= MAX_FAILED_ATTEMPTS ? Time.current : nil)
    end
  end

  def reset_failed_attempts!
    with_lock { update_columns(failed_attempts: 0, locked_at: nil) }
  end

  def first_successful_login?
    first_login_at.nil?
  end

  def login_otp_required?(ip:)
    first_successful_login? || !trusted_ip?(ip: ip)
  end

  def trusted_ip?(ip:)
    address = normalized_login_ip(ip)
    address.present? && Array(trusted_ips).filter_map { |entry| normalized_login_ip(entry) }.include?(address)
  end

  def add_trusted_ip!(ip:)
    address = normalized_login_ip(ip)
    return unless address

    with_lock do
      # Descarta hashes de aparelhos legados; só IPs confirmados dispensam OTP.
      entries = Array(trusted_ips).filter_map { |entry| normalized_login_ip(entry) }
      entries << address
      update_columns(trusted_ips: entries.uniq.last(30), first_login_at: first_login_at || Time.current)
    end
  end

  def generate_login_otp!(ip:, device_token:)
    with_lock do
      # O reenvio não reinicia o limite de tentativas e não permite flood de e-mail.
      return nil if login_otp_sent_at.present? && login_otp_sent_at > OTP_COOLDOWN.ago

      code = format('%06d', SecureRandom.random_number(1_000_000))
      update_columns(login_otp_code: otp_digest(code, ip, device_token),
                     login_otp_sent_at: Time.current, login_otp_attempts: 0)
      code
    end
  end

  def verify_login_otp(code, ip:, device_token:)
    with_lock do
      return false if login_otp_code.blank? || login_otp_sent_at.blank? ||
                      login_otp_sent_at < OTP_LIFETIME.ago || login_otp_attempts >= MAX_OTP_ATTEMPTS

      matches = code.is_a?(String) && code.match?(/\A\d{6}\z/) &&
                ActiveSupport::SecurityUtils.secure_compare(login_otp_code, otp_digest(code, ip, device_token))
      if matches
        update_columns(login_otp_code: nil, login_otp_sent_at: nil, login_otp_attempts: 0)
      else
        attempts = login_otp_attempts + 1
        update_columns(login_otp_attempts: attempts,
                       login_otp_code: attempts >= MAX_OTP_ATTEMPTS ? nil : login_otp_code)
      end
      matches
    end
  end

  private

  def normalized_login_ip(ip)
    return unless ip.is_a?(String) && ip.bytesize.between?(1, 64) && !ip.include?('/')
    IPAddr.new(ip).to_s
  rescue IPAddr::InvalidAddressError
    nil
  end

  def otp_digest(code, ip, device_token)
    data = [self.class.name, id, code, ip, device_token].to_json
    OpenSSL::HMAC.hexdigest('SHA256', Rails.application.secret_key_base, data)
  end
end
