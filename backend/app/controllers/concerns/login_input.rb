module LoginInput
  extend ActiveSupport::Concern

  included do
    before_action :validate_login_input!, only: :create
  end

  private

  def validate_login_input!
    email = params[:email]
    password = params[:password]
    otp = params[:otp_code]
    device = request.headers['X-Device-Token'].presence || params[:device_token]
    valid = email.is_a?(String) && email.bytesize <= 254 && email.strip.match?(URI::MailTo::EMAIL_REGEXP) &&
            password.is_a?(String) && password.bytesize.between?(1, 128) &&
            (otp.nil? || (otp.is_a?(String) && otp.match?(/\A\d{6}\z/))) &&
            (device.nil? || (device.is_a?(String) && device.match?(LoginProtection::DEVICE_TOKEN_FORMAT)))

    unless valid
      render json: { error: 'Dados de login inválidos.', errors: ['Dados de login inválidos.'] }, status: :unprocessable_entity
      return
    end

    params[:email] = email.strip.downcase
  end

  def sanitized_device_token
    request.headers['X-Device-Token'].presence || params[:device_token]
  end
end
