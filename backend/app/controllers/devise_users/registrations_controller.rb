class DeviseUsers::RegistrationsController < DeviseTokenAuth::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :validate_consent!, only: [:create]

  private

  # LGPD: Consentimento obrigatório antes de criar conta
  def validate_consent!
    unless params[:consent_terms] == true && params[:consent_privacy] == true
      render json: {
        error: 'É obrigatório aceitar os Termos de Uso e a Política de Privacidade para criar sua conta.'
      }, status: :unprocessable_entity
    end
  end

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(
      :sign_up,
      keys: [:name, :phone]
    )
  end

  def sign_up_params
    {
      email: params[:email],
      password: params[:password],
      password_confirmation: params[:password_confirmation],
      name: params[:name],
      phone: params[:phone],
      role: 'owner',
      consent_terms_at: params[:consent_terms] == true ? Time.current : nil,
      consent_privacy_at: params[:consent_privacy] == true ? Time.current : nil
    }
  end

  protected

  def render_create_success
    @resource.add_trusted_ip!(request.remote_ip)
    super
  end
end