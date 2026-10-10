class DeviseUsers::SessionRecoveryController < ApplicationController
  include StaffRecoveryCookie

  rescue_from StaffSessionRecovery::InvalidSession, OwnerSessionPolicy::SessionUnavailable do
    render json: { error: 'Sessão expirada ou encerrada. Entre novamente.' }, status: :unauthorized
  end

  rescue_from StaffSessionRecovery::InvalidCsrf do
    render json: { error: 'Não foi possível validar a recuperação da sessão.' }, status: :forbidden
  end

  def create
    user, headers = StaffSessionRecovery.new(staff_recovery_payload,
      client: request.headers['X-Staff-Client'], uid: request.headers['X-Staff-Uid'],
      csrf: request.headers['X-CSRF-Token']).restore!
    response.headers.merge!(headers)
    data = user.token_validation_response.merge(
      password_expired: user.password_changed_at.nil? || user.password_changed_at < 90.days.ago)
    render json: { data: data }
  end
end
