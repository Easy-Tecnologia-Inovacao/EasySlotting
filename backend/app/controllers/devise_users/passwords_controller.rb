class DeviseUsers::PasswordsController < DeviseTokenAuth::PasswordsController
  wrap_parameters false

  skip_before_action :authenticate_user!, raise: false
  skip_before_action :require_login, raise: false
  skip_before_action :set_user_by_token, raise: false

  skip_before_action :validate_redirect_url_param, only: [:create]

  def create
    email = params[:email].to_s.downcase.strip

    user = User.find_by(email: email) || User.find_by(uid: email)

    if user.nil?
      render json: {
        success: true,
        message: 'Se o e-mail estiver cadastrado, você receberá um link de redefinição de senha.'
      }
      return
    end

    frontend_url = Rails.configuration.x.frontend_url.to_s.chomp('/')
    redirect_url = "#{frontend_url}/redefinir-senha"

    raw_token, encrypted_token = Devise.token_generator.generate(User, :reset_password_token)

    user.update_columns(
      reset_password_token: encrypted_token,
      reset_password_sent_at: Time.current
    )

    reset_url = "#{redirect_url}?reset_password_token=#{raw_token}"

    Devise::Mailer.reset_password_instructions(user, raw_token, redirect_url: reset_url).deliver_now

    render json: {
      success: true,
      message: 'Se o e-mail estiver cadastrado, você receberá um link de redefinição de senha.'
    }
  rescue => e
    Rails.logger.error("[PasswordReset] #{e.class}: #{e.message}")
    render json: {
      success: true,
      message: 'Se o e-mail estiver cadastrado, você receberá um link de redefinição de senha.'
    }
  end

  def update
    attrs = params.slice(:reset_password_token, :password, :password_confirmation).permit(
      :reset_password_token, :password, :password_confirmation
    )

    user = User.reset_password_by_token(
      reset_password_token: attrs[:reset_password_token],
      password: attrs[:password],
      password_confirmation: attrs[:password_confirmation]
    )

    if user.errors.empty?
      render json: { success: true }
    else
      render json: { errors: user.errors.full_messages }, status: 422
    end
  end
end
