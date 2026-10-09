# app/controllers/customer_auth/registrations_controller.rb
# Cadastro de customers por estabelecimento (slug).
# Boas práticas:
#  - Parâmetros sanitizados via strong parameters (incluindo phone e cellphone)
#  - Validação estrita de consentimento LGPD (Termos de Uso e Política de Privacidade)
#  - Cadastro sem autenticação automática; dispositivo registrado no primeiro login

class CustomerAuth::RegistrationsController < ApplicationController
  wrap_parameters false

  def create
    establishment = find_establishment
    return unless establishment

    unless params[:consent_terms] == true
      return render json: { errors: ['Você precisa aceitar os Termos de Uso para se cadastrar.'] }, status: :unprocessable_entity
    end

    unless params[:consent_privacy] == true
      return render json: { errors: ['Você precisa aceitar a Política de Privacidade para se cadastrar.'] }, status: :unprocessable_entity
    end

    customer = establishment.customers.new(customer_params)
    customer.consent_terms_at = Time.current
    customer.consent_privacy_at = Time.current
    if customer.save
      render json: { message: 'Conta criada com sucesso! Faça login para continuar.' }, status: :created
    else
      render json: { errors: customer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def find_establishment
    est = Establishment.find_by(slug: params[:slug], active: true)
    render json: { error: 'Estabelecimento não encontrado.' }, status: :not_found unless est
    est
  end

  def customer_params
    params.permit(:name, :email, :password, :password_confirmation, :phone, :cellphone)
  end
end
