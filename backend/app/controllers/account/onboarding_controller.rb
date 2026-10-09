class Account::OnboardingController < ApplicationController
  # Inclui helper para sanitização de strings contra XSS e comandos maliciosos
  include ActionView::Helpers::SanitizeHelper

  def create
    ActiveRecord::Base.transaction do
      # Sanitização rigorosa dos parâmetros recebidos (exceto senhas para não corromper caracteres especiais)
      sanitized_user = sanitize_params(user_params, except: [:password, :password_confirmation])
      sanitized_establishment = sanitize_params(establishment_params)

      user = User.create!(
        name: sanitized_user[:name],
        email: sanitized_user[:email],
        phone: sanitized_user[:phone],
        role: 'owner',
        password: sanitized_user[:password],
        password_confirmation: sanitized_user[:password_confirmation],
        provider: 'email',
        uid: sanitized_user[:email]
      )

      # O slug é gerado/validado no backend para garantir unicidade e segurança na URL
      slug = sanitized_establishment[:slug].presence || sanitized_establishment[:name].parameterize

      establishment = Establishment.create!(
        owner: user,
        name: sanitized_establishment[:name],
        slug: slug,
        cnpj: sanitized_establishment[:cnpj],
        category: sanitized_establishment[:category],
        phone: sanitized_establishment[:phone], # Telefone Fixo
        whatsapp: sanitized_establishment[:whatsapp],
        status: 'active', # Define como ativo ao criar
        legal_pages: EstablishmentDefaults.legal_pages(sanitized_establishment[:name])
      )

      # Cria o endereço associado se fornecido
      if sanitized_establishment[:address].present?
        establishment.create_address!(
          street: sanitized_establishment[:address], # Armazena o endereço completo no campo street por enquanto
          city: 'Não informada',
          state: 'SC', # Default ou vindo do form se expandir futuramente
          zip_code: '00000-000'
        )
      end

      EstablishmentMembership.create!(
        establishment: establishment,
        user: user,
        role: 'owner',
        active: true
      )

      # (5c) Resposta mínima — sem expor campos internos desnecessários
      render json: {
        message: 'Conta empresarial criada com sucesso!',
        user: {
          id:    user.id,
          name:  user.name,
          email: user.email,
          role:  user.role
        },
        establishment: {
          id:   establishment.id,
          name: establishment.name,
          slug: establishment.slug
        }
      }, status: :created
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      message: 'Erro ao criar conta empresarial',
      errors: e.record.errors.full_messages
    }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("[Onboarding] #{e.class}: #{e.message}")
    render json: {
      message: 'Ocorreu um erro ao criar a conta. Tente novamente.',
      errors: ['Ocorreu um erro inesperado. Tente novamente mais tarde.']
    }, status: :internal_server_error
  end

  private

  def sanitize_params(params_hash, except: [])
    except_keys = except.map(&:to_s)
    params_hash.to_h.map do |k, v|
      if except_keys.include?(k.to_s)
        [k, v]
      elsif v.is_a?(String)
        # Remove tags HTML e espaços extras para prevenir XSS e injeções simples
        [k, sanitize(v.strip, tags: [])]
      else
        [k, v]
      end
    end.to_h.with_indifferent_access
  end

  def user_params
    params.require(:user).permit(
      :name,
      :email,
      :phone,
      :password,
      :password_confirmation
    )
  end

  def establishment_params
    params.require(:establishment).permit(
      :name,
      :slug,
      :cnpj,
      :category,
      :phone,
      :whatsapp,
      :address
    )
  end
end